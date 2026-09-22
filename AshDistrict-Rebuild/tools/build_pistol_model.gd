extends SceneTree

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var source: Node3D=load("res://art/characters/quaternius_zombie_apocalypse/Characters_Matt.gltf").instantiate()
	var original: MeshInstance3D=source.find_child("Pistol",true,false)
	var mesh := ArrayMesh.new()
	var bounds := original.mesh.get_aabb()
	for surface in original.mesh.get_surface_count():
		var arrays := original.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		# Source axes: barrel X, thickness Y, grip height Z. Convert to +Z barrel.
		var conversion := Basis(Vector3(0,0,0.25/bounds.size.x),Vector3(0.038/bounds.size.y,0,0),Vector3(0,0.15/bounds.size.z,0))
		for i in vertices.size():
			vertices[i]=conversion*(vertices[i]-bounds.position)-Vector3(0.019,0.075,0.05)
			if i<normals.size(): normals[i]=(conversion.inverse().transposed()*normals[i]).normalized()
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_TANGENT]=null
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(surface,original.mesh.surface_get_material(surface))
	var pistol := Node3D.new()
	pistol.name="ServicePistol"
	var body := MeshInstance3D.new()
	body.name="PistolMesh"
	body.mesh=mesh
	pistol.add_child(body)
	body.owner=pistol
	var muzzle := Marker3D.new()
	muzzle.name="Muzzle"
	muzzle.position=Vector3(0,0.047,0.20)
	pistol.add_child(muzzle)
	muzzle.owner=pistol
	var packed := PackedScene.new()
	assert(packed.pack(pistol)==OK)
	DirAccess.make_dir_recursive_absolute("res://art/weapons")
	assert(ResourceSaver.save(packed,"res://art/weapons/service_pistol.scn")==OK)
	print("PISTOL BUILT: ",mesh.get_aabb())
	pistol.free()
	source.free()
	quit()
