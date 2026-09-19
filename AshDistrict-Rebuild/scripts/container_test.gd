extends RefCounted
const Rules=preload("res://scripts/container_rules.gd")

static func run(game: Node2D) -> void:
	var source:={"water":5,"food":3}
	var pack:={"food":0,"water":23,"bandage":0,"parts":0}
	assert(Rules.transfer(source,pack,"water",5,12,24)==1)
	assert(source.water==4 and pack.water==24)
	assert(Rules.transfer(source,pack,"food",3,12,24)==0)
	assert(Rules.transfer(pack,source,"water",2,15,1000)==2)
	assert(source.water+pack.water==28)
	assert(Rules.transfer(source,pack,"bandage",1,12,24)==0)
	assert(Rules.duration({"title":"冰箱"})==1.5)
	assert(Rules.duration({"title":"冰箱","searched":true})==.15)
	var house: Node2D=game.world_map.blue_house
	var index:=1
	game.player.position=game.world_map.map_to_world(house.furniture[index].use_zone.get_center())
	house.update_player(game.player.position,1)
	assert(house.nearest_furniture(game.player.position)==index)
	game.interact()
	assert(game.searching==index)
	game._process(.2)
	assert(game.active_loot==-1 and not house.furniture[index].get("searched",false))
	var escape:=InputEventKey.new()
	escape.physical_keycode=KEY_ESCAPE
	escape.pressed=true
	game._input(escape)
	assert(game.searching==-1 and game.player.is_physics_processing())
	assert(not house.furniture[index].get("searched",false))
	game.interact()
	game._process(2.0)
	assert(game.active_loot==index and not game.player.is_physics_processing())
	var before: Dictionary=house.available_loot(index)
	game.loot_overlay.move_item("food",1,true)
	assert(house.available_loot(index).food==before.food-1)
	game.loot_overlay.move_item("food",1,false)
	for key in before: assert(int(house.available_loot(index).get(key,0))==int(before[key]))
	game.close_loot()
	game.open_loot(index,house)
	for key in before: assert(int(house.available_loot(index).get(key,0))==int(before[key]))
	assert(house.furniture[index].searched)
	var snapshot: Dictionary=house.available_loot(index)
	game.player.position+=Vector2(1000,0)
	game.loot_overlay.move_item("food",1,true)
	assert(game.active_loot==-1)
	for key in snapshot: assert(int(house.available_loot(index).get(key,0))==int(snapshot[key]))
	game.player.position=game.world_map.map_to_world(house.furniture[index].use_zone.get_center())
	game.open_loot(index,house)
	if "--container-capture" in OS.get_cmdline_user_args():
		await game.get_tree().create_timer(.5).timeout
		game.get_viewport().get_texture().get_image().save_png("res://build/container-v1.png")
	game.close_loot()
	assert(game.player.is_physics_processing())
	print("CONTAINER PASS: partial capacity, conservation, deposit, reopen persistence, search timing, modal")
	game.get_tree().quit()
