extends Node2D
const GRID := 32
var world_map: Node2D
var routes: Array = []
var plots: Array[Rect2] = []
var chunks: Dictionary = {}
var tree_data: Dictionary = {}
var anchor: Dictionary = {}
var current := Vector2i(-100,-100)
var accumulator := 0.0
var foliage_material: ShaderMaterial
var pond_center := Vector2(381,469)
var pond_radius := Vector2(24,15)

func setup(map: Node2D) -> void:
	world_map=map
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/expansion-runtime-01.json"))
	routes=data.routes
	for raw in data.plots: plots.append(Rect2(raw[0],raw[1],raw[2],raw[3]))
	foliage_material=ShaderMaterial.new()
	foliage_material.shader=load("res://shaders/foliage.gdshader")
	for route in routes:
		var points:=PackedVector2Array()
		for v in route.points: points.append(Vector2(v[0],v[1]))
		var polygons: Array[PackedVector2Array]=[]
		# Render each path segment as a strip. A near-closed ring returns an inner
		# polygon from offset_polyline; filling it would pave the whole park.
		for i in range(1,points.size()):
			polygons.append_array(Geometry2D.offset_polyline(PackedVector2Array([points[i-1],points[i]]),float(route.width)*0.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
		for polygon in polygons:
			var face:=Polygon2D.new()
			var projected:=PackedVector2Array()
			var uv:=PackedVector2Array()
			for cell in polygon:
				projected.append(world_map.map_to_world(cell))
				uv.append(cell*64.0)
			face.polygon=projected
			face.uv=uv
			face.texture=load("res://art/terrain/asphalt.png" if route.kind in ["road","street"] else "res://art/terrain/concrete.png")
			face.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
			face.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			face.modulate=Color(0.86,0.87,0.88) if route.kind in ["road","street"] else Color("b6a88a")
			face.z_index=-20 if route.kind in ["road","street"] else -19
			add_child(face)
			# Subtle shoulder under the textured strip, not a filled bare polygon.
			var shoulder:=Line2D.new()
			shoulder.points=projected
			shoulder.closed=true
			shoulder.width=5 if route.kind in ["road","street"] else 3
			shoulder.default_color=Color("b1b09a") if route.kind in ["road","street"] else Color("aaa77b")
			shoulder.z_index=face.z_index-1
			add_child(shoulder)
	for route in routes:
		if route.kind!="road": continue
		for i in range(1,route.points.size()):
			var a:=Vector2(route.points[i-1][0],route.points[i-1][1])
			var b:=Vector2(route.points[i][0],route.points[i][1])
			var length:=a.distance_to(b)
			var dir: Vector2=(b-a).normalized()
			var cursor:=3.0
			while cursor<length-3:
				var stripe:=Line2D.new()
				stripe.points=PackedVector2Array([world_map.map_to_world(a+dir*cursor),world_map.map_to_world(a+dir*minf(cursor+1.7,length-3))])
				stripe.width=2.0
				stripe.default_color=Color("cebd72")
				stripe.z_index=-16
				add_child(stripe)
				cursor+=5
	# A circular road end and actual natural destination, rather than more straight asphalt.
	var cul:=PackedVector2Array()
	var water:=PackedVector2Array()
	for i in 48:
		var angle:=i*TAU/48.0
		cul.append(world_map.map_to_world(Vector2(111,279)+Vector2(cos(angle),sin(angle))*9))
		water.append(world_map.map_to_world(pond_center+Vector2(cos(angle),sin(angle))*pond_radius))
	var turning:=Polygon2D.new()
	turning.polygon=cul
	var turn_uv:=PackedVector2Array()
	for point in cul: turn_uv.append(world_map.world_to_map(point)*64)
	turning.uv=turn_uv
	turning.texture=load("res://art/terrain/asphalt.png")
	turning.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	turning.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	turning.modulate=Color(0.86,0.87,0.88)
	turning.z_index=-18
	add_child(turning)
	var pond:=Polygon2D.new()
	pond.polygon=water
	var water_uv:=PackedVector2Array()
	for point in water:
		water_uv.append(((world_map.world_to_map(point)-pond_center)/pond_radius*0.5+Vector2.ONE*0.5)*64.0)
	pond.uv=water_uv
	var water_texture:=GradientTexture2D.new()
	water_texture.width=64
	water_texture.height=64
	water_texture.gradient=Gradient.new()
	pond.texture=water_texture
	var water_material:=ShaderMaterial.new()
	water_material.shader=load("res://shaders/pond.gdshader")
	pond.material=water_material
	pond.z_index=-18
	add_child(pond)
	var shore:=Line2D.new()
	shore.points=water
	shore.closed=true
	shore.width=20
	shore.default_color=Color("929c79")
	shore.z_index=-19
	add_child(shore)
	# Replace placeholder pads with short front walks and planted plot edges.
	var yard_rng:=RandomNumberGenerator.new()
	yard_rng.seed=106
	for plot in plots:
		var center:=plot.get_center()
		var closest:=center
		var distance:=INF
		for route in routes:
			if route.kind not in ["road","street"]: continue
			for i in range(1,route.points.size()):
				var a:=Vector2(route.points[i-1][0],route.points[i-1][1])
				var b:=Vector2(route.points[i][0],route.points[i][1])
				var foot:=Geometry2D.get_closest_point_to_segment(center,a,b)
				if center.distance_to(foot)<distance:
					distance=center.distance_to(foot)
					closest=foot
		# Stop at the plot edge: keep the future building footprint as lawn.
		var direction: Vector2=(closest-center).normalized()
		var half:=plot.size*0.5
		var reach:=minf(half.x/maxf(absf(direction.x),0.001),half.y/maxf(absf(direction.y),0.001))
		var doorstep: Vector2=center+direction*reach
		if distance-reach<14:
			var walk:=Line2D.new()
			walk.points=PackedVector2Array([world_map.map_to_world(doorstep),world_map.map_to_world(closest)])
			walk.width=20
			walk.default_color=Color("969878")
			walk.z_index=-19
			add_child(walk)
		for offset in [Vector2(-2,-2),Vector2(plot.size.x+2,-2),Vector2(-2,plot.size.y+2)]:
			var cell: Vector2=plot.position+offset
			spawn_sprite(self,"res://art/nature/bush-"+str(yard_rng.randi_range(0,2))+".png",cell,yard_rng.randf_range(0.6,0.9)*64,false)
	# Grass tufts soften the pond shore without adding impassable decoration.
	for i in 32:
		var angle:=i*TAU/32.0
		var cell:=pond_center+Vector2(cos(angle),sin(angle))*(pond_radius+Vector2(1.8,1.8))
		spawn_sprite(self,"res://art/nature/grass-"+str(i%3)+".png",cell,22+float(i%4)*3,false)
	update_chunks(Vector2(36,49))

func reserved(cell: Vector2,margin: float) -> bool:
	if Rect2(0,0,96,72).grow(margin).has_point(cell): return true
	for route in routes:
		for i in range(1,route.points.size()):
			var a:=Vector2(route.points[i-1][0],route.points[i-1][1])
			var b:=Vector2(route.points[i][0],route.points[i][1])
			if cell.distance_to(Geometry2D.get_closest_point_to_segment(cell,a,b))<float(route.width)*0.5+margin: return true
	for plot in plots:
		if plot.grow(margin+3).has_point(cell): return true
	if cell.distance_to(Vector2(111,279))<9+margin: return true
	if ((cell-pond_center)/(pond_radius+Vector2.ONE*margin)).length()<1.0: return true
	return false

func trees_for(key: Vector2i) -> Array:
	if tree_data.has(key): return tree_data[key]
	var rng:=RandomNumberGenerator.new()
	rng.seed=abs(key.x*73856093+key.y*19349663)+4242
	var result: Array=[]
	for i in 4:
		var cell:=Vector2(key*GRID)+Vector2(rng.randf_range(3,29),rng.randf_range(3,29))
		if not Rect2(Vector2.ZERO,Vector2(world_map.MAP_SIZE)).has_point(cell) or reserved(cell,6): continue
		result.append({"cell":cell,"variant":rng.randi_range(0,5),"height":rng.randf_range(6,8)*64})
	tree_data[key]=result
	return result

func blocks(cell: Vector2) -> bool:
	if ((cell-pond_center)/pond_radius).length()<1: return true
	var key:=Vector2i(floori(cell.x/GRID),floori(cell.y/GRID))
	for x in range(key.x-1,key.x+2):
		for y in range(key.y-1,key.y+2):
			for tree in trees_for(Vector2i(x,y)):
				if cell.distance_squared_to(tree.cell)<0.42*0.42: return true
	return false

func update_chunks(cell: Vector2) -> void:
	var key:=Vector2i(floori(cell.x/GRID),floori(cell.y/GRID))
	if current==key: return
	current=key
	var keep: Dictionary={}
	for x in range(maxi(0,key.x-3),mini(16,key.x+4)):
		for y in range(maxi(0,key.y-3),mini(18,key.y+4)):
			var id:=Vector2i(x,y)
			keep[id]=true
			if not chunks.has(id): build_chunk(id)
	for id in chunks.keys():
		if not keep.has(id):
			chunks[id].queue_free()
			chunks.erase(id)

func build_chunk(key: Vector2i) -> void:
	var group:=Node2D.new()
	add_child(group)
	chunks[key]=group
	var start:=Vector2(key*GRID)
	# Original base stays intact; new tiles use the same global UV phase.
	if start.x>=96 or start.y>=64:
		var top:=start.y
		if start.x<96: top=maxf(top,72)
		var bottom:=start.y+GRID
		if bottom>top:
			var floor_node:=Polygon2D.new()
			var rect:=Rect2i(int(start.x),int(top),GRID,int(bottom-top))
			floor_node.polygon=world_map.map_rect(rect)
			floor_node.uv=PackedVector2Array([Vector2(rect.position)*64,Vector2(rect.end.x,rect.position.y)*64,Vector2(rect.end)*64,Vector2(rect.position.x,rect.end.y)*64])
			floor_node.texture=load("res://art/terrain/grass.png")
			floor_node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
			floor_node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			floor_node.modulate=Color(0.94,0.96,0.88)
			floor_node.z_index=-30
			group.add_child(floor_node)
	for tree in trees_for(key):
		spawn_sprite(group,"res://art/nature/tree-"+str(tree.variant)+".png",tree.cell,tree.height,true)
	var rng:=RandomNumberGenerator.new()
	rng.seed=key.x*1031+key.y*7919+77
	for i in 38:
		var cell:=start+Vector2(rng.randf_range(1,31),rng.randf_range(1,31))
		if reserved(cell,1): continue
		spawn_sprite(group,"res://art/nature/grass-"+str(rng.randi_range(0,2))+".png",cell,rng.randf_range(0.2,0.5)*64,false)

func spawn_sprite(group: Node2D,path: String,cell: Vector2,height: float,is_tree: bool) -> void:
	var sprite:=Sprite2D.new()
	sprite.texture=load(path)
	var size:=Vector2(sprite.texture.get_size())
	if not anchor.has(path):
		var img:=sprite.texture.get_image()
		var bottom:=0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x,y).a>0.9: bottom=maxi(bottom,y)
		var sum:=0.0
		var count:=0
		for y in range(maxi(0,bottom-4),bottom+1):
			for x in img.get_width():
				if img.get_pixel(x,y).a>0.9:
					sum+=x
					count+=1
		anchor[path]=Vector2(sum/maxi(1,count),bottom+1)
	var foot: Vector2=anchor[path]
	sprite.offset=size*0.5-foot
	sprite.scale=Vector2.ONE*height/foot.y
	sprite.position=world_map.map_to_world(cell)
	sprite.z_index=roundi(sprite.position.y*0.2)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if not is_tree: sprite.material=foliage_material
	sprite.set_meta("tree",is_tree)
	group.add_child(sprite)

func _process(delta: float) -> void:
	var player: Node2D=world_map.get_parent().get("player")
	if not is_instance_valid(player): return
	accumulator+=delta
	if accumulator>=0.12:
		accumulator=0
		update_chunks(world_map.world_to_map(player.position))
	for group in chunks.values():
		for node in group.get_children():
			if not node.has_meta("tree") or not node.get_meta("tree"): continue
			var local: Rect2=node.get_rect()
			var box:=Rect2(node.position+local.position*node.scale,local.size*node.scale)
			var obscured: bool=player.position.y<node.position.y and box.has_point(player.position-Vector2(0,60))
			node.modulate.a=move_toward(node.modulate.a,0.28 if obscured else 1.0,delta*4)
