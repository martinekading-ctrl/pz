extends Node2D

var live_visual: Node2D

signal melee_impact(origin: Vector2, direction: Vector2)
signal melee_started(origin: Vector2, direction: Vector2)

var world_map: Node2D
var controls: Node
const Metrics = preload("res://scripts/player_metrics.gd")
var facing := Vector2.DOWN
var facing_index := 2
var gait := 0.0
var moving := false
var crouching := false
var running := false
var swing_remaining := 0.0
var velocity_mps := Vector2.ZERO
var impact_pending := false
var hurt_flash := 0.0
var survival_speed_multiplier := 1.0
var run_allowed := true
var weapon_swing_seconds := Metrics.SWING_SECONDS
var weapon_visual_length := 30.0
var weapon_visual_color := Color("9a7060")
var request_attack_stamina: Callable
var request_firearm_shot: Callable
var weapon_is_firearm := false
var firearm_cooldown_seconds := 0.26
var firearm_cooldown := 0.0
var muzzle_flash := 0.0
var firearm_recoil := 0.0
var aim_visible := false
var dead := false
var hurt_recoil := Vector2.ZERO
var traversal_active := false
var traversal_elapsed := 0.0
var traversal_duration := 0.65
var traversal_start := Vector2.ZERO
var traversal_end := Vector2.ZERO

func _ready() -> void:
	live_visual = preload("res://scripts/live_actor_3d.gd").new()
	live_visual.kind = "player"
	add_child(live_visual)
	queue_redraw()

func _physics_process(delta: float) -> void:
	firearm_cooldown = maxf(0.0, firearm_cooldown - delta)
	muzzle_flash = maxf(0.0, muzzle_flash - delta)
	firearm_recoil = maxf(0.0, firearm_recoil - delta)
	if traversal_active:
		update_traversal(delta)
		hurt_flash=maxf(0.0,hurt_flash-delta)
		queue_redraw()
		return
	var direction: Vector2 = controls.movement_vector() if is_instance_valid(controls) else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	crouching = controls.wants_crouch() if is_instance_valid(controls) else Input.is_action_pressed("crouch")
	running = (controls.wants_run() if is_instance_valid(controls) else Input.is_action_pressed("run")) and not crouching and run_allowed
	var touch_aim: Vector2 = controls.aim_vector() if is_instance_valid(controls) else Vector2.ZERO
	aim_visible = touch_aim.length_squared() > 0.01 or (controls.mouse_aiming() if is_instance_valid(controls) else Input.is_action_pressed("aim"))
	if touch_aim.length_squared() > 0.01:
		set_facing(touch_aim)
	elif (controls.mouse_aiming() if is_instance_valid(controls) else Input.is_action_pressed("aim")):
		set_facing(get_global_mouse_position()-position)
	elif direction.length_squared()>0:
		set_facing(direction)
	var attack_requested: bool = controls.consume_attack_request() if is_instance_valid(controls) else Input.is_action_pressed("attack")
	if attack_requested:
		var attack_aim: Vector2 = controls.consume_attack_aim() if is_instance_valid(controls) else Vector2.ZERO
		if attack_aim.length_squared() > 0.01:
			set_facing(attack_aim)
		if weapon_is_firearm:
			try_firearm(aim_visible or attack_aim.length_squared() > 0.01)
		elif swing_remaining <= 0.0 and (not request_attack_stamina.is_valid() or bool(request_attack_stamina.call())):
			start_melee()
	step_motion(direction,delta)
	hurt_flash=maxf(0.0,hurt_flash-delta)
	queue_redraw()

func begin_traversal(destination: Vector2,duration: float = 0.65) -> bool:
	if traversal_active:
		return false
	traversal_active=true
	traversal_elapsed=0.0
	traversal_duration=maxf(0.1,duration)
	traversal_start=position
	traversal_end=destination
	moving=false
	running=false
	crouching=true
	set_facing(destination-position)
	return true

func update_traversal(delta: float) -> void:
	traversal_elapsed+=delta
	var t:=clampf(traversal_elapsed/traversal_duration,0.0,1.0)
	var eased:=t*t*(3.0-2.0*t)
	position=traversal_start.lerp(traversal_end,eased)+Vector2(0,-sin(t*PI)*18.0)
	update_depth()
	if t>=1.0:
		position=traversal_end
		traversal_active=false
		crouching=false
		update_depth()

func try_firearm(aiming: bool) -> bool:
	if firearm_cooldown > 0.0 or not request_firearm_shot.is_valid():
		return false
	if not bool(request_firearm_shot.call(position, facing, aiming)):
		return false
	firearm_cooldown = firearm_cooldown_seconds
	muzzle_flash = 0.09
	firearm_recoil = 0.13
	queue_redraw()
	return true

func start_melee() -> bool:
	if swing_remaining>0.0:
		return false
	swing_remaining=weapon_swing_seconds
	impact_pending=true
	melee_started.emit(position, facing)
	queue_redraw()
	return true

func set_facing(direction: Vector2) -> void:
	if direction.length_squared()<0.01: return
	facing_index=posmod(roundi(direction.angle()/(PI/4)),8)
	facing=Vector2.from_angle(facing_index*PI/4)

func step_motion(direction: Vector2,delta: float) -> void:
	var meters_per_second: float=(Metrics.CROUCH_MPS if crouching else (Metrics.RUN_MPS if running else Metrics.WALK_MPS))*survival_speed_multiplier
	if swing_remaining>0:
		swing_remaining=maxf(0,swing_remaining-delta)
		if impact_pending and swing_remaining<=weapon_swing_seconds*0.56:
			impact_pending=false
			melee_impact.emit(position,facing)
		meters_per_second*=0.25
	# Input follows the screen; physical speed is normalized after inverse projection.
	var logical_direction: Vector2=world_map.world_to_map(direction).normalized()
	velocity_mps=logical_direction*meters_per_second*minf(1,direction.length())
	var before:=position
	move_world(world_map.map_to_world(velocity_mps/Metrics.CELL_METERS)*delta)
	var traveled: float=world_map.world_to_map(position-before).length()*Metrics.CELL_METERS
	# Animation follows resolved movement, including slowing against obstacles.
	velocity_mps=world_map.world_to_map(position-before)*Metrics.CELL_METERS/maxf(delta,0.00001)
	moving=traveled>0.0001
	if moving: gait+=traveled*TAU/(Metrics.CROUCH_CYCLE_METERS if crouching else (Metrics.RUN_CYCLE_METERS if running else Metrics.WALK_CYCLE_METERS))
	else: velocity_mps=Vector2.ZERO
	queue_redraw()

func can_stand(point: Vector2) -> bool:
	# Sample a 0.25 m physical radius in map space, including diagonal contacts.
	var logical: Vector2 = world_map.world_to_map(point)
	for i in 16:
		var offset := Vector2(cos(i*TAU/16.0),sin(i*TAU/16.0))*Metrics.RADIUS_METERS/Metrics.CELL_METERS
		if not world_map.is_walkable_world(world_map.map_to_world(logical+offset)): return false
	if not world_map.is_walkable_world(point): return false
	return true

func move_world(displacement: Vector2) -> void:
	var steps := maxi(1,ceili(displacement.length()/3.0))
	var step := displacement/steps
	for i in steps:
		if can_stand(position+step):
			position += step
		else:
			# Slide along map axes, which follow the isometric walls.
			var logical_step: Vector2=world_map.world_to_map(step)
			for axis in [Vector2(logical_step.x,0),Vector2(0,logical_step.y)]:
				var projected: Vector2=world_map.map_to_world(axis)
				if can_stand(position+projected): position+=projected
	update_depth()

func update_depth() -> void:
	z_index = roundi((position.y)*0.2)
	var logical: Vector2 = world_map.world_to_map(position)
	for building in world_map.interactive_buildings:
		var area: Rect2 = building.get_search_area()
		# A whole actor standing in front of a facade must sort past every panel
		# touched by its silhouette, including the panels beside a corner.
		if area.grow(1.4).has_point(logical) and not area.has_point(logical):
			if logical.x >= area.end.x or logical.y >= area.end.y:
				z_index = maxi(z_index,roundi((position.y+30.0)*0.2))

func receive_hit(source_world: Vector2) -> void:
	hurt_flash=0.14
	var away:=(position-source_world).normalized()
	hurt_recoil=away
	if away.length_squared()>0.01:
		move_world(away*5.0)
	queue_redraw()

func set_dead_pose(value: bool) -> void:
	dead = value
	if value:
		moving = false
		running = false
	queue_redraw()

func attack_phase() -> String:
	if swing_remaining <= 0.0:
		return "none"
	var progress := 1.0 - swing_remaining / maxf(0.01, weapon_swing_seconds)
	if progress < 0.28:
		return "windup"
	if progress < 0.62:
		return "impact"
	return "recover"

func presentation_state() -> String:
	if dead:
		return "dead"
	if traversal_active:
		return "climb"
	if hurt_flash > 0.0:
		return "hurt"
	if swing_remaining > 0.0:
		return "melee_" + attack_phase()
	if firearm_recoil > 0.0:
		return "fire"
	if crouching:
		return "crouch_walk" if moving else "crouch_idle"
	if moving:
		return "run" if running else "walk"
	return "aim" if aim_visible else "idle"

func _draw() -> void:
	if is_instance_valid(live_visual):
		return
	draw_actor_shadow(Vector2(0, 4), Vector2(19, 8), Color(0, 0, 0, 0.32))
	if dead:
		draw_dead_pose()
		return
	var active := moving and is_physics_processing()
	var step_wave := sin(gait) if active else 0.0
	var stride := step_wave * (15.0 if running else 10.0)
	var bob := absf(sin(gait * 2.0)) * (3.2 if running else 2.0) if active else 0.0
	var crouch_drop := 22.0 if crouching else 0.0
	var attack_progress := 1.0 - swing_remaining / maxf(0.01, weapon_swing_seconds)
	var recoil_amount := firearm_recoil / 0.13 if firearm_recoil > 0.0 else 0.0
	var body_offset := -hurt_recoil * (hurt_flash / 0.14) * 7.0 if hurt_flash > 0.0 else Vector2.ZERO
	var lean := facing.angle() * 0.0
	if running and active:
		lean = clampf(facing.x * 0.055, -0.055, 0.055)
	elif hurt_flash > 0.0:
		lean = -hurt_recoil.x * 0.09
	draw_set_transform(body_offset, lean, Vector2.ONE)
	var hip := Vector2(0, -43 + crouch_drop * 0.55 - bob)
	var chest := Vector2(facing.x * 3.0, -78 + crouch_drop - bob)
	var head := Vector2(facing.x * 5.0, -101 + crouch_drop - bob)
	var side_vector := Vector2(-facing.y, facing.x)
	# Backpack reads clearly from both front and rear while staying behind the arms.
	var pack_center := chest - facing * 5.0 + Vector2(0, 5)
	draw_colored_polygon(PackedVector2Array([
		pack_center + Vector2(-12, -12), pack_center + Vector2(12, -12),
		pack_center + Vector2(14, 14), pack_center + Vector2(-14, 14)
	]), Color("514b37"))
	draw_line(pack_center + Vector2(-9, -7), pack_center + Vector2(-9, 10), Color("80755a"), 2.0)
	draw_line(pack_center + Vector2(9, -7), pack_center + Vector2(9, 10), Color("80755a"), 2.0)
	# Feet plant on alternating frames; knees bend instead of sliding as a single stick.
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(side * 7.0, 0.0) + facing * stride * side
		if crouching:
			foot += side_vector * side * 4.0
		var knee := hip.lerp(foot, 0.5) + side_vector * side * 3.0 - facing * absf(stride) * 0.16
		draw_line(hip + side_vector * side * 5.0, knee, Color("39434a"), 10.0, true)
		draw_line(knee, foot, Color("2f383e"), 9.0, true)
		draw_line(foot - facing * 3.0 - side_vector * 4.0, foot + facing * 5.0 + side_vector * 4.0, Color("222729"), 7.0, true)
	# Jacket has a readable torso shape, collar and center seam.
	var jacket := Color.WHITE if hurt_flash > 0.0 else Color("52624d")
	draw_colored_polygon(PackedVector2Array([
		chest + Vector2(-14, -10), chest + Vector2(14, -10),
		hip + Vector2(11, 4), hip + Vector2(-11, 4)
	]), jacket)
	draw_polyline(PackedVector2Array([chest + Vector2(-14, -10), chest + Vector2(14, -10), hip + Vector2(11, 4), hip + Vector2(-11, 4), chest + Vector2(-14, -10)]), Color("2d372d"), 2.5, true)
	draw_line(chest + Vector2(0, -7), hip + Vector2(0, 2), Color("84907b"), 2.0)
	var weapon_direction := facing.rotated(-0.18)
	if swing_remaining > 0.0:
		var swing_angle: float
		if attack_progress < 0.28:
			swing_angle = lerpf(-1.55, -1.15, attack_progress / 0.28)
		elif attack_progress < 0.62:
			swing_angle = lerpf(-1.15, 0.75, (attack_progress - 0.28) / 0.34)
		else:
			swing_angle = lerpf(0.75, -0.18, (attack_progress - 0.62) / 0.38)
		weapon_direction = facing.rotated(swing_angle)
		if attack_phase() == "impact" and weapon_visual_length > 0.0:
			var trail_color := Color(0.94, 0.86, 0.63, 0.38)
			draw_arc(chest, 50.0 + weapon_visual_length * 0.35, facing.angle() - 1.0, weapon_direction.angle(), 16, trail_color, 4.0, true)
	for side: float in [-1.0, 1.0]:
		var shoulder := chest + side_vector * side * 13.0 + Vector2(0, 3)
		var hand := hip + side_vector * side * 16.0 - facing * stride * side * 0.55
		if weapon_is_firearm:
			hand = chest + facing * (28.0 - recoil_amount * 6.0) + side_vector * side * 4.0
		elif side > 0.0 and swing_remaining > 0.0:
			hand = chest + weapon_direction * 34.0
		draw_line(shoulder, hand, jacket.darkened(0.12), 8.0, true)
		draw_circle(hand, 4.0, Color("bd9c78"))
		if side > 0.0 and weapon_visual_length > 0.0:
			if weapon_is_firearm:
				draw_line(hand - facing * 6.0, hand + facing * weapon_visual_length, weapon_visual_color, 7.0, true)
			elif swing_remaining > 0.0:
				draw_line(hand, hand + weapon_direction * weapon_visual_length, weapon_visual_color, 6.0, true)
			else:
				draw_line(hand, hand + weapon_direction * weapon_visual_length, weapon_visual_color, 5.0, true)
	# Head, hair, ear and face marker give direction without oversized arrows.
	draw_circle(head, 12.0, Color.WHITE if hurt_flash > 0.0 else Color("bd9c78"))
	draw_arc(head + Vector2(0, -1), 11.5, PI * 0.92, TAU * 1.06, 16, Color("35362f"), 6.0, true)
	draw_circle(head - side_vector * 10.0, 2.5, Color("a98768"))
	if facing.y >= -0.25:
		draw_circle(head + facing * 7.0 + side_vector * 3.2, 1.5, Color("202522"))
		draw_line(head + facing * 8.0 - side_vector * 4.0, head + facing * 8.0 + side_vector * 4.0, Color("765449"), 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if weapon_is_firearm and aim_visible:
		var muzzle := chest + facing * (47.0 + weapon_visual_length)
		draw_dashed_line(muzzle, muzzle + facing * 118.0, Color(0.92, 0.82, 0.5, 0.48), 2.0, 8.0, true)
		var reticle := muzzle + facing * 126.0
		draw_arc(reticle, 8.0, 0.0, TAU, 18, Color("e8d58a"), 2.0, true)
		draw_line(reticle - Vector2(12, 0), reticle - Vector2(5, 0), Color("e8d58a"), 2.0)
		draw_line(reticle + Vector2(5, 0), reticle + Vector2(12, 0), Color("e8d58a"), 2.0)
	if weapon_is_firearm and muzzle_flash > 0.0:
		var muzzle := chest + facing * (49.0 + weapon_visual_length)
		draw_circle(muzzle, 8.0, Color(1.0, 0.76, 0.25, 0.9))
		draw_circle(muzzle, 3.0, Color(1.0, 0.95, 0.68, 1.0))

func draw_dead_pose() -> void:
	draw_line(Vector2(-31, -4), Vector2(19, 7), Color("39434a"), 17.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -17), Vector2(18, -10), Vector2(22, 9), Vector2(-19, 4)]), Color("52624d"))
	draw_circle(Vector2(31, 8), 12.0, Color("bd9c78"))
	draw_line(Vector2(-7, -3), Vector2(-30, 16), Color("45513e"), 8.0, true)
	draw_line(Vector2(8, -1), Vector2(31, -12), Color("45513e"), 8.0, true)

func draw_actor_shadow(center: Vector2,radius: Vector2,color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24: points.append(center+Vector2(cos(i*TAU/24.0)*radius.x,sin(i*TAU/24.0)*radius.y))
	draw_colored_polygon(points,color)
