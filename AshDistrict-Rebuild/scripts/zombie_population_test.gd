extends RefCounted

const Population = preload("res://scripts/zombie_population.gd")

static func run(game: Node2D) -> void:
	await game.get_tree().process_frame
	assert(game.zombies.size() == Population.INITIAL_TARGET, "Initial heat plan must create the target population")
	var indoor := 0
	var zones := {}
	for zombie: Node2D in game.zombies:
		zombie.set_process(false)
		zones[zombie.spawn_zone] = int(zones.get(zombie.spawn_zone, 0)) + 1
		if zombie.spawn_zone == "interior":
			indoor += 1
			assert(zombie.state == zombie.State.SLEEPING and zombie.dormant, "Indoor zombies must begin dormant")
		assert(game.world_map.is_walkable_world(zombie.position), "Population entries must use walkable points")
	assert(indoor == 4 and zones.size() >= 4, "Population must include four sleepers and several heat zones")

	var sleeper: Node2D
	for zombie: Node2D in game.zombies:
		if zombie.spawn_zone == "interior":
			sleeper = zombie
			break
	assert(sleeper.hear_sound(sleeper.position, 1.0), "A nearby sound must wake an indoor zombie")
	assert(not sleeper.dormant and sleeper.state == sleeper.State.INVESTIGATE, "Awakened sleeper must investigate the sound")

	var corpse: Node2D = game.zombies[0]
	corpse.health = 1
	corpse.take_hit(99, corpse.position - Vector2(20, 0), 0.0)
	assert(corpse.is_dead() and corpse.is_corpse_searchable() and not corpse.corpse_inventory.is_empty(), "A killed zombie must become a persistent searchable corpse")
	game.player.position = corpse.position
	game.player.update_depth()
	game.player.set_physics_process(true)
	game.interact()
	assert(is_instance_valid(game.corpse_overlay) and game.active_corpse == corpse, "Interact must open the nearby corpse page")
	assert(not game.simulation_paused and not game.gameplay_blocked(), "Corpse search must leave the world simulation running")
	var item_id := str(corpse.corpse_inventory.keys()[0])
	var before := int(game.inventory.get(item_id, 0))
	var moved: int = game.take_corpse_item(corpse, item_id, 1)
	assert(moved == 1 and int(game.inventory.get(item_id, 0)) == before + 1, "Corpse loot must transfer into the capacity-limited backpack")
	game.close_corpse_loot()

	var remaining_alive: int = game.alive_zombie_count()
	for zombie: Node2D in game.zombies:
		if remaining_alive < Population.MIN_ALIVE:
			break
		if not zombie.is_dead():
			zombie.change_state(zombie.State.DEAD)
			remaining_alive -= 1
	assert(game.alive_zombie_count() < Population.MIN_ALIVE, "Test setup must lower the living population")
	game.population_respawn_budget = 1
	var count_before: int = game.zombies.size()
	assert(game.try_replenish_population(), "Low population must accept one distant migration")
	assert(game.zombies.size() == count_before + 1 and game.population_respawn_budget == 0, "Migration must consume its limited budget")
	var migrant: Node2D = game.zombies[-1]
	assert(migrant.spawn_zone == "migration", "Replenished zombie must be marked as a migrant")
	assert(not game.position_in_camera_view(migrant.position), "A migrant must never appear in the current camera view")

	print("POPULATION PASS: heat zones, indoor sleepers, corpse search, persistent loot and limited off-screen migration")
	game.get_tree().quit()
