extends ColorRect

const SettingsStore = preload("res://scripts/settings_store.gd")
const CharacterRules = preload("res://scripts/character_rules.gd")

var game: Node2D
var screen_stack: Array[String] = ["main"]
var pending_slot := -1
var content: Control
var focus_candidates: Array[Button] = []
var settings: Dictionary
var selected_profession := "survivor"
var selected_traits: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("07100edb")
	mouse_filter = Control.MOUSE_FILTER_STOP
	settings = SettingsStore.load_values()
	rebuild()

func current_screen() -> String:
	return screen_stack.back()

func push_screen(screen: String) -> void:
	screen_stack.append(screen)
	rebuild()

func pop_screen() -> void:
	if screen_stack.size() > 1:
		screen_stack.pop_back()
		rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back") and screen_stack.size() > 1:
		pop_screen()
		get_viewport().set_input_as_handled()

func rebuild() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	focus_candidates.clear()
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]:
		content.add_theme_constant_override("margin_"+edge,28)
	add_child(content)
	var center := CenterContainer.new()
	content.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(850,600)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("101b18f4")
	panel_style.border_color = Color("718179")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel",panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	margin.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var brand := make_label("余烬街区",38,Color("f0e8d0"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(brand)
	var version := make_label("0.33.3  人形角色修正",17,Color("b7c7be"))
	version.custom_minimum_size.x = 190
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(version)
	var line := HSeparator.new()
	column.add_child(line)
	match current_screen():
		"main": build_main(column)
		"new_slots": build_slots(column,true)
		"manage_slots": build_slots(column,false)
		"settings": build_settings(column)
		"tutorial": build_tutorial(column)
		"confirm_new": build_confirm(column,true)
		"confirm_delete": build_confirm(column,false)
		"character": build_character(column)
	if not focus_candidates.is_empty():
		call_deferred("focus_first")

func focus_first() -> void:
	if not focus_candidates.is_empty() and is_instance_valid(focus_candidates[0]) and focus_candidates[0].is_inside_tree():
		focus_candidates[0].grab_focus()

func build_main(parent: VBoxContainer) -> void:
	parent.add_child(make_label("一座没有传送门的连续小镇。搜集、求生、加固你的落脚点。",18,Color("b9c6bf")))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	parent.add_child(spacer)
	var latest: int = game.latest_save_slot()
	make_button(parent,"继续游戏"+("  ·  槽位 %d" % latest if latest > 0 else ""),game.continue_slot.bind(latest),latest <= 0)
	make_button(parent,"新游戏",push_screen.bind("new_slots"))
	make_button(parent,"存档槽",push_screen.bind("manage_slots"))
	make_button(parent,"设置",push_screen.bind("settings"))
	make_button(parent,"操作教程",push_screen.bind("tutorial"))
	make_button(parent,"退出游戏",game.quit_from_shell)
	var info := make_label("单人离线 · 安全屋自动保存 · F5 手动保存 · F9 读取最近进度",15,Color("879890"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(info)

func build_slots(parent: VBoxContainer,new_game: bool) -> void:
	parent.add_child(make_label("选择新游戏槽位" if new_game else "管理本地存档",26,Color("e7c979")))
	parent.add_child(make_label("每个槽位独立保存世界、角色、容器、僵尸和窗户路障。",16,Color("aebdb6")))
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation",12)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(cards)
	for slot in range(1,4):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		cards.add_child(row)
		var summary: Dictionary = game.save_slot_summary(slot)
		var text: String = "槽位 %d\n%s" % [slot,str(summary.text)]
		var label: Label = make_label(text,18,Color("d8e0dc"))
		label.custom_minimum_size = Vector2(470,66)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if new_game:
			make_button(row,"开始" if not bool(summary.exists) else "覆盖",start_or_confirm.bind(slot,bool(summary.exists)))
		else:
			make_button(row,"继续",game.continue_slot.bind(slot),not bool(summary.exists),Vector2(120,54))
			make_button(row,"删除",confirm_delete.bind(slot),not bool(summary.exists),Vector2(120,54))
	make_button(parent,"返回",pop_screen)

func start_or_confirm(slot: int,occupied: bool) -> void:
	if occupied:
		pending_slot = slot
		push_screen("confirm_new")
	else:
		begin_character_creation(slot)

func begin_character_creation(slot: int) -> void:
	pending_slot=slot
	selected_profession="survivor"
	selected_traits.clear()
	push_screen("character")

func confirm_delete(slot: int) -> void:
	pending_slot = slot
	push_screen("confirm_delete")

func build_confirm(parent: VBoxContainer,overwrite: bool) -> void:
	var action: String = "覆盖" if overwrite else "删除"
	parent.add_child(make_label("确认%s槽位 %d？" % [action,pending_slot],30,Color("e7c979")))
	parent.add_child(make_label(("原有进度会被新游戏替换。" if overwrite else "该槽位的主存档与备份都会删除。")+"此操作无法从游戏内撤销。",18,Color("cf8278")))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	make_button(parent,"确认"+action,begin_character_creation.bind(pending_slot) if overwrite else perform_delete)
	make_button(parent,"取消",pop_screen)

func build_character(parent: VBoxContainer) -> void:
	parent.add_child(make_label("创建幸存者",28,Color("e7c979")))
	parent.add_child(make_label("职业决定初始专长与物资；负面特质返还点数。未使用点数可以保留。",15,Color("aebdb6")))
	var profile:={"profession":selected_profession,"traits":selected_traits}
	var profession_grid:=GridContainer.new()
	profession_grid.columns=2
	profession_grid.add_theme_constant_override("h_separation",10)
	profession_grid.add_theme_constant_override("v_separation",7)
	parent.add_child(profession_grid)
	for profession_id: String in CharacterRules.PROFESSION_ORDER:
		var data: Dictionary=CharacterRules.PROFESSIONS[profession_id]
		var label_text:="%s  ·  %d 点\n%s" % [data.name,int(data.points),data.desc]
		var button:=make_button(profession_grid,label_text,select_profession.bind(profession_id),false,Vector2(375,66))
		button.add_theme_font_size_override("font_size",16)
		if profession_id==selected_profession:
			button.add_theme_color_override("font_color",Color("f1cd70"))
	parent.add_child(make_label("特质",20,Color("e7c979")))
	var trait_grid:=GridContainer.new()
	trait_grid.columns=2
	trait_grid.add_theme_constant_override("h_separation",12)
	trait_grid.add_theme_constant_override("v_separation",5)
	parent.add_child(trait_grid)
	for trait_id: String in CharacterRules.TRAIT_ORDER:
		var data: Dictionary=CharacterRules.TRAITS[trait_id]
		var check:=CheckButton.new()
		check.text="%s  %s%d 点  ·  %s" % [data.name,"-" if int(data.cost)>0 else "+",absi(int(data.cost)),data.desc]
		check.custom_minimum_size=Vector2(375,46)
		check.add_theme_font_size_override("font_size",15)
		check.button_pressed=trait_id in selected_traits
		check.toggled.connect(toggle_trait.bind(trait_id))
		trait_grid.add_child(check)
		focus_candidates.append(check)
	var remaining:=CharacterRules.points_remaining(profile)
	var summary:=make_label("剩余点数：%d   ·   %s" % [remaining,CharacterRules.summary(profile)],17,Color("9ed7ab") if remaining>=0 else Color("e4776e"))
	summary.size_flags_vertical=Control.SIZE_EXPAND_FILL
	summary.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(summary)
	var action_row:=HBoxContainer.new()
	action_row.add_theme_constant_override("separation",12)
	parent.add_child(action_row)
	make_button(action_row,"返回槽位",cancel_character_creation,false,Vector2(230,48))
	make_button(action_row,"开始游戏",finish_character_creation,remaining<0,Vector2(480,48))

func select_profession(profession_id: String) -> void:
	selected_profession=profession_id
	rebuild()

func toggle_trait(enabled: bool,trait_id: String) -> void:
	if enabled and trait_id not in selected_traits:
		selected_traits.append(trait_id)
	elif not enabled:
		selected_traits.erase(trait_id)
	rebuild()

func cancel_character_creation() -> void:
	pending_slot=-1
	selected_traits.clear()
	screen_stack=["main","new_slots"]
	rebuild()

func finish_character_creation() -> void:
	var profile:={"profession":selected_profession,"traits":selected_traits.duplicate()}
	if pending_slot<1 or CharacterRules.points_remaining(profile)<0:
		return
	game.start_new_game(pending_slot,profile)

func perform_delete() -> void:
	game.delete_save_slot(pending_slot)
	pending_slot = -1
	screen_stack = ["main","manage_slots"]
	rebuild()

func build_settings(parent: VBoxContainer) -> void:
	parent.add_child(make_label("设置",28,Color("e7c979")))
	parent.add_child(make_label("音量与显示设置立即生效，并独立于存档保存。",16,Color("aebdb6")))
	make_slider(parent,"主音量",float(settings.master_volume),set_volume.bind("master_volume"))
	make_slider(parent,"音效音量",float(settings.sfx_volume),set_volume.bind("sfx_volume"))
	if not OS.has_feature("mobile"):
		var fullscreen := CheckButton.new()
		fullscreen.text = "全屏显示"
		fullscreen.button_pressed = bool(settings.fullscreen)
		fullscreen.add_theme_font_size_override("font_size",18)
		fullscreen.toggled.connect(set_fullscreen)
		parent.add_child(fullscreen)
		focus_candidates.append(fullscreen)
	parent.add_child(make_label("手机按钮布局",19))
	var layouts := HBoxContainer.new()
	layouts.add_theme_constant_override("separation",10)
	parent.add_child(layouts)
	for data in [["standard","标准"],["compact","紧凑"],["mirrored","左右互换"]]:
		var button: Button = make_button(layouts,str(data[1]),set_mobile_layout.bind(str(data[0])),false,Vector2(170,48))
		if str(settings.mobile_layout) == str(data[0]):
			button.add_theme_color_override("font_color",Color("f1cd70"))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	make_button(parent,"返回",pop_screen)

func make_slider(parent: VBoxContainer,title: String,value: float,callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	parent.add_child(row)
	var title_label: Label = make_label(title,18)
	title_label.custom_minimum_size.x = 130
	row.add_child(title_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(value*100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)
	var amount: Label = make_label("%d%%" % roundi(slider.value),17,Color("b7c7be"))
	amount.custom_minimum_size.x = 58
	row.add_child(amount)
	slider.value_changed.connect(func(new_value: float): amount.text = "%d%%" % roundi(new_value))

func set_volume(value: float,key: String) -> void:
	settings[key] = value/100.0
	commit_settings()

func set_fullscreen(value: bool) -> void:
	settings.fullscreen = value
	commit_settings()

func set_mobile_layout(layout: String) -> void:
	settings.mobile_layout = layout
	commit_settings()
	rebuild()

func commit_settings() -> void:
	settings = SettingsStore.apply(settings,true)
	SettingsStore.save_values(settings)
	if is_instance_valid(game.mobile_controls):
		game.mobile_controls.apply_layout_preset(str(settings.mobile_layout),false)

func build_tutorial(parent: VBoxContainer) -> void:
	parent.add_child(make_label("操作教程",28,Color("e7c979")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var text := make_label("""
移动与潜行
WASD 或左摇杆移动；Shift 奔跑；C 蹲伏。奔跑更快，但消耗体力并制造更远的声音。

战斗
鼠标右键瞄准、左键攻击；手机端拖动右摇杆瞄准，松开攻击。Q 切换武器，R 给手枪装填。

搜索与背包
靠近发光家具按 E 搜索。住宅、商店、浴室和仓储有不同物资；面包会变质。Tab/B 打开背包；搜索页和背包不会暂停世界。

医疗与维修
点击左上状态卡处理身体伤口。消毒剂处理选中感染，抗生素降低全身感染；强力胶带可修补当前装备的受损武器。

服装与防护
背包中选择服装即可穿戴。头部、上身、腿部和脚部装备会降低对应伤口概率，承受攻击后逐渐磨损。

供水与供电
厨房和浴室水龙头可直接饮水或灌装空瓶。供水与供电会按世界时间中断；停电后冰箱停止制冷，夜间室内会明显变暗。

制作与封窗
K 或手机“制作”按钮打开制作页。靠近住宅窗户按 E，可使用木板、钉子和木工锤加固。

生存与存档
留意生命、饱食、水分、体力与伤病。清理住宅后可在床边设为安全屋；睡醒、进入安全屋或退出时自动保存。F5 手动保存，F9 读取最近进度。
""",18,Color("d0d9d4"))
	text.custom_minimum_size.x = 740
	scroll.add_child(text)
	make_button(parent,"返回",pop_screen)

func make_label(text_value: String,font_size: int,color_value := Color("edf1ee")) -> Label:
	var node := Label.new()
	node.text = text_value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color_value)
	return node

func make_button(parent: Node,text_value: String,callback: Callable,disabled := false,minimum := Vector2(360,46)) -> Button:
	var node := Button.new()
	node.text = text_value
	node.disabled = disabled
	node.custom_minimum_size = minimum
	node.add_theme_font_size_override("font_size",19)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("22302b")
	normal.border_color = Color("60756c")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	node.add_theme_stylebox_override("normal",normal)
	node.add_theme_stylebox_override("disabled",normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("35473f")
	hover.border_color = Color("e2c66f")
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",hover)
	node.add_theme_stylebox_override("focus",hover)
	node.pressed.connect(callback)
	parent.add_child(node)
	if not disabled:
		focus_candidates.append(node)
	return node
