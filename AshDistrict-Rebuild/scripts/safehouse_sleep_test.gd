extends RefCounted

const SaveSystem = preload("res://scripts/save_system.gd")

static func run(game: Node2D) -> void:
	var test_path := "user://ash_district_safehouse_test.json"
	game.autosave_path_override = test_path
	game.remove_save_files(test_path)
	game.game_started = true
	game.player.set_physics_process(false)

	var building: Node2D = game.world_map.blue_house
	var bed_index := find_bed(building)
	assert(bed_index >= 0, "Safehouse test requires a bed")
	var bed: Dictionary = building.furniture[bed_index]
	game.player.position = game.world_map.map_to_world((bed.use_zone as Rect2).get_center())
	game.active_building = building
	game.active_loot = bed_index

	var intruder: Node2D = game.spawn_zombie((building.get_search_area() as Rect2).get_center(), {"zone":"interior","home_building_id":str(building.name)})
	var blocked: Dictionary = game.claim_safehouse_at_bed()
	assert(not bool(blocked.ok), "A house containing a living zombie must not be claimable")
	intruder.change_state(intruder.State.DEAD)
	var claimed: Dictionary = game.claim_safehouse_at_bed()
	assert(bool(claimed.ok) and game.safehouse_building_id == str(building.name), "A cleared house bed must establish the safehouse")
	assert(FileAccess.file_exists(test_path), "Claiming a safehouse must create an autosave")
	var captured: Dictionary = SaveSystem.capture_state(game)
	assert(str(captured.safehouse.building_id) == str(building.name), "Safehouse identity must enter the save snapshot")

	game.needs.fatigue = 84.0
	game.needs.stamina = 12.0
	game.active_building = building
	game.active_loot = bed_index
	var before_time: float = game.game_time_minutes
	var started: Dictionary = game.rest_at_bed()
	assert(bool(started.started) and game.sleeping, "A safe bed must start the sleep state")
	game.update_sleep(4.1)
	assert(not game.sleeping and is_equal_approx(game.game_time_minutes,before_time+game.SLEEP_DURATION_MINUTES), "Completed sleep must advance eight hours")
	assert(is_equal_approx(float(game.needs.stamina),100.0) and float(game.needs.fatigue) < 10.0, "Completed sleep must restore stamina and reduce fatigue")

	game.needs.fatigue = 84.0
	game.needs.stamina = 12.0
	game.active_building = building
	game.active_loot = bed_index
	intruder.position = game.world_map.map_to_world(Vector2(2,2))
	intruder.health = 68
	intruder.change_state(intruder.State.IDLE)
	var second_start: Dictionary = game.rest_at_bed()
	assert(bool(second_start.started), "Sleep must begin while danger is outside the wake radius")
	intruder.position = game.player.position
	var interrupted_at: float = game.game_time_minutes
	game.update_sleep(0.1)
	assert(not game.sleeping and is_equal_approx(game.game_time_minutes,interrupted_at), "Nearby danger must immediately interrupt sleep")

	game.safehouse_building_id = ""
	game.safehouse_spawn_logical = Vector2.ZERO
	assert(SaveSystem.apply_state(game,captured), "Safehouse snapshot must load")
	assert(game.safehouse_building_id == str(building.name) and game.safehouse_spawn_logical.distance_to((bed.use_zone as Rect2).get_center()) < 0.01, "Safehouse state must survive a save round trip")
	game.remove_save_files(test_path)
	print("SAFEHOUSE PASS: clear-house claim, bed sleep, danger wake-up, autosave and persisted safehouse state")
	game.get_tree().quit()

static func find_bed(building: Node2D) -> int:
	for index: int in building.furniture.size():
		if "床" in str(building.furniture[index].title):
			return index
	return -1
