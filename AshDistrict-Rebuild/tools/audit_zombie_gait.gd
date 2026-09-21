extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var actor: Node3D=load("res://art/characters/human_base/infected.scn").instantiate()
	root.add_child(actor)
	var rig: Skeleton3D=actor.find_child("Skeleton3D",true,false)
	var player: AnimationPlayer=actor.find_child("AnimationPlayer",true,false)
	for clip in ["Walk","ZombieShuffle"]:
		player.play(clip)
		var length: float=player.get_animation(clip).length
		for side in ["l","r"]:
			var bone := rig.find_bone("foot_"+side)
			var samples := []
			var low := Vector3(INF,INF,INF)
			var high := Vector3(-INF,-INF,-INF)
			for i in 49:
				player.seek(length*float(i)/48.0,true)
				rig.force_update_all_bone_transforms()
				var p := rig.get_bone_global_pose(bone).origin
				if clip=="ZombieShuffle":
					var phase := fposmod(float(i)/48.0+(0.5 if side=="r" else 0.0),1.0)
					var rest := rig.get_bone_global_rest(bone).origin
					if phase<0.6:
						assert(absf(p.y-rest.y)<0.002,"Support ankle must stay on ground plane")
						assert(absf(p.z-(rest.z+0.85/0.95*(0.3-phase)))<0.002,"Support foot must counter world travel")
					assert(p.y-rest.y<0.045,"Swing foot must stay low")
				low=low.min(p)
				high=high.max(p)
				if i%8==0: samples.append(p)
			print(clip," foot_",side," min=",low," max=",high," samples=",samples)
	actor.free()
	quit()
