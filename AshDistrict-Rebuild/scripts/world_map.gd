extends Node2D

const TILE := Vector2(64.0,32.0)
const MAP_SIZE := Vector2i(512,576)
const CHUNK_SIZE := Vector2i(32,32)
const ROAD_VERTICAL := Rect2i(44,0,8,72)
const ROAD_HORIZONTAL := Rect2i(0,32,96,8)
const BUILDINGS := {
	"blue_house": Rect2i(16,43,13,10),
	"brick_house": Rect2i(18,13,12,11),
	"store": Rect2i(57,15,16,12),
	"garage": Rect2i(68,44,15,11),
}
const PARKING := Rect2i(54,27,22,5)

var layer_names := ["Ground","Roads","Lots","Buildings","Roofs","Props"]
var surfaces: Array[Polygon2D] = []
var expansion: Node2D
var vegetation: Node2D
var blue_house: Node2D
var store_building: Node2D
var residential_b01: Node2D
var interactive_buildings: Array[Node2D]=[]
var vehicles: Array[Node2D]=[]

func _ready() -> void:
	for layer_name in layer_names:
		var layer := Node2D.new()
		layer.name = layer_name
		add_child(layer)
	build_surfaces()
	blue_house = preload("res://scripts/blue_house.gd").new(self)
	blue_house.name = "BlueHouse"
	add_child(blue_house)
	blue_house.build()
	store_building=preload("res://scripts/store.gd").new(self)
	store_building.name="ConvenienceStore"
	add_child(store_building)
	store_building.build()
	residential_b01=preload("res://scripts/residential_b01.gd").new(self)
	residential_b01.name="ResidentialB01"
	add_child(residential_b01)
	residential_b01.build()
	interactive_buildings=[blue_house,store_building,residential_b01]
	var placements: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/residential-placements.json"))
	for placement in placements:
		var house: Node2D=preload("res://scripts/catalog_house.gd").new(self)
		house.config=placement
		house.name=placement.id+"_"+placement.template
		add_child(house)
		house.build()
		interactive_buildings.append(house)
	vegetation=preload("res://scripts/vegetation.gd").new()
	add_child(vegetation)
	vegetation.setup(self)
	expansion=preload("res://scripts/expansion.gd").new()
	add_child(expansion)
	expansion.setup(self)
	var vehicle:=preload("res://scripts/vehicle.gd").new()
	vehicle.name="StationWagon01"
	add_child(vehicle)
	vehicle.setup(self,"station_wagon_01",Vector2(39.0,44.0))
	vehicles.append(vehicle)
	queue_redraw()

func build_surfaces() -> void:
	add_surface(Rect2i(0,0,96,72),"res://art/terrain/grass.png","Ground",-30,Color(0.94,0.96,0.88))
	add_surface(ROAD_VERTICAL,"res://art/terrain/asphalt.png","Roads",-20,Color(0.86,0.87,0.88))
	add_surface(ROAD_HORIZONTAL,"res://art/terrain/asphalt.png","Roads",-20,Color(0.86,0.87,0.88))
	add_surface(PARKING,"res://art/terrain/asphalt.png","Lots",-18,Color(0.90,0.90,0.90))
	add_surface(Rect2i(56,27,18,1),"res://art/terrain/concrete.png","Lots",-16,Color("bdbbaa"))
	# Sidewalks and driveways exist only around occupied parcels, keeping the rural edges simple.
	for rect in [Rect2i(12,40,23,2),Rect2i(15,30,19,2),Rect2i(52,12,2,19),Rect2i(65,40,22,2)]:
		add_surface(rect,"res://art/terrain/concrete.png","Lots",-17,Color(0.78,0.78,0.75))
	for rect in [Rect2i(29,48,15,2),Rect2i(24,24,3,8)]:
		add_surface(rect,"res://art/terrain/concrete.png","Lots",-16,Color(0.78,0.78,0.75))
	add_surface(Rect2i(72,40,5,4),"res://art/terrain/asphalt.png","Lots",-16,Color(0.88,0.88,0.88))

func add_surface(rect: Rect2i,path: String,layer_name: String,z: int,tint: Color) -> void:
	var surface := Polygon2D.new()
	surface.set_meta("logical_rect",Rect2(rect))
	surface.polygon = map_rect(rect)
	var span := Vector2(rect.size)*64.0
	surface.uv = PackedVector2Array([Vector2.ZERO,Vector2(span.x,0),span,Vector2(0,span.y)])
	surface.texture = load(path)
	surface.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	surface.modulate = tint
	surface.z_index = z
	get_node(layer_name).add_child(surface)
	surfaces.append(surface)

func map_to_world(cell: Vector2) -> Vector2:
	return Vector2((cell.x-cell.y)*TILE.x*0.5,(cell.x+cell.y)*TILE.y*0.5)

func world_to_map(point: Vector2) -> Vector2:
	return Vector2(point.y/TILE.y+point.x/TILE.x,point.y/TILE.y-point.x/TILE.x)

func map_rect(rect: Rect2i) -> PackedVector2Array:
	return PackedVector2Array([
		map_to_world(Vector2(rect.position)),
		map_to_world(Vector2(rect.position+Vector2i(rect.size.x,0))),
		map_to_world(Vector2(rect.end)),
		map_to_world(Vector2(rect.position+Vector2i(0,rect.size.y)))
	])

func contains(rect: Rect2i,cell: Vector2i) -> bool:
	return rect.has_point(cell)

func is_walkable_world(point: Vector2,exclude_vehicle: Node2D=null) -> bool:
	var logical := world_to_map(point)
	if is_instance_valid(expansion) and expansion.blocks(logical): return false
	if is_instance_valid(vegetation) and vegetation.blocks(logical): return false
	var cell := Vector2i(floori(logical.x),floori(logical.y))
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_SIZE.x or cell.y >= MAP_SIZE.y:
		return false
	for building in interactive_buildings:
		if not building.is_walkable_logical(logical): return false
	for vehicle: Node2D in vehicles:
		if vehicle!=exclude_vehicle and vehicle.blocks(logical): return false
	for key in BUILDINGS:
		var rect: Rect2i = BUILDINGS[key]
		if contains(rect,cell):
			return key == "blue_house" or key == "store"
	return true

func chunk_of_world(point: Vector2) -> Vector2i:
	var logical := world_to_map(point)
	return Vector2i(floori(logical.x/CHUNK_SIZE.x),floori(logical.y/CHUNK_SIZE.y))

func _draw() -> void:
	draw_curbs()
	draw_center_lines()
	for key in BUILDINGS:
		if key not in ["blue_house","store"]: draw_building(BUILDINGS[key],building_color(key),key)
	# Chunk boundaries are editor data, not visible game objects.

func draw_curbs() -> void:
	var curb := Color("b9b7aa")
	for segment in [
		[Vector2(44,0),Vector2(44,32)],[Vector2(52,0),Vector2(52,32)],
		[Vector2(44,40),Vector2(44,72)],[Vector2(52,40),Vector2(52,72)],
		[Vector2(0,32),Vector2(44,32)],[Vector2(0,40),Vector2(44,40)],
		[Vector2(52,32),Vector2(96,32)],[Vector2(52,40),Vector2(96,40)]
	]:
		draw_line(map_to_world(segment[0]),map_to_world(segment[1]),Color(0,0,0,0.24),7.0,true)
		draw_line(map_to_world(segment[0])+Vector2(0,-2),map_to_world(segment[1])+Vector2(0,-2),curb,4.0,true)

func draw_center_lines() -> void:
	var vertical_a := map_to_world(Vector2(48,0))
	var vertical_b := map_to_world(Vector2(48,72))
	var horizontal_a := map_to_world(Vector2(0,36))
	var horizontal_b := map_to_world(Vector2(96,36))
	draw_map_dashes(vertical_a,vertical_b,Color("d6bd5a"),2.0,20.0)
	draw_map_dashes(horizontal_a,horizontal_b,Color("d6bd5a"),2.0,20.0)

func draw_map_dashes(a: Vector2,b: Vector2,color: Color,width: float,dash: float) -> void:
	var distance := a.distance_to(b)
	var direction := (b-a).normalized()
	var cursor := 0.0
	while cursor < distance:
		draw_line(a+direction*cursor,a+direction*minf(cursor+dash,distance),color,width,true)
		cursor += dash*1.8

func building_color(key: String) -> Color:
	return {
		"blue_house":Color("7795a2"),
		"brick_house":Color("9a5d4d"),
		"store":Color("ddd7c6"),
		"garage":Color("a9aca6"),
	}[key]

func draw_building(rect: Rect2i,color: Color,key: String) -> void:
	var footprint := map_rect(rect)
	var height := 54.0 if key == "brick_house" else 36.0
	draw_colored_polygon(footprint,Color("303536"))
	var top := PackedVector2Array()
	for point in footprint: top.append(point+Vector2(0,-height))
	draw_colored_polygon(PackedVector2Array([footprint[0],footprint[1],top[1],top[0]]),color.darkened(0.23))
	draw_colored_polygon(PackedVector2Array([footprint[1],footprint[2],top[2],top[1]]),color.darkened(0.34))
	draw_colored_polygon(top,color)
	draw_polyline(PackedVector2Array([top[0],top[1],top[2],top[3],top[0]]),Color("252a29"),2.0,true)

func draw_chunk_boundaries() -> void:
	for x in range(0,MAP_SIZE.x+1,CHUNK_SIZE.x):
		draw_line(map_to_world(Vector2(x,0)),map_to_world(Vector2(x,MAP_SIZE.y)),Color(1,1,1,0.10),1.0)
	for y in range(0,MAP_SIZE.y+1,CHUNK_SIZE.y):
		draw_line(map_to_world(Vector2(0,y)),map_to_world(Vector2(MAP_SIZE.x,y)),Color(1,1,1,0.10),1.0)

func validate_layout() -> bool:
	for sample in [Vector2(48,2),Vector2(48,70),Vector2(2,36),Vector2(94,36),Vector2(48,36)]:
		if not is_walkable_world(map_to_world(sample)): return false
	if not is_walkable_world(map_to_world(Vector2(24,48))): return false
	for key in ["brick_house","garage"]:
		var rect: Rect2i = BUILDINGS[key]
		if is_walkable_world(map_to_world(Vector2(rect.get_center()))): return false
	for sample in [Vector2(0,0),Vector2(31.9,31.9),Vector2(32,32),Vector2(95,71)]:
		var round_trip := world_to_map(map_to_world(sample))
		if round_trip.distance_to(sample) > 0.001: return false
	return true

func building_near(point: Vector2) -> Node2D:
	var best: Node2D=blue_house
	var distance:=INF
	for building in interactive_buildings:
		if building.get_search_area().has_point(world_to_map(point)): return building
		var current: float=point.distance_to(building.door_midpoint())
		if current<distance:
			distance=current
			best=building
	return best

func building_containing(point: Vector2) -> Node2D:
	var logical:=world_to_map(point)
	for building in interactive_buildings:
		if building.get_search_area().has_point(logical):
			return building
	return null

func entry_between(actor_world: Vector2,target_world: Vector2) -> Dictionary:
	var target_building:=building_containing(target_world)
	var actor_building:=building_containing(actor_world)
	if target_building==actor_building:
		return {}
	var building: Node2D=target_building if target_building!=null else actor_building
	if building==null:
		return {}
	var best:={}
	var best_score: float=INF
	for door: Node2D in building.all_doors():
		var score: float=actor_world.distance_to(door.midpoint())+door.midpoint().distance_to(target_world)*0.25
		if score<best_score:
			best_score=score
			best={"type":"door","building":building,"door":door,"position":door.midpoint()}
	for index in building.windows.size():
		var window: Dictionary=building.windows[index]
		var midpoint:=map_to_world((window.a+window.b)*0.5)
		var score: float=actor_world.distance_to(midpoint)+midpoint.distance_to(target_world)*0.25
		if score<best_score:
			best_score=score
			best={"type":"window","building":building,"index":index,"position":midpoint}
	return best
