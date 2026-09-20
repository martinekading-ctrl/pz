extends SceneTree

func _initialize() -> void:
	for path: String in [
		"res://art/characters/quaternius_zombie_apocalypse/Characters_Matt.gltf",
		"res://art/characters/quaternius_zombie_apocalypse/Zombie_Basic.gltf",
	]:
		var packed := load(path) as PackedScene
		assert(packed != null, "Could not load " + path)
		var root := packed.instantiate()
		print("SCENE ", path)
		print_tree(root, "")
		root.free()
	quit()

func print_tree(node: Node, indent: String) -> void:
	var detail := ""
	if node is AnimationPlayer:
		detail = " animations=" + str((node as AnimationPlayer).get_animation_list())
	elif node is Skeleton3D:
		detail = " bones=" + str((node as Skeleton3D).get_bone_count())
	elif node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		detail = " aabb=" + str(mesh.get_aabb() if mesh != null else AABB())
	print(indent, node.name, " [", node.get_class(), "]", detail)
	for child: Node in node.get_children():
		print_tree(child, indent + "  ")
