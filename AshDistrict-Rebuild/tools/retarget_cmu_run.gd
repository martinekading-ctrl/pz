extends RefCounted
## Retarget one complete, steady human jog cycle onto the existing survivor rig.
## The source FBX starts with a bind pose and carries world translation; neither
## belongs inside the looping in-place character clip.

const SOURCE := preload("res://art/characters/motion_sources/CMU_02_03.fbx")
const START := 41.0 / 120.0
const END := 131.0 / 120.0
const FPS := 120.0
const PELVIS_DROP := 0.05
const PAIRS := {
	"pelvis": "hip", "spine_01": "abdomen", "spine_02": "chest",
	"clavicle_l": "lCollar", "upperarm_l": "lShldr", "lowerarm_l": "lForeArm", "hand_l": "lHand",
	"clavicle_r": "rCollar", "upperarm_r": "rShldr", "lowerarm_r": "rForeArm", "hand_r": "rHand",
	"thigh_l": "lThigh", "calf_l": "lShin", "foot_l": "lFoot",
	"thigh_r": "rThigh", "calf_r": "rShin", "foot_r": "rFoot"
}

func build(target_rig: Skeleton3D) -> Animation:
	var source := SOURCE.instantiate()
	target_rig.get_tree().root.add_child(source)
	var source_rig := source.find_child("Skeleton3D", true, false) as Skeleton3D
	var source_player := source.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(source_rig != null and source_player != null)
	source_player.play(source_player.get_animation_list()[0])
	source_player.seek(START, true)
	# The imported FBX uses Z up. Work in the survivor's Y-up rig space.
	var axis := Basis(Vector3.RIGHT, Vector3(0, 0, -1), Vector3.UP)
	var hip_bone := source_rig.find_bone("hip")
	var initial_rotation := axis * source_rig.get_bone_global_pose(hip_bone).basis * source_rig.get_bone_global_rest(hip_bone).basis.inverse() * axis.inverse()
	var forward := initial_rotation * Vector3.FORWARD
	# The survivor's bind pose faces +Z. Match that orientation before applying
	# the animated joint rotations; otherwise the jog faces backward in game.
	var yaw := Basis(Vector3.UP, PI - atan2(forward.x, forward.z))
	var initial_hip := axis * source_rig.get_bone_global_pose(hip_bone).origin
	var source_leg := source_rig.get_bone_global_rest(source_rig.find_bone("lThigh")).origin.distance_to(source_rig.get_bone_global_rest(source_rig.find_bone("lFoot")).origin)
	var target_leg := target_rig.get_bone_global_rest(target_rig.find_bone("thigh_l")).origin.distance_to(target_rig.get_bone_global_rest(target_rig.find_bone("foot_l")).origin)
	var leg_scale := target_leg / source_leg
	var pelvis_bone := target_rig.find_bone("pelvis")
	var pelvis_rest := target_rig.get_bone_rest(pelvis_bone).origin
	var parent_rest := target_rig.get_bone_global_rest(target_rig.get_bone_parent(pelvis_bone)).basis
	var local_up := parent_rest.inverse() * Vector3.UP

	var clip := Animation.new()
	clip.length = END - START
	clip.loop_mode = Animation.LOOP_LINEAR
	var tracks := {}
	for target_name in PAIRS:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Armature/Skeleton3D:" + target_name))
		tracks[target_name] = track
	var pelvis_track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(pelvis_track, NodePath("Armature/Skeleton3D:pelvis"))
	var frame_count := int(roundf(clip.length * FPS))
	for frame in frame_count + 1:
		var phase := float(frame) / float(frame_count)
		source_player.seek(lerpf(START, END, phase), true)
		var target_globals: Array[Basis] = []
		for bone in target_rig.get_bone_count():
			var name := target_rig.get_bone_name(bone)
			var parent := target_rig.get_bone_parent(bone)
			var parent_basis := target_globals[parent] if parent >= 0 else Basis.IDENTITY
			var desired := parent_basis * target_rig.get_bone_rest(bone).basis
			if PAIRS.has(name):
				var source_bone := source_rig.find_bone(PAIRS[name])
				var source_pose := source_rig.get_bone_global_pose(source_bone).basis
				var source_rest := source_rig.get_bone_global_rest(source_bone).basis
				var motion := axis * source_pose * source_rest.inverse() * axis.inverse()
				desired = yaw * motion * target_rig.get_bone_global_rest(bone).basis
				var local := parent_basis.inverse() * desired
				clip.rotation_track_insert_key(tracks[name], phase * clip.length, local.orthonormalized().get_rotation_quaternion())
			target_globals.append(desired)
		var hip := axis * source_rig.get_bone_global_pose(hip_bone).origin
		var bob := (hip.y - initial_hip.y) * leg_scale
		clip.position_track_insert_key(pelvis_track, phase * clip.length, pelvis_rest + local_up * (bob - PELVIS_DROP))
	# The recorded stride is nearly cyclic. Ease the small residual difference
	# into the first pose, so repeated playback has no visible keyframe jump.
	for track in clip.get_track_count():
		var first_value: Variant = clip.track_get_key_value(track, 0)
		for frame in range(frame_count - 12, frame_count + 1):
			var weight := smoothstep(0.0, 1.0, float(frame - (frame_count - 12)) / 12.0)
			var value: Variant = clip.track_get_key_value(track, frame)
			if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				clip.track_set_key_value(track, frame, Quaternion(value).slerp(Quaternion(first_value), weight).normalized())
			else:
				clip.track_set_key_value(track, frame, Vector3(value).lerp(Vector3(first_value), weight))
	source.free()
	return clip
