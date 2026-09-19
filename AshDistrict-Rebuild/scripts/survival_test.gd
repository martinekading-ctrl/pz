extends RefCounted

const Rules = preload("res://scripts/survival_rules.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused = true
	var idle := {"health": 80.0, "food": 100.0, "water": 100.0, "bleeding": 0.0}
	var split := idle.duplicate()
	Rules.advance(idle, 120.0, false)
	for i: int in 12:
		Rules.advance(split, 10.0, false)
	assert(is_equal_approx(float(idle.food), float(split.food)), "Needs decay must be frame-rate independent")
	assert(is_equal_approx(float(idle.water), float(split.water)), "Thirst decay must be frame-rate independent")
	var active := {"health": 100.0, "food": 100.0, "water": 100.0, "bleeding": 0.0}
	Rules.advance(active, 120.0, true)
	assert(float(active.food) < float(idle.food) and float(active.water) < float(idle.water), "Running must consume more food and water")
	assert(float(active.fatigue) > float(idle.fatigue), "Activity must accumulate fatigue faster")
	var danger := {"health": 50.0, "food": 0.0, "water": 0.0, "bleeding": 1.0}
	Rules.advance(danger, 10.0, false)
	assert(float(danger.health) < 48.0, "Starvation, dehydration and bleeding must damage health gradually")
	var result := Rules.use_item(danger, "water")
	assert(result.consumed and is_equal_approx(float(danger.water), 30.0))
	result = Rules.use_item(danger, "food")
	assert(result.consumed and is_equal_approx(float(danger.food), 25.0))
	result = Rules.use_item(danger, "bandage")
	assert(result.consumed and is_zero_approx(float(danger.bleeding)), "Bandage must stop bleeding")
	assert(Rules.movement_multiplier({"food": 5.0, "water": 100.0}) < 1.0)
	assert(not Rules.can_run({"food": 100.0, "water": 10.0}))
	var clock := Rules.clock_parts(2.0 * 1440.0 + 8.0 * 60.0 + 20.0)
	assert(clock.day==3 and clock.hour==8 and clock.minute==20, "Clock must start on day 3 at 08:20")
	game.needs={"health":100.0,"food":100.0,"water":100.0,"bleeding":0.0}
	game.simulation_paused=false
	game.set_simulation_paused(true)
	assert(not game.player.is_physics_processing(),"Manual pause must stop player control")
	game.set_simulation_paused(false)
	assert(game.player.is_physics_processing(),"Unpause must restore player control")
	game.needs={"health":1.0,"food":0.0,"water":0.0,"bleeding":1.0}
	game.advance_survival(10.0)
	assert(float(game.needs.health)<=0.0 and is_instance_valid(game.game_over_overlay),"Fatal survival damage must show the restart screen")
	print("SURVIVAL PASS: clock, delta-scaled decay, activity cost, graded damage, item recovery and movement penalties")
	game.get_tree().quit()
