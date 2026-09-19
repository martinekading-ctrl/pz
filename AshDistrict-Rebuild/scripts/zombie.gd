extends Node2D

const Metrics = preload("res://scripts/player_metrics.gd")
const Combat = preload("res://scripts/combat_rules.gd")

enum State { IDLE, WANDER, CHASE, ATTACK, STAGGER, DEAD, INVESTIGATE, SLEEPING, BREACH, CLIMB }

var game: Node2D
var world_map: Node2D
var target: Node2D
var state: State = State.IDLE
var health := 68
var facing := Vector2.DOWN
var gait := 0.0
var state_time := 0.0
var attack_cooldown := 0.0
var attack_committed := false
var alerted := false
var wander_target := Vector2.ZERO
var tint := Color("8f9976")
var visual_flash := 0.0
var spawn_index := 0
var investigate_target := Vector2.ZERO
var investigate_time := 0.0
var spawn_zone := "road"
var home_building_id := ""
var dormant := false
var corpse_inventory := {}
var corpse_searched := false
var corpse_highlight := false
var barrier_attack_timer := 0.0
var climb_start := Vector2.ZERO
var climb_end := Vector2.ZERO
var climb_elapsed := 0.0
var climb_duration := 0.9

func setup(owner: Node2D, map: Node2D, player: Node2D, logical_position: Vector2, index: int, profile: Dictionary = {}) -> void:
	game = owner
	world_map = map
	target = player
	spawn_index = index
	position = world_map.map_to_world(logical_position)
	spawn_zone = str(profile.get("zone", "road"))
	home_building_id = str(profile.get("home_building_id", ""))
	corpse_inventory = profile.get("corpse_loot", {}).duplicate(true)
	corpse_searched = bool(profile.get("corpse_searched", false))
	dormant = bool(profile.get("sleeping", false))
	if dormant:
		change_state(State.SLEEPING)
	tint = [Color("8f9976"), Color("90907b"), Color("7f8c78"), Color("9a8875")][index % 4]
	wander_target = logical_position + Vector2(3.0 if index % 2 == 0 else -3.0, 2.0)
	queue_redraw()

func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	if game.gameplay_blocked():
		return
	state_time += delta
	investigate_time = maxf(0.0, investigate_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	visual_flash = maxf(0.0, visual_flash - delta)
	if state==State.CLIMB:
		update_climb(delta)
		queue_redraw()
		return
	var distance := Combat.distance_meters(world_map, position, target.position)
	var visible := distance <= 10.0 and has_line_of_sight(target.position)
	if state == State.SLEEPING:
		if distance <= 2.2 or (distance <= 6.5 and visible):
			alerted = true
			change_state(State.CHASE)
		queue_redraw()
		return
	if visible or distance <= 3.5:
		alerted = true
	if state == State.STAGGER:
		if state_time >= 0.22:
			change_state(State.CHASE if alerted else (State.INVESTIGATE if investigate_time > 0.0 else State.IDLE))
		queue_redraw()
		return
	if state == State.ATTACK:
		update_attack(distance)
		queue_redraw()
		return
	if alerted:
		var entry: Dictionary=world_map.entry_between(position,target.position)
		if not entry.is_empty() and update_entry(entry,delta):
			queue_redraw()
			return
		if distance <= Combat.ZOMBIE_ATTACK_RANGE_METERS and attack_cooldown <= 0.0 and visible:
			change_state(State.ATTACK)
		else:
			change_state_if_needed(State.CHASE)
			move_toward_world(target.position, 1.05, delta)
	elif state == State.INVESTIGATE:
		update_investigate(delta)
	else:
		update_wander(delta)
	queue_redraw()

func update_entry(entry: Dictionary,delta: float) -> bool:
	var entry_distance:=Combat.distance_meters(world_map,position,entry.position)
	if entry_distance>0.72:
		change_state_if_needed(State.CHASE)
		move_toward_world(entry.position,1.05,delta)
		return true
	if str(entry.type)=="door":
		var door: Node2D=entry.door
		if door.broken or (door.opened and door.amount>0.78):
			move_toward_world(target.position,1.05,delta)
			return true
		return attack_barrier(entry,delta)
	var building: Node2D=entry.building
	var index:=int(entry.index)
	if building.barricade_layers(index)<=0 and building.window_state(index) in ["open","broken"]:
		var crossing: Dictionary=building.window_crossing(index,position)
		if crossing.is_empty(): return true
		climb_start=position
		climb_end=crossing.destination
		climb_elapsed=0.0
		change_state(State.CLIMB)
		return true
	return attack_barrier(entry,delta)

func attack_barrier(entry: Dictionary,delta: float) -> bool:
	change_state_if_needed(State.BREACH)
	barrier_attack_timer-=delta
	if barrier_attack_timer>0.0:
		return true
	barrier_attack_timer=0.82
	facing=(entry.position-position).normalized()
	var result: Dictionary
	if str(entry.type)=="door":
		result=entry.door.damage(18.0)
		result["event"]="door_broken" if bool(result.just_broken) else "door_hit"
	else:
		result=entry.building.damage_window(int(entry.index),18.0)
	game.on_barrier_damaged(entry,result,position)
	return true

func update_climb(delta: float) -> void:
	climb_elapsed+=delta
	var t:=clampf(climb_elapsed/climb_duration,0.0,1.0)
	var eased:=t*t*(3.0-2.0*t)
	position=climb_start.lerp(climb_end,eased)+Vector2(0,-sin(t*PI)*12.0)
	z_index=roundi(position.y*0.2)+1
	if t>=1.0:
		position=climb_end
		change_state(State.CHASE)

func update_wander(delta: float) -> void:
	if state == State.IDLE and state_time >= 1.5 + float(spawn_index % 3) * 0.45:
		change_state(State.WANDER)
	if state != State.WANDER:
		return
	var target_world: Vector2 = world_map.map_to_world(wander_target)
	if Combat.distance_meters(world_map, position, target_world) < 0.3 or state_time > 4.5:
		var logical: Vector2 = world_map.world_to_map(position)
		var angle := float((spawn_index * 97 + int(Time.get_ticks_msec() / 1000)) % 360) * PI / 180.0
		wander_target = logical + Vector2.from_angle(angle) * (3.0 + float(spawn_index % 3))
		change_state(State.IDLE)
		return
	move_toward_world(target_world, 0.42, delta)

func update_investigate(delta: float) -> void:
	if investigate_time <= 0.0 or Combat.distance_meters(world_map, position, investigate_target) < 0.35:
		change_state(State.IDLE)
		return
	move_toward_world(investigate_target, 0.68, delta)

func hear_sound(source: Vector2, radius_meters: float) -> bool:
	if state == State.DEAD or alerted:
		return false
	var effective_radius := radius_meters if has_line_of_sight(source) else radius_meters * 0.55
	if Combat.distance_meters(world_map, position, source) > effective_radius:
		return false
	investigate_target = source
	investigate_time = 8.0
	dormant = false
	if state not in [State.ATTACK, State.STAGGER]:
		change_state(State.INVESTIGATE)
	queue_redraw()
	return true

func update_attack(distance: float) -> void:
	facing = (target.position - position).normalized()
	if not attack_committed and state_time >= 0.38:
		attack_committed = true
		if distance <= Combat.ZOMBIE_ATTACK_RANGE_METERS + 0.12 and has_line_of_sight(target.position):
			game.damage_player(Combat.ZOMBIE_ATTACK_DAMAGE, position)
	if state_time >= 0.82:
		attack_cooldown = 0.72
		change_state(State.CHASE)

func move_toward_world(destination: Vector2, speed_mps: float, delta: float) -> void:
	var desired := destination - position
	if desired.length_squared() < 0.01:
		return
	facing = desired.normalized()
	var logical_direction: Vector2 = world_map.world_to_map(desired).normalized()
	var world_velocity: Vector2 = world_map.map_to_world(logical_direction * speed_mps / Metrics.CELL_METERS)
	var distance: float = world_velocity.length() * delta
	var directions := [0.0, 0.28, -0.28, 0.58, -0.58, 0.92, -0.92, PI]
	for angle: float in directions:
		var step: Vector2 = world_velocity.rotated(angle).normalized() * distance
		if can_stand(position + step):
			position += step
			gait += speed_mps * delta * TAU / 0.85
			z_index = roundi(position.y * 0.2) + 1
			return

func can_stand(point: Vector2) -> bool:
	var logical: Vector2 = world_map.world_to_map(point)
	for i: int in 10:
		var offset := Vector2.from_angle(float(i) * TAU / 10.0) * 0.23 / Metrics.CELL_METERS
		if not world_map.is_walkable_world(world_map.map_to_world(logical + offset)):
			return false
	for other: Node2D in game.zombies:
		if other != self and other.state != State.DEAD and Combat.distance_meters(world_map, point, other.position) < 0.48:
			return false
	return true

func has_line_of_sight(point: Vector2) -> bool:
	var distance := position.distance_to(point)
	var samples := maxi(2, ceili(distance / 18.0))
	for i: int in range(1, samples):
		if not world_map.is_walkable_world(position.lerp(point, float(i) / float(samples))):
			return false
	return true

func take_hit(damage: int, from_position: Vector2, knockback_meters: float) -> void:
	if state == State.DEAD:
		return
	health = maxi(0, health - damage)
	dormant = false
	alerted = true
	visual_flash = 0.12
	var away := (position - from_position).normalized()
	var logical_away: Vector2 = world_map.world_to_map(away).normalized()
	var destination: Vector2 = position + world_map.map_to_world(logical_away * knockback_meters / Metrics.CELL_METERS)
	if can_stand(destination):
		position = destination
	if health <= 0:
		change_state(State.DEAD)
		z_index = roundi(position.y * 0.2) - 1
	else:
		change_state(State.STAGGER)
	queue_redraw()

func change_state(next_state: State) -> void:
	state = next_state
	dormant = next_state == State.SLEEPING
	state_time = 0.0
	attack_committed = false

func change_state_if_needed(next_state: State) -> void:
	if state != next_state:
		change_state(next_state)

func is_dead() -> bool:
	return state == State.DEAD

func has_corpse_items() -> bool:
	for amount in corpse_inventory.values():
		if int(amount) > 0:
			return true
	return false

func is_corpse_searchable() -> bool:
	return is_dead() and (not corpse_searched or has_corpse_items())

func set_corpse_highlight(value: bool) -> void:
	if corpse_highlight == value:
		return
	corpse_highlight = value
	queue_redraw()

func state_label() -> String:
	return ["idle", "wander", "chase", "attack", "stagger", "dead", "investigate", "sleeping", "breach", "climb"][state]

func _draw() -> void:
	if state == State.DEAD:
		if corpse_highlight:
			draw_arc(Vector2(0, 5), 48.0, 0.0, TAU, 32, Color("e8cd72"), 4.0, true)
		draw_flat_ellipse(Vector2(0, 4), Vector2(43, 13), Color(0.0, 0.0, 0.0, 0.25))
		draw_line(Vector2(-28, -5), Vector2(24, 5), Color("695d50"), 18.0, true)
		draw_circle(Vector2(34, 8), 11.0, Color("7f8168"))
		draw_line(Vector2(-6, 0), Vector2(-32, 16), Color("4e5148"), 8.0, true)
		return
	if state == State.SLEEPING:
		draw_flat_ellipse(Vector2(0, 5), Vector2(34, 11), Color(0.0, 0.0, 0.0, 0.24))
		draw_line(Vector2(-19, -7), Vector2(18, 2), tint.darkened(0.2), 17.0, true)
		draw_circle(Vector2(27, 5), 10.0, Color("83876e"))
		draw_line(Vector2(-5, -2), Vector2(-25, 11), Color("4e5148"), 8.0, true)
		return
	draw_flat_ellipse(Vector2(0, 5), Vector2(18, 7), Color(0.0, 0.0, 0.0, 0.28))
	var stride := sin(gait) * 7.0 if state in [State.WANDER, State.CHASE] else 0.0
	var body_color := Color.WHITE if visual_flash > 0.0 else tint
	var hip := Vector2(0, -43)
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(side * 7.0 + stride * side, 0)
		draw_line(hip + Vector2(side * 4.0, 0), foot, Color("504f48"), 8.0, true)
	var chest := Vector2(0, -78)
	draw_line(hip, chest, body_color.darkened(0.18), 20.0, true)
	var head := Vector2(facing.x * 4.0, -99)
	draw_circle(head, 11.0, Color("83876e") if visual_flash <= 0.0 else Color.WHITE)
	var striking:=state in [State.ATTACK,State.BREACH]
	var reach := 35.0 if striking else 17.0
	var arm_direction := facing.normalized() if striking else Vector2(facing.x * 0.45, 1.0).normalized()
	for side: float in [-1.0, 1.0]:
		var shoulder := chest + Vector2(side * 10.0, 3.0)
		var hand := shoulder + arm_direction * reach + Vector2(side * 5.0, 0)
		draw_line(shoulder, hand, body_color.darkened(0.25), 7.0, true)
		draw_circle(hand, 4.0, Color("7b7d67"))
	if alerted or health < 68:
		draw_rect(Rect2(-20, -121, 40, 4), Color(0.05, 0.06, 0.05, 0.82))
		draw_rect(Rect2(-19, -120, 38.0 * float(health) / 68.0, 2), Color("b9685d"))
	elif state == State.INVESTIGATE:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-5, -120), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e5ce78"))

func draw_flat_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in 24:
		points.append(center + Vector2(cos(float(i) * TAU / 24.0) * radius.x, sin(float(i) * TAU / 24.0) * radius.y))
	draw_colored_polygon(points, color)
