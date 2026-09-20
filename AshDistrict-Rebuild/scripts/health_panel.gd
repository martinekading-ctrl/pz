extends ColorRect

const InjuryRules = preload("res://scripts/injury_rules.gd")
const BodyDiagram = preload("res://scripts/body_diagram.gd")

var game: Node2D
var selected_part := "torso"
var diagram: Control
var summary_label: Label
var detail_label: Label
var supplies_label: Label
var message_label: Label
var bandage_button: Button
var remove_button: Button
var painkiller_button: Button
var disinfectant_button: Button
var antibiotics_button: Button
var part_buttons := {}
var last_signature := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.012, 0.02, 0.018, 0.9)
	mouse_filter = Control.MOUSE_FILTER_STOP
	build_ui()
	refresh()

func _process(_delta: float) -> void:
	var signature := str([game.needs, game.injuries, game.inventory.get("bandage", 0), game.inventory.get("painkillers", 0), game.inventory.get("disinfectant",0), game.inventory.get("antibiotics",0), selected_part])
	if signature != last_signature:
		refresh()

func build_ui() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -500.0
	panel.offset_top = -310.0
	panel.offset_right = 500.0
	panel.offset_bottom = 310.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("16211e")
	panel_style.border_color = Color("65766f")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := make_label("健康与治疗  /  HEALTH", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := make_button("关闭  Esc", Vector2(126, 48))
	close.pressed.connect(game.close_health_panel)
	title_row.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 480)
	left.add_theme_constant_override("separation", 7)
	body.add_child(left)
	diagram = BodyDiagram.new()
	diagram.custom_minimum_size = Vector2(320, 420)
	left.add_child(diagram)
	summary_label = make_label("", 17)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(summary_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)
	right.add_child(make_label("身体部位", 21))
	var part_grid := GridContainer.new()
	part_grid.columns = 2
	part_grid.add_theme_constant_override("h_separation", 10)
	part_grid.add_theme_constant_override("v_separation", 10)
	right.add_child(part_grid)
	for part: String in InjuryRules.PARTS:
		var button := make_button("", Vector2(278, 74))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_part.bind(part))
		part_grid.add_child(button)
		part_buttons[part] = button

	var detail_panel := PanelContainer.new()
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color("202c28")
	detail_style.border_color = Color("465a52")
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(5)
	detail_style.content_margin_left = 16
	detail_style.content_margin_right = 16
	detail_style.content_margin_top = 14
	detail_style.content_margin_bottom = 14
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	detail_panel.custom_minimum_size.y = 112
	right.add_child(detail_panel)
	detail_label = make_label("", 18)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_label)

	supplies_label = make_label("", 18)
	right.add_child(supplies_label)
	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 10)
	right.add_child(actions)
	bandage_button = make_button("包扎", Vector2(145, 50))
	bandage_button.pressed.connect(apply_bandage)
	actions.add_child(bandage_button)
	remove_button = make_button("拆下绷带", Vector2(145, 50))
	remove_button.pressed.connect(remove_bandage)
	actions.add_child(remove_button)
	painkiller_button = make_button("服用止痛药", Vector2(170, 50))
	painkiller_button.pressed.connect(take_painkiller)
	actions.add_child(painkiller_button)
	disinfectant_button = make_button("消毒伤口", Vector2(145,50))
	disinfectant_button.pressed.connect(disinfect_wound)
	actions.add_child(disinfectant_button)
	antibiotics_button = make_button("服用抗生素", Vector2(170,50))
	antibiotics_button.pressed.connect(take_antibiotics)
	actions.add_child(antibiotics_button)
	message_label = make_label("选择身体部位查看伤势。治疗期间游戏世界仍在运行。", 16)
	message_label.add_theme_color_override("font_color", Color("d8c986"))
	right.add_child(message_label)

func refresh() -> void:
	if not is_instance_valid(game) or not is_instance_valid(diagram):
		return
	last_signature = str([game.needs, game.injuries, game.inventory.get("bandage", 0), game.inventory.get("painkillers", 0), game.inventory.get("disinfectant",0), game.inventory.get("antibiotics",0), selected_part])
	diagram.set_data(game.injuries, selected_part)
	var pain := roundi(float(game.needs.get("pain", 0.0)))
	var infection := roundi(float(game.needs.get("infection", 0.0)))
	summary_label.text = "生命 %d   疼痛 %d   感染 %d%%" % [roundi(float(game.needs.health)), pain, infection]
	for part: String in InjuryRules.PARTS:
		var injury: Dictionary = game.injuries[part]
		var state: String = str(InjuryRules.WOUND_LABELS[str(injury.wound)])
		if bool(injury.bandaged):
			state += " · 已包扎"
		if bool(injury.infected):
			state += " · 感染"
		var button: Button = part_buttons[part]
		button.text = "%s\n%s" % [InjuryRules.PART_LABELS[part], state]
		apply_button_style(button, part == selected_part)
	var selected: Dictionary = game.injuries[selected_part]
	var wound_name := str(InjuryRules.WOUND_LABELS[str(selected.wound)])
	var lines := "%s：%s" % [InjuryRules.PART_LABELS[selected_part], wound_name]
	if int(selected.severity) > 0:
		lines += "\n%s  ·  感染程度 %d%%" % ["绷带稳定" if bool(selected.bandaged) else "伤口正在出血", roundi(float(selected.infection))]
		if selected_part == "legs":
			lines += "  ·  会降低移动速度"
		elif selected_part == "arms":
			lines += "  ·  会降低攻击效率"
	else:
		lines += "\n没有需要处理的伤口。"
	detail_label.text = lines
	supplies_label.text = "医疗物资   绷带 ×%d   止痛药 ×%d   消毒剂 ×%d   抗生素 ×%d" % [int(game.inventory.get("bandage", 0)), int(game.inventory.get("painkillers", 0)), int(game.inventory.get("disinfectant",0)), int(game.inventory.get("antibiotics",0))]
	bandage_button.disabled = int(game.inventory.get("bandage", 0)) <= 0 or int(selected.severity) <= 0 or bool(selected.bandaged)
	remove_button.disabled = not bool(selected.bandaged)
	painkiller_button.disabled = int(game.inventory.get("painkillers", 0)) <= 0 or InjuryRules.raw_pain(game.injuries) <= 0.0 or float(game.needs.get("pain_relief", 0.0)) >= 120.0
	disinfectant_button.disabled = int(game.inventory.get("disinfectant",0)) <= 0 or not bool(selected.get("infected",false))
	antibiotics_button.disabled = int(game.inventory.get("antibiotics",0)) <= 0 or InjuryRules.infection_value(game.injuries) <= 0.0

func select_part(part: String) -> void:
	selected_part = part
	message_label.text = "已选择%s。" % InjuryRules.PART_LABELS[part]
	last_signature = ""
	refresh()

func apply_bandage() -> void:
	var result: Dictionary = game.use_inventory_item("bandage", selected_part)
	message_label.text = str(result.message)
	last_signature = ""
	refresh()

func remove_bandage() -> void:
	var result: Dictionary = game.remove_injury_bandage(selected_part)
	message_label.text = str(result.message)
	last_signature = ""
	refresh()

func take_painkiller() -> void:
	var result: Dictionary = game.use_inventory_item("painkillers")
	message_label.text = str(result.message)
	last_signature = ""
	refresh()

func disinfect_wound() -> void:
	var result: Dictionary = game.use_inventory_item("disinfectant",selected_part)
	message_label.text = str(result.message)
	last_signature = ""
	refresh()

func take_antibiotics() -> void:
	var result: Dictionary = game.use_inventory_item("antibiotics")
	message_label.text = str(result.message)
	last_signature = ""
	refresh()

func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e5ebe7"))
	return label

func make_button(text: String, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	apply_button_style(button, false)
	return button

func apply_button_style(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("34463f") if selected else Color("202d29")
	normal.border_color = Color("e4c56e") if selected else Color("5c7068")
	normal.set_border_width_all(3 if selected else 1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3d5048")
	hover.border_color = Color("ead68e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("f2edda"))
	button.add_theme_color_override("font_disabled_color", Color("828d87"))
