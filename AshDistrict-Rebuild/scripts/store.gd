extends "res://scripts/blue_house.gd"

var second_door: Node2D

func building_wall_height() -> float:
	return 192.0

func build() -> void:
	var corners: PackedVector2Array=world_map.map_rect(Rect2i(57,15,16,12))
	add_textured_polygon(corners,"res://art/terrain/concrete.png",-8,Vector2(1024,768),Color("d6d0b8"))
	for x in range(57,73):
		for y in range(15,27):
			var tile:=Polygon2D.new()
			var a: Vector2=world_map.map_to_world(Vector2(x+0.025,y+0.025))
			var b: Vector2=world_map.map_to_world(Vector2(x+0.975,y+0.025))
			var c: Vector2=world_map.map_to_world(Vector2(x+0.975,y+0.975))
			var d: Vector2=world_map.map_to_world(Vector2(x+0.025,y+0.975))
			tile.polygon=PackedVector2Array([a,b,c,d])
			tile.color=Color("ccc8b8") if (x+y)%2==0 else Color("c5c1b3")
			tile.z_index=-7
			add_child(tile)
	add_wall(corners[0],corners[1],false)
	add_wall(corners[0],corners[3],false)
	add_wall(corners[1],corners[2],true)
	for pair in near_walls:
		pair.full.texture=null
		pair.full.modulate=Color.WHITE
		pair.full.color=Color("d2cbb6")
		pair.low.texture=null
		pair.low.modulate=Color.WHITE
		pair.low.color=Color("bcb49e")
	# Each glazed bay is a separate cutaway module. The gap between 63 and 65 is physical.
	for ends in [[57.0,60.0],[60.0,62.2],[65.8,69.0],[69.0,73.0]]:
		glass_bay(Vector2(ends[0],27),Vector2(ends[1],27))
	glass_bay(Vector2(73,18),Vector2(73,22))
	glass_bay(Vector2(73,22),Vector2(73,26))
	refresh_door()
	add_furniture()
	add_flat_roof(corners)
	parking_lines()

func get_search_area() -> Rect2:
	return Rect2(57.35,15.35,15.3,11.4)

func door_midpoint() -> Vector2:
	return world_map.map_to_world(Vector2(64,27))

func refresh_door() -> void:
	door_component=preload("res://scripts/swing_door.gd").new()
	add_child(door_component)
	var texture: Texture2D=load("res://art/store/front.png")
	var size:=Vector2(texture.get_size())
	# Atlas split measured from the actual generated front elevation (not assumed equal).
	door_component.setup(world_map,Vector2(62.2,27),Vector2(1.8,0),Vector2(0,1.8),texture,Rect2(size.x*0.645,0,size.x*0.355,size.y),146.0)
	door_leaf=door_component.leaf
	second_door=preload("res://scripts/swing_door.gd").new()
	add_child(second_door)
	second_door.setup(world_map,Vector2(65.8,27),Vector2(-1.8,0),Vector2(0,1.8),texture,Rect2(size.x*0.645,0,size.x*0.355,size.y),146.0)
	var a: Vector2=world_map.map_to_world(Vector2(62.2,27))
	var b: Vector2=world_map.map_to_world(Vector2(65.8,27))
	var frame:=Line2D.new()
	frame.points=PackedVector2Array([a,a-Vector2(0,149),b-Vector2(0,149),b])
	frame.width=7
	frame.default_color=Color("eee2b5")
	frame.z_index=roundi((b.y)*0.2)+9
	add_child(frame)
	var blank:=Node2D.new()
	add_child(blank)
	near_walls.append({"full":frame,"low":blank})

func update_player(point: Vector2,delta: float=1.0/60.0) -> void:
	super.update_player(point,delta)
	second_door.opened=door_component.opened
	second_door.step(delta)

func try_toggle_door(point: Vector2) -> bool:
	var logical: Vector2=world_map.world_to_map(point)
	if door_open and absf(logical.y-27)<0.6 and logical.x>61.6 and logical.x<66.4: return false
	return super.try_toggle_door(point)

func all_doors() -> Array[Node2D]:
	return [door_component,second_door]

func nearest_door_component(point: Vector2) -> Node2D:
	return door_component if point.distance_to(door_component.midpoint())<=point.distance_to(second_door.midpoint()) else second_door


func is_walkable_logical(logical: Vector2) -> bool:
	if logical.x<57 or logical.x>73 or logical.y<15 or logical.y>27: return not door_component.blocks(logical) and not second_door.blocks(logical)
	if logical.x<57.22 or logical.x>72.78 or logical.y<15.22: return false
	if logical.y>26.78:
		return (door_component.broken or second_door.broken or (door_open and door_amount>0.85)) and logical.x>62.32 and logical.x<65.68
	for item in furniture:
		if item.bounds.has_point(logical): return false
	return not door_component.blocks(logical) and not second_door.blocks(logical)

func glass_bay(start: Vector2,end: Vector2) -> void:
	var a: Vector2=world_map.map_to_world(start)
	var b: Vector2=world_map.map_to_world(end)
	var glass:=Polygon2D.new()
	glass.polygon=PackedVector2Array([a,b,b-Vector2(0,146),a-Vector2(0,146)])
	glass.texture=load("res://art/store/front.png")
	var size:=Vector2(glass.texture.get_size())
	glass.uv=PackedVector2Array([Vector2(0,size.y),Vector2(size.x*0.643,size.y),Vector2(size.x*0.643,0),Vector2.ZERO])
	glass.z_index=roundi((maxf(a.y,b.y))*0.2)+3
	var header:=Polygon2D.new()
	header.polygon=PackedVector2Array([a-Vector2(0,146),b-Vector2(0,146),b-Vector2(0,163),a-Vector2(0,163)])
	header.color=Color("d2cbb6")
	header.z_index=glass.z_index
	add_child(header)
	var blank_header:=Node2D.new()
	add_child(blank_header)
	near_walls.append({"full":header,"low":blank_header})
	add_child(glass)
	var low:=Polygon2D.new()
	low.polygon=PackedVector2Array([a,b,b-Vector2(0,13),a-Vector2(0,13)])
	low.color=Color("bcb49e")
	low.z_index=glass.z_index
	add_child(low)
	near_walls.append({"full":glass,"low":low})

func add_flat_roof(corners: PackedVector2Array) -> void:
	var top:=PackedVector2Array()
	for p in corners: top.append(p-Vector2(0,192))
	roof=add_textured_polygon(top,"res://art/terrain/concrete.png",roundi(corners[2].y)+220,Vector2(1024,768),Color("a4a5a3"))
	for pair in [[corners[3],corners[2]],[corners[1],corners[2]]]:
		var a: Vector2=pair[0]
		var b: Vector2=pair[1]
		for stripe in [[163.0,171.0,Color("b83629")],[171.0,186.0,Color("dfbb57")],[186.0,192.0,Color("bd392d")]]:
			var face:=Polygon2D.new()
			face.polygon=PackedVector2Array([a-Vector2(0,stripe[0]),b-Vector2(0,stripe[0]),b-Vector2(0,stripe[1]),a-Vector2(0,stripe[1])])
			face.color=stripe[2]
			roof.add_child(face)
	var edge:=Line2D.new()
	edge.points=PackedVector2Array([top[0],top[1],top[2],top[3],top[0]])
	edge.width=7
	edge.default_color=Color("ebe7dd")
	roof.add_child(edge)
	# Roof seams are on the independent roof layer and disappear with it.
	for x in range(59,73,2):
		roof_line(world_map.map_to_world(Vector2(x,15))-Vector2(0,192),world_map.map_to_world(Vector2(x,27))-Vector2(0,192),1,Color("888a88"))
	for y in range(17,27,2):
		roof_line(world_map.map_to_world(Vector2(57,y))-Vector2(0,192),world_map.map_to_world(Vector2(73,y))-Vector2(0,192),1,Color("888a88"))
	var unit: Vector2=world_map.map_to_world(Vector2(65,20))-Vector2(0,194)
	var hvac:=Polygon2D.new()
	hvac.polygon=PackedVector2Array([unit+Vector2(-30,0),unit+Vector2(0,15),unit+Vector2(35,-3),unit+Vector2(35,-39),unit+Vector2(0,-55),unit+Vector2(-30,-37)])
	hvac.color=Color("666b6d")
	roof.add_child(hvac)
	roof_line(unit+Vector2(-30,-37),unit+Vector2(0,-20),3,Color("d8d9d6"))
	roof_line(unit+Vector2(0,-20),unit+Vector2(35,-39),3,Color("d8d9d6"))
	for i in 6: roof_line(unit+Vector2(-24,-30+i*4),unit+Vector2(-5,-20+i*4),2,Color("292d2e"))
	var sign:=Label.new()
	sign.text="便利商店"
	sign.add_theme_font_size_override("font_size",14)
	sign.add_theme_color_override("font_color",Color("7c221c"))
	sign.position=world_map.map_to_world(Vector2(63,27))-Vector2(0,190)
	sign.rotation=atan(0.5)
	roof.add_child(sign)

func roof_line(a: Vector2,b: Vector2,width: float,color: Color) -> void:
	var line:=Line2D.new()
	line.points=PackedVector2Array([a,b])
	line.width=width
	line.default_color=color
	roof.add_child(line)

func parking_lines() -> void:
	for x in [56,59,68,71,74]:
		var line:=Line2D.new()
		line.points=PackedVector2Array([world_map.map_to_world(Vector2(x,28)),world_map.map_to_world(Vector2(x,31.5))])
		line.width=2.5
		line.default_color=Color("d9d6c9")
		line.z_index=-12
		add_child(line)

func add_furniture() -> void:
	load_furniture_layout("store")

func furniture_texture(cell: int) -> AtlasTexture:
	var sheet: Texture2D=load("res://art/store/props.png")
	var img:=sheet.get_image()
	var boundaries: Array=[0.0,0.29,0.67,1.0]
	var region:=Rect2i(int(boundaries[cell]*img.get_width()),0,int((boundaries[cell+1]-boundaries[cell])*img.get_width()),img.get_height())
	var left:=region.end.x
	var right:=region.position.x
	var top:=img.get_height()
	var bottom:=0
	for y in img.get_height():
		for x in range(region.position.x,region.end.x):
			if img.get_pixel(x,y).a>0.45:
				left=mini(left,x)
				right=maxi(right,x)
				top=mini(top,y)
				bottom=maxi(bottom,y)
	var atlas:=AtlasTexture.new()
	atlas.atlas=sheet
	atlas.region=Rect2(left-3,top-3,right-left+7,bottom-top+7)
	return atlas
