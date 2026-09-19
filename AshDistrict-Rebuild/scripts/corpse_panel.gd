extends ColorRect

const Catalog = preload("res://scripts/item_catalog.gd")
const Backpack = preload("res://scripts/backpack.gd")
const Population = preload("res://scripts/zombie_population.gd")

var game: Node2D
var corpse: Node2D
var content: MarginContainer
var message := "选择要带走的物品；关闭页面即把其余物品留在尸体上。"
var last_signature := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.012, 0.02, 0.018, 0.91)
	mouse_filter = Control.MOUSE_FILTER_STOP
	rebuild()

func _process(_delta: float) -> void:
	if not valid_target():
		game.close_corpse_loot()
		return
	var signature := str(corpse.corpse_inventory)
	if signature != last_signature:
		rebuild()

func valid_target() -> bool:
	return is_instance_valid(corpse) and corpse.is_dead() and game.nearest_searchable_corpse(1.6, true) == corpse

func rebuild() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + edge, 34)
	add_child(content)
	var outer := CenterContainer.new()
	content.add_child(outer)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 530)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17211e")
	style.border_color = Color("68786f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	outer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := make_label("搜索尸体  /  CORPSE", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close := make_button("关闭  Esc", Vector2(126, 48))
	close.pressed.connect(game.close_corpse_loot)
	title_row.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 30)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 245
	left.add_theme_constant_override("separation", 12)
	body.add_child(left)
	left.add_child(make_label("倒下的感染者", 22))
	var silhouette := Control.new()
	silhouette.custom_minimum_size = Vector2(230, 245)
	silhouette.draw.connect(func():
		var shadow := PackedVector2Array()
		for point_index: int in 24:
			var angle := float(point_index) * TAU / 24.0
			shadow.append(Vector2(112, 185) + Vector2(cos(angle) * 89.0, sin(angle) * 25.0))
		silhouette.draw_colored_polygon(shadow, Color(0, 0, 0, 0.28))
		silhouette.draw_line(Vector2(55, 157), Vector2(151, 177), Color("62594f"), 35.0, true)
		silhouette.draw_circle(Vector2(177, 183), 22.0, Color("7f8168"))
		silhouette.draw_line(Vector2(104, 168), Vector2(48, 211), Color("484c45"), 17.0, true)
	)
	left.add_child(silhouette)
	left.add_child(make_label("发现位置：" + Population.zone_label(str(corpse.spawn_zone)), 17))
	left.add_child(make_label("搜索后尸体和剩余物品会保留。", 15))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	right.add_child(make_label("尸体携带物", 22))
	var any := false
	for item_id: String in Catalog.ITEMS:
		var amount := int(corpse.corpse_inventory.get(item_id, 0))
		if amount <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		right.add_child(row)
		var item_label := make_label("%s  %s  ×%d" % [Catalog.item(item_id).icon, Catalog.item(item_id).name, amount], 19)
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item_label)
		var one := make_button("拿取 1 件", Vector2(112, 46))
		one.pressed.connect(take_item.bind(item_id, 1))
		row.add_child(one)
		var all := make_button("全部拿取", Vector2(112, 46))
		all.pressed.connect(take_item.bind(item_id, amount))
		row.add_child(all)
	if not any:
		var empty := make_label("没有找到可用物品", 19)
		empty.add_theme_color_override("font_color", Color("9da9a3"))
		right.add_child(empty)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	var take_all_button := make_button("拿取所有装得下的物品", Vector2(260, 50))
	take_all_button.disabled = not any
	take_all_button.pressed.connect(take_all)
	right.add_child(take_all_button)
	right.add_child(make_label("背包 %.1f / %.0f kg" % [Backpack.weight(game.inventory), Backpack.MAX_WEIGHT], 17))
	var message_label := make_label(message, 16)
	message_label.add_theme_color_override("font_color", Color("ddc878"))
	column.add_child(message_label)
	last_signature = str(corpse.corpse_inventory)

func take_item(item_id: String, amount: int) -> void:
	var moved: int = game.take_corpse_item(corpse, item_id, amount)
	message = "已拿取 %d 件%s%s" % [moved, Catalog.item(item_id).name, "，背包容量不足" if moved < amount else ""]
	rebuild()

func take_all() -> void:
	var moved := 0
	for item_id: String in Catalog.ITEMS:
		moved += game.take_corpse_item(corpse, item_id, 999)
	message = "已拿取 %d 件物品；装不下的物品仍留在尸体上" % moved
	rebuild()

func make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e4e9e5"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func make_button(text: String, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("25332e")
	normal.border_color = Color("60736a")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3a4b43")
	hover.border_color = Color("e0c96f")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("eef0eb"))
	button.add_theme_color_override("font_disabled_color", Color("7d8882"))
	return button
