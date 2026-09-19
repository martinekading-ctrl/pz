extends ColorRect

var game: Node2D
var controls: Control
var current_label: Label
var preset_buttons := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.015, 0.025, 0.022, 0.88)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -330.0
	panel.offset_top = -205.0
	panel.offset_right = 330.0
	panel.offset_bottom = 205.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("17221f")
	panel_style.border_color = Color("61736c")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 26)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := make_label("操作设置", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := make_button("关闭", Vector2(104, 48))
	close.pressed.connect(game.close_mobile_settings)
	title_row.add_child(close)

	column.add_child(make_label("按钮布局", 20))
	var description := make_label("选择后立即生效并自动保存。设置界面不会暂停游戏世界。", 16)
	description.add_theme_color_override("font_color", Color("b9c8c1"))
	column.add_child(description)

	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 12)
	presets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(presets)
	for data: Dictionary in [
		{"id":"standard", "text":"标准布局\n\n移动在左\n瞄准攻击在右"},
		{"id":"compact", "text":"紧凑布局\n\n摇杆靠近边缘\n减少遮挡"},
		{"id":"mirrored", "text":"左右互换\n\n瞄准攻击在左\n移动在右"},
	]:
		var button := make_button(str(data.text), Vector2(190, 170))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_preset.bind(str(data.id)))
		presets.add_child(button)
		preset_buttons[str(data.id)] = button

	current_label = make_label("", 18)
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(current_label)
	refresh_selection()

func select_preset(preset: String) -> void:
	controls.apply_layout_preset(preset, true)
	refresh_selection()

func refresh_selection() -> void:
	if not is_instance_valid(current_label):
		return
	current_label.text = "当前：" + controls.layout_preset_name()
	for preset: String in preset_buttons:
		var button: Button = preset_buttons[preset]
		apply_button_style(button, preset == controls.layout_preset)

func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("eef2ed"))
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
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3d5048")
	hover.border_color = Color("ead68e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("f2edda") if selected else Color("d9e1dd"))
