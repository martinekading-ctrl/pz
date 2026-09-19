extends RefCounted

const Combat = preload("res://scripts/combat_rules.gd")

static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	for zombie: Node2D in game.zombies:
		zombie.set_process(false)
	var origin_logical:=Vector2(36,49)
	game.player.position=game.world_map.map_to_world(origin_logical)
	var front: Node2D=game.zombies[0]
	var rear: Node2D=game.zombies[1]
	front.position=game.world_map.map_to_world(origin_logical+Vector2(1.6,0.0))
	rear.position=game.world_map.map_to_world(origin_logical-Vector2(1.6,0.0))
	var direction: Vector2=(front.position-game.player.position).normalized()
	assert(Combat.in_melee_arc(game.world_map,game.player.position,direction,front.position))
	assert(not Combat.in_melee_arc(game.world_map,game.player.position,direction,rear.position))
	var rear_health: int=rear.health
	game._on_player_melee_impact(game.player.position,direction)
	assert(front.health==34,"Forward zombie must take one crowbar hit")
	assert(rear.health==rear_health,"Rear zombie must stay outside the melee arc")
	game._on_player_melee_impact(game.player.position,direction)
	assert(front.is_dead(),"Second crowbar hit must knock the test zombie down")
	game.needs.health=100
	game.player_invulnerability=0.0
	game.damage_player(Combat.ZOMBIE_ATTACK_DAMAGE,rear.position)
	assert(int(game.needs.health)==91,"Zombie attack must reduce player health")
	game.damage_player(Combat.ZOMBIE_ATTACK_DAMAGE,rear.position)
	assert(int(game.needs.health)==91,"Player invulnerability must prevent stacked same-frame damage")
	game.open_backpack()
	assert(not game.gameplay_blocked(),"Backpack must not pause zombie combat")
	game.player_invulnerability=0.0
	game.damage_player(Combat.ZOMBIE_ATTACK_DAMAGE,rear.position)
	assert(int(game.needs.health)==82 and is_instance_valid(game.backpack),"Player must remain vulnerable with backpack open")
	game.close_backpack()
	game.searching=0
	game.search_building=game.world_map.blue_house
	game.search_time=0.4
	game.player.set_physics_process(false)
	assert(not game.gameplay_blocked(),"Container search must not pause zombie combat")
	game.player_invulnerability=0.0
	game.damage_player(Combat.ZOMBIE_ATTACK_DAMAGE,rear.position)
	assert(int(game.needs.health)==73,"Player must remain vulnerable while searching")
	assert(game.searching==-1 and game.player.is_physics_processing(),"A zombie hit must interrupt an active search")
	print("COMBAT PASS: melee, damage, death, invulnerability and live combat during backpack/search UI")
	game.get_tree().quit()
