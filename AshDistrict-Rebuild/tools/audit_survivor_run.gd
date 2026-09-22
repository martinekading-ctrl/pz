extends SceneTree

func _initialize() -> void:
	call_deferred("audit")

func audit() -> void:
	var actor: Node3D=load("res://art/characters/human_base/survivor.scn").instantiate()
	root.add_child(actor)
	var rig: Skeleton3D=actor.find_child("Skeleton3D",true,false)
	var player: AnimationPlayer=actor.find_child("AnimationPlayer",true,false)
	for clip in ["Run","Run_Gun"]:
		player.play(clip)
		var length: float=player.get_animation(clip).length
		for side in ["l","r"]:
			var bone := rig.find_bone("foot_"+side)
			var rest := rig.get_bone_global_rest(bone).origin
			var lowest := INF
			var highest := -INF
			for i in 49:
				var phase := float(i)/48.0
				player.seek(length*phase,true)
				rig.force_update_all_bone_transforms()
				var ankle := rig.get_bone_global_pose(bone).origin
				var p := fposmod(phase+(0.5 if side=="r" else 0.0),1.0)
				if p<0.38:
					assert(absf(ankle.y-rest.y)<0.02,"Support foot drift should stay below two centimeters")
				lowest=minf(lowest,ankle.y-rest.y)
				highest=maxf(highest,ankle.y-rest.y)
				assert(ankle.y-rest.y<0.105,"Jog should not have high knee lift")
			assert(lowest>-0.004 and highest>0.07,"Run needs contact and a modest swing")
			print(clip," ",side," clearance ",lowest,"..",highest)
	actor.free()
	quit()
