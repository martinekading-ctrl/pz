extends Control

const Catalog = preload("res://scripts/item_catalog.gd")
const SLOT_COUNT := 6

var game: Node2D
var selected_index := 0
var slot_buttons: Array[Button] = []
var selected_label: Label
var panel: PanelContainer
var input_enabled := true
var flash_message := ""
var flash_time := 0.0
var last_signature := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_label = Label.new()
	selected_label.anchor_left = 0.5
	selected_label.anchor_right = 0.5
	selected_label.anchor_top = 1.0
	selected_label.anchor_bottom = 1.0
	selected_label.offset_left = -220.0
	selected_label.offset_top = -122.0
	selected_label.offset_right = 220.0
	selected_label.offset_bottom = -94.0
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_label.add_theme_font_size_override("font_size", 17)
	selected_label.add_theme_color_override("font_color", Color("f0e5c5"))
	selected_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	selected_label.add_theme_constant_override("shadow_offset_x", 2)
	selected_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(selected_label)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -226.0
	panel.offset_top = -92.0
	panel.offset_right = 226.0
	panel.offset_bottom = -12.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.035, 0.03, 0.78)
	panel_style.border_color = Color(0.55, 0.58, 0.52, 0.62)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 6)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)
	for index: int in SLOT_COUNT:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(68, 68)
		slot.focus_mode = Control.FOCUS_NONE
		slot.add_theme_font_size_override("font_size", 15)
		slot.pressed.connect(press_slot.bind(index))
		row.add_child(slot)
		slot_buttons.append(slot)
	force_refresh()

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
		if flash_time == 0.0:
			last_signature = ""
	refresh()

func slot_item_id(index: int) -> String:
	match index:
		0: return str(game.equipment.get("primary", ""))
		1: return str(game.equipment.get("secondary", ""))
		2: return "food"
		3: return "water"
		4: return "bandage"
		5: return "parts"
	return ""

func press_slot(index: int) -> void:
	if not input_enabled:
		return
	var item_id := slot_item_id(index)
	if item_id.is_empty() or int(game.inventory.get(item_id, 0)) <= 0:
		flash("该格为空")
		return
	if index < 2:
		selected_index = index
		game.set_active_weapon_slot("primary" if index == 0 else "secondary")
		force_refresh()
		return
	if index == 5:
		selected_index = index
		flash("机械零件是制作与修理材料")
		return
	if selected_index != index:
		selected_index = index
		flash("再次点击使用 " + str(Catalog.item(item_id).name))
		return
	var result: Dictionary = game.use_inventory_item(item_id)
	flash(str(result.message))

func sync_to_active_weapon() -> void:
	selected_index = 1 if str(game.active_weapon_slot) == "secondary" else 0
	flash_time = 0.0
	force_refresh()

func set_interactive(value: bool) -> void:
	input_enabled = value
	force_refresh()

func flash(text: String) -> void:
	flash_message = text
	flash_time = 1.6
	force_refresh()

func force_refresh() -> void:
	last_signature = ""
	refresh()

func refresh() -> void:
	if not is_instance_valid(game) or slot_buttons.size() != SLOT_COUNT:
		return
	var signature := str([selected_index, game.active_weapon_slot, game.equipment, game.inventory, input_enabled, flash_time > 0.0])
	if signature == last_signature:
		return
	last_signature = signature
	for index: int in SLOT_COUNT:
		var item_id := slot_item_id(index)
		var count := int(game.inventory.get(item_id, 0)) if not item_id.is_empty() else 0
		var slot := slot_buttons[index]
		var icon := str(Catalog.item(item_id).get("icon", "·")) if count > 0 else "·"
		slot.text = "%d\n%s  %s" % [index + 1, icon, ("×%d" % count if count > 0 else "空")]
		slot.tooltip_text = str(Catalog.item(item_id).get("name", "空物品栏"))
		slot.disabled = not input_enabled
		apply_slot_style(slot, index == selected_index, count <= 0)
	selected_label.text = flash_message if flash_time > 0.0 else selected_description()

func selected_description() -> String:
	var item_id := slot_item_id(selected_index)
	var count := int(game.inventory.get(item_id, 0)) if not item_id.is_empty() else 0
	if count <= 0:
		return "空物品栏"
	if selected_index < 2:
		if Catalog.is_firearm(item_id):
			return "%s · 弹匣 %d/%d · 备弹 %d" % [Catalog.item(item_id).name, game.active_firearm_loaded(), int(Catalog.item(item_id).mag_capacity), int(game.inventory.get(str(Catalog.item(item_id).ammo_item), 0))]
		return "%s · 耐久 %s" % [Catalog.item(item_id).name, game.weapon_condition_text(item_id)]
	if selected_index in [2, 3, 4]:
		return "%s ×%d · 再次点击使用" % [Catalog.item(item_id).name, count]
	return "%s ×%d" % [Catalog.item(item_id).name, count]

func apply_slot_style(slot: Button, selected: bool, empty: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.14, 0.13, 0.84 if not empty else 0.58)
	normal.border_color = Color("e1bd62") if selected else Color(0.62, 0.65, 0.6, 0.64)
	normal.set_border_width_all(3 if selected else 1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.24, 0.19, 0.92)
	hover.border_color = Color("f1d57b")
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.35, 0.29, 0.14, 0.96)
	slot.add_theme_stylebox_override("normal", normal)
	slot.add_theme_stylebox_override("disabled", normal)
	slot.add_theme_stylebox_override("hover", hover)
	slot.add_theme_stylebox_override("pressed", pressed)
	slot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	slot.add_theme_color_override("font_color", Color("f2f0e8") if not empty else Color("969b94"))
	slot.add_theme_color_override("font_disabled_color", Color("a8ada5"))
