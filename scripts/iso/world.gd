extends RefCounted

const BACKGROUND = preload("res://art/isometric/cedar-lane.png")
const District = preload("res://scripts/iso/district.gd")
var yard: RefCounted
var residence: RefCounted
var occluders: Array = []
var game: Node2D
var walkable: Array[PackedVector2Array] = []
var obstacles: Array[PackedVector2Array] = []

func _init(owner: Node2D) -> void:
	game = owner

func poly(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points: result.append(Vector2(p[0], p[1]))
	return result

func build() -> void:
	build_ground()
	paint_ground([[0,177],[1535,889],[1535,1023],[1030,1023],[0,535]])
	game.depth = Node2D.new()
	game.depth.y_sort_enabled = true
	game.add_child(game.depth)
	# Feet must not enter the solid footprint of the furniture and vehicles.
	block([[47,401],[107,366],[302,457],[280,498],[211,506],[65,438]])
	block([[976,894],[1011,854],[1081,867],[1192,935],[1205,976],[1159,994],[1035,939]])
	block([[318,191],[402,148],[445,173],[438,215],[352,247],[316,226]])
	block([[440,216],[483,192],[525,216],[491,245],[443,238]])
	block([[789,260],[835,238],[852,279],[807,304]])
	block([[839,240],[1000,155],[1030,201],[866,288]])
	# Keep a character-width aisle beside the bed so the bedside cabinet can be searched.
	block([[1133,345],[1249,282],[1290,311],[1274,357],[1222,397],[1140,371]])
	block([[1125,217],[1163,200],[1211,227],[1171,297],[1127,276]])
	block([[735,295],[768,279],[793,298],[756,324]])
	block([[591,437],[617,421],[639,438],[621,465],[593,456]])
	# Overlay the visible object silhouettes, sorted by their ground contact depth.
	foreground([[45,380],[87,342],[155,333],[217,360],[247,417],[300,448],[309,473],[281,494],[232,503],[193,480],[90,441],[60,425]], Vector2(176,484))
	foreground([[976,883],[1004,850],[1050,832],[1117,853],[1157,885],[1192,925],[1207,950],[1202,975],[1163,992],[1113,967],[1047,947],[1000,917]], Vector2(1091,977))
	foreground([[1137,316],[1244,264],[1322,300],[1320,352],[1232,405],[1137,366]], Vector2(1235,397))
	foreground([[1125,196],[1162,180],[1212,205],[1213,262],[1170,298],[1124,273]], Vector2(1170,293))
	foreground([[783,179],[822,158],[849,174],[851,274],[805,299],[785,287]], Vector2(817,292))
	foreground([[319,188],[405,146],[444,164],[445,214],[352,246],[318,227]], Vector2(382,241))
	foreground([[589,413],[614,396],[637,411],[637,447],[619,464],[590,452]], Vector2(614,461))
	game.safe_point = Vector2(397,270)
	game.add_loot("厨房橱柜", Vector2(913,280), {"food":2,"water":1})
	game.add_loot("床边药箱", Vector2(1350,350), {"water":1,"bandage":2})
	game.add_loot("卧室储物柜", Vector2(1111,308), {"parts":2,"food":1})
	game.add_loot("旅行车后备箱", Vector2(87,457), {"water":1,"food":1})
	game.add_loot("营地工具袋", Vector2(475,271), {"parts":1,"bandage":1})
	game.add_loot("旧冰箱", Vector2(815,321), {"food":1,"water":1})
	# Interaction anchors sit on reachable floor; outlines follow the actual furniture.
	game.set_container_visual(0, poly([[839,227],[992,154],[1028,177],[1027,223],[866,289],[839,277]]), Vector2(933,204), 2.0)
	game.set_container_visual(1, poly([[1309,309],[1344,292],[1377,310],[1376,353],[1338,374],[1310,357]]), Vector2(1345,318), 1.6)
	game.containers[1].title = "床头柜"
	game.set_container_visual(2, poly([[1124,195],[1161,180],[1212,205],[1213,262],[1170,298],[1124,273]]), Vector2(1165,214), 2.2)
	game.set_container_visual(3, poly([[46,380],[88,342],[155,333],[186,346],[135,389],[81,413]]), Vector2(99,362), 1.8)
	game.set_container_visual(4, poly([[438,216],[482,192],[525,212],[518,237],[487,250],[440,235]]), Vector2(484,207), 1.4)
	game.set_container_visual(5, poly([[783,179],[822,158],[849,174],[851,274],[805,299],[785,287]]), Vector2(815,195), 2.0)
	foreground([[201,111],[423,42],[427,139],[389,182],[210,207]],Vector2(320,200))
	foreground([[438,216],[482,192],[525,212],[518,237],[487,250],[440,235]],Vector2(484,250))
	yard = preload("res://scripts/iso/yard.gd").new(self)
	residence = preload("res://scripts/iso/residence.gd").new(self)
	residence.build()
	yard.build()
	build_expansion()
	build_roads()
	build_navigation()

func edge_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/iso/edge-blend.gdshader")
	return material

func textured_ground(vertices: PackedVector2Array,texture: Texture2D,z: int,tint := Color.WHITE) -> Polygon2D:
	var ground := Polygon2D.new()
	ground.polygon = vertices
	var uv := PackedVector2Array()
	for v in vertices: uv.append(v*4.0)
	ground.uv = uv
	ground.texture = texture
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.z_index = z
	ground.modulate = tint
	game.add_child(ground)
	return ground

func build_ground() -> void:
	textured_ground(poly([[0,0],[5760,0],[5760,3072],[0,3072]]),load("res://art/isometric/waste-ground.png"),-20,Color(0.65,0.71,0.62))

func build_roads() -> void:
	var asphalt: Texture2D = load("res://art/isometric/worn-asphalt.png")
	for road in District.ROADS:
		var line := PackedVector2Array(road.points)
		for shoulder in Geometry2D.offset_polyline(line,road.width/2.0+22,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			var node := textured_ground(shoulder,asphalt,-12,Color(0.65,0.63,0.52))
			soften_road(node,road,road.width/2.0+22)
		for surface in Geometry2D.offset_polyline(line,road.width/2.0,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			walkable.append(surface)
			var node := textured_ground(surface,asphalt,-11,Color(0.65,0.68,0.7))
			soften_road(node,road,road.width/2.0)
		for i in range(line.size()-1):
			var direction := (line[i+1]-line[i]).normalized()
			for distance in range(0,int(line[i].distance_to(line[i+1]))-16,32):
				var marking := Line2D.new()
				marking.points = PackedVector2Array([line[i]+direction*distance,line[i]+direction*(distance+14)])
				marking.width = 2
				marking.default_color = Color(0.62,0.56,0.34,0.45)
				marking.z_index = -11
				game.add_child(marking)

func soften_road(node: Polygon2D,road: Dictionary,width: float) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/iso/road-edge.gdshader")
	var points := PackedVector2Array(road.points)
	points.resize(4)
	mat.set_shader_parameter("road_points",points)
	mat.set_shader_parameter("road_count",road.points.size())
	mat.set_shader_parameter("half_width",width)
	node.material = mat

func build_expansion() -> void:
	for zone in ["junction","store","alley"]:
		var origin: Vector2 = District.ORIGINS[zone]
		var background := Sprite2D.new()
		background.texture = load("res://art/isometric/"+zone+".png")
		background.centered = false
		background.position = origin
		background.z_index = -10
		background.material = edge_material()
		game.add_child(background)
		for points in District.region_paths(zone): walkable.append(District.polygon(points,origin))
	# Separate furniture sprites own their collision footprint and inventory.
	add_prop("junction",3,Vector2(680,605),85,"路口遗留物资箱",{"water":1,"bandage":1})
	add_prop("store",0,Vector2(920,430),146,"食品货架",{"food":3})
	add_prop("store",0,Vector2(1100,520),146,"饮料货架",{"water":2})
	add_prop("store",1,Vector2(1140,390),145,"便利店冰柜",{"food":2,"water":1})
	add_prop("store",2,Vector2(720,425),124,"收银台储物柜",{"parts":1,"bandage":1})
	add_prop("store",3,Vector2(1190,480),84,"后门送货箱",{"parts":2,"food":1})
	add_prop("alley",3,Vector2(560,550),86,"后巷工具箱",{"parts":1,"bandage":1})
	add_prop("alley",3,Vector2(745,625),86,"庭院补给箱",{"food":1,"water":1})

func add_prop(zone: String,cell: int,local_at: Vector2,width: float,title: String,contents: Dictionary) -> void:
	var sheet: Texture2D = load("res://art/isometric/shop-props.png")
	var image := sheet.get_image()
	# The generated sheet has uneven gutters: use verified individual atlas regions.
	var cell_rect: Rect2i = [Rect2i(100,0,620,545),Rect2i(800,0,670,530),Rect2i(180,545,580,479),Rect2i(940,530,450,475)][cell]
	var used := image.get_region(cell_rect).get_used_rect()
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(cell_rect.position+used.position,used.size)
	texture.filter_clip = true
	var node := Sprite2D.new()
	node.texture = texture
	var factor := width/used.size.x
	node.scale = Vector2.ONE*factor
	node.offset.y = -used.size.y/2.0
	var at: Vector2 = District.ORIGINS[zone]+local_at
	node.position = at
	game.depth.add_child(node)
	obstacles.append(PackedVector2Array([at+Vector2(-width*0.45,-width*0.23),at+Vector2(0,-width*0.43),at+Vector2(width*0.45,-width*0.23),at]))
	var index: int = game.containers.size()
	game.add_loot(title,at+Vector2(0,23),contents)
	var outline := PackedVector2Array()
	var cropped := image.get_region(Rect2i(texture.region))
	# Trace alpha extents into a convex silhouette for subtle proximity glow.
	for y in range(0,cropped.get_height(),6):
		var first := -1
		var last := -1
		for x in cropped.get_width():
			if cropped.get_pixel(x,y).a > 0.2:
				if first < 0: first = x
				last = x
		if first >= 0:
			outline.append(at+Vector2(first-used.size.x/2.0,y-used.size.y)*factor)
			outline.append(at+Vector2(last-used.size.x/2.0,y-used.size.y)*factor)
	game.set_container_visual(index,Geometry2D.convex_hull(outline),at+Vector2(0,-used.size.y*factor),2.0)

func block(points: Array) -> void:
	obstacles.append(poly(points))

func foreground(points: Array, anchor: Vector2) -> void:
	var node := Node2D.new()
	node.position = anchor
	game.depth.add_child(node)
	var shape := Polygon2D.new()
	var vertices := poly(points)
	shape.uv = vertices
	var local := PackedVector2Array()
	for v in vertices: local.append(v - anchor)
	shape.polygon = local
	shape.texture = BACKGROUND
	node.add_child(shape)
	occluders.append({"node":node,"shape":vertices})

func point_allowed(p: Vector2) -> bool:
	if not District.BOUNDS.grow(-12).has_point(p): return false
	# Unpainted terrain and the rebuilt residential district are ordinary walkable ground.
	# The remaining baked scenes retain their old collision masks until their own rebuild.
	for zone in ["junction","store","alley"]:
		if Rect2(District.ORIGINS[zone],Vector2(1536,1024)).has_point(p):
			var inside := false
			for region in walkable:
				if Geometry2D.is_point_in_polygon(p,region):
					inside = true
					break
			if not inside: return false
	for obstacle in obstacles:
		if Geometry2D.is_point_in_polygon(p,obstacle): return false
	if yard != null and yard.blocks(p): return false
	return true

func paint_ground(points: Array) -> void:
	var shape := Polygon2D.new()
	shape.polygon = poly(points)
	shape.uv = shape.polygon
	shape.texture = BACKGROUND
	shape.z_index = -10
	game.add_child(shape)

func update_occlusion(p: Vector2) -> void:
	for piece in occluders:
		piece.node.modulate.a = 0.30 if Geometry2D.is_point_in_polygon(p+Vector2(0,-45),piece.shape) and p.y < piece.node.position.y+5 else 1.0

func build_navigation() -> void:
	game.nav = AStarGrid2D.new()
	game.nav.region = Rect2i(0,0,360,192)
	game.nav.cell_size = Vector2(16,16)
	game.nav.offset = Vector2(8,8)
	game.nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	game.nav.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	game.nav.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	game.nav.update()
	for x in 360:
		for y in 192:
			var point := Vector2(x*16+8,y*16+8)
			var allowed := point_allowed(point)
			for offset in [Vector2(-5,0),Vector2(5,0),Vector2(0,-5),Vector2(0,5)]: allowed = allowed and point_allowed(point+offset)
			game.nav.set_point_solid(Vector2i(x,y), not allowed)

func refresh_navigation(area: Rect2) -> void:
	for x in range(maxi(0,floori(area.position.x/16)),mini(360,ceili(area.end.x/16))):
		for y in range(maxi(0,floori(area.position.y/16)),mini(192,ceili(area.end.y/16))):
			var p := Vector2(x*16+8,y*16+8)
			var allowed := point_allowed(p)
			for offset in [Vector2(-5,0),Vector2(5,0),Vector2(0,-5),Vector2(0,5)]: allowed = allowed and point_allowed(p+offset)
			game.nav.set_point_solid(Vector2i(x,y),not allowed)
