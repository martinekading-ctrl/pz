extends Node2D

signal melee_impact(origin: Vector2, direction: Vector2)

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
var aim_visible := false
var traversal_active := false
var traversal_elapsed := 0.0
var traversal_duration := 0.65
var traversal_start := Vector2.ZERO
var traversal_end := Vector2.ZERO

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	firearm_cooldown = maxf(0.0, firearm_cooldown - delta)
	muzzle_flash = maxf(0.0, muzzle_flash - delta)
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
	queue_redraw()
	return true

func start_melee() -> bool:
	if swing_remaining>0.0:
		return false
	swing_remaining=weapon_swing_seconds
	impact_pending=true
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
	moving=traveled>0.0001
	if moving: gait+=traveled*TAU/(1.3 if running else 0.9)
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
	if away.length_squared()>0.01:
		move_world(away*5.0)
	queue_redraw()


func _draw() -> void:
	var active:=moving and is_physics_processing()
	var stride:=sin(gait)*(14.0 if running else 9.0) if active else 0.0
	var bob:=absf(sin(gait))*3.0 if active else 0.0
	var lower:=25.0 if crouching else 0.0
	var hip:=Vector2(0,-43+lower*.6-bob)
	var chest:=Vector2(facing.x*3,-79+lower-bob)
	var head:=Vector2(facing.x*4,-99+lower-bob)
	draw_actor_shadow(Vector2(0,3),Vector2(17,7),Color(0,0,0,.3))
	for side in [-1,1]:
		var foot: Vector2=Vector2(side*7,0)+facing*stride*side
		var knee: Vector2=(hip+foot)*.5+Vector2(facing.x*5,0)
		draw_polyline(PackedVector2Array([hip+Vector2(side*5,0),knee,foot]),Color("343a40"),9,true)
		draw_line(foot-Vector2(4,0),foot+Vector2(6,0),Color("202629"),7,true)
	draw_line(hip,chest,Color.WHITE if hurt_flash>0.0 else Color("516049"),25,true)
	var attack:=1.0-swing_remaining/maxf(0.01,weapon_swing_seconds)
	for side in [-1,1]:
		var shoulder:=chest+Vector2(side*13,4)
		var hand: Vector2=hip+Vector2(side*17,0)-facing*stride*side*.65
		if side==1 and weapon_is_firearm:
			hand = chest + facing * 29.0 + Vector2(side * 3.0, 2.0)
			if weapon_visual_length > 0.0:
				draw_line(hand - facing * 7.0, hand + facing * weapon_visual_length, weapon_visual_color, 7, true)
		elif side==1 and swing_remaining>0:
			var arc:=facing.rotated(lerpf(-1.4,1.3,sin(attack*PI*.5)))
			hand=chest+arc*35
			if weapon_visual_length>0.0:
				draw_line(hand,hand+arc*weapon_visual_length,weapon_visual_color,5,true)
		draw_line(shoulder,hand,Color("45513e"),8,true)
		draw_circle(hand,4,Color("bd9c78"))
		if side==1 and not weapon_is_firearm and swing_remaining<=0.0 and weapon_visual_length>0.0:
			var rest_direction:=facing.rotated(-0.18)
			draw_line(hand,hand+rest_direction*weapon_visual_length,weapon_visual_color,5,true)
	draw_circle(head,11,Color("bd9c78"))
	draw_arc(head,11,PI,TAU,12,Color("39382e"),5,true)
	if facing.y>=0:
		draw_circle(head+facing*6+Vector2(3,-1),1.6,Color("242722"))
	else:
		draw_line(chest+Vector2(0,8),hip+Vector2(0,-4),Color("786e51"),17,true)
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

func draw_actor_shadow(center: Vector2,radius: Vector2,color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24: points.append(center+Vector2(cos(i*TAU/24.0)*radius.x,sin(i*TAU/24.0)*radius.y))
	draw_colored_polygon(points,color)
