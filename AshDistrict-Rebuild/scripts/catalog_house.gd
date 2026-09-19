extends "res://scripts/blue_house.gd"

var config: Dictionary
var origin := Vector2.ZERO
var outline := PackedVector2Array()
var wall_sections: Array[Dictionary] = []
var roofs: Array[Polygon2D] = []
var approach := PackedVector2Array()

func logical(v: Array) -> Vector2:
	return origin+Vector2(v[0],v[1])*2.0

func build() -> void:
	origin=Vector2(config.origin[0],config.origin[1])
	for v in config.outline: outline.append(logical(v))
	var ground := Polygon2D.new()
	# Packed arrays are value types: assign the completed array explicitly.
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for p in outline:
		points.append(world_map.map_to_world(p))
		uv.append((p-origin)*64.0)
	ground.polygon=points
	ground.uv=uv
	ground.texture=load("res://art/house_blue/floor.png")
	ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.z_index=-8
	add_child(ground)
	for wall in config.walls:
		make_wall(logical(wall.a),logical(wall.b),wall.exterior)
	var a:=logical([float(config.entry)-0.5,float(config.size_m[1])])
	var b:=a+Vector2(2,0)
	door_component=preload("res://scripts/swing_door.gd").new()
	add_child(door_component)
	var texture: Texture2D=load(DOOR_TEXTURE_PATH)
	var size:=Vector2(texture.get_size())
	door_component.setup(world_map,a,Vector2(2,0),Vector2(0,2),texture,Rect2(Vector2.ZERO,size))
	door_leaf=door_component.leaf
	make_lintel(a,b)
	for gap in config.doorways: make_lintel(logical(gap[0]),logical(gap[1]))
	# Windows are on the exposed west facade; furniture is set back from them.
	add_window(world_map.map_to_world(logical([0,1.0])),world_map.map_to_world(logical([0,2.1])))
	var width: float=config.size_m[0]
	add_window(world_map.map_to_world(logical([width-2.2,0])),world_map.map_to_world(logical([width-1.0,0])))
	var front_width: float=6.0 if config.template=="H04" else width
	for window_x in [1.0,front_width-2.4]:
		if absf(window_x+0.6-float(config.entry))<1.2: continue
		add_window(world_map.map_to_world(logical([window_x,config.size_m[1]])),world_map.map_to_world(logical([window_x+1.2,config.size_m[1]])),true)
	load_furniture_layout("",config)
	for section in config.roofs:
		var r:=Rect2(logical([section[0],section[1]]),Vector2(section[2],section[3])*2)
		var fp:=PackedVector2Array([world_map.map_to_world(r.position),world_map.map_to_world(Vector2(r.end.x,r.position.y)),world_map.map_to_world(r.end),world_map.map_to_world(Vector2(r.position.x,r.end.y))])
		# Shared roof constructor uses the same house-scale texture family.
		super.add_roof(fp)
		roof.z_index=roundi(fp[2].y*0.2)+220
		roof.modulate=Color("b7b2a6") if config.template in ["H02","H06"] else Color("929da3")
		roofs.append(roof)

func make_wall(a: Vector2,b: Vector2,exterior: bool) -> void:
	# Short panels allow furniture and actor depth sorting along long walls.
	var count:=maxi(1,ceili(a.distance_to(b)/1.0))
	for i in count:
		var left:=a.lerp(b,float(i)/count)
		var right:=a.lerp(b,float(i+1)/count)
		var wa: Vector2=world_map.map_to_world(left)
		var wb: Vector2=world_map.map_to_world(right)
		var full:=wall_face(wa,wb,172.8)
		var low:=wall_face(wa,wb,32.0)
		for face in [full,low]:
			if not exterior: face.texture=null
			face.modulate=Color.WHITE
			face.color=Color(str(config.palette)) if exterior else Color("d9d1be")
			var cap:=Line2D.new()
			var height: float=172.8 if face==full else 32
			cap.points=PackedVector2Array([wa-Vector2(0,height),wb-Vector2(0,height)])
			cap.width=7
			cap.default_color=Color("eee6d7")
			face.add_child(cap)
		low.visible=false
		wall_sections.append({"a":left,"b":right,"full":full,"low":low,"exterior":exterior})

func make_lintel(a: Vector2,b: Vector2) -> void:
	var wa: Vector2=world_map.map_to_world(a)
	var wb: Vector2=world_map.map_to_world(b)
	var node:=Polygon2D.new()
	node.polygon=PackedVector2Array([wa-Vector2(0,140),wb-Vector2(0,140),wb-Vector2(0,172.8),wa-Vector2(0,172.8)])
	node.color=Color("d9d1be")
	node.z_index=roundi(maxf(wa.y,wb.y)*0.2)+1
	add_child(node)
	var frame:=Line2D.new()
	frame.points=PackedVector2Array([wa,wa-Vector2(0,140),wb-Vector2(0,140),wb])
	frame.default_color=Color("f0e6d3")
	frame.width=5
	node.add_child(frame)
	var low:=Node2D.new()
	add_child(low)
	wall_sections.append({"a":a,"b":b,"full":node,"low":low,"exterior":false})

func get_search_area() -> Rect2:
	return Rect2(origin+Vector2.ONE*.25,Vector2(config.size_m[0],config.size_m[1])*2.0-Vector2.ONE*.5)

func door_midpoint() -> Vector2:
	return world_map.map_to_world(logical([config.entry,config.size_m[1]]))

func is_walkable_logical(point: Vector2) -> bool:
	if not get_search_area().grow(3).has_point(point): return true
	for section in config.walls:
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,logical(section.a),logical(section.b)))<0.14: return false
	for item in furniture:
		if item.bounds.has_point(point): return false
	return not door_component.blocks(point)

func update_player(point: Vector2,delta: float=0.016) -> void:
	player_location=point
	var p: Vector2=world_map.world_to_map(point)
	inside=Geometry2D.is_point_in_polygon(p,outline)
	for top in roofs:
		top.modulate.a=move_toward(top.modulate.a,0.0 if inside else 1.0,delta*5)
		top.visible=top.modulate.a>.02
	for section in wall_sections:
		var a: Vector2=section.a
		var b: Vector2=section.b
		var vertical:=absf(a.x-b.x)<.01
		var cut: bool=inside and (p.x<a.x if vertical else p.y<a.y)
		section.full.visible=not cut
		section.low.visible=cut
		if section.exterior:
			for face in [section.full,section.low]:
				face.texture=null if inside else load(SIDING_TEXTURE_PATH)
				face.color=Color("d9d1be") if inside else Color(str(config.palette))
	for window in near_walls:
		window.full.visible=not inside
	update_windows(point)
	door_component.step(delta)
	door_open=door_component.opened
	door_amount=door_component.amount
	selected=nearest_furniture(point) if inside else -1
	for i in furniture.size():
		var visible_from_player:=inside
		if inside:
			var target: Vector2=furniture[i].bounds.get_center()
			for wall in config.walls:
				if Geometry2D.segment_intersects_segment(p,target,logical(wall.a),logical(wall.b))!=null:
					visible_from_player=false
					break
		furniture[i].sprite.visible=visible_from_player
		furniture[i].sprite.material.set_shader_parameter("glow",.75 if selected==i else 0.0)
