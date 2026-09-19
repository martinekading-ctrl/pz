extends RefCounted

var floor_shape := PackedVector2Array([
	Vector2(666,330), Vector2(978,162), Vector2(1408,353), Vector2(1067,532)
])
const WALL_HEIGHT := 98.0
const CUTAWAY_HEIGHT := 30.0

var owner_ref: WeakRef
var world: RefCounted:
	get: return owner_ref.get_ref()
var game: Node2D

func _init(owner: RefCounted) -> void:
	owner_ref = weakref(owner)
	game = world.game

func build() -> void:
	add_floor()
	# Rear walls stay full height; front walls use a clean cutaway so the room remains readable.
	add_wall(Vector2(666,330),Vector2(978,162),WALL_HEIGHT,true)
	add_wall(Vector2(978,162),Vector2(1408,353),WALL_HEIGHT,true)
	var door_a := Vector2(812,404)
	var door_b := Vector2(922,461)
	add_wall(Vector2(666,330),door_a,CUTAWAY_HEIGHT,false)
	add_wall(door_b,Vector2(1067,532),CUTAWAY_HEIGHT,false)
	add_wall(Vector2(1067,532),Vector2(1408,353),CUTAWAY_HEIGHT,false)
	world.yard.add_door("住宅前门",door_a,door_b,true,0)

func add_floor() -> void:
	var floor := Polygon2D.new()
	floor.polygon = floor_shape
	floor.uv = PackedVector2Array([Vector2(0,0),Vector2(3300,0),Vector2(3300,2280),Vector2(0,2280)])
	floor.texture = load("res://art/isometric/house-floor.png")
	floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	floor.z_index = -9
	game.add_child(floor)
	# Thin foundation lip gives the floor a physical edge without exposing a rectangular crop.
	for edge in [[floor_shape[0],floor_shape[3]],[floor_shape[3],floor_shape[2]]]:
		var lip := Polygon2D.new()
		lip.polygon = PackedVector2Array([edge[0],edge[1],edge[1]+Vector2(0,8),edge[0]+Vector2(0,8)])
		lip.color = Color("4c4a40")
		lip.z_index = -8
		game.add_child(lip)

func add_wall(a: Vector2,b: Vector2,height: float,occludes: bool) -> void:
	# Keep the visible wall face and its foot collision aligned at character scale.
	var inset := 5.0 if occludes else 8.0
	var collision_a := a.move_toward(b,inset)
	var collision_b := b.move_toward(a,inset)
	world.yard.barrier(collision_a,collision_b,18.0 if occludes else 44.0)
	var node := Node2D.new()
	node.position = (a+b)/2
	game.depth.add_child(node)
	var length := a.distance_to(b)
	var local_a := a-node.position
	var local_b := b-node.position
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([local_a,local_b,local_b+Vector2(0,-height),local_a+Vector2(0,-height)])
	face.uv = PackedVector2Array([Vector2(0,height*2.2),Vector2(length*2.2,height*2.2),Vector2(length*2.2,0),Vector2(0,0)])
	face.texture = load("res://art/isometric/house-wall.png")
	face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	face.color = Color(0.70,0.71,0.66)
	node.add_child(face)
	var top := Polygon2D.new()
	var normal := Vector2(-(b-a).y,(b-a).x).normalized()*5
	top.polygon = PackedVector2Array([local_a+Vector2(0,-height),local_b+Vector2(0,-height),local_b+Vector2(0,-height)+normal,local_a+Vector2(0,-height)+normal])
	top.color = Color("5b5b51")
	node.add_child(top)
	var base := Line2D.new()
	base.points = PackedVector2Array([local_a+Vector2(0,-7),local_b+Vector2(0,-7)])
	base.width = 4
	base.default_color = Color("405149")
	node.add_child(base)
	if occludes:
		world.occluders.append({"node":node,"shape":PackedVector2Array([a,b,b+Vector2(0,-height),a+Vector2(0,-height)])})
