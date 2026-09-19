extends Control

var game: Node3D
var font = preload("res://art/NotoSansSC-Regular.otf")
var ink := Color("e2e4d6")
var muted := Color("a1ac9e")
var gold := Color("dbbc7f")
var green := Color("9bbe9b")
var dark := Color(0.055, 0.08, 0.073, 0.92)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func text(at: Vector2, words: String, size := 18, color := Color("e2e4d6")) -> void:
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2, color := Color(0.055, 0.08, 0.073, 0.92), border := Color(0.6, 0.65, 0.55, 0.25)) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	draw_style_box(style, rect)

func _draw() -> void:
	var s := get_viewport_rect().size
	draw_set_transform(Vector2.ZERO, 0, s / Vector2(1440, 900))
	if game.mode == "title":
		draw_rect(Rect2(0, 0, 1440, 900), Color(0.04, 0.07, 0.06, 0.22))
		panel(Rect2(62, 76, 464, 746), Color(0.045, 0.07, 0.06, 0.94))
		draw_rect(Rect2(94, 117, 36, 3), gold)
		text(Vector2(143, 125), "A S H   D I S T R I C T", 16, gold)
		text(Vector2(94, 224), "余烬街区", 57)
		text(Vector2(98, 261), "在寂静里，带着希望活下去。", 19, muted)
		draw_line(Vector2(98, 298), Vector2(488, 298), Color("3a493d"))
		text(Vector2(98, 337), "第 03 天  /  柳杉路", 17, gold)
		text(Vector2(98, 380), "无线电已经沉默了两天。", 20)
		text(Vector2(98, 415), "搜索住宅，收集补给与维修零件，", 18, muted)
		text(Vector2(98, 445), "然后返回街边的无线电安全点。", 18, muted)
		text(Vector2(98, 493), "感染者会被奔跑声吸引。", 17, gold)
		text(Vector2(98, 521), "保持体力，别让自己被包围。", 17, muted)
		panel(Rect2(98, 568, 390, 61), Color("a9bd91"), Color("a9bd91"))
		text(Vector2(183, 608), "开始探索   ↵", 24, Color("1d3027"))
		panel(Rect2(98, 644, 390, 48))
		text(Vector2(204, 675), "读取存档  F9", 18, muted)
		text(Vector2(98, 746), "WASD 移动   ·   鼠标瞄准   ·   E 搜索", 15, muted)
		text(Vector2(98, 776), "单人探索   /   可玩原型 0.1", 14, muted)
		text(Vector2(1120, 852), "CEDAR LANE  /  07", 17, gold)
		if game.notice_time > 0: toast()
		return
	# Top identity strip and survival telemetry.
	panel(Rect2(28, 26, 300, 57))
	text(Vector2(47, 62), "第 3 天", 22)
	var minutes := 8 * 60 + 20 + int(game.elapsed / 4)
	text(Vector2(160, 62), "%02d:%02d" % [(minutes / 60) % 24, minutes % 60], 23, gold)
	draw_circle(Vector2(299, 53), 7, gold)
	panel(Rect2(28, 93, 300, 172))
	var values := [game.health, game.hunger, game.thirst, game.stamina]
	var labels := ["生命", "饥饿", "口渴", "体力"]
	var colors := [Color("c87969"), Color("c2a664"), Color("77aeb6"), Color("9cbb86")]
	for i in 4:
		var y := 122 + i * 38
		text(Vector2(46, y), labels[i], 15, muted)
		draw_rect(Rect2(95, y - 13, 160, 11), Color("2a382f"))
		draw_rect(Rect2(95, y - 13, 160 * values[i] / 100, 11), colors[i])
		text(Vector2(269, y), "%d" % int(values[i]), 16, colors[i])
	text(Vector2(38, 292), "● " + ("奔跑 · 声响较大" if game.running else ("潜行 · 声响较小" if game.crouching else "柳杉路 · 住宅区")), 15, gold if game.running else muted)
	# Inventory hotkeys, each with a hand-drawn item silhouette.
	for i in 4:
		var x := 1058 + i * 88
		panel(Rect2(x, 26, 78, 76), dark, gold if i == 0 else Color("475246"))
		text(Vector2(x + 8, 45), ["武器", "1", "2", "3"][i], 12, muted)
		if i == 0:
			draw_line(Vector2(x + 29, 83), Vector2(x + 51, 47), Color("c2967c"), 4, true)
			draw_arc(Vector2(x + 53, 47), 5, PI, TAU + 0.4, 12, Color("c2967c"), 3, true)
		elif i == 1:
			draw_rect(Rect2(x + 30, 49, 22, 30), Color("9a6651"))
			draw_line(Vector2(x + 30, 50), Vector2(x + 52, 50), ink, 3)
			draw_line(Vector2(x + 32, 62), Vector2(x + 50, 62), gold, 7)
		elif i == 2:
			draw_rect(Rect2(x + 32, 52, 18, 30), Color("7babb1"))
			draw_rect(Rect2(x + 36, 46, 10, 6), Color("c6d2c7"))
		else:
			draw_rect(Rect2(x + 28, 50, 27, 30), Color("c8c9ae"))
			draw_line(Vector2(x + 35, 65), Vector2(x + 49, 65), Color("996852"), 4)
			draw_line(Vector2(x + 42, 58), Vector2(x + 42, 72), Color("996852"), 4)
		if i > 0: text(Vector2(x + 59, 91), str(game.inventory[["food", "water", "bandage"][i - 1]]), 16)
	# Objective card.
	panel(Rect2(1085, 124, 325, 173))
	text(Vector2(1105, 157), "01   /   让信号再次响起", 18, gold)
	var names := ["收集罐头", "收集饮用水", "找到无线电零件"]
	for i in 3:
		var count: int = game.collected[["food", "water", "parts"][i]]
		text(Vector2(1107, 192 + i * 29), ("✓  " if count >= 2 else "○  ") + names[i], 16, green if count >= 2 else ink)
		text(Vector2(1355, 192 + i * 29), "%d/2" % mini(2, count), 16, muted)
	# Lower corner map, matching the actual street coordinates.
	panel(Rect2(28, 595, 230, 202))
	text(Vector2(46, 623), "街区地图", 14, muted)
	text(Vector2(213, 623), "N", 13, gold)
	draw_rect(Rect2(42, 714, 201, 28), Color("47524a"))
	draw_rect(Rect2(132, 642, 48, 54), Color("89937b"))
	for c in game.containers:
		if not c.searched: draw_circle(map_point(c.node.position), 3, gold)
	draw_circle(map_point(Vector3(-6.5, 0, 1.7)), 5, green)
	draw_circle(map_point(game.player.position), 4, Color("f0eedb"))
	for enemy in game.enemies:
		if not enemy.dead and enemy.chasing: draw_circle(map_point(enemy.position), 3, Color("c27e65"))
	text(Vector2(44, 780), "● 你    ● 安全点    ◇ 补给", 12, muted)
	# Contextual interaction above the survivor.
	for enemy in game.enemies:
		if enemy.dead or not enemy.chasing or enemy.position.distance_to(game.player.position) > 7: continue
		var ep: Vector2 = game.camera.unproject_position(enemy.position + Vector3(0, 2.05, 0)) * Vector2(1440, 900) / s
		draw_rect(Rect2(ep.x - 20, ep.y, 40, 4), Color("303c31"))
		draw_rect(Rect2(ep.x - 20, ep.y, 40 * maxf(0, enemy.hp) / 100, 4), Color("c77a60"))
	if game.nearest >= 0:
		var c: Dictionary = game.containers[game.nearest]
		var p: Vector2 = game.camera.unproject_position(c.node.position + Vector3(0, 1.9, 0)) * Vector2(1440, 900) / s
		panel(Rect2(p.x - 108, p.y - 40, 216, 69))
		text(Vector2(p.x - 91, p.y - 13), c.title, 18, gold)
		text(Vector2(p.x - 91, p.y + 12), "按住 E  搜索", 15)
		if game.search_progress > 0: draw_rect(Rect2(p.x - 107, p.y + 25, 214 * game.search_progress / 1.4, 3), gold)
	if game.player.position.distance_to(Vector3(-6.5, 0, 1.7)) < 2:
		panel(Rect2(450, 708, 550, 44))
		text(Vector2(475, 737), "安全点  /  集齐补给与零件后，按 E 修复无线电", 17, green)
	panel(Rect2(280, 818, 1130, 56))
	text(Vector2(302, 852), "WASD 移动    Shift 奔跑    C 潜行    左键 / 空格 攻击    E 搜索    Tab 背包", 17)
	text(Vector2(1182, 852), "Esc 暂停", 16, muted)
	if game.notice_time > 0: toast()
	if game.hit_time > 0: draw_rect(Rect2(0, 0, 1440, 900), Color(0.65, 0.13, 0.06, game.hit_time * 0.35))
	if game.mode == "pause": pause_screen()
	if game.mode in ["dead", "win"]: end_screen()

func map_point(p: Vector3) -> Vector2:
	return Vector2(138 + p.x * 5.8, 687 + p.z * 5.8)

func toast() -> void:
	var width := font.get_string_size(game.notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 48
	panel(Rect2(720 - width / 2, 756, width, 44), Color(0.07, 0.105, 0.085, 0.96))
	text(Vector2(744 - width / 2, 785), game.notice, 17, gold)

func pause_screen() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color(0.025, 0.045, 0.04, 0.65))
	panel(Rect2(470, 222, 500, 465))
	text(Vector2(510, 280), "背包 / INVENTORY" if game.bag else "片刻喘息 / PAUSED", 28, gold)
	if game.bag:
		var keys := ["food", "water", "bandage", "parts"]
		for i in 4:
			text(Vector2(512, 342 + i * 48), game.item_name(keys[i]), 22)
			text(Vector2(866, 342 + i * 48), "× %d" % game.inventory[keys[i]], 22, gold)
		text(Vector2(512, 553), "回到游戏后：1 吃罐头 / 2 喝水 / 3 包扎", 17, muted)
	else:
		text(Vector2(512, 347), "F5   保存当前进度", 22)
		text(Vector2(512, 393), "F9   读取上次存档", 22)
		text(Vector2(512, 451), "回到游戏后使用存档快捷键。", 17, muted)
		text(Vector2(512, 492), "滚轮缩放视角 · 鼠标控制攻击方向", 17, muted)
	panel(Rect2(512, 592, 414, 53), Color("9eaf88"))
	text(Vector2(643, 627), "继续探索  Esc", 21, Color("213528"))

func end_screen() -> void:
	var success: bool = game.mode == "win"
	draw_rect(Rect2(0, 0, 1440, 900), Color(0.025, 0.045, 0.04, 0.78))
	panel(Rect2(425, 245, 590, 406))
	text(Vector2(470, 304), "S I G N A L   R E S T O R E D" if success else "T H E   S T R E E T   R E M A I N S", 17, gold)
	text(Vector2(470, 373), "信号回来了。" if success else "你倒在了街区。", 42)
	text(Vector2(470, 420), "补给已带回，远方终于有人回应。" if success else "每次探索都是一次新的机会。", 20, muted)
	text(Vector2(470, 470), "探索 %d 秒    ·    击退 %d 名感染者" % [int(game.elapsed), game.kills], 18, gold)
	panel(Rect2(470, 538, 500, 58), Color("a9bd91"))
	text(Vector2(615, 576), "重新开始  ↵", 24, Color("213528"))

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	var p: Vector2 = event.position * Vector2(1440, 900) / get_viewport_rect().size
	if game.mode == "title":
		if Rect2(98, 568, 390, 61).has_point(p):
			game.start_game()
			get_viewport().set_input_as_handled()
		elif Rect2(98, 644, 390, 48).has_point(p):
			game.load_game()
			get_viewport().set_input_as_handled()
	elif game.mode == "pause" and Rect2(512, 592, 414, 53).has_point(p):
		game.mode = "play"
		game.bag = false
		get_viewport().set_input_as_handled()
	elif game.mode in ["dead", "win"] and Rect2(470, 538, 500, 58).has_point(p):
		get_tree().reload_current_scene()

