extends RefCounted

var g: Node3D
var grass := Color("59634b")
var wood := Color("756655")
var wall := Color("a0957d")

func _init(game: Node3D) -> void:
	g = game

func build() -> void:
	g.box(g, Vector3(0, -0.24, 0), Vector3(48, 0.4, 42), Color("505b45"), true)
	g.box(g, Vector3(0, -0.015, 8), Vector3(48, 0.1, 7), Color("393e3d"))
	for z in [3.8, 12.2]:
		g.box(g, Vector3(0, 0.04, z), Vector3(48, 0.15, 1.4), Color("8c8a78"))
		for x in range(-23, 24):
			g.box(g, Vector3(x, 0.15, z + (-0.65 if z > 8 else 0.65)), Vector3(0.94, 0.19, 0.22), Color("a3a18c"))
	for x in range(-23, 24, 4):
		g.box(g, Vector3(x, 0.055, 8), Vector3(1.9, 0.015, 0.11), Color("a7a388"))
	for i in 100:
		var p := Vector3(g.rng.randf_range(-23, 23), 0.06, g.rng.randf_range(5, 11))
		var crack = g.box(g, p, Vector3(g.rng.randf_range(0.3, 1.5), 0.01, 0.035), Color("242e2c"))
		crack.rotation.y = g.rng.randf_range(-PI, PI)
	for i in 130:
		var p := Vector3(g.rng.randf_range(-20, 20), 0.13, g.rng.randf_range(2.5, 13))
		var litter = g.box(g, p, Vector3(0.12, 0.02, 0.18), Color("aaa491") if i % 3 else Color("605b4c"))
		litter.rotation.y = g.rng.randf() * TAU
	house()
	car(Vector3(-7, 0.15, 6.5), Color("536b67"), 0.13)
	car(Vector3(8.7, 0.15, 9.8), Color("847c63"), -0.13)
	car(Vector3(-15, 0.15, 10), Color("724e41"), 0.3)
	for x in [-12, 11, 20]:
		lamp(Vector3(x, 0, 3.6))
	for x in range(-18, 20):
		if x > -2 and x < 9: continue
		fence(Vector3(x, 0, -8.8))
	for z in range(-8, 3):
		var f := fence(Vector3(9, 0, z))
		f.rotation.y = PI / 2
	for p in [Vector3(-10, 0, -5), Vector3(-15, 0, -8), Vector3(12, 0, -6), Vector3(15, 0, 1), Vector3(-17, 0, 1), Vector3(19, 0, -9), Vector3(17, 0, 14), Vector3(-12, 0, 15)]: tree(p)
	vegetation()
	# Distant silhouettes establish the abandoned neighborhood.
	for x in [-17, -8, 4, 16]:
		g.box(g, Vector3(x, 1.6, -16), Vector3(7, 3.2, 5), Color("646b5f"), true)
		g.box(g, Vector3(x, 3.35, -16), Vector3(7.5, 0.35, 5.5), Color("394640"))
		for wx in [-2, 0, 2]:
			g.box(g, Vector3(x + wx, 1.9, -13.47), Vector3(0.85, 1.05, 0.06), Color("303e3b"))
	# Safe camp: a distinctive teal radio beacon and supply table.
	g.box(g, Vector3(-7, 0.08, 1), Vector3(3, 0.2, 2.5), Color("696a52"))
	g.box(g, Vector3(-7.5, 0.55, 0.8), Vector3(1.4, 1, 0.8), Color("505b49"), true)
	g.box(g, Vector3(-7.5, 1.12, 0.8), Vector3(0.65, 0.23, 0.4), Color("333e37"))
	g.box(g, Vector3(-7.65, 1.13, 1.015), Vector3(0.18, 0.1, 0.02), Color("9bceab"))
	g.box(g, Vector3(-7.6, 1.55, 0.8), Vector3(0.02, 0.7, 0.02), Color("b6baa2"))
	var marker = g.ring(Vector3(-6.5, 0.22, 1.7), 1.15, Color("93c9a9"))
	marker.name = "SafeCircle"
	g.label3d("安全点 / RADIO", Vector3(-7.1, 2.1, 0.8), Color("b4ddbd"), 26)
	g.add_loot("工具箱", Vector3(-11, 0.35, 3), {"parts": 1, "bandage": 1})
	g.add_loot("废车后备箱", Vector3(7, 0.5, 10), {"water": 1, "food": 1})
	# Physical world bounds.
	for x in [-23.5, 23.5]: g.invisible_wall(Vector3(x, 1, 0), Vector3(0.5, 4, 42))
	for z in [-20.5, 20.5]: g.invisible_wall(Vector3(0, 1, z), Vector3(48, 4, 0.5))

func house() -> void:
	g.box(g, Vector3(3, 0.09, -3), Vector3(8.6, 0.24, 8.5), Color("686354"))
	for x in range(16):
		for z in range(4):
			g.box(g, Vector3(-0.8 + x * 0.5, 0.22, -6.05 + z * 2), Vector3(0.48, 0.09, 1.97), Color("82735d").darkened(g.rng.randf() * 0.12))
	g.box(g, Vector3(3, 1.7, -7), Vector3(8.4, 3.2, 0.22), wall, true)
	g.box(g, Vector3(-1.1, 1.7, -3), Vector3(0.22, 3.2, 8), wall, true)
	# Front and camera-side walls lower as the survivor approaches.
	for item in [[Vector3(0.3, 1.65, 1), Vector3(2.8, 3, 0.22)], [Vector3(5.7, 1.65, 1), Vector3(2.8, 3, 0.22)], [Vector3(7.1, 1.65, -3), Vector3(0.22, 3, 8)]]:
		var mesh = g.box(g, item[0], item[1], wall)
		g.cut_walls.append(mesh)
		g.invisible_wall(item[0], item[1])
	g.box(g, Vector3(3, 2.95, 1), Vector3(2.6, 0.35, 0.26), wood)
	for x in [1.65, 4.35]: g.box(g, Vector3(x, 1.55, 1.02), Vector3(0.12, 2.9, 0.32), wood)
	g.box(g, Vector3(3, 0.12, 1.6), Vector3(2.7, 0.23, 1.2), Color("9c927c"))
	# Board siding on visible back walls.
	for y in range(1, 12):
		g.box(g, Vector3(3, y * 0.26, -6.87), Vector3(8, 0.025, 0.015), Color("827c69"))
	for x in [0.1, 5.5]:
		g.box(g, Vector3(x, 1.85, -6.82), Vector3(1.55, 1.45, 0.13), Color("5a5144"))
		g.box(g, Vector3(x, 1.85, -6.72), Vector3(1.3, 1.2, 0.06), Color("52655f"))
		g.box(g, Vector3(x, 1.85, -6.67), Vector3(0.07, 1.2, 0.04), Color("b6ad95"))
		g.box(g, Vector3(x, 1.85, -6.67), Vector3(1.3, 0.07, 0.04), Color("b6ad95"))
	g.roof = g.box(g, Vector3(3, 3.42, -3), Vector3(8.7, 0.25, 8.7), Color("3e4a43"))
	for x in range(9):
		g.box(g.roof, Vector3(x - 4, 0.16, 0), Vector3(0.055, 0.08, 8.6), Color("657065"))
	# Kitchen along the rear wall.
	g.box(g, Vector3(1.5, 0.76, -5.9), Vector3(2.8, 1, 1.05), Color("5b5c48"), true)
	g.box(g, Vector3(1.5, 1.32, -5.9), Vector3(3, 0.12, 1.16), Color("b0aa91"))
	g.box(g, Vector3(1.1, 1.39, -5.9), Vector3(0.75, 0.025, 0.63), Color("555f5b"))
	g.box(g, Vector3(1.1, 1.4, -5.9), Vector3(0.55, 0.025, 0.43), Color("354442"))
	g.box(g, Vector3(1.1, 1.56, -6.2), Vector3(0.045, 0.35, 0.05), Color("b6bdb1"))
	g.box(g, Vector3(-0.1, 1.28, -5.7), Vector3(0.8, 2.05, 1.05), Color("c0baa1"), true)
	g.box(g, Vector3(-0.1, 1.7, -5.155), Vector3(0.72, 0.04, 0.02), Color("6c756a"))
	g.box(g, Vector3(0.19, 1.35, -5.12), Vector3(0.055, 0.4, 0.06), Color("57665b"))
	# Bed and linen, bedside lamp, divider and rug.
	g.box(g, Vector3(5.6, 0.54, -5.25), Vector3(1.8, 0.55, 2.7), wood, true)
	g.box(g, Vector3(5.6, 0.87, -5.25), Vector3(1.75, 0.26, 2.62), Color("b5b3a0"))
	g.box(g, Vector3(5.6, 1.02, -4.8), Vector3(1.79, 0.14, 1.75), Color("617976"))
	g.box(g, Vector3(5.6, 1.06, -6.03), Vector3(1.1, 0.2, 0.53), Color("d0cbb2"))
	g.box(g, Vector3(5.6, 1.05, -6.65), Vector3(1.95, 1.4, 0.16), wood)
	g.box(g, Vector3(4.2, 0.6, -6), Vector3(0.7, 0.7, 0.7), wood, true)
	g.cylinder(g, Vector3(4.2, 1.08, -6), 0.045, 0.32, Color("494a38"))
	g.cylinder(g, Vector3(4.2, 1.35, -6), 0.23, 0.26, Color("e4c58b"))
	var light := OmniLight3D.new()
	light.position = Vector3(4.2, 1.7, -5.9)
	light.light_color = Color("ffd699")
	light.light_energy = 1.2
	light.omni_range = 4
	g.add_child(light)
	g.box(g, Vector3(4, 0.28, -1.9), Vector3(3.2, 0.025, 2.4), Color("725b48"))
	for z in [-2.95, -0.85]: g.box(g, Vector3(4, 0.3, z), Vector3(3, 0.025, 0.07), Color("b09a70"))
	g.box(g, Vector3(3.4, 1, -2.5), Vector3(1.7, 0.14, 1.1), wood, true)
	for x in [2.8, 4]:
		for z in [-2.85, -2.15]: g.box(g, Vector3(x, 0.62, z), Vector3(0.09, 0.7, 0.09), Color("4c493c"))
	g.cylinder(g, Vector3(3.3, 1.16, -2.4), 0.1, 0.19, Color("c6bea4"))
	g.box(g, Vector3(2.9, 1.09, -2.65), Vector3(0.35, 0.035, 0.25), Color("aaab8b"))
	g.box(g, Vector3(0, 0.65, -2.1), Vector3(1, 0.8, 2), Color("657065"), true)
	g.box(g, Vector3(-0.45, 1.05, -2.1), Vector3(0.2, 1.3, 2), Color("4a584d"))
	g.add_loot("厨房冰箱", Vector3(0, 0.35, -4.35), {"food": 2, "water": 1})
	g.add_loot("床边药箱", Vector3(6.25, 0.4, -3.1), {"bandage": 2, "water": 1})
	g.add_loot("储物木箱", Vector3(5.8, 0.45, -0.15), {"parts": 2, "food": 1})
	g.label3d("07  /  柳杉路", Vector3(0.4, 2.7, 1.2), Color("e1d4b0"), 24)

func fence(p: Vector3) -> Node3D:
	var n := Node3D.new()
	g.add_child(n)
	n.position = p
	for x in [-0.36, -0.12, 0.12, 0.36]:
		g.box(n, Vector3(x, 0.8, 0), Vector3(0.19, 1.6 + g.rng.randf() * 0.16, 0.09), wood.darkened(g.rng.randf() * 0.2))
	for y in [0.4, 1.15]: g.box(n, Vector3(0, y, -0.06), Vector3(1, 0.1, 0.1), Color("555344"))
	g.invisible_wall(p + Vector3(0, 0.8, 0), Vector3(1, 1.7, 0.15))
	return n

func car(p: Vector3, color: Color, angle: float) -> void:
	var n := Node3D.new()
	g.add_child(n)
	n.position = p
	n.rotation.y = angle
	g.box(n, Vector3(0, 0.55, 0), Vector3(3.9, 0.65, 1.7), color, true)
	g.box(n, Vector3(0.1, 1.02, 0), Vector3(2.05, 0.68, 1.53), Color("303f3e"))
	g.box(n, Vector3(0.1, 1.39, 0), Vector3(2.12, 0.12, 1.62), color)
	for x in [-0.85, 0.25, 1.05]: g.box(n, Vector3(x, 1.02, 0), Vector3(0.095, 0.7, 1.59), color)
	for x in [-1.25, 1.25]:
		for z in [-0.85, 0.85]:
			var tire = g.cylinder(n, Vector3(x, 0.4, z), 0.38, 0.18, Color("232927"))
			tire.rotation.x = PI / 2
			var hub = g.cylinder(n, Vector3(x, 0.4, z * 1.11), 0.18, 0.025, Color("72796e"))
			hub.rotation.x = PI / 2
	for z in [-0.56, 0.56]: g.box(n, Vector3(-1.97, 0.69, z), Vector3(0.035, 0.18, 0.34), Color("bbb88c"))
	for i in 12:
		g.box(n, Vector3(g.rng.randf_range(-1.8, 1.8), 0.89, g.rng.randf_range(-0.75, 0.75)), Vector3(0.2, 0.018, 0.15), Color("795744"))

func lamp(p: Vector3) -> void:
	g.cylinder(g, p + Vector3(0, 2, 0), 0.07, 4, Color("394a42"))
	g.box(g, p + Vector3(0.35, 4, 0), Vector3(0.8, 0.08, 0.1), Color("394a42"))
	g.box(g, p + Vector3(0.7, 3.95, 0), Vector3(0.45, 0.12, 0.24), Color("cabf91"))
	g.box(g, p + Vector3(0.8, 0.5, -0.6), Vector3(0.6, 1, 0.6), Color("3c5445"), true)
	g.box(g, p + Vector3(0.8, 1.05, -0.6), Vector3(0.67, 0.12, 0.67), Color("516b50"))

func tree(p: Vector3) -> void:
	g.cylinder(g, p + Vector3(0, 1.5, 0), 0.17, 3, Color("565044"))
	for i in 5:
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = g.rng.randf_range(1.1, 1.6)
		sphere.height = sphere.radius * 1.9
		sphere.radial_segments = 7
		sphere.rings = 4
		mesh.mesh = sphere
		mesh.material_override = g.material(Color("4c6549").darkened(g.rng.randf() * 0.25))
		g.add_child(mesh)
		mesh.position = p + Vector3(g.rng.randf_range(-0.9, 0.9), 3 + g.rng.randf(), g.rng.randf_range(-0.9, 0.9))

func vegetation() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var blade := PrismMesh.new()
	blade.size = Vector3(0.14, 0.44, 0.08)
	var grass_material := StandardMaterial3D.new()
	grass_material.vertex_color_use_as_albedo = true
	grass_material.roughness = 1.0
	blade.material = grass_material
	mm.mesh = blade
	mm.instance_count = 6500
	for i in 6500:
		var x: float = g.rng.randf_range(-22, 22)
		var z: float = g.rng.randf_range(-18, 18)
		if (x > -1.5 and x < 7.5 and z > -7.5 and z < 2) or (z > 3 and z < 12.8):
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -3, 0)))
			continue
		var basis := Basis(Vector3.UP, g.rng.randf() * TAU).scaled(Vector3(1, g.rng.randf_range(0.5, 1.8), 1))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, 0.22, z)))
		mm.set_instance_color(i, Color("6b7650").darkened(g.rng.randf() * 0.4))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	g.add_child(node)

