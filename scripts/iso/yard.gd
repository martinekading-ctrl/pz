extends RefCounted

var owner_ref: WeakRef
var world: RefCounted:
	get: return owner_ref.get_ref()
var game: Node2D
var doors: Array = []

func _init(owner: RefCounted) -> void:
	owner_ref = weakref(owner)
	game = world.game

func barrier(a: Vector2,b: Vector2,width := 12.0) -> void:
	for shape in Geometry2D.offset_polyline(PackedVector2Array([a,b]),width/2,Geometry2D.JOIN_SQUARE,Geometry2D.END_SQUARE): world.obstacles.append(shape)

func build() -> void:
	# Ordinary yard ground is walkable; these are independent scene objects.
	fence(Vector2(540,80),Vector2(800,80))
	fence(Vector2(900,80),Vector2(1500,80))
	fence(Vector2(1500,80),Vector2(1630,440))
	fence(Vector2(1660,550),Vector2(1560,740))
	add_door("后院侧门",Vector2(1630,440),Vector2(1660,550),false,1)
	for at in [Vector2(220,110),Vector2(565,160),Vector2(1485,245),Vector2(1470,690),Vector2(310,620),Vector2(70,810)]:
		plant(at,0,145,14)
	for at in [Vector2(610,290),Vector2(990,80),Vector2(1300,670),Vector2(380,770),Vector2(740,710)]:
		plant(at,1,60,17)

func sprite_region(cell: int) -> AtlasTexture:
	var sheet: Texture2D = load("res://art/isometric/yard-props.png")
	var image := sheet.get_image()
	var region: Rect2i = [Rect2i(0,0,640,695),Rect2i(660,0,594,695),Rect2i(0,700,640,554),Rect2i(650,700,604,554)][cell]
	var used := image.get_region(region).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(region.position+used.position,used.size)
	atlas.filter_clip = true
	return atlas

func plant(at: Vector2,cell: int,width: float,radius: float) -> void:
	var atlas := sprite_region(cell)
	var node := Sprite2D.new()
	node.texture = atlas
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.position = at
	node.offset.y = -atlas.get_height()/2.0
	node.scale = Vector2.ONE*width/atlas.get_width()
	game.depth.add_child(node)
	var shape := PackedVector2Array()
	for i in 12: shape.append(at+Vector2(cos(i*TAU/12),sin(i*TAU/12)*0.6)*radius)
	world.obstacles.append(shape)
	world.occluders.append({"node":node,"shape":PackedVector2Array([at+Vector2(-width/2,-atlas.get_height()*node.scale.y),at+Vector2(width/2,-atlas.get_height()*node.scale.y),at+Vector2(width/2,0),at+Vector2(-width/2,0)])})

func fence(a: Vector2,b: Vector2) -> void:
	barrier(a,b,14)
	var holder := Node2D.new()
	holder.position = (a+b)/2
	game.depth.add_child(holder)
	var direction := b-a
	var length := direction.length()
	var local_a := a-holder.position
	var local_b := b-holder.position
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([local_a,local_b,local_b+Vector2(0,-45),local_a+Vector2(0,-45)])
	face.color = Color("5b5543")
	holder.add_child(face)
	var count := maxi(2,roundi(length/12.0))
	for i in count+1:
		var base := local_a.lerp(local_b,float(i)/count)
		var width := 5.2 if i%6 else 7.5
		var height := 44.0 if i%6 else 52.0
		var picket := Polygon2D.new()
		picket.polygon = PackedVector2Array([base+Vector2(-width,0),base+Vector2(-width,-height+5),base+Vector2(0,-height),base+Vector2(width,-height+5),base+Vector2(width,0)])
		picket.color = Color(0.34+float(i%4)*0.014,0.32+float(i%3)*0.012,0.245)
		holder.add_child(picket)
	for height in [-13.0,-32.0]:
		var rail := Line2D.new()
		rail.points = PackedVector2Array([local_a+Vector2(0,height),local_b+Vector2(0,height)])
		rail.width = 5
		rail.default_color = Color("39352a")
		holder.add_child(rail)

func add_door(title: String,a: Vector2,b: Vector2,opened: bool,orientation: int) -> void:
	var node := Node2D.new()
	node.position = a
	game.depth.add_child(node)
	doors.append({"title":title,"a":a,"b":b,"open":opened,"orientation":orientation,"node":node,"shape":Geometry2D.offset_polyline(PackedVector2Array([a,b]),8,Geometry2D.JOIN_SQUARE,Geometry2D.END_SQUARE)[0]})
	refresh_door(doors.size()-1)

func refresh_door(index: int) -> void:
	var door: Dictionary = doors[index]
	for child in door.node.get_children():
		door.node.remove_child(child)
		child.queue_free()
	if door.title == "后院侧门":
		draw_fence_gate(door)
		return
	var sprite := Sprite2D.new()
	sprite.texture = door_texture(door.orientation,door.open)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = (door.b-door.a)/2
	sprite.offset.y = -sprite.texture.get_height()/2.0
	sprite.scale = Vector2.ONE*(108.0/sprite.texture.get_height())
	door.node.add_child(sprite)

func draw_fence_gate(door: Dictionary) -> void:
	var delta: Vector2 = door.b-door.a
	if door.open:
		delta = Vector2(-66,-33)
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([Vector2.ZERO,delta,delta+Vector2(0,-46),Vector2(0,-46)])
	face.color = Color("625a45")
	door.node.add_child(face)
	var count := maxi(3,roundi(delta.length()/12.0))
	for i in count+1:
		var base := delta*float(i)/count
		var slat := Polygon2D.new()
		slat.polygon = PackedVector2Array([base+Vector2(-5,0),base+Vector2(-5,-41),base+Vector2(0,-47),base+Vector2(5,-41),base+Vector2(5,0)])
		slat.color = Color(0.37+float(i%3)*0.015,0.34,0.25)
		door.node.add_child(slat)
	for height in [-14.0,-32.0]:
		var rail := Line2D.new()
		rail.points = PackedVector2Array([Vector2(0,height),delta+Vector2(0,height)])
		rail.width = 5
		rail.default_color = Color("39352a")
		door.node.add_child(rail)

func door_texture(orientation: int,opened: bool) -> AtlasTexture:
	var sheet: Texture2D = load("res://art/isometric/door-states.png")
	var image := sheet.get_image()
	var cell := orientation*2+int(opened)
	var size := Vector2i(image.get_width()/2,image.get_height()/2)
	var region := Rect2i(Vector2i(cell%2,int(cell/2))*size,size)
	var used := image.get_region(region).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(region.position+used.position,used.size)
	atlas.filter_clip = true
	return atlas

func nearest() -> int:
	for i in doors.size():
		var door: Dictionary = doors[i]
		if game.player.position.distance_to((door.a+door.b)/2)<62: return i
	return -1

func toggle(index: int) -> bool:
	var door: Dictionary = doors[index]
	if door.open:
		for actor in [game.player]+game.enemies:
			if not actor.dead and Geometry2D.is_point_in_polygon(actor.position,door.shape):
				game.notify("门口有人，先让开再关门。")
				return false
	door.open = not door.open
	var old_sprite: CanvasItem = door.node.get_child(0)
	var tween: Tween = door.node.create_tween()
	tween.tween_property(old_sprite,"modulate:a",0.0,0.08)
	tween.tween_callback(refresh_door.bind(index))
	world.refresh_navigation(Rect2(door.a,Vector2.ZERO).expand(door.b).grow(32))
	for e in game.enemies: e.path_timer = 0
	return true

func blocks(p: Vector2) -> bool:
	for door in doors:
		if not door.open and Geometry2D.is_point_in_polygon(p,door.shape): return true
	return false
