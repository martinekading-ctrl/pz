extends SceneTree
## Reproducible adaptation of CC0 human base, clothes and retargeted animation.
const BASE = preload("res://art/characters/human_base/Superhero_Male_FullBody.gltf")
const MOTION = preload("res://art/characters/human_base/UAL1_Standard.glb")
const HAIR = preload("res://art/characters/human_base/Hair_SimpleParted.gltf")
const CLIPS = {"Idle":"Idle", "Idle_Gun":"Pistol_Idle", "Idle_Attack":"Idle", "Walk":"Walk", "Walk_Gun":"Walk", "Run":"Jog_Fwd", "Run_Gun":"Jog_Fwd", "Slash":"Sword_Attack", "Punch":"Punch_Cross", "HitReact":"Hit_Chest", "Jump":"Jump", "Death":"Death01", "Crouch_Walk":"Crouch_Fwd", "Crouch_Idle":"Crouch_Idle", "Shoot":"Pistol_Shoot"}

func _initialize() -> void:
	call_deferred("build_all")

func build_grab(skeleton: Skeleton3D) -> Animation:
	# Authored open-handed reach, forward head contact, then slow recovery.
	# Global arm directions avoid dependence on the imported bone roll axes.
	var clip := Animation.new()
	clip.length=1.3
	var times := [0.0,0.24,0.50,0.62,0.78,1.05,1.3]
	var reaches := [0.0,0.30,1.0,1.0,0.86,0.35,0.0]
	var leans := [0.10,0.13,0.23,0.34,0.30,0.17,0.10]
	var tracks := []
	for bone in skeleton.get_bone_count():
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track,NodePath("Armature/Skeleton3D:"+skeleton.get_bone_name(bone)))
		tracks.append(track)
	for key in times.size():
		var globals := []
		for bone in skeleton.get_bone_count():
			var parent := skeleton.get_bone_parent(bone)
			var parent_basis: Basis=globals[parent] if parent>=0 else Basis.IDENTITY
			var local := skeleton.get_bone_rest(bone).basis
			var name := skeleton.get_bone_name(bone)
			if name=="spine_02": local=local*Basis(Vector3.RIGHT,leans[key])
			if name=="Head": local=local*Basis(Vector3.RIGHT,0.18 if key in [3,4] else -0.06)
			if name.begins_with("upperarm_") or name.begins_with("lowerarm_"):
				var side := 1.0 if name.ends_with("_l") else -1.0
				var upper := name.begins_with("upperarm_")
				var target := Vector3(side*0.22,-0.94,0.25).lerp(Vector3(side*0.18,-0.15,1.0) if upper else Vector3(-side*0.10,0.18,1.0),reaches[key]).normalized()
				var child := skeleton.find_bone(("lowerarm_" if upper else "hand_")+("l" if side>0 else "r"))
				var rest_global := skeleton.get_bone_global_rest(bone).basis
				var rest_dir := (rest_global*skeleton.get_bone_rest(child).origin).normalized()
				local=parent_basis.inverse()*Basis(Quaternion(rest_dir,target))*rest_global
			globals.append(parent_basis*local)
			clip.rotation_track_insert_key(tracks[bone],times[key],local.get_rotation_quaternion().normalized())
	return clip

func own_children(node: Node, scene: Node) -> void:
	for child in node.get_children():
		child.owner = scene
		own_children(child, scene)

func build_shuffle(source: Animation, skeleton: Skeleton3D, grab: Animation) -> Animation:
	var clip := Animation.new()
	clip.length=1.5
	clip.loop_mode=Animation.LOOP_LINEAR
	for track in source.get_track_count():
		var type := source.track_get_type(track)
		if type not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]: continue
		var path := source.track_get_path(track)
		var name := str(path.get_subname(0))
		var bone := skeleton.find_bone(name)
		var rest := skeleton.get_bone_rest(bone)
		var output := clip.add_track(type)
		clip.track_set_path(output,path)
		for key in 49:
			var phase := float(key)/48.0
			# Unequal stance times: one foot drags longer; endpoints still match.
			var warped := phase
			var time := warped*source.length
			if type==Animation.TYPE_POSITION_3D:
				var value := source.position_track_interpolate(track,time)
				var adjusted := rest.origin+(value-rest.origin)*0.3
				if name=="pelvis": adjusted+=skeleton.get_bone_global_rest(skeleton.get_bone_parent(bone)).basis.inverse()*Vector3(0,-0.065,0)
				clip.position_track_insert_key(output,phase*clip.length,adjusted)
			else:
				var value := source.rotation_track_interpolate(track,time)
				var neutral := rest.basis.get_rotation_quaternion()
				if name.begins_with("thigh_"): value=neutral.slerp(value,0.62 if name.ends_with("l") else 0.48)
				elif name.begins_with("calf_"): value=neutral.slerp(value,0.48 if name.ends_with("l") else 0.32)
				elif name.begins_with("foot_") or name.begins_with("ball_"): value=neutral.slerp(value,0.45)
				elif name.contains("arm_") or name.begins_with("hand_"):
					var pose_track := grab.find_track(path,Animation.TYPE_ROTATION_3D)
					value=grab.rotation_track_interpolate(pose_track,0.15)
					value=value*Quaternion(Vector3.RIGHT,sin(phase*TAU)*0.02)
				elif name=="spine_02": value=neutral*Quaternion(Vector3.RIGHT,0.22)
				elif name=="Head": value=neutral*Quaternion(Vector3.RIGHT,-0.08)
				clip.rotation_track_insert_key(output,phase*clip.length,value.normalized())
	ground_shuffle(clip,skeleton)
	return clip

func build_pursuit(source: Animation, skeleton: Skeleton3D, grab: Animation) -> Animation:
	# Separate full-body pursuit clip: regular footfalls and alert upper body.
	# Never derive it from the limp/shuffle track set.
	var clip: Animation=source.duplicate(true)
	for track in clip.get_track_count():
		var name := str(clip.track_get_path(track).get_subname(0))
		var bone := skeleton.find_bone(name)
		var rest := skeleton.get_bone_rest(bone)
		for key in clip.track_get_key_count(track):
			var time := clip.track_get_key_time(track,key)
			var phase := time/clip.length*TAU
			if clip.track_get_type(track)==Animation.TYPE_POSITION_3D:
				var value: Vector3=clip.track_get_key_value(track,key)
				value=rest.origin+(value-rest.origin)*0.22
				if name=="pelvis": value+=skeleton.get_bone_global_rest(skeleton.get_bone_parent(bone)).basis.inverse()*Vector3(0,-0.085,0)
				clip.track_set_key_value(track,key,value)
			elif clip.track_get_type(track)==Animation.TYPE_ROTATION_3D:
				var value: Quaternion=clip.track_get_key_value(track,key)
				if name.contains("arm_") or name.begins_with("hand_"):
					var ready := grab.find_track(clip.track_get_path(track),Animation.TYPE_ROTATION_3D)
					value=grab.rotation_track_interpolate(ready,0.32)
					var side := 1.0 if name.ends_with("l") else -1.0
					value=value*Quaternion(Vector3.RIGHT,sin(phase)*0.055*side)
				elif name=="spine_02": value=rest.basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,0.16)
				elif name=="Head": value=rest.basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,-0.12)
				elif name=="pelvis": value=rest.basis.get_rotation_quaternion()
				clip.track_set_key_value(track,key,value.normalized())
	ground_shuffle(clip,skeleton,1.05,0.075)
	return clip

func ground_shuffle(clip: Animation, skeleton: Skeleton3D, cycle_meters: float=0.85, lift: float=0.04) -> void:
	# Bake a two-bone leg solve. Support feet travel backwards at world speed;
	# swing feet clear the ground by 4cm. No runtime IK cost on mobile.
	var corrected := {}
	for side in ["l","r"]:
		for part in ["thigh_","calf_","foot_"]: corrected[part+side]=[]
	for frame in 49:
		var phase := float(frame)/48.0
		var poses := []
		for bone in skeleton.get_bone_count():
			var local := skeleton.get_bone_rest(bone)
			var path := NodePath("Armature/Skeleton3D:"+skeleton.get_bone_name(bone))
			var rotation := clip.find_track(path,Animation.TYPE_ROTATION_3D)
			var position := clip.find_track(path,Animation.TYPE_POSITION_3D)
			if rotation>=0: local.basis=Basis(clip.rotation_track_interpolate(rotation,phase*clip.length))
			if position>=0: local.origin=clip.position_track_interpolate(position,phase*clip.length)
			var parent := skeleton.get_bone_parent(bone)
			poses.append(poses[parent]*local if parent>=0 else local)
		for side in ["l","r"]:
			var thigh := skeleton.find_bone("thigh_"+side)
			var calf := skeleton.find_bone("calf_"+side)
			var foot := skeleton.find_bone("foot_"+side)
			var p := fposmod(phase+(0.5 if side=="r" else 0.0),1.0)
			var ankle := skeleton.get_bone_global_rest(foot).origin
			var stride := cycle_meters/0.95
			if p<0.60:
				ankle.z+=stride*(0.30-p)
			else:
				var swing := (p-0.60)/0.40
				ankle.z+=lerpf(-stride*0.30,stride*0.30,smoothstep(0.0,1.0,swing))
				ankle.y+=sin(swing*PI)*lift
			var hip: Vector3=poses[thigh].origin
			var upper := skeleton.get_bone_rest(calf).origin.length()
			var lower := skeleton.get_bone_rest(foot).origin.length()
			var distance := hip.distance_to(ankle)
			var axis := (ankle-hip).normalized()
			var reach := minf(distance,upper+lower-0.001)
			var along := (upper*upper-lower*lower+reach*reach)/(2.0*reach)
			var bend := (Vector3.BACK-axis*axis.dot(Vector3.BACK)).normalized()
			var knee := hip+axis*along+bend*sqrt(maxf(0.0,upper*upper-along*along))
			for pair in [[thigh,calf,knee-hip],[calf,foot,ankle-knee]]:
				var bone: int=pair[0]
				var child: int=pair[1]
				var rest_basis := skeleton.get_bone_global_rest(bone).basis
				var direction := (rest_basis*skeleton.get_bone_rest(child).origin).normalized()
				var basis := Basis(Quaternion(direction,Vector3(pair[2]).normalized()))*rest_basis
				var parent := skeleton.get_bone_parent(bone)
				var local: Basis=poses[parent].basis.inverse()*basis
				corrected[skeleton.get_bone_name(bone)].append(local.get_rotation_quaternion())
				poses[bone].basis=basis
			var foot_local: Basis=poses[calf].basis.inverse()*skeleton.get_bone_global_rest(foot).basis
			corrected["foot_"+side].append(foot_local.get_rotation_quaternion())
	for name in corrected:
		var path := NodePath("Armature/Skeleton3D:"+name)
		var track := clip.find_track(path,Animation.TYPE_ROTATION_3D)
		if track>=0: clip.remove_track(track)
		track=clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track,path)
		for frame in 49: clip.rotation_track_insert_key(track,float(frame)/48.0*clip.length,corrected[name][frame])

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.95
	return result

func attach(skeleton: Skeleton3D, bone: String, label: String) -> Node3D:
	var node := BoneAttachment3D.new()
	node.name = label
	node.bone_name = bone
	skeleton.add_child(node)
	# Author accessories in the same rest coordinate system as the body.
	var rest_space := Node3D.new()
	node.add_child(rest_space)
	rest_space.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse()
	return rest_space

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, label: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = at
	return node

func clothing_shader(infected: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 jacket : source_color;
uniform vec4 trousers : source_color;
uniform bool infected = false;
varying vec3 rest;
void vertex(){rest=VERTEX;}
void fragment(){
 float x=abs(rest.x); float y=rest.y; float z=rest.z;
 float weave=sin(rest.x*570.0)*sin(rest.y*570.0)*0.018;
 float wear=sin(rest.x*41.0+rest.y*28.0)*sin(rest.z*63.0+rest.y*17.0)*0.045;
 vec3 c=jacket.rgb;
 if(y<1.03){c=trousers.rgb;}
 if(y<0.17){c=vec3(0.16,0.125,0.09);}
 if(y>0.99 && y<1.025){c=vec3(0.14,0.11,0.08);}
 if(y>1.025 && y<1.51 && x<0.044 && z>0.035){c=vec3(0.28,0.29,0.27);}
 // Front placket, paired chest pockets and cuffs remain legible at game scale.
 if(y>1.08 && y<1.49 && abs(x-0.048)<0.007 && z>0.07){c*=0.64;}
 if(y>1.28 && y<1.36 && x>0.073 && x<0.155 && z>0.085){c*=0.79;}
 if(x>0.635 && x<0.66 && y>1.1){c*=0.64;}
 if(infected && x>0.46 && y>1.3 && sin(rest.x*27.0+rest.y*13.0+z*21.0)>0.65){c=mix(c,vec3(0.19,0.09,0.065),0.58);}
 ALBEDO=clamp(c+vec3(weave+wear),vec3(0.02),vec3(1.0));ROUGHNESS=0.97;
}
"""
	var result := ShaderMaterial.new()
	result.shader = shader
	result.set_shader_parameter("jacket", Color("697375") if infected else Color("535b40"))
	result.set_shader_parameter("trousers", Color("514939") if infected else Color("35414b"))
	result.set_shader_parameter("infected", infected)
	return result

func dress(body: MeshInstance3D, infected: bool) -> void:
	var source := body.mesh
	var garment := MeshInstance3D.new()
	garment.name = "Clothes"
	garment.skeleton = body.skeleton
	garment.skin = body.skin
	var mesh := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var chosen := PackedInt32Array()
		for offset in range(0, indices.size(), 3):
			var center := (vertices[indices[offset]]+vertices[indices[offset+1]]+vertices[indices[offset+2]])/3.0
			if center.y < 1.54 and absf(center.x) < 0.665:
				for i in 3: chosen.append(indices[offset+i])
		for i in vertices.size():
			# Give cloth an actual shell and looser silhouette instead of painting skin.
			var p := vertices[i]
			var thickness := 0.022 if p.y>1.03 else 0.018
			if p.y<0.14: thickness=0.014
			vertices[i] += normals[i]*thickness
			if p.y>1.05 and p.y<1.44 and absf(p.x)<0.23:
				# A loose jacket hangs off the rib cage, covering abdominal definition.
				var outline := 0.13*sqrt(maxf(0.0,1.0-pow(p.x/0.235,2.0)))
				vertices[i].z=lerpf(vertices[i].z,signf(p.z+0.012)*maxf(absf(vertices[i].z),outline),0.85)
			if p.y<0.04: vertices[i].y=maxf(0.006,vertices[i].y)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = chosen
		if not chosen.is_empty(): mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	garment.mesh = mesh
	garment.material_override = clothing_shader(infected)
	body.get_parent().add_child(garment)
	# Preserve facial UV detail while bringing skin into a restrained palette.
	var skin_shader := Shader.new()
	skin_shader.code = """
shader_type spatial;
uniform sampler2D skin_map : source_color;
uniform vec4 skin_color : source_color;
void fragment(){vec3 t=texture(skin_map,UV).rgb; float d=dot(t,vec3(0.3,0.59,0.11)); ALBEDO=skin_color.rgb*clamp(d*2.8,0.48,1.22); ROUGHNESS=0.9;}
"""
	var skin_mat := ShaderMaterial.new()
	skin_mat.shader=skin_shader
	var original := source.surface_get_material(0) as StandardMaterial3D
	skin_mat.set_shader_parameter("skin_map", original.albedo_texture)
	skin_mat.set_shader_parameter("skin_color",Color("999388") if infected else Color("b28e73"))
	body.material_override=skin_mat

func build_all() -> void:
	var motion: Node3D=MOTION.instantiate()
	root.add_child(motion)
	var source_skeleton := motion.find_child("Skeleton3D",true,false) as Skeleton3D
	var source_player := motion.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for infected in [false,true]:
		var character: Node3D=BASE.instantiate()
		character.name="Infected" if infected else "Survivor"
		root.add_child(character)
		var skeleton := character.find_child("Skeleton3D",true,false) as Skeleton3D
		var body := character.find_child("SuperHero_Male",true,false) as MeshInstance3D
		dress(body,infected)
		var hair_root := attach(skeleton,"Head","HairAttachment")
		var hair_source: Node3D=HAIR.instantiate()
		for node in hair_source.find_children("*","MeshInstance3D",true,false):
			var hair := MeshInstance3D.new()
			hair.name="Hair"
			hair.mesh=node.mesh
			hair.transform=node.transform
			hair.material_override=material(Color("353029"))
			hair_root.add_child(hair)
		hair_source.free()
		if not infected:
			var pack_root := attach(skeleton,"spine_03","BackpackAttachment")
			box(pack_root,Vector3(0,1.32,-0.18),Vector3(0.27,0.34,0.15),Color("615b40"),"CanvasBackpack")
			box(pack_root,Vector3(0,1.26,-0.265),Vector3(0.2,0.15,0.04),Color("4b4835"),"PackPocket")
		var player := AnimationPlayer.new()
		player.name="AnimationPlayer"
		character.add_child(player)
		var library := AnimationLibrary.new()
		for alias in CLIPS:
			var animation: Animation=source_player.get_animation(CLIPS[alias]).duplicate(true)
			for track in range(animation.get_track_count()-1,-1,-1):
				var path := animation.track_get_path(track)
				if path.get_subname_count()==0:
					animation.remove_track(track)
					continue
				var bone := str(path.get_subname(0))
				var src_index := source_skeleton.find_bone(bone)
				var dst_index := skeleton.find_bone(bone)
				if src_index<0 or dst_index<0:
					animation.remove_track(track)
					continue
				animation.track_set_path(track,NodePath("Armature/Skeleton3D:"+bone))
				var src_rest := source_skeleton.get_bone_rest(src_index)
				var dst_rest := skeleton.get_bone_rest(dst_index)
				for key in animation.track_get_key_count(track):
					if animation.track_get_type(track)==Animation.TYPE_POSITION_3D:
						var p: Vector3=animation.track_get_key_value(track,key)
						animation.track_set_key_value(track,key,dst_rest.origin+(p-src_rest.origin))
					elif animation.track_get_type(track)==Animation.TYPE_ROTATION_3D:
						var q: Quaternion=animation.track_get_key_value(track,key)
						if alias in ["Walk_Gun","Run_Gun"] and (bone.contains("arm_") or bone.contains("hand_") or bone.begins_with("clavicle") or bone.begins_with("index_") or bone.begins_with("middle_") or bone.begins_with("ring_") or bone.begins_with("pinky_") or bone.begins_with("thumb_")):
							var aim := source_player.get_animation("Pistol_Idle")
							var aim_track := aim.find_track(path,Animation.TYPE_ROTATION_3D)
							if aim_track>=0: q=aim.rotation_track_interpolate(aim_track,0.2)
						q=dst_rest.basis.get_rotation_quaternion()*src_rest.basis.get_rotation_quaternion().inverse()*q
						if infected and alias not in ["Death","Jump"] and bone=="spine_02": q=q*Quaternion(Vector3.RIGHT,0.18)
						animation.track_set_key_value(track,key,q.normalized())
			animation.loop_mode=Animation.LOOP_LINEAR if alias in ["Idle","Idle_Gun","Idle_Attack","Walk","Walk_Gun","Run","Run_Gun","Crouch_Walk","Crouch_Idle"] else Animation.LOOP_NONE
			library.add_animation(alias,animation)
		if infected:
			library.remove_animation("Punch")
			library.add_animation("GrabBite",build_grab(skeleton))
			library.add_animation("ZombieShuffle",build_shuffle(library.get_animation("Walk"),skeleton,library.get_animation("GrabBite")))
			library.add_animation("ZombiePursuit",build_pursuit(library.get_animation("Walk"),skeleton,library.get_animation("GrabBite")))
		player.add_animation_library("",library)
		# 1.75m adult, a narrower ordinary build; all equipment scales with the rig.
		character.scale=Vector3(0.88,0.965,0.95)
		character.rotation.y=PI
		own_children(character,character)
		var packed := PackedScene.new()
		assert(packed.pack(character)==OK)
		var path := "res://art/characters/human_base/"+("infected" if infected else "survivor")+".scn"
		assert(ResourceSaver.save(packed,path)==OK)
		print("BUILT ",path," bones=",skeleton.get_bone_count())
		character.free()
	motion.free()
	quit()
