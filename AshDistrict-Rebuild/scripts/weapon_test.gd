extends RefCounted

const Catalog=preload("res://scripts/item_catalog.gd")
const Rules=preload("res://scripts/weapon_rules.gd")

static func run(game: Node2D) -> void:
	game.simulation_paused=true
	assert(Catalog.is_weapon("crowbar") and int(Rules.stats("crowbar").damage)==34)
	assert(int(Rules.stats("baseball_bat").damage)==30 and float(Rules.stats("baseball_bat").range)>float(Rules.stats("crowbar").range))
	assert(float(Rules.stats("kitchen_knife").swing)<float(Rules.stats("crowbar").swing))
	game.inventory.baseball_bat=1
	game.add_weapon_instances("baseball_bat",1)
	assert(game.equip_weapon("baseball_bat","secondary"),"Owned weapon must equip into the secondary slot")
	game.set_active_weapon_slot("secondary")
	assert(game.active_weapon_id()=="baseball_bat" and int(game.active_weapon_stats().damage)==30)
	game.spawn_zombies()
	for zombie: Node2D in game.zombies:
		zombie.set_process(false)
	var origin: Vector2=game.world_map.map_to_world(Vector2(36,49))
	game.player.position=origin
	var target: Node2D=game.zombies[0]
	target.position=game.world_map.map_to_world(Vector2(37.8,49))
	var direction: Vector2=(target.position-origin).normalized()
	var before: float=game.active_weapon_durability()
	game.simulation_paused=false
	game._on_player_melee_impact(origin,direction)
	game.simulation_paused=true
	assert(target.health==38,"Baseball bat must apply its data-defined 30 damage")
	assert(game.active_weapon_durability()<before,"A successful hit must consume weapon durability")
	game.weapon_durability.baseball_bat[0]=float(Rules.stats("baseball_bat").wear)
	game.damage_active_weapon()
	assert(int(game.inventory.baseball_bat)==0 and game.active_weapon_id()!="baseball_bat","Broken weapon must leave inventory and equipment")
	game.inventory.kitchen_knife=1
	game.add_weapon_instances("kitchen_knife",1,17.0)
	game.open_backpack()
	game.backpack.selected="kitchen_knife"
	game.backpack.drop_item()
	assert(int(game.inventory.kitchen_knife)==0 and is_equal_approx(float(game.ground_items[-1].durability),17.0),"Dropped weapon must preserve its durability")
	game.backpack.pickup()
	assert(int(game.inventory.kitchen_knife)==1 and is_equal_approx(float(game.weapon_durability.kitchen_knife[0]),17.0),"Picked-up weapon must restore its durability")
	print("WEAPON PASS: data stats, two equipment slots, switching, wear, breakage and durability preservation")
	game.get_tree().quit()
