extends ColorRect

const Catalog=preload("res://scripts/item_catalog.gd")
const WeaponRules=preload("res://scripts/weapon_rules.gd")
const ITEMS=Catalog.ITEMS
const MAX_WEIGHT:=12.0
const MAX_SLOTS:=24
var game: Node2D
var selected:="food"
var content: MarginContainer
var message:="点击物品查看详情"
var survivor_status_label: Label
var condition_status_label: Label

static func weight(items: Dictionary) -> float:
	var total:=0.0
	for key in items: total+=items[key]*float(ITEMS[key].weight)
	return total

static func slots(items: Dictionary) -> int:
	var total:=0
	for key in items: total+=ceili(float(items[key])/int(ITEMS[key].stack))
	return total

static func fits(items: Dictionary,key: String,count: int) -> bool:
	var copy:=items.duplicate()
	copy[key]=int(copy.get(key,0))+count
	return weight(copy)<=MAX_WEIGHT+.001 and slots(copy)<=MAX_SLOTS

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color=Color("0d1217f5")
	mouse_filter=Control.MOUSE_FILTER_STOP
	rebuild()

func _process(_delta: float) -> void:
	if is_instance_valid(survivor_status_label):
		survivor_status_label.text="生命 %d   饱食 %d   水分 %d" % [roundi(game.needs.health),roundi(game.needs.food),roundi(game.needs.water)]
	if is_instance_valid(condition_status_label):
		condition_status_label.text=preload("res://scripts/survival_rules.gd").condition_text(game.needs)

func label(parent: Node,text_value: String,size_value:=18) -> Label:
	var n:=Label.new()
	n.text=text_value
	n.add_theme_font_size_override("font_size",size_value)
	n.add_theme_color_override("font_color",Color("d3dcd9"))
	parent.add_child(n)
	return n

func button(parent: Node,text_value: String,callback: Callable) -> Button:
	var n:=Button.new()
	n.text=text_value
	n.custom_minimum_size=Vector2(110,42)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("202c32")
	style.border_color=Color("49615f")
	style.set_border_width_all(1)
	n.add_theme_stylebox_override("normal",style)
	n.add_theme_stylebox_override("disabled",style)
	var hover:=style.duplicate() as StyleBoxFlat
	hover.border_color=Color("83d1ba")
	n.add_theme_stylebox_override("hover",hover)
	n.add_theme_stylebox_override("focus",hover)
	n.pressed.connect(callback)
	parent.add_child(n)
	return n

func rebuild() -> void:
	if content:
		remove_child(content)
		content.queue_free()
	content=MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: content.add_theme_constant_override("margin_"+edge,28)
	add_child(content)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	content.add_child(column)
	var top:=HBoxContainer.new()
	column.add_child(top)
	var title:=label(top,"装备与物资  /  INVENTORY",26)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(top,"关闭  Tab / Esc",game.close_backpack)
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",26)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var left:=VBoxContainer.new()
	left.custom_minimum_size.x=300
	body.add_child(left)
	label(left,"幸存者  /  当前装备",21)
	var portrait:=Control.new()
	portrait.custom_minimum_size=Vector2(290,275)
	left.add_child(portrait)
	portrait.draw.connect(func():
		portrait.draw_circle(Vector2(145,42),21,Color("b69a79"))
		portrait.draw_line(Vector2(145,80),Vector2(145,164),Color("596b58"),64)
		for side in [-1,1]:
			portrait.draw_line(Vector2(145+side*38,84),Vector2(145+side*54,170),Color("485c4c"),17)
			portrait.draw_line(Vector2(145+side*18,166),Vector2(145+side*25,258),Color("47505a"),23)
	)
	var equip:=GridContainer.new()
	equip.columns=2
	left.add_child(equip)
	for slot in ["头部","护甲"]:
		var empty:=button(equip,slot+" · 预留",func(): pass)
		empty.disabled=true
	for slot: String in ["primary","secondary"]:
		var weapon_id: String=str(game.equipment[slot])
		var slot_name: String="主武器" if slot=="primary" else "副武器"
		var weapon_name: String="空" if weapon_id.is_empty() else str(ITEMS[weapon_id].name)
		var active: String="  [使用中]" if game.active_weapon_slot==slot and not weapon_id.is_empty() else ""
		button(equip,slot_name+" · "+weapon_name+active,game.set_active_weapon_slot.bind(slot)).disabled=weapon_id.is_empty()
	survivor_status_label=label(left,"生命 %d   饱食 %d   水分 %d" % [roundi(game.needs.health),roundi(game.needs.food),roundi(game.needs.water)],16)
	condition_status_label=label(left,preload("res://scripts/survival_rules.gd").condition_text(game.needs),16)
	label(left,"负重  %.1f / %.0f kg" % [weight(game.inventory),MAX_WEIGHT],22)
	var right:=VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(right)
	label(right,"随身背包   %d / %d 格" % [slots(game.inventory),MAX_SLOTS],22)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=6
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	scroll.add_child(grid)
	var count:=0
	for key in ITEMS:
		var remaining: int=game.inventory.get(key,0)
		while remaining>0:
			var amount:=mini(remaining,int(ITEMS[key].stack))
			var suffix: String="\n"+game.weapon_condition_text(key) if Catalog.is_weapon(key) else ""
			var cell:=button(grid,str(ITEMS[key].icon)+"  ×"+str(amount)+"\n"+str(ITEMS[key].name)+suffix,choose.bind(key))
			cell.custom_minimum_size=Vector2(115,72)
			cell.tooltip_text=str(ITEMS[key].desc)+("\n耐久 "+game.weapon_condition_text(key) if Catalog.is_weapon(key) else "")
			remaining-=amount
			count+=1
	for i in maxi(0,MAX_SLOTS-count):
		var empty:=button(grid,"·",func(): pass)
		empty.custom_minimum_size=Vector2(115,72)
		empty.disabled=true
	label(right,str(ITEMS[selected].name)+"  /  %.2f kg 每件" % float(ITEMS[selected].weight),20)
	label(right,str(ITEMS[selected].desc),16)
	if Catalog.is_weapon(selected):
		var stats: Dictionary=WeaponRules.stats(selected)
		if Catalog.is_firearm(selected):
			label(right,"伤害 %d   射程 %.1f 米   弹匣 %d/%d   备弹 %d" % [stats.damage,stats.range,int(game.firearm_loaded.get(selected,0)),int(stats.mag_capacity),int(game.inventory.get(str(stats.ammo_item),0))],16)
			label(right,"需要 %s · 装填 %.2f 秒 · 枪声半径 %.0f 米" % [Catalog.item(str(stats.magazine_item)).name,float(stats.reload_seconds),float(stats.noise_radius)],16)
		else:
			label(right,"伤害 %d   距离 %.2f 米   攻速 %.2f 秒   耐久 %s" % [stats.damage,stats.range,stats.swing,game.weapon_condition_text(selected)],16)
	var actions:=HBoxContainer.new()
	right.add_child(actions)
	if Catalog.is_weapon(selected):
		button(actions,"装备主武器",equip_weapon.bind("primary")).disabled=game.inventory.get(selected,0)<=0
		button(actions,"装备副武器",equip_weapon.bind("secondary")).disabled=game.inventory.get(selected,0)<=0
	else:
		button(actions,"使用 1 件",use_item).disabled=game.inventory.get(selected,0)<=0 or str(ITEMS[selected].category)!="consumable"
	button(actions,"丢弃 1 件",drop_item).disabled=game.inventory.get(selected,0)<=0
	button(actions,"拾回附近物品",pickup)
	label(column,message,16)

func choose(key: String) -> void:
	selected=key
	rebuild()

func use_item() -> void:
	if str(ITEMS[selected].category)!="consumable" or game.inventory.get(selected,0)<=0: return
	var result: Dictionary=game.use_inventory_item(selected)
	message=str(result.message)
	rebuild()

func equip_weapon(slot: String) -> void:
	if game.equip_weapon(selected,slot):
		message="已将 "+str(ITEMS[selected].name)+" 装备到"+("主武器" if slot=="primary" else "副武器")
	else:
		message="背包中没有这件武器"
	rebuild()

func drop_item() -> void:
	if game.inventory.get(selected,0)<=0: return
	var firearm_rounds := int(game.firearm_loaded.get(selected, 0)) if Catalog.is_firearm(selected) else 0
	game.inventory[selected]-=1
	var ground:={"key":selected,"position":game.player.position}
	if Catalog.is_weapon(selected):
		var removed: Array[float]=game.remove_weapon_instances(selected,1)
		ground["durability"]=removed[0] if not removed.is_empty() else WeaponRules.max_durability(selected)
		if Catalog.is_firearm(selected):
			ground["loaded_ammo"] = firearm_rounds
			if int(game.inventory.get(selected, 0)) <= 0:
				game.firearm_loaded[selected] = 0
	game.ground_items.append(ground)
	message="已放在脚边，可在附近拾回"
	rebuild()

func pickup() -> void:
	var taken:=0
	for i in range(game.ground_items.size()-1,-1,-1):
		var item: Dictionary=game.ground_items[i]
		if game.world_map.world_to_map(item.position-game.player.position).length()*.5>1.2: continue
		if not fits(game.inventory,item.key,1): continue
		game.inventory[item.key]+=1
		if Catalog.is_weapon(item.key):
			game.add_weapon_instances(item.key,1,float(item.get("durability",WeaponRules.max_durability(item.key))))
			if Catalog.is_firearm(item.key) and int(game.inventory.get(item.key, 0)) == 1:
				game.firearm_loaded[item.key] = clampi(int(item.get("loaded_ammo", 0)), 0, int(Catalog.item(item.key).mag_capacity))
		game.ground_items.remove_at(i)
		taken+=1
	message="拾回 %d 件物品（仅拾取 1.2 米内且背包装得下的物品）" % taken
	rebuild()
