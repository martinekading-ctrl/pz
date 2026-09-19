extends ColorRect

const Catalog = preload("res://scripts/item_catalog.gd")
const Rules = preload("res://scripts/crafting_rules.gd")
const Backpack = preload("res://scripts/backpack.gd")

var game: Node2D
var target_building: Node2D
var target_window := -1
var content: MarginContainer
var message := "制作会消耗材料，工具会保留。"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("0d1217f5")
	mouse_filter = Control.MOUSE_FILTER_STOP
	rebuild()

func label(parent: Node,text_value: String,size_value := 18,color_value := Color("d3dcd9")) -> Label:
	var node := Label.new()
	node.text = text_value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size_value)
	node.add_theme_color_override("font_color",color_value)
	parent.add_child(node)
	return node

func button(parent: Node,text_value: String,callback: Callable,disabled := false) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size = Vector2(154,46)
	node.disabled = disabled
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202c32")
	style.border_color = Color("49615f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	node.add_theme_stylebox_override("normal",style)
	node.add_theme_stylebox_override("disabled",style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.border_color = Color("dfbd69")
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("focus",hover)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func rebuild() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		content.add_theme_constant_override("margin_"+edge,32)
	add_child(content)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	content.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	label(top,"制作与加固  /  CRAFTING",27).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(top,"关闭  K / Esc",game.close_crafting)
	var capacity := label(column,"随身背包  %.1f / %.0f kg   ·   %d / %d 格" % [Backpack.weight(game.inventory),Backpack.MAX_WEIGHT,Backpack.slots(game.inventory),Backpack.MAX_SLOTS],17,Color("aebdb6"))
	capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var recipe_column := VBoxContainer.new()
	recipe_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(recipe_column)
	label(recipe_column,"基础制作",23,Color("e5c77d"))
	for recipe_id: String in Rules.RECIPES:
		var recipe: Dictionary = Rules.RECIPES[recipe_id]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation",5)
		recipe_column.add_child(card)
		label(card,str(recipe.name),21)
		label(card,str(recipe.description),15,Color("aebdb6"))
		label(card,"材料："+Rules.item_list(recipe.inputs)+"   →   "+Rules.item_list(recipe.outputs),16)
		var allowed := Rules.has_items(game.inventory,recipe.inputs) and Rules.can_fit_result(game.inventory,recipe.inputs,recipe.outputs)
		button(card,"制作",craft.bind(recipe_id),not allowed)
		var separator := HSeparator.new()
		recipe_column.add_child(separator)
	var barricade_column := VBoxContainer.new()
	barricade_column.custom_minimum_size.x = 410
	body.add_child(barricade_column)
	label(barricade_column,"窗户路障",23,Color("e5c77d"))
	if valid_window_target():
		var layers: int = target_building.barricade_layers(target_window)
		var state: String=target_building.window_state(target_window)
		var state_label: String={"closed":"关闭","open":"打开","broken":"玻璃破碎"}.get(state,state)
		label(barricade_column,str(target_building.window_title(target_window))+"   %s · 加固 %d / %d 层" % [state_label,layers,Rules.MAX_BARRICADE_LAYERS],21)
		button(barricade_column,"打开窗户" if state=="closed" else "关闭窗户",toggle_window,layers>0 or state=="broken")
		button(barricade_column,"翻越碎窗（可能划伤）" if state=="broken" else "翻越窗户",climb_window,layers>0 or state=="closed")
		label(barricade_column,"每层材料："+Rules.item_list(Rules.BARRICADE_COST),16)
		label(barricade_column,"工具：木工锤（保留）",16,Color("aebdb6"))
		var build_check: Dictionary = Rules.can_build_barricade(game.inventory)
		button(barricade_column,"钉上一层木板",build_layer,layers >= Rules.MAX_BARRICADE_LAYERS or not bool(build_check.ok))
		var remove_check: Dictionary = Rules.can_remove_barricade(game.inventory)
		button(barricade_column,"拆下一层并回收",remove_layer,layers <= 0 or not bool(remove_check.ok))
		var needs_repair:=false
		if layers>0:
			needs_repair=float(target_building.windows[target_window].layer_hp[layers-1])<target_building.BARRICADE_LAYER_HP
		button(barricade_column,"维修外层木板（1 钉子）",repair_layer,not needs_repair)
		label(barricade_column,"拆除每层回收："+Rules.item_list(Rules.RECOVERED_MATERIALS),15,Color("aebdb6"))
	else:
		label(barricade_column,"靠近住宅窗户后按 E，可在这里施工。",18)
		label(barricade_column,"窗框会微微变成金色，表示当前可交互。",15,Color("aebdb6"))
	label(column,message,18,Color("e7cf91"))
	label(column,"制作和背包页面不会暂停世界；附近的僵尸仍会移动并攻击。",15,Color("c47d72"))

func valid_window_target() -> bool:
	return is_instance_valid(target_building) and target_window >= 0 and target_window < target_building.windows.size()

func craft(recipe_id: String) -> void:
	var result: Dictionary = game.craft_recipe(recipe_id)
	message = str(result.message)
	rebuild()

func build_layer() -> void:
	var result: Dictionary = game.build_window_barricade(target_building,target_window)
	message = str(result.message)
	rebuild()

func remove_layer() -> void:
	var result: Dictionary = game.remove_window_barricade(target_building,target_window)
	message = str(result.message)
	rebuild()

func toggle_window() -> void:
	var result: Dictionary=game.toggle_target_window(target_building,target_window)
	message=str(result.message)
	rebuild()

func climb_window() -> void:
	var result: Dictionary=game.climb_target_window(target_building,target_window)
	if not bool(result.ok):
		message=str(result.message)
		rebuild()

func repair_layer() -> void:
	var result: Dictionary=game.repair_window_barricade(target_building,target_window)
	message=str(result.message)
	rebuild()
