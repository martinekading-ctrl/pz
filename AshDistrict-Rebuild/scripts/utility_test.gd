extends RefCounted

const UtilityRules=preload("res://scripts/utility_rules.gd")
const Survival=preload("res://scripts/survival_rules.gd")
const SaveSystem=preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused=true
	game.player.set_physics_process(false)
	game.power_cutoff_minutes=game.game_time_minutes+10.0
	game.water_cutoff_minutes=game.game_time_minutes+20.0
	assert(game.power_available() and game.water_available())

	game.needs.water=40.0
	var tap: Dictionary=game.drink_from_tap()
	assert(tap.ok and int(game.needs.water)==75,"Working tap must restore thirst")
	game.inventory.water=1
	game.inventory.empty_bottle=0
	game.needs.water=40.0
	var bottle: Dictionary=game.use_inventory_item("water")
	assert(bottle.consumed and int(game.inventory.water)==0 and int(game.inventory.empty_bottle)==1,"Drinking bottled water must leave an empty bottle")
	var filled: Dictionary=game.fill_water_bottles()
	assert(filled.ok and int(filled.moved)==1 and int(game.inventory.water)==1 and int(game.inventory.empty_bottle)==0,"A working tap must refill empty bottles")

	game.fresh_food_expiry_minutes=game.game_time_minutes+5000.0
	game.advance_world_time(11.0)
	assert(not game.power_available() and game.water_available(),"Power must stop at its saved cutoff")
	assert(game.fresh_food_expiry_minutes<=game.game_time_minutes+UtilityRules.OUTAGE_FRESH_FOOD_GRACE_MINUTES+0.01,"Power loss must shorten the shared fresh-food deadline")
	game.advance_world_time(10.0)
	assert(not game.water_available(),"Water must stop at its saved cutoff")
	game.needs.water=20.0
	assert(not bool(game.drink_from_tap().ok),"Dry taps must not restore thirst")

	var bed: Dictionary=game.world_map.blue_house.furniture[0]
	game.player.position=game.world_map.map_to_world((bed.use_zone as Rect2).get_center())
	game.game_time_minutes=22.0*60.0
	game.power_cutoff_minutes=1000.0
	game.update_world_lighting()
	var base:=Survival.light_color(game.game_time_minutes)
	assert(game.world_tint.color.r<base.r and not game.current_player_building_id().is_empty(),"Unpowered interiors must be darker at night")

	game.power_cutoff_minutes=6000.0
	game.water_cutoff_minutes=8000.0
	var state:=SaveSystem.capture_state(game)
	assert(is_equal_approx(float(state.world.power_cutoff_minutes),6000.0) and is_equal_approx(float(state.world.water_cutoff_minutes),8000.0),"Utility cutoffs must save")
	var legacy:=state.duplicate(true)
	legacy.version=4
	legacy.world.erase("power_cutoff_minutes")
	legacy.world.erase("water_cutoff_minutes")
	var migrated:=SaveSystem.migrate(legacy)
	assert(int(migrated.version)==SaveSystem.SAVE_VERSION and migrated.world.has("power_cutoff_minutes") and migrated.world.has("water_cutoff_minutes"),"Version 4 saves must migrate to utility schedules")
	print("UTILITY PASS: tap drinking, bottle refill, timed outages, fridge spoilage, dark interiors and save migration")
	game.get_tree().quit()
