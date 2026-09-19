extends CharacterBody3D

var game: Node3D
var enemy := false
var hp := 100.0
var cooldown := 0.0
var gait := 0.0
var hit_flash := 0.0
var chasing := false
var home := Vector3.ZERO
var wander := Vector3.ZERO
var wander_time := 0.0
var visual: Node3D
var left_leg: Node3D
var right_leg: Node3D
var arm: Node3D
var weapon: Node3D
var facing := Vector3(0, 0, -1)
var swing := 0.0
var dead := false

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)
	collision_layer = 2 if enemy else 4
	collision_mask = 1 | 2 | 4
	visual = Node3D.new()
	add_child(visual)
	var coat := Color("606b51") if not enemy else Color("70665d")
	var skin := Color("be9f7e") if not enemy else Color("89907a")
	game.box(visual, Vector3(0, 1.08, 0), Vector3(0.55, 0.61, 0.32), coat)
	game.box(visual, Vector3(0, 1.54, -0.035), Vector3(0.32, 0.34, 0.31), skin)
	game.box(visual, Vector3(0, 1.72, 0), Vector3(0.35, 0.1, 0.33), Color("30362d"))
	if not enemy:
		game.box(visual, Vector3(0, 1.7, -0.19), Vector3(0.34, 0.05, 0.2), Color("30362d"))
		game.box(visual, Vector3(0, 1.08, 0.24), Vector3(0.43, 0.5, 0.23), Color("333e2f"))
		game.box(visual, Vector3(0, 1, 0.37), Vector3(0.3, 0.18, 0.07), Color("737456"))
	else:
		game.box(visual, Vector3(-0.11, 1.17, -0.17), Vector3(0.17, 0.25, 0.03), Color("653f36"))
	for side in [-1, 1]:
		var leg := Node3D.new()
		visual.add_child(leg)
		leg.position = Vector3(side * 0.15, 0.79, 0)
		game.box(leg, Vector3(0, -0.3, 0), Vector3(0.21, 0.59, 0.23), Color("303b3d"))
		game.box(leg, Vector3(0, -0.66, -0.06), Vector3(0.23, 0.17, 0.36), Color("222726"))
		if side == -1: left_leg = leg
		else: right_leg = leg
		var limb := Node3D.new()
		visual.add_child(limb)
		limb.position = Vector3(side * 0.35, 1.29, 0)
		game.box(limb, Vector3(0, -0.16, 0), Vector3(0.18, 0.34, 0.21), coat)
		game.box(limb, Vector3(0, -0.4, 0), Vector3(0.15, 0.24, 0.16), skin)
		if enemy: limb.rotation.x = -0.8
		if side == 1: arm = limb
	if not enemy:
		weapon = Node3D.new()
		arm.add_child(weapon)
		weapon.position = Vector3(0, -0.45, -0.15)
		game.box(weapon, Vector3(0, 0, -0.26), Vector3(0.055, 0.055, 0.8), Color("9c5c49"))
		game.box(weapon, Vector3(0, -0.065, -0.63), Vector3(0.06, 0.17, 0.055), Color("bfb6a2"))
	home = position

func _physics_process(dt: float) -> void:
	if game.mode != "play" or dead: return
	cooldown = maxf(0, cooldown - dt)
	swing = maxf(0, swing - dt)
	hit_flash = maxf(0, hit_flash - dt)
	var direction := Vector3.ZERO
	var speed := 2.7
	if enemy:
		var distance := position.distance_to(game.player.position)
		var detection := 9.5 if game.running else (3.6 if game.crouching else 6.5)
		if distance < detection and game.clear_line(position, game.player.position): chasing = true
		if distance > 15: chasing = false
		if chasing:
			var destination: Vector3 = game.player.position
			if game.inside_house(position) != game.inside_house(destination):
				destination = Vector3(3, 0, 2.8 if game.inside_house(position) else 0.3)
			direction = (destination - position).normalized()
			speed = 1.55
			if distance < 1.15 and cooldown <= 0 and game.clear_line(position, game.player.position):
				game.hurt(9)
				cooldown = 1.3
		else:
			wander_time -= dt
			if wander_time <= 0:
				wander_time = game.rng.randf_range(2, 5)
				wander = home + Vector3(game.rng.randf_range(-2, 2), 0, game.rng.randf_range(-2, 2))
			if position.distance_to(wander) > 0.4: direction = (wander - position).normalized()
			speed = 0.55
	else:
		var input := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		direction = Vector3(input.x + input.y, 0, input.y - input.x).normalized()
		game.crouching = Input.is_physical_key_pressed(KEY_C)
		game.running = Input.is_physical_key_pressed(KEY_SHIFT) and game.stamina > 5 and direction.length() > 0 and not game.crouching
		if game.running: speed = 4.6
		if game.crouching: speed = 1.35
		if game.search_progress > 0: speed = 0
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_SPACE): attack()
		var mouse: Vector2 = get_viewport().get_mouse_position()
		var origin: Vector3 = game.camera.project_ray_origin(mouse)
		var ray: Vector3 = game.camera.project_ray_normal(mouse)
		var point = Plane(Vector3.UP, 0).intersects_ray(origin, ray)
		if point != null:
			var aim: Vector3 = point - position
			aim.y = 0
			if aim.length() > 0.4: facing = aim.normalized()
	if enemy and direction.length() > 0.1: facing = direction
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), dt * 12)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= 20 * dt
	move_and_slide()
	gait += dt * speed * 4 if direction.length() > 0 else dt * 2
	var step := sin(gait) * 0.55 if direction.length() > 0 else 0.0
	left_leg.rotation.x = step
	right_leg.rotation.x = -step
	visual.position.y = absf(sin(gait)) * 0.035 if direction.length() > 0 else 0.0
	visual.scale.y = 0.76 if not enemy and game.crouching else 1.0
	if not enemy: arm.rotation.x = -sin(swing / 0.32 * PI) * 2.2

func attack() -> void:
	if cooldown > 0 or game.stamina < 12 or game.search_progress > 0: return
	cooldown = 0.55
	swing = 0.32
	game.stamina -= 12
	game.sound(220, 0.08, 0.13)
	for target in game.enemies:
		if target.dead: continue
		var offset: Vector3 = target.position - position
		if offset.length() < 2.1 and facing.dot(offset.normalized()) > 0.15 and game.clear_line(position, target.position):
			target.damage(40, facing)
			game.sound(80, 0.12, 0.28)
			break

func damage(amount: float, direction: Vector3) -> void:
	hp -= amount
	velocity = direction * 4
	move_and_slide()
	game.sparks(position + Vector3.UP, Color("b85e42"))
	if hp <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		visual.rotation.z = PI / 2
		visual.position.y = 0.2
		game.kills += 1
