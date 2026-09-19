extends "res://scripts/blue_house.gd"

const HOUSE_RECT := Rect2(53.0,128.0,17.0,13.0)
const FRONT_HINGE := Vector2(64.3,141.0)
const FRONT_VECTOR := Vector2(2.0,0.0)
const REAR_HINGE := Vector2(70.0,132.0)
const REAR_VECTOR := Vector2(0.0,2.0)
const VISIBLE_CUT_HEIGHT := 38.0

var rear_door: Node2D
var partition_segments: Array[PackedVector2Array] = []
var interior_wall_pairs: Array[Dictionary] = []
var solid_bounds: Array[Rect2] = []
var decor_sprites: Array[Sprite2D] = []

func build() -> void:
	var corners := PackedVector2Array([
		world_map.map_to_world(HOUSE_RECT.position),
		world_map.map_to_world(Vector2(HOUSE_RECT.end.x,HOUSE_RECT.position.y)),
		world_map.map_to_world(HOUSE_RECT.end),
		world_map.map_to_world(Vector2(HOUSE_RECT.position.x,HOUSE_RECT.end.y))
	])
	add_textured_polygon(corners,"res://art/house_blue/floor.png",-8,Vector2(1088,832),Color("c5b9a5"))
	add_room_floor(Rect2(53.35,128.35,6.0,6.05),Color("b8aa98"))
	add_room_floor(Rect2(59.55,128.35,4.25,4.55),Color("b8bdad"))
	add_room_floor(Rect2(64.1,128.35,5.55,4.55),Color("b7aa91"))
	add_room_floor(Rect2(53.35,134.8,16.3,5.85),Color("ad9e8b"))

	# Four outside walls are split at actual door openings. South and east are
	# independent cutaway modules so the actor can enter without crossing art.
	add_wall(corners[0],corners[1],false)
	add_wall(corners[0],corners[3],false)
	add_wall(corners[1],world_map.map_to_world(REAR_HINGE),true)
	add_wall(world_map.map_to_world(REAR_HINGE+REAR_VECTOR),corners[2],true)
	add_wall(corners[3],world_map.map_to_world(FRONT_HINGE),true)
	add_wall(world_map.map_to_world(FRONT_HINGE+FRONT_VECTOR),corners[2],true)

	add_window(world_map.map_to_world(Vector2(53,129.2)),world_map.map_to_world(Vector2(53,131.6)))
	add_window(world_map.map_to_world(Vector2(65,128)),world_map.map_to_world(Vector2(67.4,128)))
	add_window(world_map.map_to_world(Vector2(55.5,141)),world_map.map_to_world(Vector2(57.9,141)),true)
	add_window(world_map.map_to_world(Vector2(70,134.3)),world_map.map_to_world(Vector2(70,136.1)),true)

	build_partitions()
	refresh_door()
	add_furniture()
	add_decorative_furniture()
	add_roof(corners)

func add_room_floor(rect: Rect2,color: Color) -> void:
	var floor := Polygon2D.new()
	floor.polygon = PackedVector2Array([
		world_map.map_to_world(rect.position),
		world_map.map_to_world(Vector2(rect.end.x,rect.position.y)),
		world_map.map_to_world(rect.end),
		world_map.map_to_world(Vector2(rect.position.x,rect.end.y))
	])
	floor.color = color
	floor.z_index = -7
	add_child(floor)

func add_wall(a: Vector2,b: Vector2,near_side: bool) -> void:
	var count := maxi(1,ceili(a.distance_to(b)/36.0))
	for i in count:
		var start := a.lerp(b,float(i)/count)
		var end := a.lerp(b,float(i+1)/count)
		var full := wall_face(start,end,building_wall_height())
		full.modulate = Color("9a968b") if b.x>a.x else Color("888c82")
		if near_side:
			var low := wall_face(start,end,VISIBLE_CUT_HEIGHT)
			low.modulate = Color("85877e")
			low.visible = false
			near_walls.append({"full":full,"low":low})

func build_partitions() -> void:
	# Bedroom: 3.2 x 3.3 m. Bathroom: 2.2 x 2.6 m. Door gaps are
	# 1.0 m and 0.9 m respectively, matching the reusable house standard.
	for segment in [
		PackedVector2Array([Vector2(53.0,134.6),Vector2(56.8,134.6)]),
		PackedVector2Array([Vector2(58.8,134.6),Vector2(59.4,134.6)]),
		PackedVector2Array([Vector2(59.4,128.0),Vector2(59.4,134.6)]),
		PackedVector2Array([Vector2(64.0,128.0),Vector2(64.0,133.2)]),
		PackedVector2Array([Vector2(59.4,133.2),Vector2(61.7,133.2)]),
		PackedVector2Array([Vector2(63.5,133.2),Vector2(64.0,133.2)])
	]:
		partition_segments.append(segment)
		add_partition(segment[0],segment[1])
	add_doorway_frame(Vector2(56.8,134.6),Vector2(58.8,134.6))
	add_doorway_frame(Vector2(61.7,133.2),Vector2(63.5,133.2))

func add_partition(a: Vector2,b: Vector2) -> void:
	var full := wall_face(world_map.map_to_world(a),world_map.map_to_world(b),building_wall_height())
	full.modulate = Color("b4afa2")
	var low := wall_face(world_map.map_to_world(a),world_map.map_to_world(b),VISIBLE_CUT_HEIGHT)
	low.modulate = Color("9c978b")
	low.visible = false
	interior_wall_pairs.append({"full":full,"low":low,"a":a,"b":b})

func add_doorway_frame(a: Vector2,b: Vector2) -> void:
	var wa: Vector2 = world_map.map_to_world(a)
	var wb: Vector2 = world_map.map_to_world(b)
	var frame := Line2D.new()
	frame.points = PackedVector2Array([wa,wa-Vector2(0,140),wb-Vector2(0,140),wb])
	frame.width = 5.0
	frame.default_color = Color("d7d0c1")
	frame.z_index = roundi(maxf(wa.y,wb.y)*0.2)+6
	add_child(frame)
	var low := Node2D.new()
	add_child(low)
	interior_wall_pairs.append({"full":frame,"low":low,"a":a,"b":b})

func refresh_door() -> void:
	var texture: Texture2D = load(DOOR_TEXTURE_PATH)
	var size := Vector2(texture.get_size())
	door_component = preload("res://scripts/swing_door.gd").new()
	add_child(door_component)
	door_component.setup(world_map,FRONT_HINGE,FRONT_VECTOR,Vector2(0,-2.0),texture,Rect2(Vector2.ZERO,size))
	door_leaf = door_component.leaf
	rear_door = preload("res://scripts/swing_door.gd").new()
	add_child(rear_door)
	rear_door.setup(world_map,REAR_HINGE,REAR_VECTOR,Vector2(2.0,0),texture,Rect2(Vector2.ZERO,size))
	add_exterior_door_frame(FRONT_HINGE,FRONT_HINGE+FRONT_VECTOR,true)
	add_exterior_door_frame(REAR_HINGE,REAR_HINGE+REAR_VECTOR,true)
	update_door()

func add_exterior_door_frame(a: Vector2,b: Vector2,cutaway: bool) -> void:
	var wa: Vector2 = world_map.map_to_world(a)
	var wb: Vector2 = world_map.map_to_world(b)
	var frame := Line2D.new()
	frame.points = PackedVector2Array([wa,wa-Vector2(0,140),wb-Vector2(0,140),wb])
	frame.width = 6.0
	frame.default_color = Color("e5ddcc")
	frame.z_index = roundi(maxf(wa.y,wb.y)*0.2)+7
	add_child(frame)
	if cutaway:
		var blank := Node2D.new()
		add_child(blank)
		near_walls.append({"full":frame,"low":blank})

func add_furniture() -> void:
	load_furniture_layout("residential_b01")

func add_decorative_furniture() -> void:
	spawn_decor("res://art/residential_b01/shower-v011.png",Rect2(59.9,128.4,1.8,1.8),0.75,Color.WHITE)
	spawn_decor("res://art/residential_b01/toilet-v011.png",Rect2(62.1,128.4,1.3,1.7),0.68,Color.WHITE)

func spawn_decor(path: String,bounds: Rect2,scale_factor: float,tint: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = world_map.map_to_world(bounds.end)
	sprite.offset.y = -sprite.texture.get_height()*0.5
	var meters_sum := (bounds.size.x+bounds.size.y)*0.5
	var scale_value := meters_sum*64.0/float(sprite.texture.get_width())*scale_factor
	sprite.scale = Vector2.ONE*scale_value
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/search_outline.gdshader")
	material.set_shader_parameter("desaturate",0.0)
	material.set_shader_parameter("color_grade",tint)
	sprite.material = material
	sprite.z_index = roundi(sprite.position.y*0.2)
	add_child(sprite)
	solid_bounds.append(bounds)
	decor_sprites.append(sprite)

func add_roof(footprint: PackedVector2Array) -> void:
	var center := (footprint[0]+footprint[2])*0.5
	var e := PackedVector2Array()
	for point in footprint:
		e.append(center+(point-center)*1.055-Vector2(0,WALL_HEIGHT))
	var ridge_a := (e[0]+e[3])*0.5-Vector2(0,82)
	var ridge_b := (e[1]+e[2])*0.5-Vector2(0,82)
	roof = add_textured_polygon(PackedVector2Array([e[0],e[1],ridge_b,ridge_a]),"res://art/house_blue/roof.png",roundi(footprint[2].y)+220,Vector2(1856,820),Color("746e69"))
	var rear_slope := Polygon2D.new()
	rear_slope.polygon = PackedVector2Array([ridge_a,ridge_b,e[2],e[3]])
	rear_slope.uv = PackedVector2Array([Vector2.ZERO,Vector2(1856,0),Vector2(1856,820),Vector2(0,820)])
	rear_slope.texture = roof.texture
	rear_slope.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rear_slope.modulate = Color("655f5c")
	roof.add_child(rear_slope)
	var gable := Polygon2D.new()
	gable.polygon = PackedVector2Array([e[1],e[2],ridge_b])
	gable.color = Color("8e8d82")
	roof.add_child(gable)
	for endpoints in [[e[0],e[1],ridge_b,e[2],e[3]],[ridge_a,ridge_b],[e[3],ridge_a]]:
		var trim := Line2D.new()
		trim.points = PackedVector2Array(endpoints)
		trim.width = 5.0
		trim.default_color = Color("d8d1c4")
		roof.add_child(trim)

func get_search_area() -> Rect2:
	return Rect2(53.35,128.35,16.3,12.3)

func door_midpoint() -> Vector2:
	return world_map.map_to_world(FRONT_HINGE+FRONT_VECTOR*0.5)

func update_player(point: Vector2,delta: float=1.0/60.0) -> void:
	super.update_player(point,delta)
	rear_door.step(delta)
	var logical: Vector2 = world_map.world_to_map(point)
	for pair in interior_wall_pairs:
		var a: Vector2 = pair.a
		var b: Vector2 = pair.b
		var vertical := absf(a.x-b.x)<0.01
		# The camera looks from the south-east. Keep walls behind the actor at
		# full height; lower only walls between the actor and the camera.
		var obscures := inside and ((vertical and logical.x<a.x) or (not vertical and logical.y<a.y))
		pair.full.visible = not obscures
		pair.low.visible = obscures
	if point.distance_to(rear_door.midpoint()) < point.distance_to(door_component.midpoint()):
		door_open = rear_door.opened
		door_amount = rear_door.amount
	for sprite in decor_sprites:
		sprite.visible = inside

func near_door(point: Vector2) -> bool:
	return door_component.near(point) or rear_door.near(point)

func try_toggle_door(point: Vector2) -> bool:
	var target: Node2D = rear_door if point.distance_to(rear_door.midpoint())<point.distance_to(door_component.midpoint()) else door_component
	var result: bool = target.toggle(point)
	door_open = target.opened
	door_amount = target.amount
	return result

func all_doors() -> Array[Node2D]:
	return [door_component,rear_door]

func nearest_door_component(point: Vector2) -> Node2D:
	return rear_door if point.distance_to(rear_door.midpoint())<point.distance_to(door_component.midpoint()) else door_component

func is_walkable_logical(logical: Vector2) -> bool:
	if not HOUSE_RECT.grow(0.01).has_point(logical):
		return not door_component.blocks(logical) and not rear_door.blocks(logical)
	if logical.x<53.22 or logical.y<128.22:
		return false
	if logical.y>140.78:
		return (door_component.broken or (door_component.opened and door_component.amount>0.85)) and logical.x>64.42 and logical.x<66.18
	if logical.x>69.78:
		return (rear_door.broken or (rear_door.opened and rear_door.amount>0.85)) and logical.y>132.12 and logical.y<133.88
	for segment in partition_segments:
		if logical.distance_to(Geometry2D.get_closest_point_to_segment(logical,segment[0],segment[1]))<0.08:
			return false
	for item in furniture:
		if item.bounds.has_point(logical):
			return false
	for bounds in solid_bounds:
		if bounds.has_point(logical):
			return false
	return not door_component.blocks(logical) and not rear_door.blocks(logical)
