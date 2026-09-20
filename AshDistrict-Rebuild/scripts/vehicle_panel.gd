extends ColorRect

const Catalog=preload("res://scripts/item_catalog.gd")
const Backpack=preload("res://scripts/backpack.gd")
const Rules=preload("res://scripts/vehicle_rules.gd")

var game: Node2D
var vehicle: Node2D
var content: MarginContainer
var message:="检查车辆、整理后备箱，或进入驾驶位。"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color=Color("0b1114f2")
	mouse_filter=Control.MOUSE_FILTER_STOP
	rebuild()

func _process(_delta: float) -> void:
	if not is_instance_valid(vehicle) or vehicle.interaction_distance_meters(game.player.position)>2.4:
		game.close_vehicle_panel()

func label(parent: Node,text_value: String,size_value: int=18,color_value: Color=Color("d8dfdc")) -> Label:
	var result:=Label.new()
	result.text=text_value
	result.add_theme_font_size_override("font_size",size_value)
	result.add_theme_color_override("font_color",color_value)
	parent.add_child(result)
	return result

func button(parent: Node,text_value: String,callback: Callable) -> Button:
	var result:=Button.new()
	result.text=text_value
	result.custom_minimum_size=Vector2(122,44)
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func rebuild() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content=MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: content.add_theme_constant_override("margin_"+edge,30)
	add_child(content)
	var center:=CenterContainer.new()
	content.add_child(center)
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(1120,630)
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color("151f1cf8")
	panel_style.border_color=Color("63766d")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",panel_style)
	center.add_child(panel)
	var inner:=MarginContainer.new()
	for edge: String in ["left","right","top","bottom"]: inner.add_theme_constant_override("margin_"+edge,24)
	panel.add_child(inner)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	inner.add_child(column)
	var header:=HBoxContainer.new()
	column.add_child(header)
	var title:=label(header,"%s  /  VEHICLE" % vehicle.display_name,27,Color("f0e8d0"))
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(header,"关闭  Esc",game.close_vehicle_panel)
	var stats:=HBoxContainer.new()
	stats.add_theme_constant_override("separation",28)
	column.add_child(stats)
	var condition_label:=label(stats,"车况 %d%%" % roundi(vehicle.condition),20,Color("a8c9ae" if vehicle.condition>35.0 else "db806f"))
	condition_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var fuel_label:=label(stats,"油量 %.1f / %.0f L" % [vehicle.fuel_liters,Rules.MAX_FUEL_LITERS],20,Color("d8c477"))
	fuel_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var trunk_label:=label(stats,"后备箱 %.1f / %.0f kg" % [Backpack.weight(vehicle.trunk),Rules.TRUNK_MAX_WEIGHT],20)
	trunk_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var actions:=HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	column.add_child(actions)
	button(actions,"上车驾驶",drive).disabled=vehicle.condition<=0.0 or vehicle.fuel_liters<=0.0
	button(actions,"加入 10 L 汽油",refuel).disabled=int(game.inventory.get("gas_can",0))<=0 or vehicle.fuel_liters>=Rules.MAX_FUEL_LITERS-0.01
	var driving_hint:=label(actions,"W/S 油门与倒车 · A/D 转向 · E 下车",16,Color("9eaaa4"))
	driving_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	driving_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",26)
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(body)
	build_inventory_side(body,"后备箱",vehicle.trunk,true)
	build_inventory_side(body,"随身背包",game.inventory,false)
	label(column,message,17,Color("ddc878"))

func build_inventory_side(parent: HBoxContainer,title: String,items: Dictionary,from_vehicle: bool) -> void:
	var side:=VBoxContainer.new()
	side.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x=500
	parent.add_child(side)
	label(side,title,22)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	side.add_child(scroll)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	var any:=false
	for item_id: String in Catalog.ITEMS:
		var amount:=int(items.get(item_id,0))
		if amount<=0: continue
		any=true
		var row:=HBoxContainer.new()
		rows.add_child(row)
		var item_label:=label(row,"%s  %s ×%d" % [Catalog.item(item_id).icon,Catalog.item(item_id).name,amount],17)
		item_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var transfer:=button(row,"取出 1 件" if from_vehicle else "存入 1 件",move_item.bind(item_id,from_vehicle))
		transfer.disabled=not from_vehicle and not game.vehicle_item_storable(item_id)
	if not any:
		label(rows,"没有物品",17,Color("89958f"))

func move_item(item_id: String,from_vehicle: bool) -> void:
	var result: Dictionary=game.transfer_vehicle_item(vehicle,item_id,1,from_vehicle)
	message=str(result.message)
	rebuild()

func refuel() -> void:
	var result: Dictionary=game.refuel_vehicle(vehicle)
	message=str(result.message)
	rebuild()

func drive() -> void:
	game.enter_vehicle(vehicle)
