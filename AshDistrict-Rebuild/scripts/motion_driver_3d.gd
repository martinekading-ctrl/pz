extends CharacterBody3D
## Isolated locomotion pilot. All travel comes from AnimationTree root motion.

const RIG := preload("res://art/characters/human_base/survivor.scn")
const WALK_SPEED := 1.35
const JOG_SPEED := 2.7
# Measured from the support foot's backwards travel in the source clips.
const WALK_STRIDE := 1.2
const JOG_STRIDE := 2.0

var rig: Node3D
var skeleton: Skeleton3D
var tree: AnimationTree
var speed_mps := 0.0
var requested_speed := 0.0
var root_delta := Vector3.ZERO
var motion_time_scale := 1.0

func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.875
	add_child(collision)
	rig = RIG.instantiate()
	add_child(rig)
	var player := rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = rig.find_child("Skeleton3D", true, false) as Skeleton3D
	assert(player != null and skeleton != null)
	# Keep the packed scene untouched; this pilot adds translation to local copies.
	var clips := player.get_animation_library("").duplicate(true) as AnimationLibrary
	player.remove_animation_library("")
	var motion_root := Node3D.new()
	motion_root.name = "MotionRoot"
	rig.add_child(motion_root)
	for entry in [["Idle", 0.0], ["Walk", WALK_STRIDE], ["Run", JOG_STRIDE]]:
		var clip := clips.get_animation(entry[0])
		var track := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(track, NodePath("MotionRoot:position"))
		clip.position_track_insert_key(track, 0.0, Vector3.ZERO)
		clip.position_track_insert_key(track, clip.length, Vector3(0, 0, float(entry[1])))
	player.add_animation_library("", clips)
	player.active = false
	tree = AnimationTree.new()
	tree.name = "LocomotionTree"
	rig.add_child(tree)
	tree.anim_player = NodePath("../AnimationPlayer")
	var blend := AnimationNodeBlendSpace1D.new()
	blend.min_space = 0.0
	blend.max_space = JOG_SPEED
	blend.sync_mode = AnimationNodeBlendSpace1D.SYNC_MODE_CYCLIC_MUTABLE
	for entry in [["Idle", 0.0], ["Walk", WALK_SPEED], ["Run", JOG_SPEED]]:
		var node := AnimationNodeAnimation.new()
		node.animation = StringName(entry[0])
		blend.add_blend_point(node, float(entry[1]), -1, StringName(entry[0]))
	tree.tree_root = blend
	tree.root_motion_track = NodePath("MotionRoot:position")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	tree.set("parameters/blend_position", 0.0)
	tree.advance(0.001)

func step_motion(direction: Vector3, running: bool, delta: float) -> void:
	var input_length := minf(1.0, direction.length())
	requested_speed = (JOG_SPEED if running else WALK_SPEED) * input_length
	speed_mps = move_toward(speed_mps, requested_speed, (5.0 if requested_speed > speed_mps else 7.0) * delta)
	if direction.length_squared() > 0.0001:
		var desired_yaw := atan2(-direction.x, -direction.z)
		rotation.y = rotate_toward(rotation.y, desired_yaw, 6.0 * delta)
	tree.set("parameters/blend_position", speed_mps)
	var player := rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var walk_base := WALK_STRIDE / player.get_animation("Walk").length
	var jog_base := JOG_STRIDE / player.get_animation("Run").length
	var base_speed := walk_base if speed_mps <= WALK_SPEED else lerpf(walk_base, jog_base, (speed_mps - WALK_SPEED) / (JOG_SPEED - WALK_SPEED))
	motion_time_scale = speed_mps / maxf(0.01, base_speed) if speed_mps > 0.01 else 1.0
	tree.advance(delta * motion_time_scale)
	root_delta = tree.get_root_motion_position()
	# The rig's imported forward axis is +Z and its model is turned 180 degrees.
	var world_delta := global_basis * Vector3(0, 0, -root_delta.z)
	velocity = world_delta / maxf(delta, 0.00001)
	move_and_slide()
