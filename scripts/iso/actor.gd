extends CharacterBody2D

var game: Node2D
var enemy := false
var hp := 100.0
var dead := false
var chasing := false
var facing := Vector2(1, 0.5)
var home := Vector2.ZERO
var cooldown := 0.0
var gait := 0.0
var swing := 0.0
var hit_pending := false
var flash := 0.0
var path_timer := 0.0
var target := Vector2.ZERO
var waypoints := PackedVector2Array()
var sprite: Sprite2D
var frame_index := 0
var row := 0
var frozen := false
var knockback := Vector2.ZERO

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7
	shape.shape = circle
	add_child(shape)
	collision_layer = 2 if enemy else 4
	collision_mask = 6
	sprite = Sprite2D.new()
	add_child(sprite)
	home = position
	target = position
	update_sprite()

func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0, Vector2(1, 0.42))
	draw_circle(Vector2.ZERO, 15 if not dead else 23, Color(0.035, 0.04, 0.03, 0.4))
	if not enemy and not dead:
		draw_arc(Vector2.ZERO, 19, 0, TAU, 32, Color(0.78, 0.85, 0.65, 0.65), 1.7, true)
	draw_set_transform(Vector2.ZERO)
	if swing > 0.15 and swing < 0.31:
		var angle := facing.angle()
		draw_arc(Vector2(0, -21), 38, angle - 0.85, angle + 0.85, 20, Color(0.88, 0.82, 0.57, swing * 2.5), 3, true)

func _physics_process(dt: float) -> void:
	if game.mode != "play" or dead or frozen: return
	if enemy and position.distance_to(game.player.position) > 850: return
	cooldown = maxf(0, cooldown - dt)
	tick_attack(dt)
	flash = maxf(0, flash - dt)
	var direction := Vector2.ZERO
	var speed := 105.0
	if enemy:
		path_timer -= dt
		var distance := position.distance_to(game.player.position)
		var radius := 270.0 if game.running else (95.0 if game.crouching else 175.0)
		if distance < radius and game.clear_line(position, game.player.position): chasing = true
		if distance > 410: chasing = false
		if path_timer <= 0:
			path_timer = 0.6 if chasing else 2.5
			if chasing: target = game.player.position
			elif position.distance_to(target) < 18:
				target = game.closest_walkable(home + Vector2(game.rng.randf_range(-65, 65), game.rng.randf_range(-45, 45)))
			waypoints = game.find_route(position, target)
		while waypoints.size() > 0 and position.distance_to(waypoints[0]) < 9: waypoints.remove_at(0)
		if waypoints.size() > 0: direction = (waypoints[0] - position).normalized()
		speed = 54.0 if chasing else 23.0
		if distance < 31 and cooldown <= 0 and game.clear_line(position, game.player.position):
			game.hurt(9)
			cooldown = 1.35
		if direction.length() > 0.1: facing = direction
	else:
		direction = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
		game.crouching = Input.is_physical_key_pressed(KEY_C)
		game.running = Input.is_physical_key_pressed(KEY_SHIFT) and game.stamina > 5 and direction.length() > 0 and not game.crouching
		if game.running: speed = 165
		if game.crouching: speed = 57
		if game.search_progress > 0: speed = 0
		var aim := get_global_mouse_position() - position
		if swing <= 0 and game.search_progress <= 0:
			if direction.length() > 0.1: facing = direction
			elif aim.length() > 12: facing = aim.normalized()
		if not game.block_attack_until_release and ((Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and game.hovered_container() < 0) or Input.is_physical_key_pressed(KEY_SPACE)): attack()
		if swing > 0: speed *= 0.3
	var old := position
	velocity = direction * speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, dt * 500)
	if not game.can_walk(position + Vector2(velocity.x * dt, 0)): velocity.x = 0
	if not game.can_walk(position + Vector2(0, velocity.y * dt)): velocity.y = 0
	move_and_slide()
	if not game.can_walk(position): position = old
	var walking := position.distance_to(old) > 0.1
	if walking:
		gait += position.distance_to(old) / (12.0 if enemy else 15.0)
		frame_index = int(gait) % 4
	else: frame_index = 1
	row = (0 if facing.x >= 0 else 1) if facing.y >= 0 else (2 if facing.x >= 0 else 3)
	update_sprite()
	queue_redraw()

func update_sprite() -> void:
	var frames: Array = game.zombie_frames if enemy else game.player_frames
	if frames.is_empty(): return
	var frame: Dictionary = frames[row * 4 + frame_index]
	sprite.texture = frame.texture
	sprite.scale = Vector2.ONE * (86.0 / frame.reference_height)
	sprite.offset = Vector2(0, -frame.height / 2)
	if not enemy and game.crouching: sprite.scale.y *= 0.85
	sprite.modulate = Color(1.4, 0.72, 0.6) if flash > 0 else Color.WHITE
	if dead:
		sprite.rotation = -PI / 2
		sprite.position = Vector2(-25, 1)
		sprite.scale *= 0.8
		sprite.modulate = Color(0.64, 0.62, 0.57)
	else:
		sprite.position = Vector2.ZERO
		sprite.rotation = 0

func attack() -> void:
	if cooldown > 0 or game.stamina < 12 or game.search_progress > 0: return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var aim := get_global_mouse_position()-position
		if aim.length() > 12: facing = aim.normalized()
	cooldown = 0.52
	swing = 0.48
	hit_pending = true
	game.stamina -= 12
	game.sound(220, 0.08, 0.13)

func tick_attack(dt: float) -> void:
	swing = maxf(0,swing-dt)
	if not hit_pending or swing > 0.30: return
	hit_pending = false
	for target_enemy in game.enemies:
		if target_enemy.dead: continue
		var offset: Vector2 = target_enemy.position - position
		if offset.length() <= 65 and facing.dot(offset.normalized()) > 0.15 and game.clear_line(position, target_enemy.position):
			target_enemy.damage(40, offset.normalized())
			game.sound(80, 0.12, 0.22)
			break

func damage(amount: float, direction: Vector2) -> void:
	hp -= amount
	flash = 0.14
	knockback = direction * 125
	if hp <= 0:
		dead = true
		chasing = false
		collision_layer = 0
		collision_mask = 0
		game.kills += 1
		update_sprite()
	queue_redraw()

