extends Node2D

const Actor = preload("res://scripts/iso/actor.gd")
const World = preload("res://scripts/iso/world.gd")
const HUD = preload("res://scripts/iso/hud.gd")
const PLAYER_SHEET = preload("res://art/isometric/survivor.png")
const ZOMBIE_SHEET = preload("res://art/isometric/infected.png")
const District = preload("res://scripts/iso/district.gd")
var current_zone := "cedar"
var visited := {"cedar":true,"junction":false,"store":false,"alley":false}
var map_marker := "store"
var rng := RandomNumberGenerator.new()
var camera: Camera2D
var depth: Node2D
var nav: AStarGrid2D
var world: RefCounted
var player: CharacterBody2D
var player_frames: Array = []
var zombie_frames: Array = []
var enemies: Array = []
var containers: Array = []
var hud: Control
var safe_point := Vector2.ZERO
var mode := "title"
var health := 100.0
var hunger := 82.0
var thirst := 76.0
var stamina := 100.0
var elapsed := 0.0
var running := false
var crouching := false
var kills := 0
var inventory := {"food":0,"water":0,"bandage":1,"parts":0}
var collected := {"food":0,"water":0,"parts":0}
var nearest := -1
var search_progress := 0.0
var search_target := -1
var clicked_search := false
var search_sound_timer := 0.0
var loot_container := -1
var loot_decisions: Dictionary = {}
var wait_interact_release := false
var block_attack_until_release := false
var notice := ""
var notice_time := 0.0
var hit_time := 0.0
var saved_time := 0.0
var bag := false
var won := false
var ambient: AudioStreamPlayer
var target_zoom := 1.25
var inspect_scene := false
var guide_cache := Vector2.ZERO
var guide_time := 0.0

func _ready() -> void:
	DisplayServer.window_set_title("余烬街区 · 0.8 模块化住宅预览")
	rng.seed = 7219
	setup_input()
	player_frames = split_sheet(PLAYER_SHEET)
	zombie_frames = split_sheet(ZOMBIE_SHEET)
	world = World.new(self)
	world.build()
	player = spawn_actor(Vector2(748,563),false)
	for p in [Vector2(578,600),Vector2(389,471),Vector2(1030,380),Vector2(1069,803),Vector2(301,662),Vector2(941,689)]:
		enemies.append(spawn_actor(p,true))
	for entry in [["junction",Vector2(710,525)],["junction",Vector2(1130,390)],["junction",Vector2(1050,800)],["store",Vector2(1010,335)],["store",Vector2(1220,410)],["store",Vector2(480,510)],["alley",Vector2(1020,440)]]:
		enemies.append(spawn_actor(District.ORIGINS[entry[0]]+entry[1],true))
	camera = Camera2D.new()
	camera.position = Vector2(800,505)
	camera.zoom = Vector2.ONE * 1.04
	add_child(camera)
	camera.make_current()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	canvas.add_child(hud)
	start_ambient()
	if "--smoke-test" in OS.get_cmdline_user_args(): call_deferred("smoke_test")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture")
	if "--yard-test" in OS.get_cmdline_user_args(): call_deferred("yard_test")
	if "--yard-capture" in OS.get_cmdline_user_args(): call_deferred("yard_capture")
	if "--verify-yard-save" in OS.get_cmdline_user_args():
		assert(load_game("user://iso-yard-test.json"))
		assert(world.yard.doors[1].open and can_walk(Vector2(1645,495)))
		print("YARD SAVE PASS: fresh process restores open gate and its navigation state")
		get_tree().quit()
	if "--verify-save" in OS.get_cmdline_user_args(): call_deferred("verify_persistence")
	if "--walk-test" in OS.get_cmdline_user_args(): call_deferred("walk_test")
	if "--search-test" in OS.get_cmdline_user_args(): call_deferred("search_test")
	if "--search-capture" in OS.get_cmdline_user_args(): call_deferred("search_capture")
	if "--verify-choice-save" in OS.get_cmdline_user_args(): call_deferred("verify_choice_save")
	if "--district-test" in OS.get_cmdline_user_args(): call_deferred("district_test")
	if "--district-capture" in OS.get_cmdline_user_args(): call_deferred("district_capture")
	if "--seamless-capture" in OS.get_cmdline_user_args(): call_deferred("seamless_capture")
	if "--seamless-chase-test" in OS.get_cmdline_user_args(): call_deferred("seamless_chase_test")
	if "--verify-seamless-save" in OS.get_cmdline_user_args():
		assert(load_game("user://iso-seamless-test.json"))
		assert(current_zone == "store" and containers[9].remaining.water == 1 and containers[9].remaining.food == 0)
		print("SEAMLESS SAVE PASS: fresh process restores continuous world position and leftover items")
		get_tree().quit()
	if "--district-walk-test" in OS.get_cmdline_user_args(): call_deferred("district_walk_test")
	if "--verify-district-save" in OS.get_cmdline_user_args():
		assert(load_game("user://iso-district-test.json"))
		assert(current_zone == "store" and visited.alley and containers[9].remaining.water == 1)
		print("DISTRICT SAVE PASS: fresh process restores region, discovery, inventory and leftovers")
		get_tree().quit()

func split_sheet(sheet: Texture2D) -> Array:
	var image := sheet.get_image()
	var width := image.get_width()
	var height := image.get_height()
	# Find transparent gutters near the expected row boundaries, avoiding clipped feet.
	var rows: Array[int] = [0]
	for r in range(1,4):
		var best := int(height*r/4.0)
		var score := width+1
		for y in range(best-25,best+26):
			var count := 0
			for x in range(0,width,2):
				if image.get_pixel(x,y).a > 0.15: count += 1
			if count < score:
				score = count
				best = y
		rows.append(best)
	rows.append(height)
	var frames: Array = []
	for r in 4:
		for c in 4:
			var left := int(width*c/4.0)
			var right := int(width*(c+1)/4.0)
			var region := Rect2i(left,rows[r],right-left,rows[r+1]-rows[r])
			var used := image.get_region(region).get_used_rect()
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(region.position+used.position,used.size)
			atlas.filter_clip = true
			frames.append({"texture":atlas,"height":float(used.size.y)})
	var reference_height := 0.0
	for frame in frames: reference_height = maxf(reference_height,frame.height)
	for frame in frames: frame.reference_height = reference_height
	return frames

func spawn_actor(p: Vector2, infected: bool) -> CharacterBody2D:
	var actor := Actor.new()
	actor.game = self
	actor.enemy = infected
	actor.position = closest_walkable(p)
	depth.add_child(actor)
	return actor

func setup_input() -> void:
	for pair in [["interact",KEY_E],["bag",KEY_TAB],["pause",KEY_ESCAPE],["map",KEY_M],["food",KEY_1],["water",KEY_2],["bandage",KEY_3],["save",KEY_F5],["load",KEY_F9]]:
		if InputMap.has_action(pair[0]): continue
		InputMap.add_action(pair[0])
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0],ev)

func can_walk(p: Vector2) -> bool:
	var cell := Vector2i(floori(p.x/16),floori(p.y/16))
	return nav.is_in_boundsv(cell) and not nav.is_point_solid(cell)

func closest_walkable(p: Vector2) -> Vector2:
	if can_walk(p): return p
	var best := Vector2(744,568)
	var distance := INF
	for x in nav.region.size.x:
		for y in nav.region.size.y:
			if nav.is_point_solid(Vector2i(x,y)): continue
			var candidate := Vector2(x*16+8,y*16+8)
			var d := candidate.distance_squared_to(p)
			if d < distance:
				distance = d
				best = candidate
	return best

func find_route(from: Vector2,to: Vector2) -> PackedVector2Array:
	var a := Vector2i(floori(from.x/16),floori(from.y/16))
	var b := Vector2i(floori(to.x/16),floori(to.y/16))
	if not nav.is_in_boundsv(a) or not nav.is_in_boundsv(b) or nav.is_point_solid(a) or nav.is_point_solid(b): return PackedVector2Array()
	return nav.get_point_path(a,b)

func clear_line(from: Vector2,to: Vector2) -> bool:
	var steps := maxi(1,ceili(from.distance_to(to)/6))
	for i in range(1,steps):
		if not world.point_allowed(from.lerp(to,float(i)/steps)): return false
	return true

func screen_point(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * p

func _process(dt: float) -> void:
	if player == null: return
	notice_time = maxf(0,notice_time-dt)
	hit_time = maxf(0,hit_time-dt)
	current_zone = District.zone_of(player.position)
	guide_time -= dt
	world.update_occlusion(player.position)
	if mode == "play" and not visited[current_zone]:
		visited[current_zone] = true
		notify("进入"+District.LABELS[current_zone]+" · 道路连续通行")
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_physical_key_pressed(KEY_SPACE): block_attack_until_release = false
	var zoom_value := 1.04 if mode == "title" else target_zoom
	camera.zoom = camera.zoom.lerp(Vector2.ONE*zoom_value,minf(1,dt*4))
	var center := Vector2(800,505) if mode == "title" else player.position + Vector2(0,-85)
	var half_view := get_viewport_rect().size / camera.zoom / 2
	center.x = clampf(center.x,half_view.x,District.BOUNDS.size.x-half_view.x)
	center.y = clampf(center.y,half_view.y,District.BOUNDS.size.y-half_view.y)
	if not inspect_scene: camera.position = camera.position.lerp(center,1-exp(-dt*5))
	if mode == "play":
		elapsed += dt
		hunger = maxf(0,hunger-dt*0.07)
		thirst = maxf(0,thirst-dt*(0.15 if running else 0.1))
		stamina = clampf(stamina+dt*(-15 if running else 10),0,100)
		if hunger <= 0 or thirst <= 0: hurt(dt*1.5,false)
		update_interaction(dt)
		saved_time += dt
		if saved_time > 60 and player.position.distance_to(safe_point) < 65:
			save_game("user://iso-autosave.json")
			saved_time = 0
	hud.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if safe_point == Vector2.ZERO: return
	draw_set_transform(safe_point,0,Vector2(1,0.48))
	draw_arc(Vector2.ZERO,28,0,TAU,48,Color(0.65,0.8,0.65,0.8),2,true)
	draw_set_transform(Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if mode == "loot":
		if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER): close_loot()
		return
	if mode == "title":
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER: start_game()
		if event.is_action_pressed("load"): load_game()
		return
	if event.is_action_pressed("map") and mode in ["play","map"]:
		mode = "play" if mode == "map" else "map"
		return
	if mode == "map":
		if event.is_action_pressed("pause"): mode = "play"
		return
	if mode in ["dead","win"]:
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER: get_tree().reload_current_scene()
		return
	if event.is_action_pressed("pause"):
		mode = "play" if mode == "pause" else "pause"
		bag = false
		return
	if event.is_action_pressed("bag"):
		bag = not bag
		mode = "pause" if bag else "play"
		return
	if event.is_action_pressed("save"):
		save_game()
		return
	if event.is_action_pressed("load"):
		load_game()
		return
	if mode != "play": return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index := hovered_container()
		if index >= 0:
			start_clicked_search(index)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("food"): consume("food")
	if event.is_action_pressed("water"): consume("water")
	if event.is_action_pressed("bandage"): consume("bandage")
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: target_zoom = minf(1.65,target_zoom+0.1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: target_zoom = maxf(1.05,target_zoom-0.1)

func start_game() -> void:
	mode = "play"
	notify("住宅草地与后院可自由探索；靠近门按 E 开关，M 标记目标。")

func guide_point() -> Vector2:
	if guide_time > 0: return guide_cache
	guide_time = 0.4
	var destination: Vector2 = safe_point if map_marker == "cedar" else District.CENTERS[map_marker]
	var route := find_route(player.position,closest_walkable(destination))
	guide_cache = destination if route.is_empty() else route[mini(route.size()-1,16)]
	return guide_cache

func add_loot(title: String,p: Vector2,contents: Dictionary) -> void:
	var node := Node2D.new()
	node.position = p
	add_child(node)
	containers.append({"title":title,"node":node,"loot":contents,"remaining":contents.duplicate(),"searched":false,"outline":PackedVector2Array(),"marker_position":p,"duration":1.4})

func set_container_visual(index: int,outline: PackedVector2Array,marker: Vector2,duration: float) -> void:
	containers[index].outline = outline
	containers[index].marker_position = marker
	containers[index].duration = duration

func hovered_container() -> int:
	var pointer := get_global_mouse_position()
	for i in range(containers.size()-1,-1,-1):
		if Geometry2D.is_point_in_polygon(pointer,containers[i].outline): return i
	return -1

func can_search(index: int) -> bool:
	return index >= 0 and index < containers.size() and player.position.distance_to(containers[index].node.position) < 70 and clear_line(player.position,containers[index].node.position)

func cancel_search() -> void:
	search_progress = 0
	search_target = -1
	clicked_search = false

func start_clicked_search(index: int) -> void:
	if not can_search(index):
		notify("先走到"+containers[index].title+"前面，再点击搜索。")
		return
	if containers[index].searched:
		loot(index)
		return
	cancel_search()
	search_target = index
	clicked_search = true
	search_sound_timer = 0

func movement_pressed() -> bool:
	return Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D)

func update_interaction(dt: float) -> void:
	if not Input.is_action_pressed("interact"): wait_interact_release = false
	nearest = -1
	var distance := 70.0
	for i in containers.size():
		var c: Dictionary = containers[i]
		var d: float = player.position.distance_to(c.node.position)
		if d < distance and clear_line(player.position,c.node.position):
			nearest = i
			distance = d
	var hovered := hovered_container()
	if can_search(hovered): nearest = hovered
	if clicked_search and can_search(search_target): nearest = search_target
	if movement_pressed():
		cancel_search()
		return
	if wait_interact_release: return
	var door_index: int = world.yard.nearest()
	if door_index >= 0 and Input.is_action_pressed("interact"):
		world.yard.toggle(door_index)
		wait_interact_release = true
		return
	if Input.is_action_pressed("interact") or clicked_search:
		if Input.is_action_pressed("interact") and visited.store and player.position.distance_to(safe_point) < 65 and collected.food >= 2 and collected.water >= 2 and collected.parts >= 2:
			won = true
			mode = "win"
			if not "--smoke-test" in OS.get_cmdline_user_args(): save_game("user://iso-autosave.json")
			return
		if nearest >= 0 and containers[nearest].searched:
			loot(nearest)
			return
		if nearest >= 0:
			if search_target != nearest: search_progress = 0
			search_target = nearest
			player.facing = (containers[nearest].marker_position-player.position).normalized()
			search_progress += dt
			search_sound_timer -= dt
			if search_sound_timer <= 0:
				sound(135+int(search_progress*60),0.06,0.04)
				search_sound_timer = 0.45
			if search_progress >= containers[nearest].duration:
				loot(nearest)
				cancel_search()
		else: cancel_search()
	else:
		cancel_search()

func loot(index: int) -> void:
	if not can_search(index): return
	containers[index].searched = true
	loot_container = index
	loot_decisions.clear()
	cancel_search()
	mode = "loot"
	block_attack_until_release = true
	sound(560,0.12,0.06)

func remaining_count(index: int) -> int:
	var count := 0
	for amount in containers[index].remaining.values(): count += int(amount)
	return count

func take_item(key: String) -> void:
	if mode != "loot" or loot_container < 0: return
	var c: Dictionary = containers[loot_container]
	var amount: int = int(c.remaining.get(key,0))
	if amount <= 0: return
	c.remaining[key] = 0
	inventory[key] += amount
	if collected.has(key): collected[key] += amount
	loot_decisions[key] = "taken"
	sound(740,0.1,0.06)

func leave_item(key: String) -> void:
	if mode != "loot" or loot_container < 0: return
	if containers[loot_container].remaining.get(key,0) > 0: loot_decisions[key] = "left"

func close_loot() -> void:
	if mode != "loot": return
	mode = "play"
	loot_container = -1
	loot_decisions.clear()
	wait_interact_release = true
	block_attack_until_release = true
	cancel_search()

func capture_state() -> Dictionary:
	var states: Array = []
	for e in enemies: states.append({"pos":[e.position.x,e.position.y],"hp":e.hp,"dead":e.dead})
	var searched: Array = []
	for c in containers: searched.append(c.searched)
	return {"version":6,"doors":world.yard.doors.map(func(d): return d.open),"visited":visited.duplicate(),"map_marker":map_marker,"remaining":containers.map(func(c): return c.remaining.duplicate()),"pos":[player.position.x,player.position.y],"health":health,"hunger":hunger,"thirst":thirst,"stamina":stamina,"inventory":inventory.duplicate(),"collected":collected.duplicate(),"elapsed":elapsed,"kills":kills,"won":won,"enemies":states,"searched":searched}

func save_game(path := "user://iso-save.json") -> bool:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		notify("存档写入失败")
		return false
	file.store_string(JSON.stringify(capture_state()))
	file.flush()
	file.close()
	if FileAccess.file_exists(path) and DirAccess.copy_absolute(path,path+".bak") != OK: return false
	var error := DirAccess.rename_absolute(path+".tmp",path)
	notify("进度已保存" if error == OK else "存档写入失败，旧存档已保留")
	return error == OK

func valid_position(p: Variant) -> bool:
	if not p is Array or p.size() != 2: return false
	for v in p:
		if not (v is float or v is int) or not is_finite(float(v)): return false
	return p[0] >= 0 and p[0] < 7168 and p[1] >= 0 and p[1] < 3072

func valid_save(d: Variant) -> bool:
	if not d is Dictionary or (d.get("version") != 2 and d.get("version") != 3 and d.get("version") != 4 and d.get("version") != 5 and d.get("version") != 6) or not valid_position(d.get("pos")): return false
	if d.version == 6:
		if not d.get("doors") is Array or d.doors.size() != world.yard.doors.size(): return false
		for opened in d.doors:
			if not opened is bool: return false
	if d.version >= 4:
		if not d.get("visited") is Dictionary or not d.get("map_marker") in District.ZONES: return false
		for zone in District.ZONES:
			if not d.visited.get(zone) is bool: return false
	for key in ["health","hunger","thirst","stamina","elapsed","kills"]:
		if not (d.get(key) is float or d.get(key) is int) or not is_finite(float(d[key])) or d[key] < 0: return false
	for key in ["health","hunger","thirst","stamina"]:
		if d[key] > 100: return false
	for name_key in ["inventory","collected"]:
		if not d.get(name_key) is Dictionary: return false
		var keys: Array = inventory.keys() if name_key == "inventory" else collected.keys()
		for key in keys:
			var value = d[name_key].get(key)
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > 100: return false
	if not d.get("searched") is Array or d.searched.size() not in [5,6,containers.size()]: return false
	if d.version >= 4 and d.searched.size() != containers.size(): return false
	for value in d.searched:
		if not value is bool: return false
	if d.version >= 3:
		if not d.get("remaining") is Array or d.remaining.size() != d.searched.size(): return false
		for i in d.remaining.size():
			if not d.remaining[i] is Dictionary or d.remaining[i].size() != containers[i].loot.size(): return false
			for key in containers[i].loot:
				var value = d.remaining[i].get(key)
				if not (value is int or value is float) or not is_finite(float(value)) or value != int(value) or value < 0 or value > containers[i].loot[key]: return false
	if not d.get("enemies") is Array or d.enemies.size() not in [6,enemies.size()]: return false
	if d.version >= 4 and d.enemies.size() != enemies.size(): return false
	for e in d.enemies:
		if not e is Dictionary or not valid_position(e.get("pos")) or not e.get("dead") is bool: return false
		if not (e.get("hp") is int or e.get("hp") is float) or not is_finite(float(e.hp)) or e.hp < -100 or e.hp > 100: return false
	return d.get("won") is bool

func load_game(path := "user://iso-save.json") -> bool:
	var data: Variant = null
	for candidate in [path,path+".bak"]:
		if FileAccess.file_exists(candidate):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(candidate))
			if valid_save(parsed):
				data = parsed
				break
	if data == null:
		notify("没有可读取的 2.5D 存档，请先开始探索。")
		return false
	for i in world.yard.doors.size():
		world.yard.doors[i].open = data.doors[i] if data.version == 6 else i == 0
		world.yard.refresh_door(i)
	world.build_navigation()
	player.position = closest_walkable(District.migrate_position(Vector2(data.pos[0],data.pos[1]),int(data.version)))
	player.velocity = Vector2.ZERO
	player.cooldown = 0
	player.knockback = Vector2.ZERO
	player.swing = 0
	player.hit_pending = false
	current_zone = District.zone_of(player.position)
	visited = data.visited.duplicate() if data.version >= 4 else {"cedar":true,"junction":false,"store":false,"alley":false}
	visited[current_zone] = true
	map_marker = data.map_marker if data.version >= 4 else "store"
	camera.position = player.position
	health = data.health
	hunger = data.hunger
	thirst = data.thirst
	stamina = data.stamina
	inventory = data.inventory
	collected = data.collected
	for key in inventory: inventory[key] = int(inventory[key])
	for key in collected: collected[key] = int(collected[key])
	elapsed = data.elapsed
	kills = int(data.kills)
	won = data.won
	for i in enemies.size():
		var e = enemies[i]
		var state = data.enemies[i] if i < data.enemies.size() else {"pos":[e.home.x,e.home.y],"hp":100.0,"dead":false}
		e.position = closest_walkable(District.migrate_position(Vector2(state.pos[0],state.pos[1]),int(data.version))) if i < data.enemies.size() else e.home
		e.hp = state.hp
		e.dead = state.dead
		e.chasing = false
		e.velocity = Vector2.ZERO
		e.waypoints.clear()
		e.path_timer = 0
		e.cooldown = 0
		e.knockback = Vector2.ZERO
		e.collision_layer = 0 if e.dead else 2
		e.collision_mask = 0 if e.dead else 6
		e.update_sprite()
	for i in containers.size():
		containers[i].searched = data.searched[i] if i < data.searched.size() else false
		if data.version >= 3 and i < data.remaining.size():
			containers[i].remaining = data.remaining[i].duplicate()
		else:
			containers[i].remaining = containers[i].loot.duplicate()
			if containers[i].searched:
				for key in containers[i].remaining: containers[i].remaining[key] = 0
	loot_container = -1
	loot_decisions.clear()
	cancel_search()
	bag = false
	mode = "win" if won else ("dead" if health <= 0 else "play")
	notify("已恢复 2.5D 探索进度")
	return true

func capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("iso-title.png"))
	start_game()
	player.position = closest_walkable(Vector2(861,483))
	for e in enemies: e.frozen = true
	enemies[0].position = closest_walkable(Vector2(774,554))
	enemies[1].position = closest_walkable(Vector2(668,628))
	enemies[2].position = closest_walkable(Vector2(1100,447))
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("iso-gameplay.png"))
	print("2.5D RENDER: fps=",Engine.get_frames_per_second()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()

func yard_test() -> void:
	await preload("res://scripts/iso/yard-tests.gd").run(self)

func yard_capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	start_game()
	for e in enemies: e.frozen = true
	for point in [Vector2(620,290),Vector2(1170,140),Vector2(1510,490)]:
		player.position = closest_walkable(point)
		camera.position = player.position
		await get_tree().create_timer(1.3).timeout
		get_viewport().get_texture().get_image().save_png(output_dir.path_join("yard-%d.png" % int(point.x)))
	get_tree().quit()

func verify_persistence() -> void:
	if not load_game("user://iso-test.json") or health != 85 or inventory.food != 2 or not containers[0].searched:
		push_error("2.5D persistence failed")
		get_tree().quit(1)
		return
	print("2.5D PERSISTENCE PASS")
	get_tree().quit()

func verify_choice_save() -> void:
	if not load_game("user://iso-choice-test.json") or inventory.food != 1 or inventory.water != 0 or containers[5].remaining.water != 1 or containers[5].remaining.food != 0:
		push_error("Leftover save verification failed")
		get_tree().quit(1)
		return
	print("LEFTOVER PERSISTENCE PASS: fresh process restores chosen items and items left behind")
	get_tree().quit()

func search_capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	start_game()
	for e in enemies: e.frozen = true
	player.position = closest_walkable(Vector2(815,321))
	await get_tree().create_timer(1).timeout
	start_clicked_search(5)
	await get_tree().create_timer(1).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("furniture-search.png"))
	await get_tree().create_timer(1.3).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("furniture-loot.png"))
	get_tree().quit()

func search_test() -> void:
	await get_tree().physics_frame
	start_game()
	for e in enemies: e.frozen = true
	player.position = closest_walkable(containers[5].node.position)
	start_clicked_search(5)
	update_interaction(0.8)
	assert(search_progress > 0 and not containers[5].searched)
	hurt(1)
	assert(not clicked_search and search_progress == 0)
	start_clicked_search(5)
	update_interaction(2.1)
	assert(mode == "loot" and inventory.food == 0 and inventory.water == 0,"Searching must not transfer items")
	var before := elapsed
	_process(1.0)
	assert(elapsed == before,"Selection pauses the world")
	# Exercise the real row buttons through the HUD input handler.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(855,342)*get_viewport_rect().size/Vector2(1440,900)
	hud._input(click)
	assert(inventory.food == 1 and inventory.water == 0 and containers[5].remaining.food == 0)
	click.position = Vector2(950,430)*get_viewport_rect().size/Vector2(1440,900)
	hud._input(click)
	assert(loot_decisions.water == "left" and containers[5].remaining.water == 1)
	close_loot()
	assert(save_game("user://iso-choice-test.json"))
	containers[5].remaining.water = 0
	assert(load_game("user://iso-choice-test.json"))
	assert(containers[5].remaining.water == 1 and inventory.food == 1 and inventory.water == 0)
	start_clicked_search(5)
	assert(mode == "loot","Searched container reopens without searching again")
	take_item("water")
	take_item("water")
	assert(inventory.water == 1 and remaining_count(5) == 0,"Transfer cannot duplicate items")
	close_loot()
	var legacy := capture_state()
	legacy.version = 2
	legacy.erase("remaining")
	legacy.searched.resize(5)
	legacy.enemies.resize(6)
	assert(valid_save(legacy))
	var file := FileAccess.open("user://iso-legacy-test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	assert(load_game("user://iso-legacy-test.json"))
	assert(remaining_count(5) == 2,"Added fridge remains fresh for original five-container save")
	var malformed := capture_state()
	malformed.remaining[0].food = -1
	assert(not valid_save(malformed))
	print("CHOICE TEST PASS: timed search, interruption, modal pause, real take/leave buttons, leftovers, reopen, persistence, no duplication, legacy save")
	get_tree().quit()

func test_take_container(index: int) -> void:
	player.position = closest_walkable(containers[index].node.position)
	loot(index)
	for key in containers[index].loot: take_item(key)
	close_loot()

func walk_test() -> void:
	start_game()
	for e in enemies:
		e.frozen = true
		e.collision_layer = 0
	var route := find_route(player.position,closest_walkable(Vector2(966,349)))
	var count := 0
	for point in route:
		while player.position.distance_to(point) > 10 and count < 1800:
			var d: Vector2 = point-player.position
			for pair in [[KEY_D,d.x>3],[KEY_A,d.x< -3],[KEY_S,d.y>3],[KEY_W,d.y< -3]]:
				var ev := InputEventKey.new()
				ev.physical_keycode = pair[0]
				ev.pressed = pair[1]
				Input.parse_input_event(ev)
			await get_tree().physics_frame
			count += 1
	for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.pressed = false
		Input.parse_input_event(ev)
	if player.position.distance_to(Vector2(966,349)) > 35:
		push_error("Keyboard doorway walk failed at "+str(player.position))
		get_tree().quit(1)
		return
	print("2.5D WALK PASS: physical WASD input moved player from sidewalk through entrance into the room in ",count," physics ticks")
	get_tree().quit()

func smoke_test() -> void:
	await get_tree().physics_frame
	for e in enemies: e.frozen = true
	start_game()
	assert(player_frames.size() == 16 and zombie_frames.size() == 16)
	for frames in [player_frames,zombie_frames]:
		for frame in frames: assert(frame.height > 100)
	# Every search point has an accessible neighboring tile reachable from the start.
	for c in containers:
		if District.zone_of(c.node.position) != "cedar": continue
		var accessible := false
		for x in range(-3,4):
			for y in range(-3,4):
				var p: Vector2 = c.node.position+Vector2(x*16,y*16)
				if can_walk(p) and p.distance_to(c.node.position) < 63 and clear_line(p,c.node.position) and find_route(player.position,p).size() > 0: accessible = true
		print("LOOT ACCESS ",c.title," = ",accessible," at ",c.node.position)
		if not accessible:
			for x in range(-3,4):
				for y in range(-3,4):
					var probe: Vector2 = c.node.position+Vector2(x*16,y*16)
					if can_walk(probe): print("  PROBE ",probe," clear=",clear_line(probe,c.node.position)," route=",find_route(player.position,probe).size())
		assert(accessible,"Unreachable search point: "+c.title)
	assert(find_route(player.position,safe_point).size() > 0,"Camp must connect to street")
	test_take_container(0)
	test_take_container(0)
	assert(inventory.food == 2)
	health = 50
	consume("bandage")
	assert(health == 85)
	assert(save_game("user://iso-test.json"))
	health = 1
	assert(load_game("user://iso-test.json"))
	assert(health == 85 and inventory.food == 2)
	assert(not valid_save({"version":2}))
	player.position = closest_walkable(Vector2(680,621))
	var e = enemies[0]
	e.position = player.position+Vector2(40,0)
	player.facing = Vector2.RIGHT
	for i in 3:
		player.cooldown = 0
		stamina = 100
		player.attack()
		player.tick_attack(0.2)
	assert(e.dead,"Directional melee must kill")
	for i in containers.size(): test_take_container(i)
	player.position = safe_point
	visited.store = true
	wait_interact_release = false
	Input.action_press("interact")
	update_interaction(0.1)
	Input.action_release("interact")
	assert(mode == "win")
	mode = "play"
	health = 1
	hurt(9)
	assert(mode == "dead")
	print("2.5D SMOKE PASS: 32 animation frames, reachable loot and camp, collision map, consumables, save/load, melee, victory and death")
	get_tree().quit()

func item_name(key: String) -> String:
	return {"food": "罐头", "water": "饮用水", "bandage": "绷带", "parts": "无线电零件"}.get(key, key)

func district_test() -> void:
	await seamless_test()

func seamless_test() -> void:
	await get_tree().physics_frame
	preload("res://scripts/iso/seamless-tests.gd").state_test(self)

func seamless_walk_test() -> void:
	await preload("res://scripts/iso/seamless-tests.gd").walk_test(self)

func seamless_chase_test() -> void:
	start_game()
	player.frozen = true
	for e in enemies: e.frozen = true
	player.position = Vector2(1840,970)
	var pursuer = enemies[0]
	pursuer.position = Vector2(1500,976)
	pursuer.chasing = true
	pursuer.frozen = false
	pursuer.path_timer = 0
	for i in 380: await get_tree().physics_frame
	assert(pursuer.position.x > 1792,"Enemy stopped at old region edge")
	assert(pursuer.position.distance_to(player.position)<65)
	print("SEAMLESS CHASE PASS: infected follows across former cedar/junction border without reset or transfer")
	get_tree().quit()

func district_capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	start_game()
	for e in enemies: e.frozen = true
	for zone in ["junction","store","alley"]:
		current_zone = zone
		visited[zone] = true
		player.position = closest_walkable(District.ORIGINS[zone]+({"junction":Vector2(800,540),"store":Vector2(980,490),"alley":Vector2(700,590)}[zone]))
		camera.position = player.position
		await get_tree().create_timer(1.3).timeout
		get_viewport().get_texture().get_image().save_png(output_dir.path_join("district-"+zone+".png"))
	mode = "map"
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("district-map.png"))
	print("DISTRICT RENDER: fps=",Engine.get_frames_per_second()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()

func district_walk_test() -> void:
	await seamless_walk_test()

func seamless_capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	start_game()
	for e in enemies: e.frozen = true
	for i in District.ROADS.size():
		var road: Dictionary = District.ROADS[i]
		player.position = closest_walkable(road.points[1])
		camera.position = player.position
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png(output_dir.path_join("seamless-road-%d.png" % i))
	print("SEAMLESS RENDER fps=",Engine.get_frames_per_second())
	get_tree().quit()


func consume(key: String) -> void:
	if inventory[key] <= 0:
		notify("背包里没有" + item_name(key))
		return
	if (key == "food" and hunger >= 100) or (key == "water" and thirst >= 100) or (key == "bandage" and health >= 100):
		notify("当前状态良好，留着稍后使用。")
		return
	inventory[key] -= 1
	if key == "food": hunger = minf(100, hunger + 35)
	if key == "water": thirst = minf(100, thirst + 40)
	if key == "bandage": health = minf(100, health + 35)
	notify("使用了" + item_name(key))
	sound(480, 0.12, 0.08)


func hurt(amount: float, feedback := true) -> void:
	if mode != "play": return
	health = maxf(0, health - amount)
	if feedback:
		hit_time = 0.3
		cancel_search()
		sound(60, 0.13, 0.18)
	if health <= 0: mode = "dead"


func notify(message: String) -> void:
	notice = message
	notice_time = 4


func sound(frequency: float, duration: float, volume: float) -> void:
	if DisplayServer.get_name() == "headless": return
	var data := PackedByteArray()
	var count := int(22050 * duration)
	data.resize(count * 2)
	for i in count:
		var value := sin(float(i) / 22050 * frequency * TAU) * volume * (1.0 - float(i) / count)
		data.encode_s16(i * 2, int(value * 30000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func start_ambient() -> void:
	if DisplayServer.get_name() == "headless": return
	var data := PackedByteArray()
	data.resize(22050 * 4 * 2)
	var noise := 0.0
	var audio_rng := RandomNumberGenerator.new()
	audio_rng.seed = 12
	for i in 88200:
		noise = lerpf(noise, audio_rng.randf_range(-1, 1), 0.025)
		data.encode_s16(i * 2, int((noise * 0.11 + sin(float(i) / 22050 * 55 * TAU) * 0.005) * 30000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 88200
	ambient = AudioStreamPlayer.new()
	ambient.stream = stream
	add_child(ambient)
	ambient.play()


