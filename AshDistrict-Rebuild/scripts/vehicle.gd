extends Node2D

const Rules = preload("res://scripts/vehicle_rules.gd")
const Metrics = preload("res://scripts/player_metrics.gd")

var world_map: Node2D
var game: Node2D
var controls: Node
var vehicle_id := "station_wagon_01"
var display_name := "旧旅行车"
var heading_logical := Vector2.RIGHT
var speed_mps := 0.0
var fuel_liters := 18.0
var condition := 82.0
var occupied := false
var driving_enabled := false
var engine_noise_timer := 0.0
var trunk := {"food":1,"water":1,"duct_tape":1}
var zombie_hit_cooldowns := {}
var spawn_logical_position := Vector2.ZERO

func setup(map: Node2D,id: String,logical_position: Vector2) -> void:
	world_map=map
	vehicle_id=id
	spawn_logical_position=logical_position
	reset_default()

func reset_default() -> void:
	position=world_map.map_to_world(spawn_logical_position)
	heading_logical=Vector2.RIGHT
	speed_mps=0.0
	fuel_liters=18.0
	condition=82.0
	occupied=false
	driving_enabled=false
	trunk={"food":1,"water":1,"duct_tape":1}
	zombie_hit_cooldowns.clear()
	update_pose()

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	advance_hit_cooldowns(delta)
	if not occupied or not driving_enabled or condition<=0.0:
		speed_mps=move_toward(speed_mps,0.0,Rules.COAST_DRAG_MPS2*delta)
		return
	var input: Vector2=controls.movement_vector() if is_instance_valid(controls) else Input.get_vector("move_left","move_right","move_up","move_down")
	var throttle:=-input.y
	var has_fuel:=fuel_liters>0.001
	speed_mps=Rules.next_speed(speed_mps,throttle,delta,has_fuel)
	if absf(speed_mps)>0.04:
		heading_logical=heading_logical.rotated(Rules.steering_delta(speed_mps,input.x,delta)).normalized()
	var distance_meters:=absf(speed_mps)*delta
	if distance_meters>0.001:
		var logical: Vector2=world_map.world_to_map(position)
		var candidate: Vector2=logical+heading_logical*(speed_mps/Metrics.CELL_METERS)*delta
		if can_occupy(candidate):
			var old_position:=position
			position=world_map.map_to_world(candidate)
			fuel_liters=maxf(0.0,fuel_liters-Rules.fuel_for_distance(distance_meters))
			update_pose()
			if is_instance_valid(game):
				game.on_vehicle_travel(self,old_position,distance_meters)
		else:
			var impact_speed:=absf(speed_mps)
			speed_mps=0.0
			condition=maxf(0.0,condition-Rules.collision_condition_loss(impact_speed))
			if is_instance_valid(game) and impact_speed>2.0:
				game.on_vehicle_collision(self,impact_speed)
	engine_noise_timer-=delta
	if engine_noise_timer<=0.0 and is_instance_valid(game) and (absf(speed_mps)>0.2 or absf(throttle)>0.1):
		engine_noise_timer=0.65
		game.emit_world_sound(position,18.0,"vehicle")
	queue_redraw()

func can_occupy(center_logical: Vector2) -> bool:
	var forward:=heading_logical.normalized()
	var side:=Vector2(-forward.y,forward.x)
	for longitudinal: float in [-4.1,0.0,4.1]:
		for lateral: float in [-1.65,0.0,1.65]:
			var sample:=center_logical+forward*longitudinal+side*lateral
			if not world_map.is_walkable_world(world_map.map_to_world(sample),self):
				return false
	return true

func blocks(logical_point: Vector2) -> bool:
	var center: Vector2=world_map.world_to_map(position)
	var offset: Vector2=logical_point-center
	var forward:=heading_logical.normalized()
	var side:=Vector2(-forward.y,forward.x)
	return absf(offset.dot(forward))<=4.35 and absf(offset.dot(side))<=1.9

func interaction_distance_meters(world_point: Vector2) -> float:
	var offset: Vector2=world_map.world_to_map(world_point-position)
	var forward:=heading_logical.normalized()
	var side:=Vector2(-forward.y,forward.x)
	var longitudinal:=maxf(0.0,absf(offset.dot(forward))-4.35)
	var lateral:=maxf(0.0,absf(offset.dot(side))-1.9)
	return Vector2(longitudinal,lateral).length()*Metrics.CELL_METERS

func exit_world_position() -> Vector2:
	var center: Vector2=world_map.world_to_map(position)
	var side:=Vector2(-heading_logical.y,heading_logical.x)
	for offset: Vector2 in [side*2.8,-side*2.8,-heading_logical*5.2,heading_logical*5.2]:
		var candidate: Vector2=world_map.map_to_world(center+offset)
		if world_map.is_walkable_world(candidate,self):
			return candidate
	return position

func can_hit_zombie(zombie: Node2D) -> bool:
	var key:=zombie.get_instance_id()
	if float(zombie_hit_cooldowns.get(key,0.0))>0.0:
		return false
	zombie_hit_cooldowns[key]=0.8
	return true

func advance_hit_cooldowns(delta: float) -> void:
	for key in zombie_hit_cooldowns.keys():
		var remaining:=float(zombie_hit_cooldowns[key])-delta
		if remaining<=0.0:
			zombie_hit_cooldowns.erase(key)
		else:
			zombie_hit_cooldowns[key]=remaining

func update_pose() -> void:
	var world_direction: Vector2=world_map.map_to_world(heading_logical)-world_map.map_to_world(Vector2.ZERO)
	rotation=world_direction.angle()
	z_index=roundi(position.y*0.2)

func _draw() -> void:
	var body:=Color("496a78") if condition>30.0 else Color("665e58")
	draw_colored_polygon(PackedVector2Array([Vector2(-112,-38),Vector2(100,-38),Vector2(116,-23),Vector2(116,23),Vector2(100,38),Vector2(-112,38)]),body)
	draw_polyline(PackedVector2Array([Vector2(-112,-38),Vector2(100,-38),Vector2(116,-23),Vector2(116,23),Vector2(100,38),Vector2(-112,38),Vector2(-112,-38)]),Color("ced6cf"),3.0,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-46,-30),Vector2(44,-30),Vector2(68,-21),Vector2(68,21),Vector2(44,30),Vector2(-46,30),Vector2(-67,20),Vector2(-67,-20)]),Color("233039"))
	draw_line(Vector2(-4,-29),Vector2(-4,29),Color("87999c"),3.0)
	for x: float in [-72.0,72.0]:
		draw_line(Vector2(x,-41),Vector2(x+24,-41),Color("161a1b"),10.0,true)
		draw_line(Vector2(x,41),Vector2(x+24,41),Color("161a1b"),10.0,true)
	draw_circle(Vector2(106,-19),5.0,Color("e9d28a"))
	draw_circle(Vector2(106,19),5.0,Color("e9d28a"))
	draw_circle(Vector2(-107,-20),4.0,Color("ad3f38"))
	draw_circle(Vector2(-107,20),4.0,Color("ad3f38"))
	if occupied:
		draw_circle(Vector2(18,13),8.0,Color("b79a77"))
