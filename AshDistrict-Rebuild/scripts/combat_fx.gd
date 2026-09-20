extends Node2D

var effects: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4096

func spawn_impact(world_position: Vector2, direction: Vector2, lethal: bool = false, player_hit: bool = false) -> void:
	var normalized := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var droplets: Array[Dictionary] = []
	var count := 9 if lethal else 6
	for index: int in count:
		var spread := -0.9 + 1.8 * float(index) / float(maxi(1, count - 1))
		var speed := 42.0 + float((index * 17) % 31)
		droplets.append({
			"offset": Vector2.ZERO,
			"velocity": normalized.rotated(spread) * speed + Vector2(0.0, -18.0 - float(index % 3) * 6.0),
			"radius": 2.2 + float(index % 2),
		})
	effects.append({
		"position": world_position,
		"age": 0.0,
		"duration": 0.42 if lethal else 0.3,
		"lethal": lethal,
		"player_hit": player_hit,
		"droplets": droplets,
	})
	queue_redraw()

func _process(delta: float) -> void:
	for effect: Dictionary in effects:
		effect.age = float(effect.age) + delta
		for droplet: Dictionary in effect.droplets:
			droplet.velocity = Vector2(droplet.velocity) + Vector2(0.0, 150.0) * delta
			droplet.offset = Vector2(droplet.offset) + Vector2(droplet.velocity) * delta
	for index: int in range(effects.size() - 1, -1, -1):
		if float(effects[index].age) >= float(effects[index].duration):
			effects.remove_at(index)
	queue_redraw()

func active_effect_count() -> int:
	return effects.size()

func _draw() -> void:
	for effect: Dictionary in effects:
		var age := float(effect.age)
		var duration := float(effect.duration)
		var progress := clampf(age / duration, 0.0, 1.0)
		var origin := Vector2(effect.position)
		var ring_color := Color("f0d89a") if not bool(effect.player_hit) else Color("e88772")
		ring_color.a = (1.0 - progress) * 0.8
		draw_arc(origin, lerpf(5.0, 23.0, progress), 0.0, TAU, 20, ring_color, lerpf(4.0, 1.0, progress), true)
		for droplet: Dictionary in effect.droplets:
			var blood := Color("762f2a") if not bool(effect.player_hit) else Color("9b4035")
			blood.a = 1.0 - progress
			draw_circle(origin + Vector2(droplet.offset), float(droplet.radius) * (1.0 - progress * 0.45), blood)
