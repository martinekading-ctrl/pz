extends RefCounted

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	game.player.set_dead_pose(false)
	game.player.moving = true
	game.player.running = false
	game.player.crouching = false
	assert(game.player.presentation_state() == "walk", "Moving player must use the walk presentation")
	game.player.running = true
	assert(game.player.presentation_state() == "run", "Running player must use the run presentation")
	game.player.running = false
	game.player.moving = false
	assert(game.player.start_melee(), "Melee presentation must start")
	game.player.swing_remaining = game.player.weapon_swing_seconds * 0.88
	assert(game.player.attack_phase() == "windup", "Melee must begin with a windup")
	game.player.swing_remaining = game.player.weapon_swing_seconds * 0.55
	assert(game.player.attack_phase() == "impact", "Melee must expose a readable impact phase")
	game.player.swing_remaining = game.player.weapon_swing_seconds * 0.18
	assert(game.player.attack_phase() == "recover", "Melee must finish with recovery")
	game.player.swing_remaining = 0.0
	game.player.receive_hit(game.player.position - Vector2(20, 0))
	assert(game.player.presentation_state() == "hurt", "Player hit must override locomotion presentation")
	var zombie: Node2D = game.zombies[0]
	zombie.set_process(false)
	zombie.change_state(zombie.State.ATTACK)
	zombie.state_time = 0.62
	assert(zombie.presentation_state() == "attack_impact", "Zombie attack must expose its contact phase")
	zombie.take_hit(1, game.player.position, 0.0)
	assert(zombie.presentation_state() == "stagger", "A surviving zombie must visibly stagger")
	zombie.take_hit(999, game.player.position, 0.0)
	assert(zombie.presentation_state() == "dead", "A killed zombie must use the corpse pose")
	var effects_before: int = game.combat_fx.active_effect_count()
	game.combat_fx.spawn_impact(game.player.position, Vector2.RIGHT, false)
	assert(game.combat_fx.active_effect_count() == effects_before + 1, "A hit must create one impact effect bundle")
	game.add_camera_trauma(0.3)
	var trauma_before: float = game.camera_trauma
	game.update_camera_feedback(0.02)
	assert(game.camera_trauma < trauma_before and game.camera_trauma > 0.0, "Camera trauma must decay after the impact")
	print("PRESENTATION PASS: player states, melee phases, zombie attack/stagger/death, hit FX and camera feedback")
	game.stop_firearm_audio()
	await game.get_tree().process_frame
	game.get_tree().quit()
