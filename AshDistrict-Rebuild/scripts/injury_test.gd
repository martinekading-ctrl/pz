extends RefCounted

const InjuryRules = preload("res://scripts/injury_rules.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = false
	game.player.set_physics_process(false)

	var injuries := InjuryRules.fresh_state()
	var needs := {"health":100.0, "food":80.0, "water":80.0, "stamina":100.0, "fatigue":0.0, "bleeding":0.0, "pain":0.0, "infection":0.0, "pain_relief":0.0}
	var scratch: Dictionary = InjuryRules.apply_zombie_hit(injuries, 0.60, 0.60, 0.90)
	assert(scratch.wounded and scratch.part == "arms" and injuries.arms.wound == "scratch", "Deterministic hit must create an arm scratch")
	InjuryRules.sync_needs(injuries, needs)
	var open_bleeding := float(needs.bleeding)
	assert(open_bleeding > 0.0 and float(needs.pain) > 0.0, "An open wound must produce bleeding and pain")
	var bandage: Dictionary = InjuryRules.apply_bandage(injuries, "arms")
	InjuryRules.sync_needs(injuries, needs)
	assert(bandage.consumed and bool(injuries.arms.bandaged) and float(needs.bleeding) < open_bleeding, "Bandaging a selected part must reduce its bleeding")
	var pain_before := float(needs.pain)
	var pills: Dictionary = InjuryRules.take_painkillers(needs, injuries)
	assert(pills.consumed and float(needs.pain) < pain_before and float(needs.pain_relief) == 180.0, "Painkillers must provide timed relief")

	var bite: Dictionary = InjuryRules.apply_zombie_hit(injuries, 0.99, 0.90, 0.99)
	assert(bite.part == "legs" and injuries.legs.wound == "bite" and injuries.legs.infected, "A bite must create an infected leg wound")
	InjuryRules.sync_needs(injuries, needs)
	assert(InjuryRules.movement_multiplier(injuries, needs) < 0.8, "A bitten leg must slow movement")
	var infection_before := float(injuries.legs.infection)
	InjuryRules.advance(injuries, needs, 180.0)
	assert(float(injuries.legs.infection) > infection_before and float(needs.pain_relief) == 0.0, "Infection and medicine duration must advance in game time")
	assert(InjuryRules.attack_duration_multiplier(injuries, needs) > 1.0, "Arm injury must slow attacks")
	var healing_state := InjuryRules.fresh_state()
	healing_state.head = InjuryRules.make_wound("scratch", true, false, 0.0)
	InjuryRules.advance(healing_state, needs.duplicate(true), 720.0)
	assert(int(healing_state.head.severity) == 0, "A clean bandaged scratch must heal over game time")

	game.injuries = injuries
	game.needs = needs
	game.inventory.bandage = 2
	game.inventory.painkillers = 1
	var used: Dictionary = game.use_inventory_item("bandage", "legs")
	assert(used.consumed and int(game.inventory.bandage) == 1 and bool(game.injuries.legs.bandaged), "Game treatment must consume exactly one bandage")
	var rest_needs: Dictionary = game.needs.duplicate(true)
	rest_needs.fatigue = 80.0
	rest_needs.stamina = 10.0
	var rest_result: Dictionary = preload("res://scripts/survival_rules.gd").rest(rest_needs, 480.0)
	assert(rest_result.rested, "Fully bandaged wounds must allow safe bed rest")
	game.player.set_physics_process(true)
	game.health_status_button.pressed.emit()
	assert(is_instance_valid(game.health_overlay) and not game.player.is_physics_processing(), "Health page must lock player input")
	assert(not game.simulation_paused and not game.gameplay_blocked(), "Health page must leave the world simulation running")
	var health_before := float(game.needs.health)
	game.player_invulnerability = 0.0
	game.damage_player(9, game.player.position + Vector2(20, 0))
	assert(float(game.needs.health) == health_before - 9.0 and is_instance_valid(game.health_overlay), "Player must remain vulnerable while treating wounds")
	game.close_health_panel()
	assert(game.player.is_physics_processing(), "Closing health page must restore player control")

	print("INJURY PASS: body parts, wounds, infection, bandages, pain relief, penalties, live treatment UI")
	game.get_tree().quit()
