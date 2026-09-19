extends RefCounted

const Exertion = preload("res://scripts/exertion_rules.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = true
	game.player.set_physics_process(false)
	for zombie: Node2D in game.zombies:
		zombie.set_process(false)

	var needs := {"stamina":100.0, "fatigue":0.0}
	var delay := Exertion.advance_stamina(needs, 2.0, true, 0.0)
	assert(is_equal_approx(float(needs.stamina), 78.0), "Running must drain stamina per real second")
	assert(is_equal_approx(delay, Exertion.RECOVERY_DELAY_SECONDS), "Exertion must start a recovery delay")
	delay = Exertion.advance_stamina(needs, 0.5, false, delay)
	assert(is_equal_approx(float(needs.stamina), 78.0) and delay > 0.0, "Stamina must not regenerate during recovery delay")
	Exertion.advance_stamina(needs, 1.0, false, delay)
	assert(float(needs.stamina) > 78.0, "Resting must regenerate stamina after the delay")
	var tired := {"stamina":50.0, "fatigue":100.0}
	Exertion.advance_stamina(tired, 1.0, false, 0.0)
	assert(float(tired.stamina) < float(needs.stamina) - 20.0, "Fatigue must reduce stamina recovery")
	var cost := Exertion.attack_cost(2.1)
	var attack_needs := {"stamina":cost, "fatigue":0.0}
	assert(Exertion.spend_attack(attack_needs, cost) and is_zero_approx(float(attack_needs.stamina)), "Attack must spend its complete stamina cost")
	assert(not Exertion.spend_attack(attack_needs, cost), "Attack must fail without enough stamina")
	assert(Exertion.movement_noise_radius(true, false) > Exertion.movement_noise_radius(false, false))
	assert(Exertion.movement_noise_radius(false, true) < Exertion.movement_noise_radius(false, false))
	var rest_needs := {"health":80.0, "food":80.0, "water":80.0, "stamina":12.0, "fatigue":82.0, "bleeding":0.0}
	var rest_result: Dictionary = preload("res://scripts/survival_rules.gd").rest(rest_needs, 480.0)
	assert(rest_result.rested and is_equal_approx(float(rest_needs.stamina),100.0) and float(rest_needs.fatigue)<10.0, "Bed rest must close the fatigue and stamina loop")

	assert(not game.zombies.is_empty(), "Sound test requires one zombie")
	var listener: Node2D = game.zombies[0]
	listener.alerted = false
	listener.change_state(listener.State.IDLE)
	var logical: Vector2 = game.world_map.world_to_map(listener.position)
	var source: Vector2 = game.world_map.map_to_world(logical + Vector2(8.0, 0.0))
	assert(listener.hear_sound(source, 10.0), "Nearby noise must be heard even without player sight")
	assert(listener.state == listener.State.INVESTIGATE and listener.investigate_target == source, "Heard noise must enter investigate state with a remembered target")
	listener.change_state(listener.State.DEAD)
	assert(not listener.hear_sound(source, 10.0), "Dead zombies must ignore sound")
	for zombie: Node2D in game.zombies:
		zombie.change_state(zombie.State.DEAD)
	var bed_index := -1
	for index: int in game.world_map.blue_house.furniture.size():
		if "床" in str(game.world_map.blue_house.furniture[index].title):
			bed_index = index
			break
	assert(bed_index >= 0, "Playable house must expose a bed rest point")
	var bed: Dictionary = game.world_map.blue_house.furniture[bed_index]
	game.player.position = game.world_map.map_to_world((bed.use_zone as Rect2).get_center())
	game.active_building = game.world_map.blue_house
	game.active_loot = bed_index
	game.needs = {"health":80.0, "food":80.0, "water":80.0, "stamina":10.0, "fatigue":82.0, "bleeding":0.0}
	var before_time: float = game.game_time_minutes
	var bed_result: Dictionary = game.rest_at_bed()
	assert(bed_result.rested and is_equal_approx(game.game_time_minutes,before_time+480.0), "Safe bed interaction must advance eight hours and recover the player")

	print("EXERTION PASS: running drain, delayed recovery, fatigue, attack cost, noise investigation and safe bed rest")
	game.get_tree().quit()
