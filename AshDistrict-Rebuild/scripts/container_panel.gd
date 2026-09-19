extends "res://scripts/backpack.gd"

var building: Node2D
var index: int
const Rules=preload("res://scripts/container_rules.gd")

func valid_target() -> bool:
	return is_instance_valid(building) and building.nearest_furniture(game.player.position)==index

func rebuild() -> void:
	if content:
		remove_child(content)
		content.queue_free()
	content=MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: content.add_theme_constant_override("margin_"+edge,32)
	add_child(content)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	content.add_child(column)
	var top:=HBoxContainer.new()
	column.add_child(top)
	label(top,"搜索与整理  /  LOOT",26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(top,"关闭  Esc / E",game.close_loot)
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",30)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var item: Dictionary=building.furniture[index]
	var rule: Dictionary=Rules.profile(item)
	for from_container in [true,false]:
		var side:=VBoxContainer.new()
		side.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		body.add_child(side)
		var items: Dictionary=item.remaining if from_container else game.inventory
		label(side,building.item_title(index) if from_container else "随身背包",24)
		label(side,(str(rule.label)+" · 已搜索") if from_container else "物品可放回左侧容器",16)
		label(side,"%.1f / %.0f kg" % [weight(items),float(rule.capacity) if from_container else MAX_WEIGHT],20)
		var scroll:=ScrollContainer.new()
		scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
		side.add_child(scroll)
		var rows:=VBoxContainer.new()
		rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		rows.add_theme_constant_override("separation",12)
		scroll.add_child(rows)
		var any:=false
		for key in ITEMS:
			if int(items.get(key,0))<=0: continue
			any=true
			label(rows,str(ITEMS[key].icon)+"  "+str(ITEMS[key].name)+"  ×"+str(int(items[key])),20)
			var actions:=HBoxContainer.new()
			rows.add_child(actions)
			button(actions,"拿取 1 件" if from_container else "放回 1 件",move_item.bind(key,1,from_container))
			button(actions,"拿取该类" if from_container else "放回该类",move_item.bind(key,int(items[key]),from_container))
		if not any: label(rows,"容器已空" if from_container else "背包为空",18)
	button(column,"拿取所有装得下的物品",take_all)
	if "床" in str(item.title):
		if game.is_safehouse(building):
			var safehouse_label := label(column,"安全屋床位 · 进入住宅与睡醒后自动保存",17)
			safehouse_label.add_theme_color_override("font_color",Color("d9c66f"))
		else:
			button(column,"将这栋住宅设为安全屋",claim_safehouse)
		button(column,"睡觉 8 小时",rest_at_bed)
	label(column,message,18)
	label(column,"不拿取即保留在原处。本次游戏内，物品不会因重新打开或离开区域而刷新。",16)

func move_item(key: String,amount: int,from_container: bool) -> void:
	if not valid_target():
		game.close_loot()
		return
	var item: Dictionary=building.furniture[index]
	var moved: int=Rules.transfer(item.remaining if from_container else game.inventory,game.inventory if from_container else item.remaining,key,amount,MAX_WEIGHT if from_container else float(Rules.profile(item).capacity),MAX_SLOTS if from_container else 1000)
	if moved>0 and Catalog.is_weapon(key):
		transfer_weapon_durability(item,key,moved,from_container)
	message=("已拿取 " if from_container else "已放回 ")+str(moved)+" 件"+("，容量不足，余量保留" if moved<amount else "")
	rebuild()

func take_all() -> void:
	if not valid_target():
		game.close_loot()
		return
	var moved:=0
	for key in ITEMS:
		var item: Dictionary=building.furniture[index]
		var count: int=Rules.transfer(item.remaining,game.inventory,key,999,MAX_WEIGHT,MAX_SLOTS)
		if count>0 and Catalog.is_weapon(key):
			transfer_weapon_durability(item,key,count,true)
		moved+=count
	message="已拿取 %d 件；未转移的物品保留在容器内" % moved
	rebuild()

func rest_at_bed() -> void:
	if not valid_target():
		game.close_loot()
		return
	var result: Dictionary = game.rest_at_bed()
	if bool(result.get("started",false)):
		return
	message = str(result.message)
	rebuild()

func claim_safehouse() -> void:
	if not valid_target():
		game.close_loot()
		return
	var result: Dictionary = game.claim_safehouse_at_bed()
	message = str(result.message)
	rebuild()

func transfer_weapon_durability(item: Dictionary,key: String,count: int,from_container: bool) -> void:
	var stored: Dictionary=item.get("weapon_durability",{})
	var values: Array=stored.get(key,[])
	var stored_firearms: Dictionary = item.get("firearm_loaded", {})
	var loaded_values: Array = stored_firearms.get(key, [])
	if from_container:
		for i: int in count:
			var durability: float=float(values.pop_back()) if not values.is_empty() else WeaponRules.max_durability(key)
			game.add_weapon_instances(key,1,durability)
			if Catalog.is_firearm(key) and int(game.inventory.get(key, 0)) == 1:
				game.firearm_loaded[key] = clampi(int(loaded_values.pop_back()) if not loaded_values.is_empty() else 0, 0, int(Catalog.item(key).mag_capacity))
	else:
		if Catalog.is_firearm(key):
			for i: int in count:
				loaded_values.append(int(game.firearm_loaded.get(key, 0)) if i == 0 else 0)
			if int(game.inventory.get(key, 0)) <= 0:
				game.firearm_loaded[key] = 0
		for durability: float in game.remove_weapon_instances(key,count):
			values.append(durability)
	stored[key]=values
	item["weapon_durability"]=stored
	if Catalog.is_firearm(key):
		stored_firearms[key] = loaded_values
		item["firearm_loaded"] = stored_firearms
