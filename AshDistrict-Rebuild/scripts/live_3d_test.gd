extends RefCounted

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	for zombie: Node2D in game.zombies: zombie.set_process(false)
	var actors: Array = [game.player,game.zombies[0],game.world_map.vehicles[0]]
	for actor: Node2D in actors:
		var visual: Node2D = actor.live_visual
		assert(visual.viewport.own_world_3d and visual.viewport.transparent_bg)
		assert(visual.model.get_child_count()>0)
		var camera: Camera3D = visual.viewport.get_camera_3d()
		var anchor: Vector2 = camera.unproject_position(Vector3.ZERO)*visual.sprite.scale+visual.sprite.position
		assert(anchor.length()<0.01,"3D ground anchor must coincide with actor collision origin")
	for character: Node2D in [game.player, game.zombies[0]]:
		var character_visual: Node2D = character.live_visual
		assert(character_visual.uses_skeletal_animation(), "Player and zombie must use imported skeletal animation")
		assert(character_visual.skeleton.get_bone_count() >= 40, "Imported humanoid rig must retain its full skeleton")
		var body: MeshInstance3D = character_visual.rigged_character.find_child("SuperHero_Male",true,false)
		var clothes: MeshInstance3D = character_visual.rigged_character.find_child("Clothes",true,false)
		assert(body != null and clothes != null and clothes.skin != null, "Human body and clothes must both be skinned")
		var height: float = body.mesh.get_aabb().size.y*character_visual.rigged_character.scale.y
		assert(height>1.7 and height<1.85,"Human height must follow the meter standard")
	var vehicle: Node2D = actors[2]
	vehicle.heading_logical = Vector2.DOWN
	vehicle.update_pose()
	assert(is_zero_approx(vehicle.rotation),"Vehicle must turn in 3D, not rotate its projected image")
	var visual: Node2D = vehicle.live_visual
	vehicle.position=game.player.position+Vector2(100,0)
	visual._process(1.0)
	assert(absf(angle_difference(visual.model.rotation.y,PI))<0.01)
	game.player.moving=true
	game.update_player_condition_effects()
	assert(game.player.moving,"Condition updates must not reset the walking animation")
	game.player.velocity_mps = Vector2(1.6, 0.0)
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.animation_clip == "Walk")
	var rig_player: AnimationPlayer=game.player.live_visual.animation_player
	var rig: Skeleton3D=game.player.live_visual.skeleton
	rig_player.advance(0.2)
	var thigh := rig.find_bone("thigh_l")
	var first_pose := rig.get_bone_pose_rotation(thigh)
	rig_player.advance(0.22)
	assert(first_pose.angle_to(rig.get_bone_pose_rotation(thigh))>0.01,"Retargeted walk must actually move leg bones")
	var full_speed: float=game.player.live_visual.desired_rig_animation().speed
	game.player.velocity_mps*=0.5
	assert(is_equal_approx(float(game.player.live_visual.desired_rig_animation().speed),full_speed*0.5),"Half travel speed must halve foot cadence without a minimum playback clamp")
	game.player.velocity_mps=Vector2(3.2,0)
	game.player.running=true
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.animation_clip=="Run")
	game.player.running=false
	game.player.crouching=true
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.animation_clip=="Crouch_Walk")
	game.player.crouching=false
	game.player.swing_remaining = game.player.weapon_swing_seconds
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.animation_clip == "Slash")
	game.player.swing_remaining = 0.0
	var test_zombie: Node2D = game.zombies[0]
	test_zombie.change_state(test_zombie.State.CHASE)
	test_zombie.live_visual._process(0.1)
	assert(test_zombie.live_visual.animation_clip == "Walk")
	game.player.visible=false
	game.player.live_visual._process(0.1)
	assert(game.player.live_visual.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
	assert(not game.player.live_visual.animation_player.active, "Offscreen skeleton animation must stop processing")
	game.player.swing_remaining=0.0
	var impacts := [0]
	game.player.melee_impact.connect(func(_position: Vector2,_facing: Vector2): impacts[0]+=1)
	assert(game.player.weapon_swing_seconds>=0.89,"Crowbar needs a full recovery interval")
	assert(game.player.start_melee())
	var duration: float=game.player.weapon_swing_seconds
	game.player.step_motion(Vector2.ZERO,duration*0.3)
	assert(impacts[0]==0 and not game.player.start_melee(),"Windup must not hit or accept another attack")
	game.player.step_motion(Vector2.ZERO,duration*0.2)
	assert(impacts[0]==1,"Swing must deliver one hit after windup")
	game.player.step_motion(Vector2.ZERO,duration*0.4)
	assert(impacts[0]==1 and not game.player.start_melee(),"Recovery must prevent attack spam")
	game.player.step_motion(Vector2.ZERO,duration*0.11)
	assert(game.player.start_melee(),"Next attack unlocks when recovery completes")
	game.stop_firearm_audio()
	print("LIVE 3D PASS: rigged meshes, 40+ bone skeletons, blended walk/attack states, ground anchoring, vehicle heading and hidden viewport suspension")
	await game.get_tree().process_frame
	game.get_tree().quit()
