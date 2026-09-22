extends SceneTree
func _initialize() -> void:
	var actor: Node3D=load("res://art/characters/quaternius_zombie_apocalypse/Characters_Matt.gltf").instantiate()
	root.add_child(actor)
	for node in actor.find_children("*Pistol*","",true,false):
		print(node.get_path()," ",node.transform)
		if node is MeshInstance3D: print("MESH ",node.mesh.get_aabb()," surfaces ",node.mesh.get_surface_count()," skin ",node.skin)
	actor.free()
	quit()
