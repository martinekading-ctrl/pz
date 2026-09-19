extends Control

var game: Node2D
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
		text(Vector2(98, 415), "前往便利店，收集补给与维修零件，", 18, muted)
		text(Vector2(98, 445), "然后返回街边的无线电安全点。", 18, muted)
		text(Vector2(98, 493), "感染者会被奔跑声吸引。", 17, gold)
		text(Vector2(98, 521), "保持体力，别让自己被包围。", 17, muted)
		panel(Rect2(98, 568, 390, 61), Color("a9bd91"), Color("a9bd91"))
		text(Vector2(183, 608), "开始探索   ↵", 24, Color("1d3027"))
		panel(Rect2(98, 644, 390, 48))
		text(Vector2(204, 675), "读取存档  F9", 18, muted)
		text(Vector2(98, 746), "WASD 移动   ·   鼠标瞄准   ·   E 搜索", 15, muted)
		text(Vector2(98, 776), "2.5D 等距生存   /   模块化住宅 0.8", 14, muted)
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
	text(Vector2(38, 292), "● " + ("奔跑 · 声响较大" if game.running else ("潜行 · 声响较小" if game.crouching else game.District.LABELS[game.current_zone])), 15, gold if game.running else muted)
	var direction: Vector2 = game.guide_point()-game.player.position
	var bearing: String = ("右" if direction.x > 20 else ("左" if direction.x < -20 else ""))+("下" if direction.y > 20 else ("上" if direction.y < -20 else ""))
	panel(Rect2(430,28,570,47))
	text(Vector2(448,58),"目标："+game.District.LABELS[game.map_marker]+" · 方位"+bearing+"（可自由绕行）",17,gold)
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
	panel(Rect2(1085, 124, 325, 207))
	text(Vector2(1105, 157), "01   /   让信号再次响起", 18, gold)
	var names := ["收集罐头", "收集饮用水", "找到无线电零件"]
	for i in 3:
		var count: int = game.collected[["food", "water", "parts"][i]]
		text(Vector2(1107, 192 + i * 29), ("✓  " if count >= 2 else "○  ") + names[i], 16, green if count >= 2 else ink)
		text(Vector2(1355, 192 + i * 29), "%d/2" % mini(2, count), 16, muted)
	text(Vector2(1107,282),("✓  " if game.visited.store else "○  ")+"探索青叶便利店",16,green if game.visited.store else ink)
	panel(Rect2(28,595,230,202))
	text(Vector2(46,623),"区域路线 · M 展开",14,gold)
	var nodes := [Vector2(65,676),Vector2(140,676),Vector2(218,662),Vector2(218,725)]
	for edge in [[0,1],[1,2],[1,3],[2,3]]: draw_line(nodes[edge[0]],nodes[edge[1]],Color("53664f"),2,true)
	for i in 4:
		var zone: String = game.District.ZONES[i]
		draw_circle(nodes[i],7,green if game.visited[zone] else Color("4a5147"))
		if zone == game.current_zone: draw_arc(nodes[i],12,0,TAU,24,ink,2,true)
		if zone == game.map_marker: draw_arc(nodes[i],17,0,TAU,24,gold,1,true)
		text(nodes[i]+Vector2(-21,28),["营地","路口","商店","后巷"][i],12,muted)
	text(Vector2(44,780),"白圈 当前位置   金圈 目标",12,muted)
	# Contextual interaction above the survivor.
	# Nearby usable furniture has a faint halo; no floating markers or filled tint.
	for i in game.containers.size():
		if not game.can_search(i) or (game.containers[i].searched and game.remaining_count(i) == 0): continue
		var furniture: Dictionary = game.containers[i]
		var points := PackedVector2Array()
		for vertex in furniture.outline: points.append(game.screen_point(vertex)*Vector2(1440,900)/s)
		if points.size() < 3: continue
		points.append(points[0])
		var pulse := 0.85+sin(game.elapsed*2.4)*0.15
		draw_polyline(points,Color(0.88,0.86,0.65,0.035*pulse),9,true)
		draw_polyline(points,Color(0.88,0.86,0.65,0.065*pulse),5,true)
		draw_polyline(points,Color(0.91,0.9,0.73,0.40*pulse),1.3,true)
	for enemy in game.enemies:
		if enemy.dead or not enemy.chasing or enemy.position.distance_to(game.player.position) > 230: continue
		var ep: Vector2 = game.screen_point(enemy.position + Vector2(0, -100)) * Vector2(1440, 900) / s
		draw_rect(Rect2(ep.x - 20, ep.y, 40, 4), Color("303c31"))
		draw_rect(Rect2(ep.x - 20, ep.y, 40 * maxf(0, enemy.hp) / 100, 4), Color("c77a60"))
	var door_index: int = game.world.yard.nearest()
	if door_index >= 0:
		var door: Dictionary = game.world.yard.doors[door_index]
		panel(Rect2(435,680,550,45))
		text(Vector2(454,710),door.title+" · E "+("关闭" if door.open else "打开"),20,gold)
	if game.nearest >= 0:
		var c: Dictionary = game.containers[game.nearest]
		var p: Vector2 = game.screen_point(c.marker_position + Vector2(0, -35)) * Vector2(1440, 900) / s
		p.x = clampf(p.x,130,1000)
		p.y = clampf(p.y,140,680)
		panel(Rect2(p.x - 122, p.y - 44, 244, 78))
		text(Vector2(p.x - 105, p.y - 16), c.title, 20, gold if not c.searched else green)
		var caption := ("已搜空 · 点击查看" if game.remaining_count(game.nearest) == 0 else "还有物品 · 点击 / E 查看") if c.searched else "点击家具 / 按住 E 搜索"
		if game.search_progress > 0: caption = "正在翻找… %d%%" % int(game.search_progress/c.duration*100)
		text(Vector2(p.x - 105, p.y + 12), caption, 15, muted if c.searched else ink)
		if game.search_progress > 0:
			draw_rect(Rect2(p.x - 121,p.y + 28,242,5),Color("354033"))
			draw_rect(Rect2(p.x - 121,p.y + 28,242 * game.search_progress/c.duration,5),gold)
	if game.player.position.distance_to(game.safe_point) < 65:
		panel(Rect2(450, 708, 550, 44))
		text(Vector2(475, 737), "安全点  /  集齐补给与零件后，按 E 修复无线电", 17, green)
	panel(Rect2(280, 818, 1130, 56))
	text(Vector2(302, 852), "WASD 移动    Shift 奔跑    C 潜行    左键 / 空格 攻击    E 互动    M 地图    Tab 背包", 17)
	text(Vector2(1182, 852), "Esc 暂停", 16, muted)
	if game.notice_time > 0: toast()
	if game.mode == "map": district_map()
	if game.mode == "loot": loot_page()
	if game.hit_time > 0: draw_rect(Rect2(0, 0, 1440, 900), Color(0.65, 0.13, 0.06, game.hit_time * 0.35))
	if game.mode == "pause": pause_screen()
	if game.mode in ["dead", "win"]: end_screen()

func map_point(p: Vector2) -> Vector2:
	return Vector2(42 + p.x * 0.131, 638 + p.y * 0.125)

func loot_page() -> void:
	var c: Dictionary = game.containers[game.loot_container]
	draw_rect(Rect2(0,0,1440,900),Color(0.025,0.04,0.035,0.76))
	panel(Rect2(390,184,660,534),Color("142019"),Color("60735a"))
	text(Vector2(424,228),c.title,29,gold)
	text(Vector2(424,263),"搜索完成 · 选择你要带走的物品",18)
	draw_line(Vector2(424,283),Vector2(1016,283),Color("3b4a39"))
	var row := 0
	for key in c.loot:
		var y := 305+row*88
		var count: int = c.remaining[key]
		panel(Rect2(418,y,604,74),Color("1d2b21"))
		panel(Rect2(432,y+16,40,40),Color("344437"))
		text(Vector2(442,y+45),{"food":"罐","water":"水","bandage":"绷","parts":"件"}[key],20,gold)
		text(Vector2(489,y+29),game.item_name(key),21,ink if count > 0 else muted)
		text(Vector2(489,y+54),"容器中 ×%d    背包 ×%d" % [count,game.inventory[key]],15,muted)
		if count > 0:
			panel(Rect2(814,y+18,82,38),Color("91a67c"))
			text(Vector2(835,y+44),"拿取",18,Color("18261c"))
			var left: bool = game.loot_decisions.get(key,"") == "left"
			panel(Rect2(906,y+18,100,38),Color("253629"),green if left else Color("4e6149"))
			text(Vector2(922,y+44),"已留下" if left else "留下",18,green if left else muted)
		else:
			text(Vector2(880,y+44),"已拿取" if game.loot_decisions.get(key,"") == "taken" else "已取空",18,green)
		row += 1
	text(Vector2(424,614),"挑选时游戏暂停。没拿的物品留在这里，下次还能取。",16,muted)
	panel(Rect2(424,645,592,46),Color("334a36"),Color("78916b"))
	text(Vector2(616,676),"完成 · 返回游戏",20)

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
		text(Vector2(512, 451), "暂停时也可使用存档快捷键。", 17, muted)
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
	if game.mode == "map":
		get_viewport().set_input_as_handled()
		game.block_attack_until_release = true
		for i in 4:
			if map_card(i).has_point(p): game.map_marker = game.District.ZONES[i]
		if Rect2(520,695,400,48).has_point(p): game.mode = "play"
		return
	if game.mode == "loot":
		get_viewport().set_input_as_handled()
		if Rect2(424,645,592,46).has_point(p):
			game.close_loot()
			return
		var keys: Array = game.containers[game.loot_container].loot.keys()
		for i in keys.size():
			var y := 305+i*88
			if Rect2(814,y+18,82,38).has_point(p): game.take_item(keys[i])
			if Rect2(906,y+18,100,38).has_point(p): game.leave_item(keys[i])
		return

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


func map_card(i: int) -> Rect2:
	return [Rect2(210,360,240,125),Rect2(590,360,240,125),Rect2(990,240,240,125),Rect2(990,500,240,125)][i]

func district_map() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(0.025,0.04,0.035,0.94))
	text(Vector2(180,150),"柳杉路街区",38,gold)
	text(Vector2(180,193),"点击区域标记目标 · 沿道路直接行走 · 未探索区域只显示路线",18,muted)
	for edge in [[0,1],[1,2],[1,3],[2,3]]:
		draw_line(map_card(edge[0]).get_center(),map_card(edge[1]).get_center(),Color("657357"),3,true)
	for i in 4:
		var zone: String = game.District.ZONES[i]
		var card := map_card(i)
		panel(card,Color("25372a") if game.visited[zone] else Color("18221b"),gold if zone == game.map_marker else Color("526149"))
		text(card.position+Vector2(18,37),game.District.LABELS[zone],23,ink if game.visited[zone] else muted)
		text(card.position+Vector2(18,70),"你在这里" if zone == game.current_zone else ("已探索" if game.visited[zone] else "尚未探索"),17,green)
		text(card.position+Vector2(18,102),["无线电营地 · 交付补给","街道交汇 · 注意感染者","食品 / 饮水 / 零件","绕行路线 · 仓储物资"][i] if game.visited[zone] else "抵达后揭示区域详情",14,muted)
	text(Vector2(180,669),"当前目标："+game.District.LABELS[game.map_marker]+"。地图暂停游戏，标记不会传送角色。",18,gold)
	panel(Rect2(520,695,400,48),Color("334a36"))
	text(Vector2(613,727),"返回游戏 · M / Esc",20)
