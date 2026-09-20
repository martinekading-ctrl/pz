extends Node2D
## Live 3D model composited at its ground anchor into the existing isometric world.
const PLAYER_RIG := preload("res://art/characters/quaternius_zombie_apocalypse/Characters_Matt.gltf")
const ZOMBIE_RIG := preload("res://art/characters/quaternius_zombie_apocalypse/Zombie_Basic.gltf")
const LOOPED_CLIPS := [&"Idle", &"Idle_Gun", &"Idle_Attack", &"Walk", &"Walk_Gun", &"Run", &"Run_Gun", &"Run_Arms"]
const IMPORTED_WEAPONS := [&"Axe", &"Guitar", &"Knife", &"Pistol", &"Rifle", &"Shotgun", &"SMG", &"Spear", &"WoodenBat_Barbed", &"WoodenBat_Saw"]

var kind := "player"
var actor: Node2D
var viewport: SubViewport
var model: Node3D
var rigged_character: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var rigged_mode := false
var animation_state := ""
var animation_clip := ""
var imported_weapon_nodes := {}
var torso: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var locomotion_blend := 0.0
var run_blend := 0.0
var legs: Array[Node3D] = []
var wheels: Array[Node3D] = []
var pistol: Node3D
var weapon: Node3D
var sprite: Sprite2D
var yaw := 0.0
var wheel_angle := 0.0

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node

func joint(parent: Node3D, at: Vector3) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = at
	return node

func _ready() -> void:
	actor = get_parent()
	viewport = SubViewport.new()
	viewport.size = Vector2i(384,384) if kind == "vehicle" else Vector2i(192,192)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_CLEAR_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c6d2dc")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	light.light_energy = 1.1
	stage.add_child(light)
	model = joint(stage, Vector3.ZERO)
	if kind == "vehicle": build_vehicle()
	else: build_person()
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.0 if kind == "vehicle" else 3.8
	var center := Vector3(0,0.65,0)
	camera.position = center + Vector3(6,4.2426407,6)
	camera.look_at(center)
	camera.current = true
	sprite = Sprite2D.new()
	sprite.texture = viewport.get_texture()
	sprite.centered = false
	var pixels_per_meter := 71.554175
	sprite.scale = Vector2.ONE * pixels_per_meter * camera.size / float(viewport.size.y)
	sprite.position = -camera.unproject_position(Vector3.ZERO) * sprite.scale
	add_child(sprite)
	queue_redraw()

func build_person() -> void:
	if build_rigged_person():
		return
	build_procedural_person()

func build_rigged_person() -> bool:
	var packed: PackedScene = ZOMBIE_RIG if kind == "zombie" else PLAYER_RIG
	if packed == null:
		return false
	rigged_character = packed.instantiate() as Node3D
	if rigged_character == null:
		return false
	model.add_child(rigged_character)
	animation_player = rigged_character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = rigged_character.find_child("Skeleton3D", true, false) as Skeleton3D
	if animation_player == null or skeleton == null:
		rigged_character.queue_free()
		rigged_character = null
		return false
	for clip: StringName in LOOPED_CLIPS:
		if animation_player.has_animation(clip):
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if kind == "player":
		for weapon_name: StringName in IMPORTED_WEAPONS:
			var weapon_mesh := rigged_character.find_child(weapon_name, true, false) as GeometryInstance3D
			if weapon_mesh != null:
				weapon_mesh.visible = false
				imported_weapon_nodes[weapon_name] = weapon_mesh
	rigged_mode = true
	return true

func build_procedural_person() -> void:
	var infected := kind == "zombie"
	var skin := Color("87917c") if infected else Color("c59d7b")
	var shirt: Color = actor.shirt_color if infected else Color("53684e")
	var pants: Color = actor.pants_color if infected else Color("364554")
	torso = joint(model, Vector3(0,0.9,0))
	box(torso,Vector3(0,0.26,0),Vector3(0.42,0.48,0.25),shirt)
	box(torso,Vector3(0,0.02,0),Vector3(0.36,0.08,0.27),Color("3f3528"))
	box(torso,Vector3(0,0.55,0),Vector3(0.12,0.12,0.12),skin)
	var head := box(torso,Vector3(0,0.69,0),Vector3(0.25,0.28,0.23),skin)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.14
	head_mesh.height = 0.3
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	box(torso,Vector3(0,0.81,0.01),Vector3(0.26,0.08,0.24),Color("39352f"))
	box(torso,Vector3(0,0.67,-0.135),Vector3(0.065,0.065,0.065),skin)
	for side: float in [-1.0,1.0]:
		box(torso,Vector3(side*0.065,0.73,-0.12),Vector3(0.025,0.025,0.012),Color("292929"))
		var arm := joint(torso,Vector3(side*0.25,0.43,0))
		box(arm,Vector3(0,-0.12,0),Vector3(0.14,0.25,0.16),shirt)
		var elbow := joint(arm,Vector3(0,-0.25,0))
		box(elbow,Vector3(0,-0.1,0),Vector3(0.11,0.2,0.12),skin)
		elbows.append(elbow)
		arms.append(arm)
		var leg := joint(model,Vector3(side*0.105,0.9,0))
		box(leg,Vector3(0,-0.22,0),Vector3(0.17,0.43,0.2),pants)
		var calf := joint(leg,Vector3(0,-0.43,0))
		box(calf,Vector3(0,-0.18,0),Vector3(0.15,0.36,0.17),pants)
		box(calf,Vector3(0,-0.4,-0.05),Vector3(0.18,0.13,0.31),Color("292a27"))
		legs.append(leg)
	if infected:
		box(torso,Vector3(-0.07,0.3,-0.132),Vector3(0.13,0.12,0.012),Color("703d35"))
	else:
		box(torso,Vector3(0,0.27,0.21),Vector3(0.32,0.38,0.21),Color("766a47"))
		for side: float in [-1.0,1.0]:
			box(torso,Vector3(side*0.13,0.27,-0.132),Vector3(0.04,0.42,0.03),Color("827754"))
		weapon = joint(elbows[1],Vector3(0,-0.2,0))
		box(weapon,Vector3(0,0,-0.23),Vector3(0.035,0.035,0.52),Color("81766a"))
		box(weapon,Vector3(0,0.04,-0.48),Vector3(0.035,0.1,0.035),Color("81766a"))
		pistol = joint(elbows[1],Vector3(0,-0.2,0))
		box(pistol,Vector3(0,0,-0.09),Vector3(0.055,0.065,0.23),Color("383d40"))
		box(pistol,Vector3(0,-0.05,-0.015),Vector3(0.05,0.12,0.06),Color("25292b"))

func uses_skeletal_animation() -> bool:
	return rigged_mode and skeleton != null and animation_player != null

func set_imported_weapon_visibility() -> void:
	for weapon_mesh: GeometryInstance3D in imported_weapon_nodes.values():
		weapon_mesh.visible = false
	var selected := &"Pistol" if actor.weapon_is_firearm else &"WoodenBat_Barbed"
	var selected_mesh: GeometryInstance3D = imported_weapon_nodes.get(selected) as GeometryInstance3D
	if selected_mesh != null:
		selected_mesh.visible = actor.weapon_is_firearm or actor.weapon_visual_length > 0.0

func desired_rig_animation() -> Dictionary:
	var state: String = actor.presentation_state()
	if kind == "zombie":
		if state == "dead":
			return {"state":"dead", "clip":&"Death", "speed":1.0, "blend":0.16}
		if state == "sleeping":
			return {"state":"sleeping", "clip":&"Death", "speed":1.0, "blend":0.0, "seek_end":true}
		if state == "stagger":
			return {"state":"stagger", "clip":&"HitReact", "speed":1.35, "blend":0.06}
		if state.begins_with("attack_"):
			return {"state":"attack", "clip":&"Punch", "speed":clip_speed(&"Punch", 0.82), "blend":0.07}
		if state == "climb":
			return {"state":"climb", "clip":&"Jump", "speed":clip_speed(&"Jump", 0.9), "blend":0.08}
		if state == "walk":
			var chase_speed := 1.0 if actor.state == actor.State.CHASE else 0.72
			return {"state":"walk", "clip":&"Walk", "speed":chase_speed, "blend":0.16}
		return {"state":"idle", "clip":&"Idle_Attack", "speed":0.82, "blend":0.18}
	if state == "dead":
		return {"state":"dead", "clip":&"Death", "speed":1.0, "blend":0.16}
	if state == "hurt":
		return {"state":"hurt", "clip":&"HitReact", "speed":1.35, "blend":0.06}
	if state.begins_with("melee_"):
		return {"state":"melee", "clip":&"Slash", "speed":clip_speed(&"Slash", actor.weapon_swing_seconds), "blend":0.06}
	if state == "climb":
		return {"state":"climb", "clip":&"Jump", "speed":clip_speed(&"Jump", actor.traversal_duration), "blend":0.08}
	if state.begins_with("crouch_"):
		return {"state":state, "clip":&"Duck", "speed":0.72, "blend":0.12}
	var gun: bool = bool(actor.weapon_is_firearm)
	if state == "run":
		return {"state":"run_gun" if gun else "run", "clip":&"Run_Gun" if gun else &"Run", "speed":clampf(actor.velocity_mps.length() / 3.8, 0.72, 1.15), "blend":0.14}
	if state == "walk":
		return {"state":"walk_gun" if gun else "walk", "clip":&"Walk_Gun" if gun else &"Walk", "speed":clampf(actor.velocity_mps.length() / 1.6, 0.62, 1.08), "blend":0.16}
	if state == "fire":
		return {"state":"fire", "clip":&"Idle_Gun", "speed":1.0, "blend":0.05}
	if state == "aim":
		return {"state":"aim", "clip":&"Idle_Gun", "speed":0.9, "blend":0.14}
	return {"state":"idle_gun" if gun else "idle", "clip":&"Idle_Gun" if gun else &"Idle", "speed":0.9, "blend":0.18}

func clip_speed(clip: StringName, duration: float) -> float:
	if animation_player == null or not animation_player.has_animation(clip):
		return 1.0
	return animation_player.get_animation(clip).length / maxf(0.05, duration)

func update_rigged_person(delta: float) -> void:
	model.rotation.z = 0.0
	model.position.y = 0.0
	var flash: float = actor.visual_flash if kind == "zombie" else actor.hurt_flash
	sprite.modulate = Color(1.5,1.4,1.4) if flash > 0.0 else Color.WHITE
	if kind == "player":
		set_imported_weapon_visibility()
	var target := desired_rig_animation()
	var next_state := str(target.state)
	var next_clip := StringName(target.clip)
	if not animation_player.has_animation(next_clip):
		next_clip = &"Idle"
	var target_speed := float(target.speed)
	if next_state != animation_state or str(next_clip) != animation_clip:
		animation_state = next_state
		animation_clip = str(next_clip)
		animation_player.speed_scale = target_speed
		animation_player.play(next_clip, float(target.blend), 1.0)
		if bool(target.get("seek_end", false)):
			animation_player.seek(animation_player.get_animation(next_clip).length, true)
	else:
		animation_player.speed_scale = lerpf(animation_player.speed_scale, target_speed, 1.0-exp(-delta*8.0))

func build_vehicle() -> void:
	var paint := Color("526e83")
	box(model,Vector3(0,0.64,0),Vector3(1.72,0.52,4.25),paint)
	box(model,Vector3(0,1.04,0.23),Vector3(1.52,0.56,2.65),Color("243d49"))
	box(model,Vector3(0,1.35,0.23),Vector3(1.65,0.13,2.82),paint)
	for side: float in [-1.0,1.0]:
		for longitudinal: float in [-1.1,0.2,1.53]:
			box(model,Vector3(side*0.79,1.08,longitudinal),Vector3(0.08,0.52,0.09),paint)
		for longitudinal: float in [-1.32,1.3]:
			var wheel := joint(model,Vector3(side*0.87,0.36,longitudinal))
			var tire := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.35
			mesh.bottom_radius = 0.35
			mesh.height = 0.22
			mesh.radial_segments = 16
			tire.mesh = mesh
			tire.rotation.z = PI/2.0
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("242727")
			tire.material_override = material
			wheel.add_child(tire)
			box(wheel,Vector3(side*0.13,0,0),Vector3(0.03,0.37,0.08),Color("92999a"))
			wheels.append(wheel)
		box(model,Vector3(side*0.57,0.69,-2.14),Vector3(0.36,0.18,0.035),Color("eddfae"))
		box(model,Vector3(side*0.61,0.68,2.14),Vector3(0.25,0.2,0.035),Color("97372c"))
		box(model,Vector3(side*0.92,1.05,-0.9),Vector3(0.16,0.13,0.24),paint)
	for end: float in [-1.0,1.0]:
		box(model,Vector3(0,0.4,end*2.16),Vector3(1.75,0.14,0.09),Color("44494c"))

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(model): return
	# Stop GPU updates for offscreen objects; 2D node still owns sorting and collisions.
	var screen := actor.get_global_transform_with_canvas().origin
	var visible_now := actor.is_visible_in_tree() and Rect2(Vector2(-300,-300),get_viewport_rect().size+Vector2(600,600)).has_point(screen)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible_now else SubViewport.UPDATE_DISABLED
	if animation_player != null:
		animation_player.active = visible_now
	if not visible_now: return
	queue_redraw()
	var heading: Vector2 = actor.heading_logical if kind == "vehicle" else actor.world_map.world_to_map(actor.facing).normalized()
	var target_yaw := atan2(-heading.x,-heading.y)
	yaw = lerp_angle(yaw,target_yaw,minf(1.0,delta*18.0))
	model.rotation.y = yaw
	if kind == "vehicle":
		wheel_angle += actor.speed_mps * delta / 0.35
		for wheel: Node3D in wheels: wheel.rotation.x = wheel_angle
		return
	if rigged_mode:
		update_rigged_person(delta)
		return
	var infected := kind == "zombie"
	var dead_now: bool = actor.is_dead() if infected else actor.dead
	var sleeping_now: bool = infected and actor.state == actor.State.SLEEPING
	model.rotation.z = PI/2.0 if dead_now or sleeping_now else 0.0
	model.position.y = 0.16 if dead_now or sleeping_now else 0.0
	if dead_now or sleeping_now: return
	var flash: float = actor.visual_flash if infected else actor.hurt_flash
	sprite.modulate = Color(1.5,1.4,1.4) if flash > 0.0 else Color.WHITE
	var moving_now: bool = actor.state in [actor.State.WANDER,actor.State.CHASE,actor.State.INVESTIGATE] if infected else actor.moving
	var blend_weight := 1.0-exp(-delta*12.0)
	locomotion_blend = lerpf(locomotion_blend,1.0 if moving_now else 0.0,blend_weight)
	var wants_run: bool = not infected and actor.running and moving_now
	run_blend = lerpf(run_blend,1.0 if wants_run else 0.0,blend_weight)
	var gait_phase := float(actor.gait)
	var amplitude := 0.3 if infected else lerpf(0.36,0.62,run_blend)
	var bounce := (1.0-cos(gait_phase*2.0))*0.5*lerpf(0.018,0.045,run_blend)*locomotion_blend
	# Move pelvis and torso together; recovery knee folds backward while the thigh lifts.
	model.position.y = bounce
	torso.position.y = 0.9
	torso.rotation.x = -0.12 if infected else -0.12*run_blend
	torso.rotation.z = sin(gait_phase)*0.025*locomotion_blend
	for index: int in 2:
		var phase := gait_phase + float(index)*PI
		var swing := sin(phase)
		legs[index].rotation.x = swing*amplitude*locomotion_blend
		legs[index].get_child(1).rotation.x = -(0.06+pow(maxf(0.0,swing),1.3)*lerpf(0.48,1.15,run_blend))*locomotion_blend
		arms[index].rotation.x = -swing*lerpf(0.25,0.52,run_blend)*locomotion_blend+(-0.35 if infected else 0.0)
		elbows[index].rotation.x = -lerpf(0.12,0.95,run_blend)
	if infected:
		if actor.state in [actor.State.ATTACK,actor.State.BREACH]:
			var phase := fmod(float(actor.state_time),0.82)/0.82
			for arm: Node3D in arms: arm.rotation.x = -0.4-sin(phase*PI)*1.1
		if actor.state == actor.State.STAGGER: torso.rotation.x = sin(float(actor.state_time)/0.22*PI)*0.35
	else:
		weapon.visible = actor.weapon_visual_length > 0.0 and not actor.weapon_is_firearm
		pistol.visible = actor.weapon_is_firearm
		weapon.scale.z = maxf(0.2,float(actor.weapon_visual_length)/30.0)
		if actor.crouching:
			torso.position.y -= 0.25
			torso.rotation.x = -0.3
		if actor.weapon_is_firearm:
			for index: int in 2:
				arms[index].rotation.x = -1.15 + float(actor.firearm_recoil)*1.5
				elbows[index].rotation.x = -0.2
		elif actor.swing_remaining > 0.0:
			var phase := 1.0-float(actor.swing_remaining)/maxf(0.01,float(actor.weapon_swing_seconds))
			arms[1].rotation.x = -0.2-sin(phase*PI)*2.0
			torso.rotation.y = sin(phase*TAU)*0.22
		else: torso.rotation.y = 0.0

func _draw() -> void:
	var radius := Vector2(108,42) if kind == "vehicle" else Vector2(17,7)
	var points := PackedVector2Array()
	for index in 32: points.append(Vector2(cos(index*TAU/32.0),sin(index*TAU/32.0))*radius)
	draw_colored_polygon(points,Color(0,0,0,0.22))

	if kind == "player" and actor.weapon_is_firearm and actor.aim_visible:
		var start: Vector2 = Vector2(0,-65)+actor.facing*35.0
		draw_dashed_line(start,start+actor.facing*150.0,Color(0.9,0.8,0.5,0.55),2.0,8.0)
		if actor.muzzle_flash>0.0: draw_circle(start,6.0,Color("ffd779"))
