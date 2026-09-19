extends RefCounted

const Catalog = preload("res://scripts/item_catalog.gd")
const Rules = preload("res://scripts/firearm_rules.gd")

static func run(game: Node2D) -> void:
	var seeded := {"pistol":0, "pistol_magazine":0, "pistol_ammo":0}
	for building: Node2D in [game.world_map.store_building, game.world_map.residential_b01]:
		for container: Dictionary in building.furniture:
			for item_id: String in seeded:
				seeded[item_id] += int(container.remaining.get(item_id, 0))
	assert(int(seeded.pistol) == 1 and int(seeded.pistol_magazine) >= 1 and int(seeded.pistol_ammo) >= 30, "Pistol, magazine and ammunition must be searchable world loot")
	game.clear_zombies()
	game.inventory.pistol = 1
	game.inventory.pistol_magazine = 1
	game.inventory.pistol_ammo = 15
	game.weapon_durability.pistol = []
	game.add_weapon_instances("pistol", 1)
	game.firearm_loaded.pistol = 0
	assert(game.equip_weapon("pistol", "secondary"), "Owned pistol must equip")
	assert(Catalog.is_firearm("pistol") and Rules.capacity("pistol") == 12, "Pistol data must expose firearm and magazine rules")
	assert(InputMap.has_action("reload"), "Reload must use a named input action")
	assert(game.player.weapon_is_firearm, "Equipping a pistol must switch the player into firearm handling")

	assert(game.begin_reload(), "A pistol, magazine and loose ammunition must start a reload")
	game.update_firearm_reload(float(Catalog.item("pistol").reload_seconds) + 0.01)
	assert(game.active_firearm_loaded() == 12 and int(game.inventory.pistol_ammo) == 3 and int(game.inventory.pistol_magazine) == 1, "Reload must fill the magazine, keep the magazine and consume only loose ammunition")

	var player_logical := Vector2(36, 49)
	game.player.position = game.world_map.map_to_world(player_logical)
	game.player.moving = false
	game.player.crouching = true
	var direction: Vector2 = game.world_map.map_to_world(Vector2.RIGHT).normalized()
	var near: Node2D = game.spawn_zombie(player_logical + Vector2(6, 0), {"zone":"test", "corpse_loot":{}})
	var far: Node2D = game.spawn_zombie(player_logical + Vector2(12, 0), {"zone":"test", "corpse_loot":{}})
	game.shot_sequence = 0
	var before := int(game.active_firearm_loaded())
	assert(game.try_fire_active_weapon(game.player.position, direction, true), "Aimed trigger pull with ammunition must fire")
	assert(game.active_firearm_loaded() == before - 1 and near.health == 22 and far.health == 68, "Hitscan must damage the first target only and spend one round")
	assert(str(game.last_noise.kind) == "gunshot" and float(game.last_noise.radius) == 26.0 and int(game.last_noise.listeners) >= 2, "A gunshot must publish its full sound radius and alert nearby zombies")
	assert(game.active_weapon_durability() < 100.0, "Every fired round must wear the weapon")
	before = game.active_firearm_loaded()
	assert(not game.try_fire_active_weapon(game.player.position, direction, false) and game.active_firearm_loaded() == before, "A desktop shot without aiming must be rejected without consuming ammunition")
	game.firearm_loaded.pistol = 0
	assert(not game.try_fire_active_weapon(game.player.position, direction, true) and game.active_firearm_loaded() == 0, "An empty pistol must click without producing a shot")

	game.firearm_loaded.pistol = 10
	game.inventory.pistol_ammo = 1
	assert(game.begin_reload(), "A partial reload must start")
	game.update_firearm_reload(2.0)
	assert(game.active_firearm_loaded() == 11 and int(game.inventory.pistol_ammo) == 0, "Partial reload must keep unfilled magazine space")
	game.firearm_loaded.pistol = 5
	game.inventory.pistol_ammo = 5
	game.inventory.pistol_magazine = 0
	assert(not game.begin_reload() and game.active_firearm_loaded() == 5, "Reloading without a magazine must fail safely")
	game.open_backpack()
	game.backpack.selected = "pistol"
	game.backpack.drop_item()
	assert(int(game.inventory.pistol) == 0 and int(game.ground_items[-1].loaded_ammo) == 5, "A dropped pistol must keep its loaded magazine state")
	game.backpack.pickup()
	assert(int(game.inventory.pistol) == 1 and int(game.firearm_loaded.pistol) == 5, "Picking the pistol back up must restore its loaded rounds")
	game.close_backpack()

	print("FIREARM PASS: world loot, named input, aim gate, reloads, empty trigger, first-target hitscan, durability, ground state and 26 m zombie hearing")
	game.stop_firearm_audio()
	game.get_tree().quit()
