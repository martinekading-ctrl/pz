extends SceneTree

func _initialize() -> void:
	for path: String in [
		"res://art/characters/human_base/Superhero_Male_FullBody.gltf",
		"res://art/characters/human_base/UAL1_Standard.glb",
		"res://art/characters/human_base/Hair_SimpleParted.gltf",
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
		for bone_name in ["root", "pelvis", "spine_01", "Head", "upperarm_l", "hand_l"]:
			var index: int = node.find_bone(bone_name)
			if index >= 0: print(bone_name, " rest=", node.get_bone_rest(index), " global=", node.get_bone_global_rest(index))
	elif node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		detail = " aabb=" + str(mesh.get_aabb() if mesh != null else AABB())
	print(indent, node.name, " [", node.get_class(), "]", detail)
	for child: Node in node.get_children():
		print_tree(child, indent + "  ")
