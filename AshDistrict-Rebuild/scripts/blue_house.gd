extends Node2D

const RECT := Rect2i(16,43,13,10)
const WALL_HEIGHT := 172.8
const CUT_HEIGHT := 24.0
const DOOR_MIN_Y := 48.0
const DOOR_MAX_Y := 50.0
const DOOR_X := 29.0
const SIDING_TEXTURE_PATH := "res://art/wood_wall_v1/siding_blue.png"
const DOOR_TEXTURE_PATH := "res://art/wood_wall_v1/door_wood.png"
const WINDOW_TEXTURE_PATH := "res://art/wood_wall_v1/window_double.png"
const WINDOW_GLASS_HP := 36.0
const BARRICADE_LAYER_HP := 70.0

var world_map: Node2D
var roof: Polygon2D
var near_walls: Array[Dictionary] = []
var windows: Array[Dictionary] = []
var furniture: Array[Dictionary] = []
var door_open := false
var door_amount := 0.0
var door_leaf: Polygon2D
var door_component: Node2D
var player_location := Vector2.ZERO
var selected := -1
var selected_window := -1
var fence_segments: Array[Array] = []
var inside := false
var door_nodes: Array[CanvasItem] = []

func _init(owner: Node2D) -> void:
	world_map = owner

func build() -> void:
	var a: Vector2 = world_map.map_to_world(Vector2(16,43))
	var b: Vector2 = world_map.map_to_world(Vector2(29,43))
	var c: Vector2 = world_map.map_to_world(Vector2(29,53))
	var d: Vector2 = world_map.map_to_world(Vector2(16,53))
	add_textured_polygon(PackedVector2Array([a,b,c,d]),"res://art/house_blue/floor.png",-8,Vector2(832,640),Color(0.95,0.92,0.86))
	add_wall(a,b,false)
	add_wall(a,d,false)
	var door_a: Vector2 = world_map.map_to_world(Vector2(DOOR_X,DOOR_MIN_Y))
	var door_b: Vector2 = world_map.map_to_world(Vector2(DOOR_X,DOOR_MAX_Y))
	add_wall(b,door_a,true)
	add_wall(door_b,c,true)
	add_wall(d,c,true)
	add_window(world_map.map_to_world(Vector2(23,43)),world_map.map_to_world(Vector2(25,43)))
	add_window(world_map.map_to_world(Vector2(29,45)),world_map.map_to_world(Vector2(29,47)),true)
	add_window(world_map.map_to_world(Vector2(19,53)),world_map.map_to_world(Vector2(21,53)),true)
	add_window(world_map.map_to_world(Vector2(25,53)),world_map.map_to_world(Vector2(27,53)),true)
	refresh_door()
	add_furniture()
	build_fence()
	add_roof(PackedVector2Array([a,b,c,d]))

func add_textured_polygon(points: PackedVector2Array,path: String,z: int,uv_span: Vector2,tint: Color) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = points
	node.uv = PackedVector2Array([Vector2.ZERO,Vector2(uv_span.x,0),uv_span,Vector2(0,uv_span.y)])
	node.texture = load(path)
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.modulate = tint
	node.z_index = z
	add_child(node)
	return node

func add_wall(a: Vector2,b: Vector2,near_side: bool) -> void:
	# Small independent wall panels are sorted by their ground contact, like props.
	# A single far-wall z-index lets the fence behind it paint over the entire room.
	var count := maxi(1,ceili(a.distance_to(b)/36.0))
	for i in count:
		var start := a.lerp(b,float(i)/count)
		var end := a.lerp(b,float(i+1)/count)
		var full := wall_face(start,end,building_wall_height())
		if not near_side:
			full.texture = null
			full.color = Color("d6cebb") if b.x>a.x else Color("c7bfac")
			full.modulate = Color.WHITE
		else:
			var low := wall_face(start,end,CUT_HEIGHT)
			low.visible = false
			near_walls.append({"full":full,"low":low})

func building_wall_height() -> float:
	return WALL_HEIGHT

func wall_face(a: Vector2,b: Vector2,height: float) -> Polygon2D:
	var points := PackedVector2Array([a,b,b+Vector2(0,-height),a+Vector2(0,-height)])
	var face := Polygon2D.new()
	face.polygon = points
	face.uv = PackedVector2Array([Vector2(a.y*14,height*7),Vector2(b.y*14,height*7),Vector2(b.y*14,0),Vector2(a.y*14,0)])
	face.texture = load(SIDING_TEXTURE_PATH)
	face.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	face.modulate = Color(0.72,0.78,0.82)
	face.z_index = roundi((maxf(a.y,b.y))*0.2)
	add_child(face)
	var cap := Line2D.new()
	cap.points = PackedVector2Array([a+Vector2(0,-height),b+Vector2(0,-height)])
	cap.width = 4
	cap.default_color = Color("e2e0d3")
	cap.z_index = 1
	face.add_child(cap)
	var skirt := Line2D.new()
	skirt.points = PackedVector2Array([a+Vector2(0,-7),b+Vector2(0,-7)])
	skirt.width = 9
	skirt.default_color = Color("c9c4b7")
	face.add_child(skirt)
	return face

func add_window(a: Vector2,b: Vector2,near_side: bool = false) -> void:
	var pane := Polygon2D.new()
	pane.polygon = PackedVector2Array([a+Vector2(0,-62),b+Vector2(0,-62),b+Vector2(0,-136),a+Vector2(0,-136)])
	pane.texture = load(WINDOW_TEXTURE_PATH)
	var size := Vector2(pane.texture.get_size())
	pane.uv = PackedVector2Array([Vector2(0,size.y),size,Vector2(size.x,0),Vector2.ZERO])
	pane.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pane.z_index = roundi((maxf(a.y,b.y))*0.2)+4
	add_child(pane)
	var frame := Line2D.new()
	frame.points = PackedVector2Array([pane.polygon[0],pane.polygon[1],pane.polygon[2],pane.polygon[3],pane.polygon[0]])
	frame.width = 4
	frame.default_color = Color("e5e2d5")
	frame.z_index = pane.z_index+1
	add_child(frame)
	var sill := Line2D.new()
	sill.points = PackedVector2Array([pane.polygon[0]+Vector2(-3,4),pane.polygon[1]+Vector2(3,4)])
	sill.width = 7
	sill.default_color = Color("d8d2c4")
	frame.add_child(sill)
	var broken_marks := Node2D.new()
	broken_marks.visible = false
	broken_marks.z_index = pane.z_index + 2
	add_child(broken_marks)
	for diagonal in [[pane.polygon[0],pane.polygon[2]],[pane.polygon[1],pane.polygon[3]]]:
		var crack := Line2D.new()
		crack.points = PackedVector2Array(diagonal)
		crack.width = 2.0
		crack.default_color = Color(0.78,0.90,0.91,0.75)
		broken_marks.add_child(crack)
	var layers: Array[Node2D] = []
	for layer_index in 2:
		var plank_root := Node2D.new()
		plank_root.name = "Barricade_%02d_%d" % [windows.size(), layer_index]
		plank_root.visible = false
		plank_root.z_index = pane.z_index + 4 + layer_index
		add_child(plank_root)
		var lift := 86.0 + layer_index * 28.0
		var shadow := Line2D.new()
		shadow.points = PackedVector2Array([a-Vector2(0,lift),b-Vector2(0,lift)])
		shadow.width = 19.0
		shadow.default_color = Color("33261d")
		plank_root.add_child(shadow)
		var plank := Line2D.new()
		plank.points = shadow.points
		plank.width = 14.0
		plank.default_color = Color("805538")
		plank_root.add_child(plank)
		var grain := Line2D.new()
		grain.points = PackedVector2Array([a.lerp(b,0.1)-Vector2(0,lift+2.0),a.lerp(b,0.9)-Vector2(0,lift+2.0)])
		grain.width = 1.5
		grain.default_color = Color("b98755")
		plank_root.add_child(grain)
		layers.append(plank_root)
	windows.append({
		"id":"window_%02d" % windows.size(),
		"a":world_map.world_to_map(a),
		"b":world_map.world_to_map(b),
		"near_side":near_side,
		"pane":pane,
		"frame":frame,
		"broken_marks":broken_marks,
		"state":"closed",
		"glass_hp":WINDOW_GLASS_HP,
		"layers":0,
		"layer_hp":[],
		"layer_nodes":layers,
	})
	if near_side:
		var blank := Node2D.new()
		add_child(blank)
		near_walls.append({"full":pane,"low":blank})
		near_walls.append({"full":frame,"low":blank})

func add_roof(footprint: PackedVector2Array) -> void:
	var center := (footprint[0]+footprint[2])*0.5
	var e := PackedVector2Array()
	for p in footprint: e.append(center+(p-center)*1.055+Vector2(0,-WALL_HEIGHT))
	var r0 := (e[0]+e[3])*0.5+Vector2(0,-88)
	var r1 := (e[1]+e[2])*0.5+Vector2(0,-88)
	roof = add_textured_polygon(PackedVector2Array([e[0],e[1],r1,r0]),"res://art/house_blue/roof.png",roundi(footprint[2].y*0.2)+220,Vector2(1664,840),Color(0.88,0.91,0.95))
	var slope := Polygon2D.new()
	slope.polygon = PackedVector2Array([r0,r1,e[2],e[3]])
	slope.uv = PackedVector2Array([Vector2.ZERO,Vector2(1664,0),Vector2(1664,840),Vector2(0,840)])
	slope.texture = roof.texture
	slope.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	slope.color = Color("b5b9c1")
	roof.add_child(slope)
	var gable := Polygon2D.new()
	gable.polygon = PackedVector2Array([e[1],e[2],r1])
	gable.color = Color("7795a2")
	roof.add_child(gable)
	for endpoints in [[e[0],e[1],r1,e[2],e[3]],[r0,r1],[e[3],r0]]:
		var trim := Line2D.new()
		trim.points = PackedVector2Array(endpoints)
		trim.width = 5
		trim.default_color = Color("e3e1d9")
		roof.add_child(trim)

func door_midpoint() -> Vector2:
	return world_map.map_to_world(Vector2(DOOR_X,(DOOR_MIN_Y+DOOR_MAX_Y)*0.5))

func refresh_door() -> void:
	var a: Vector2 = world_map.map_to_world(Vector2(DOOR_X,DOOR_MIN_Y))
	var b: Vector2 = world_map.map_to_world(Vector2(DOOR_X,DOOR_MAX_Y))
	door_component=preload("res://scripts/swing_door.gd").new()
	add_child(door_component)
	var texture: Texture2D=load(DOOR_TEXTURE_PATH)
	var size:=Vector2(texture.get_size())
	door_component.setup(world_map,Vector2(DOOR_X,DOOR_MIN_Y),Vector2(0,2),Vector2(-2,0),texture,Rect2(Vector2.ZERO,size))
	door_leaf=door_component.leaf
	var frame := Line2D.new()
	frame.points = PackedVector2Array([a,a+Vector2(0,-140),b+Vector2(0,-140),b])
	frame.width = 6
	frame.default_color = Color("ebe7dc")
	frame.z_index = roundi((b.y)*0.2)+7
	add_child(frame)
	var lintel := Polygon2D.new()
	lintel.polygon = PackedVector2Array([a+Vector2(0,-140),b+Vector2(0,-140),b+Vector2(0,-WALL_HEIGHT),a+Vector2(0,-WALL_HEIGHT)])
	lintel.color = Color("7895a6")
	lintel.z_index = frame.z_index-1
	add_child(lintel)
	var blank := Node2D.new()
	add_child(blank)
	near_walls.append({"full":lintel,"low":blank})
	near_walls.append({"full":frame,"low":blank})
	update_door()

func update_door() -> void:
	door_component.step(0.0)

func get_search_area() -> Rect2:
	return Rect2(16.35,43.35,12.5,9.3)

func build_fence() -> void:
	fence_segments = [
		[Vector2(13,41),Vector2(34,41)],
		[Vector2(13,41),Vector2(13,57)],
		[Vector2(13,57),Vector2(34,57)],
		[Vector2(34,41),Vector2(34,48)],
		[Vector2(34,50),Vector2(34,57)],
	]
	for segment in fence_segments:
		var a: Vector2 = world_map.map_to_world(segment[0])
		var b: Vector2 = world_map.map_to_world(segment[1])
		var count := ceili(a.distance_to(b)/12.0)
		for i in count:
			var foot := a.lerp(b,float(i)/count)
			var next := a.lerp(b,float(i+1)/count)
			var post := Polygon2D.new()
			post.polygon = PackedVector2Array([foot+Vector2(-2,0),foot+Vector2(2,0),foot+Vector2(2,-47),foot+Vector2(0,-51),foot+Vector2(-2,-47)])
			post.color = Color("e7e4d7")
			post.z_index = roundi((foot.y)*0.2)
			add_child(post)
			for h in [15,35]:
				var rail := Line2D.new()
				rail.points = PackedVector2Array([foot-Vector2(0,h),next-Vector2(0,h)])
				rail.width = 3
				rail.default_color = Color("c8c9ba")
				rail.z_index = roundi((foot.y)*0.2)-1
				add_child(rail)

func add_furniture() -> void:
	load_furniture_layout("blue_house")

func load_furniture_layout(key: String, supplied: Dictionary = {}) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/building_layouts.json"))
	var layout: Dictionary = data.buildings[key] if supplied.is_empty() else supplied
	var origin := Vector2(layout.origin[0],layout.origin[1])
	for entry in layout.items:
		var size_m := Vector2(entry.size_m[0],entry.size_m[1])
		var minimum := origin+Vector2(entry.position_m[0],entry.position_m[1])/float(data.cell_m)
		var bounds := Rect2(minimum,size_m/float(data.cell_m))
		var sprite := Sprite2D.new()
		var external_asset := str(entry.get("asset",""))
		sprite.texture = load(external_asset) if not external_asset.is_empty() else furniture_texture(int(entry.get("asset_cell",entry.cell)))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		# The bottom-center sprite pivot belongs on the projected south-east
		# corner of its collision footprint. Project the corner directly so both
		# the horizontal and vertical isometric offsets stay correct.
		sprite.position = world_map.map_to_world(bounds.end)
		sprite.offset.y = -sprite.texture.get_height()*0.5
		# Match projected footprint width and physical elevation independently.
		var projected := Vector2((size_m.x+size_m.y)*64.0,(size_m.x+size_m.y)*32.0+float(entry.height_m)*64.0)
		if external_asset.is_empty():
			sprite.scale = projected/Vector2(sprite.texture.get_size())
			sprite.flip_h = entry.front == "east" and int(entry.cell) != 0
		else:
			# CC0 isometric sprites already contain their height and projection. Scale
			# uniformly from the physical footprint so doors, beds and actors agree.
			var asset_scale := projected.x/float(sprite.texture.get_width())*float(entry.get("asset_scale",1.0))
			sprite.scale = Vector2.ONE*asset_scale
			sprite.modulate = Color.WHITE
		sprite.z_index = roundi((sprite.position.y)*0.2)
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/search_outline.gdshader")
		if not external_asset.is_empty():
			material.set_shader_parameter("desaturate",float(entry.get("desaturate",0.58)))
			material.set_shader_parameter("color_grade",Color(str(entry.get("tint","d6d0c5"))))
		sprite.material = material
		add_child(sprite)
		var zone := bounds
		var depth := float(entry.clearance_m)/float(data.cell_m)
		match str(entry.front):
			"south": zone = Rect2(bounds.position.x,bounds.end.y,bounds.size.x,depth)
			"north": zone = Rect2(bounds.position.x,bounds.position.y-depth,bounds.size.x,depth)
			"east": zone = Rect2(bounds.end.x,bounds.position.y,depth,bounds.size.y)
			"west": zone = Rect2(bounds.position.x-depth,bounds.position.y,depth,bounds.size.y)
		furniture.append({"title":entry.name,"map":bounds.get_center(),"sprite":sprite,"remaining":entry.loot.duplicate(),"bounds":bounds,"use_zone":zone,"front":entry.front,"visual_anchor":bounds.end})
	# A floor mat marks the actual entrance, without a floating interaction icon.
	var center := door_midpoint()
	var mat := Polygon2D.new()
	mat.polygon = PackedVector2Array([center+Vector2(-35,0),center+Vector2(0,-17),center+Vector2(35,0),center+Vector2(0,17)])
	mat.color = Color("baad80")
	mat.z_index = -5
	add_child(mat)

func furniture_texture(cell: int) -> Texture2D:
	return load("res://art/house_blue/prop-v08-"+str(cell)+".png")

func update_player(player_world: Vector2,delta: float = 1.0/60.0) -> void:
	player_location = player_world
	var logical: Vector2 = world_map.world_to_map(player_world)
	inside = get_search_area().has_point(logical)
	roof.modulate.a = move_toward(roof.modulate.a,0.0 if inside else 1.0,delta*4.5)
	roof.visible = roof.modulate.a > 0.02
	for pair in near_walls:
		pair.full.visible = not inside
		pair.low.visible = inside
	door_component.step(delta)
	door_amount=door_component.amount
	door_open=door_component.opened
	selected = nearest_furniture(player_world)
	update_windows(player_world)
	for i in furniture.size():
		# Interior props belong to the cutaway interior, not the exterior facade.
		furniture[i].sprite.visible = inside
		furniture[i].sprite.material.set_shader_parameter("glow",0.75 if i == selected else 0.0)

func update_windows(player_world: Vector2) -> void:
	selected_window = nearest_window(player_world)
	for i in windows.size():
		var window: Dictionary = windows[i]
		window.frame.default_color = Color("f0c86b") if i == selected_window else Color("e5e2d5")
		var cutaway: bool = inside and bool(window.near_side)
		window.pane.visible = str(window.state)=="closed" and not cutaway
		window.broken_marks.visible = str(window.state)=="broken" and not cutaway
		for layer_index in window.layer_nodes.size():
			window.layer_nodes[layer_index].visible = layer_index < int(window.layers) and not cutaway
			if layer_index < window.layer_hp.size():
				window.layer_nodes[layer_index].modulate = Color.WHITE.lerp(Color("774b42"),1.0-clampf(float(window.layer_hp[layer_index])/BARRICADE_LAYER_HP,0.0,1.0))

func nearest_window(player_world: Vector2,max_distance_meters: float = 1.15) -> int:
	var logical: Vector2 = world_map.world_to_map(player_world)
	var best: int = -1
	var best_distance: float = max_distance_meters
	for i in windows.size():
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(logical,windows[i].a,windows[i].b)
		var distance: float = logical.distance_to(closest)*0.5
		if distance <= best_distance:
			best_distance = distance
			best = i
	return best

func barricade_layers(index: int) -> int:
	return int(windows[index].layers) if index >= 0 and index < windows.size() else 0

func set_barricade_layers(index: int,value: int) -> void:
	if index < 0 or index >= windows.size():
		return
	windows[index].layers = clampi(value,0,2)
	var hp: Array = windows[index].layer_hp
	while hp.size()<int(windows[index].layers): hp.append(BARRICADE_LAYER_HP)
	while hp.size()>int(windows[index].layers): hp.pop_back()
	windows[index].layer_hp=hp
	update_windows(player_location)

func add_barricade_layer(index: int) -> bool:
	if index < 0 or index >= windows.size() or int(windows[index].layers) >= 2:
		return false
	set_barricade_layers(index,int(windows[index].layers)+1)
	return true

func remove_barricade_layer(index: int) -> bool:
	if index < 0 or index >= windows.size() or int(windows[index].layers) <= 0:
		return false
	set_barricade_layers(index,int(windows[index].layers)-1)
	return true

func barricade_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for window in windows:
		result.append({"state":str(window.state),"glass_hp":float(window.glass_hp),"layer_hp":window.layer_hp.duplicate()})
	return result

func apply_barricade_state(saved: Array) -> void:
	for i in mini(saved.size(),windows.size()):
		if typeof(saved[i])==TYPE_DICTIONARY:
			windows[i].state=str(saved[i].get("state","closed"))
			windows[i].glass_hp=clampf(float(saved[i].get("glass_hp",WINDOW_GLASS_HP)),0.0,WINDOW_GLASS_HP)
			windows[i].layer_hp=saved[i].get("layer_hp",[]).duplicate()
			windows[i].layers=mini(2,windows[i].layer_hp.size())
		else:
			set_barricade_layers(i,int(saved[i]))
	update_windows(player_location)

func window_state(index: int) -> String:
	return str(windows[index].state) if index>=0 and index<windows.size() else "closed"

func toggle_window(index: int) -> Dictionary:
	if index<0 or index>=windows.size(): return {"ok":false,"message":"无效窗户"}
	var window: Dictionary=windows[index]
	if int(window.layers)>0: return {"ok":false,"message":"木板挡住了窗户"}
	if str(window.state)=="broken": return {"ok":false,"message":"玻璃已经破碎"}
	window.state="open" if str(window.state)=="closed" else "closed"
	update_windows(player_location)
	return {"ok":true,"message":"已打开窗户" if str(window.state)=="open" else "已关闭窗户"}

func window_crossing(index: int,actor_world: Vector2) -> Dictionary:
	if index<0 or index>=windows.size(): return {}
	var window: Dictionary=windows[index]
	if int(window.layers)>0 or str(window.state)=="closed": return {}
	var midpoint: Vector2=(window.a+window.b)*0.5
	var direction: Vector2=(window.b-window.a).normalized()
	var normal:=Vector2(-direction.y,direction.x)
	var actor_logical: Vector2=world_map.world_to_map(actor_world)
	var side:=1.0 if (actor_logical-midpoint).dot(normal)>=0.0 else -1.0
	return {"start":world_map.map_to_world(midpoint+normal*side*0.82),"destination":world_map.map_to_world(midpoint-normal*side*0.82),"broken":str(window.state)=="broken"}

func damage_window(index: int,value: float) -> Dictionary:
	if index<0 or index>=windows.size(): return {"event":"none"}
	var window: Dictionary=windows[index]
	if int(window.layers)>0:
		var hp_index:=int(window.layers)-1
		window.layer_hp[hp_index]=maxf(0.0,float(window.layer_hp[hp_index])-value)
		if float(window.layer_hp[hp_index])<=0.0:
			window.layer_hp.pop_back()
			window.layers=int(window.layers)-1
			update_windows(player_location)
			return {"event":"board_broken","window":index}
		update_windows(player_location)
		return {"event":"board_hit","window":index}
	if str(window.state)!="broken":
		window.glass_hp=maxf(0.0,float(window.glass_hp)-value)
		if float(window.glass_hp)<=0.0:
			window.state="broken"
			update_windows(player_location)
			return {"event":"glass_broken","window":index}
	return {"event":"glass_hit","window":index}

func repair_window(index: int,value: float=BARRICADE_LAYER_HP) -> bool:
	if index<0 or index>=windows.size() or int(windows[index].layers)<=0: return false
	var hp_index:=int(windows[index].layers)-1
	if float(windows[index].layer_hp[hp_index])>=BARRICADE_LAYER_HP: return false
	windows[index].layer_hp[hp_index]=minf(BARRICADE_LAYER_HP,float(windows[index].layer_hp[hp_index])+value)
	update_windows(player_location)
	return true

func all_doors() -> Array[Node2D]:
	return [door_component]

func nearest_door_component(point: Vector2) -> Node2D:
	return door_component

func window_title(index: int) -> String:
	return "窗户 %d" % (index+1)

func is_walkable_logical(logical: Vector2) -> bool:
	for segment in fence_segments:
		var closest := Geometry2D.get_closest_point_to_segment(logical,segment[0],segment[1])
		if logical.distance_to(closest) < 0.09: return false
	if logical.x < 16 or logical.x > 29 or logical.y < 43 or logical.y > 53: return true
	if logical.x < 16.22 or logical.y < 43.22 or logical.y > 52.78: return false
	if logical.x > 28.78:
		return (door_component.broken or (door_open and door_amount>0.85)) and logical.y>DOOR_MIN_Y+0.12 and logical.y<DOOR_MAX_Y-0.12
	for item in furniture:
		if item.bounds.has_point(logical): return false
	if door_amount>0.1:
		var hinge := Vector2(DOOR_X,DOOR_MIN_Y)
		var tip := hinge+Vector2(-sin(door_amount*PI*0.5),cos(door_amount*PI*0.5))*2.0
		if logical.distance_to(Geometry2D.get_closest_point_to_segment(logical,hinge,tip))<0.10: return false
	return true

func near_door(player_world: Vector2) -> bool:
	return door_component.near(player_world)

func try_toggle_door(player_world: Vector2) -> bool:
	var result: bool=door_component.toggle(player_world)
	door_open=door_component.opened
	return result

func nearest_furniture(player_world: Vector2) -> int:
	var logical: Vector2 = world_map.world_to_map(player_world)
	if not get_search_area().has_point(logical): return -1
	var best := -1
	var distance: float=preload("res://scripts/player_metrics.gd").INTERACTION_METERS
	for i in furniture.size():
		if not furniture[i].use_zone.has_point(logical): continue
		var box: Rect2 = furniture[i].bounds
		var nearest := logical.clamp(box.position,box.end)
		var current := logical.distance_to(nearest)*0.5
		if current >= distance: continue
		var blocked := false
		for step in range(1,10):
			var probe := logical.lerp(nearest,float(step)/10.0)
			if not is_walkable_logical(probe): blocked=true
			for j in furniture.size():
				if j != i and furniture[j].bounds.has_point(probe): blocked = true
		if not blocked:
			distance = current
			best = i
	return best

func available_loot(index: int) -> Dictionary:
	return furniture[index].remaining.duplicate()

func take_item(index: int,key: String) -> int:
	var amount := int(furniture[index].remaining.get(key,0))
	furniture[index].remaining[key] = 0
	return amount

func item_title(index: int) -> String:
	return furniture[index].title
