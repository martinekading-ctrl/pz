extends ColorRect

const SkillRules = preload("res://scripts/skill_rules.gd")

var game: Node2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("0b1114f4")
	mouse_filter = Control.MOUSE_FILTER_STOP
	build_ui()

func make_label(text_value: String, size_value: int = 18, color_value: Color = Color("d7dfda")) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size",size_value)
	result.add_theme_color_override("font_color",color_value)
	return result

func make_button(text_value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size = Vector2(155,46)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("223137")
	normal.border_color = Color("607b73")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	result.add_theme_stylebox_override("normal",normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color("9bc9a9")
	result.add_theme_stylebox_override("hover",hover)
	result.add_theme_stylebox_override("focus",hover)
	result.pressed.connect(callback)
	return result

func build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,28)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := make_label("幸存者技能  /  SKILLS",28,Color("f0e8d0"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(make_button("返回背包",game.close_skills_panel.bind(true)))
	var note := make_label("技能会随着实际行动自动成长。等级上限 5；没有加点和重置成本。",16,Color("aebeb7"))
	column.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	column.add_child(grid)
	for skill_id: String in SkillRules.ORDER:
		grid.add_child(make_skill_card(skill_id))
	var footer := make_label("体能：奔跑/挥击  ·  近战：命中/击倒  ·  搜索：首次搜查  ·  生存：医疗/制作/施工",15,Color("91a79f"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)

func make_skill_card(skill_id: String) -> PanelContainer:
	var definition: Dictionary = SkillRules.DEFINITIONS[skill_id]
	var level := SkillRules.level(game.skills,skill_id)
	var progress: Dictionary = SkillRules.level_progress(game.skills,skill_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0,210)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17231ff2")
	style.border_color = Color("52685e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var icon := make_label(str(definition.icon),28,Color("d5c27e"))
	icon.custom_minimum_size.x = 48
	row.add_child(icon)
	var title := make_label(str(definition.name),24,Color("eef0dd"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(make_label("等级 %d / %d" % [level,SkillRules.MAX_LEVEL],20,Color("b8d5b8")))
	column.add_child(make_label(str(definition.desc),16,Color("b8c5bf")))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 24
	bar.value = float(progress.percent)
	bar.show_percentage = false
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color("27322f")
	bar_background.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background",bar_background)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("6e9b78")
	bar_fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill",bar_fill)
	column.add_child(bar)
	var progress_label := make_label(str(progress.text),14,Color("899c95"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(progress_label)
	column.add_child(make_label(SkillRules.bonus_text(skill_id,level),17,Color("d5c27e")))
	return panel
