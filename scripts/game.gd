extends Node3D

const Actor = preload("res://scripts/actor.gd")
const World = preload("res://scripts/world.gd")
const HUD = preload("res://scripts/hud.gd")
const FONT = preload("res://art/NotoSansSC-Regular.otf")
var rng := RandomNumberGenerator.new()
var camera: Camera3D
var player: CharacterBody3D
var enemies: Array = []
var containers: Array = []
var cut_walls: Array = []
var roof: MeshInstance3D
var hud: Control
var mode := "title"
var health := 100.0
var hunger := 82.0
var thirst := 76.0
var stamina := 100.0
var elapsed := 0.0
var running := false
var crouching := false
var kills := 0
var inventory := {"food": 0, "water": 0, "bandage": 1, "parts": 0}
var collected := {"food": 0, "water": 0, "parts": 0}
var nearest := -1
var search_progress := 0.0
var search_target := -1
var notice := ""
var notice_time := 0.0
var hit_time := 0.0
var saved_time := 0.0
var bag := false
var won := false
var materials := {}
var ambient: AudioStreamPlayer

func _ready() -> void:
	rng.seed = 7219
	setup_input()
	setup_lighting()
	World.new(self).build()
	batch_static_world()
	player = Actor.new()
	player.game = self
	player.position = Vector3(-4, 0.5, 3)
	add_child(player)
	var player_marker := ring(Vector3.ZERO, 0.42, Color("b9c79b"))
	player_marker.reparent(player, false)
	player_marker.position.y = 0.06
	for p in [Vector3(-2, 0.5, 9), Vector3(5, 0.5, 6), Vector3(-10, 0.5, 8), Vector3(11, 0.5, 4), Vector3(3, 0.5, -4), Vector3(15, 0.5, 11), Vector3(-15, 0.5, -3)]:
		var enemy := Actor.new()
		enemy.game = self
		enemy.enemy = true
		enemy.position = p
		add_child(enemy)
		enemies.append(enemy)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 21
	camera.far = 100
	add_child(camera)
	camera.position = Vector3(20, 25, 26)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	canvas.add_child(hud)
	start_ambient()
	if "--smoke-test" in OS.get_cmdline_user_args(): call_deferred("smoke_test")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture")
	if "--verify-save" in OS.get_cmdline_user_args(): call_deferred("verify_persistence")

func setup_input() -> void:
	for pair in [["interact", KEY_E], ["bag", KEY_TAB], ["pause", KEY_ESCAPE], ["food", KEY_1], ["water", KEY_2], ["bandage", KEY_3], ["save", KEY_F5], ["load", KEY_F9]]:
		InputMap.add_action(pair[0])
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], ev)

func batch_static_world() -> void:
	# Bake only immutable visuals. Keep collision nodes and interactive props intact.
	var groups := {}
	var pending: Array[Node] = [self]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node == roof or node in cut_walls: continue
		var interactive := false
		for container in containers:
			if node == container.node:
				interactive = true
				break
		if interactive: continue
		for child in node.get_children(): pending.append(child)
		if not node is MeshInstance3D or node.mesh == null: continue
		var source := node as MeshInstance3D
		var mat := source.material_override
		if mat == null: continue
		if not groups.has(mat): groups[mat] = []
		groups[mat].append(source)
	for mat in groups:
		var meshes: Array = groups[mat]
		if meshes.size() < 2: continue
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for source in meshes:
			builder.append_from(source.mesh, 0, source.global_transform)
			# Removing only geometry preserves children and transforms.
			source.mesh = null
		var merged := MeshInstance3D.new()
		merged.mesh = builder.commit()
		merged.material_override = mat
		add_child(merged)

func setup_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9da994")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bac5b2")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -34, 0)
	sun.light_color = Color("eee2c8")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)

func _process(dt: float) -> void:
	notice_time = maxf(0, notice_time - dt)
	hit_time = maxf(0, hit_time - dt)
	if player == null: return
	var center := player.position + Vector3(0, 0, -1.6) if mode != "title" else Vector3(0.5, 0, -1)
	camera.position = camera.position.lerp(center + Vector3(19, 23, 25), 1 - exp(-dt * 4))
	camera.look_at(camera.position - Vector3(19, 23, 25))
	var cutaway := player.position.distance_to(Vector3(3, 0, -2)) < 10 or mode == "title"
	roof.visible = not cutaway
	for mesh in cut_walls:
		mesh.scale.y = lerpf(mesh.scale.y, 0.15 if cutaway else 1.0, minf(1, dt * 6))
		mesh.position.y = 0.16 + mesh.scale.y * 1.5
	if mode == "play":
		elapsed += dt
		hunger = maxf(0, hunger - dt * 0.07)
		thirst = maxf(0, thirst - dt * (0.15 if running else 0.1))
		stamina = clampf(stamina + dt * (-15 if running else 10), 0, 100)
		if hunger <= 0 or thirst <= 0: hurt(dt * 1.5, false)
		update_interaction(dt)
		saved_time += dt
		if saved_time > 60 and player.position.distance_to(Vector3(-6.5, 0, 1.7)) < 2:
			save_game("user://autosave.json")
			saved_time = 0
	hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if mode == "title":
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ENTER: start_game()
		if event.is_action_pressed("load"): load_game()
		return
	if mode in ["dead", "win"]:
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
	if mode != "play": return
	if event.is_action_pressed("food"): consume("food")
	if event.is_action_pressed("water"): consume("water")
	if event.is_action_pressed("bandage"): consume("bandage")
	if event.is_action_pressed("save"): save_game()
	if event.is_action_pressed("load"): load_game()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.size = maxf(16, camera.size - 1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.size = minf(28, camera.size + 1)

func start_game() -> void:
	mode = "play"
	notify("先去住宅找补给。按住 E 搜索，注意附近的感染者。")

func inside_house(p: Vector3) -> bool:
	return p.x > -1 and p.x < 7 and p.z > -7 and p.z < 1

func clear_line(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a + Vector3.UP, b + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func update_interaction(dt: float) -> void:
	nearest = -1
	var distance := 2.0
	for i in containers.size():
		var c: Dictionary = containers[i]
		var d: float = player.position.distance_to(c.node.position)
		if not c.searched and d < distance and clear_line(player.position, c.node.position):
			nearest = i
			distance = d
	if Input.is_action_pressed("interact"):
		if player.position.distance_to(Vector3(-6.5, 0, 1.7)) < 2 and collected.food >= 2 and collected.water >= 2 and collected.parts >= 2:
			won = true
			mode = "win"
			save_game("user://autosave.json")
			return
		if nearest >= 0:
			if search_target != nearest: search_progress = 0
			search_target = nearest
			search_progress += dt
			if search_progress >= 1.4:
				loot(nearest)
				search_progress = 0
				search_target = -1
		else: search_progress = 0
	else:
		search_progress = 0
		search_target = -1

func loot(index: int) -> void:
	var c: Dictionary = containers[index]
	if c.searched: return
	c.searched = true
	var words: Array[String] = []
	for key in c.loot:
		inventory[key] += c.loot[key]
		if collected.has(key): collected[key] += c.loot[key]
		words.append("%s ×%d" % [item_name(key), c.loot[key]])
	c.marker.visible = false
	c.lid.rotation.z = -0.3
	notify("找到：" + "  ·  ".join(words))
	sound(740, 0.17, 0.1)

func item_name(key: String) -> String:
	return {"food": "罐头", "water": "饮用水", "bandage": "绷带", "parts": "无线电零件"}.get(key, key)

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
		search_progress = 0
		sound(60, 0.13, 0.18)
	if health <= 0: mode = "dead"

func notify(message: String) -> void:
	notice = message
	notice_time = 4

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if materials.has(key): return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	materials[key] = mat
	return mat

func box(parent: Node3D, p: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = p
	if solid:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
	return mesh

func invisible_wall(p: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = p
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = size
	shape.shape = bounds
	body.add_child(shape)

func cylinder(parent: Node3D, p: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	cylinder_mesh.radial_segments = 10
	mesh.mesh = cylinder_mesh
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = p
	return mesh

func ring(p: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.035
	torus.outer_radius = radius
	torus.rings = 32
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = material(color)
	add_child(mesh)
	mesh.position = p
	return mesh

func label3d(text: String, p: Vector3, color: Color, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = FONT
	label.font_size = size
	label.pixel_size = 0.014
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 4
	add_child(label)
	label.position = p
	return label

func add_loot(title: String, p: Vector3, contents: Dictionary) -> void:
	var crate := box(self, p, Vector3(0.78, 0.5, 0.64), Color("726044"))
	var lid := box(crate, Vector3(0, 0.27, 0), Vector3(0.82, 0.07, 0.68), Color("9b8560"))
	for x in [-0.25, 0.25]: box(crate, Vector3(x, 0, 0.325), Vector3(0.055, 0.5, 0.025), Color("3e483c"))
	var marker := label3d("◇", p + Vector3(0, 1, 0), Color("ebc985"), 40)
	containers.append({"title": title, "node": crate, "lid": lid, "marker": marker, "loot": contents, "searched": false})

func sparks(p: Vector3, color: Color) -> void:
	for i in 6:
		var mote := box(self, p, Vector3.ONE * 0.08, color)
		var tween := create_tween()
		tween.tween_property(mote, "position", p + Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.6, 0.6), rng.randf_range(-0.7, 0.7)), 0.25)
		tween.tween_callback(mote.queue_free)

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

func capture_state() -> Dictionary:
	var enemy_states: Array = []
	for enemy in enemies: enemy_states.append({"pos": [enemy.position.x, enemy.position.y, enemy.position.z], "hp": enemy.hp, "dead": enemy.dead})
	var searched: Array = []
	for c in containers: searched.append(c.searched)
	return {"version": 1, "pos": [player.position.x, player.position.y, player.position.z], "health": health, "hunger": hunger, "thirst": thirst, "stamina": stamina, "inventory": inventory.duplicate(), "collected": collected.duplicate(), "elapsed": elapsed, "kills": kills, "won": won, "enemies": enemy_states, "searched": searched}

func save_game(path := "user://save.json") -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		notify("存档写入失败")
		return false
	file.store_string(JSON.stringify(capture_state()))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".bak") != OK: return false
	var error := DirAccess.rename_absolute(path + ".tmp", path)
	notify("进度已保存" if error == OK else "存档写入失败，旧存档已保留")
	return error == OK

func valid_save(d: Variant) -> bool:
	if not d is Dictionary or d.get("version") != 1: return false
	for key in ["health", "hunger", "thirst", "stamina", "elapsed", "kills"]:
		if not d.get(key) is float and not d.get(key) is int: return false
		if not is_finite(float(d[key])) or d[key] < 0: return false
	for key in ["health", "hunger", "thirst", "stamina"]:
		if d[key] > 100: return false
	if not valid_position(d.get("pos")): return false
	if not d.get("inventory") is Dictionary or not d.get("collected") is Dictionary: return false
	for key in inventory:
		if not d.inventory.get(key) is float and not d.inventory.get(key) is int: return false
		if d.inventory[key] < 0 or d.inventory[key] > 100: return false
	for key in collected:
		if not d.collected.get(key) is float and not d.collected.get(key) is int: return false
		if d.collected[key] < 0 or d.collected[key] > 100: return false
	if not d.get("searched") is Array or d.searched.size() != containers.size(): return false
	for value in d.searched:
		if not value is bool: return false
	if not d.get("enemies") is Array or d.enemies.size() != enemies.size(): return false
	for enemy in d.enemies:
		if not enemy is Dictionary or not valid_position(enemy.get("pos")) or not enemy.get("dead") is bool: return false
		if not enemy.get("hp") is float and not enemy.get("hp") is int: return false
		if not is_finite(float(enemy.hp)) or enemy.hp > 100 or enemy.hp < -100: return false
	return d.get("won") is bool

func valid_position(p: Variant) -> bool:
	if not p is Array or p.size() != 3: return false
	for v in p:
		if not v is int and not v is float: return false
		if not is_finite(float(v)) or absf(float(v)) > 50: return false
	return true

func load_game(path := "user://save.json") -> bool:
	var data: Variant = null
	for candidate in [path, path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(candidate))
			if valid_save(parsed):
				data = parsed
				break
	if data == null:
		notify("没有可读取的存档。请先开始新的探索。")
		return false
	player.position = Vector3(data.pos[0], data.pos[1], data.pos[2])
	player.velocity = Vector3.ZERO
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
		var enemy = enemies[i]
		var state = data.enemies[i]
		enemy.position = Vector3(state.pos[0], state.pos[1], state.pos[2])
		enemy.hp = state.hp
		enemy.dead = state.dead
		enemy.chasing = false
		enemy.velocity = Vector3.ZERO
		enemy.collision_layer = 0 if enemy.dead else 2
		enemy.collision_mask = 0 if enemy.dead else 7
		enemy.visual.rotation.z = PI / 2 if enemy.dead else 0.0
		enemy.visual.position.y = 0.2 if enemy.dead else 0.0
	for i in containers.size():
		containers[i].searched = data.searched[i]
		containers[i].marker.visible = not data.searched[i]
		containers[i].lid.rotation.z = -0.3 if data.searched[i] else 0.0
	search_progress = 0
	bag = false
	mode = "win" if won else ("dead" if health <= 0 else "play")
	notify("已恢复探索进度")
	return true

func capture() -> void:
	var output_dir := OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://build")
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("title.png"))
	start_game()
	player.position = Vector3(3, 0.5, 2)
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png(output_dir.path_join("gameplay.png"))
	print("RENDER CHECK: fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()

func verify_persistence() -> void:
	await get_tree().physics_frame
	if not load_game("user://test.json") or health != 85 or not containers[0].searched or inventory.bandage != 0 or inventory.food != 2:
		push_error("Persistence verification failed")
		get_tree().quit(1)
		return
	print("PERSISTENCE PASS: restored health, inventory and searched container in a fresh process")
	get_tree().quit()

func smoke_test() -> void:
	await get_tree().physics_frame
	start_game()
	assert(enemies.size() == 7 and containers.size() == 5)
	loot(0)
	var count: int = inventory.bandage
	loot(0)
	assert(inventory.bandage == count, "Containers must not duplicate loot")
	health = 50
	consume("bandage")
	assert(health == 85)
	var saved := capture_state()
	assert(save_game("user://test.json"))
	health = 1
	assert(load_game("user://test.json"))
	assert(health == saved.health and inventory == saved.inventory)
	assert(not valid_save({"version": 1}))
	# The front entrance is passable; adjacent walls block movement and attacks.
	assert(clear_line(Vector3(3, 0, 2.5), Vector3(3, 0, -0.5)))
	assert(not clear_line(Vector3(5, 0, 2.5), Vector3(5, 0, -0.5)))
	player.position = Vector3(3, 0.3, 2)
	for i in 90:
		player.velocity = Vector3(0, 0, -2)
		player.move_and_slide()
		await get_tree().physics_frame
	assert(player.position.z < 1, "Player must enter through doorway")
	mode = "pause"
	var enemy = enemies[0]
	player.position = Vector3(-3, 0.2, 7)
	enemy.position = Vector3(-3, 0.2, 5.6)
	await get_tree().physics_frame
	player.facing = Vector3(0, 0, -1)
	for i in 3:
		player.cooldown = 0
		stamina = 100
		player.attack()
	assert(enemy.dead and kills >= 1, "Three crowbar hits must kill")
	mode = "play"
	for i in containers.size(): loot(i)
	player.position = Vector3(-6.5, 0.2, 1.7)
	Input.action_press("interact")
	update_interaction(0.1)
	Input.action_release("interact")
	assert(mode == "win", "Return to radio must finish mission")
	mode = "play"
	health = 2
	hurt(9)
	assert(mode == "dead")
	print("SMOKE PASS: loot, consumables, persistence, validation, doorway, wall occlusion, melee, victory, death")
	get_tree().quit()

