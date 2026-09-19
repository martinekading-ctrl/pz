extends Control

const InjuryRules = preload("res://scripts/injury_rules.gd")

var injuries: Dictionary = InjuryRules.fresh_state()
var selected_part := "torso"

func set_data(value: Dictionary, selected: String) -> void:
	injuries = value
	selected_part = selected
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 34.0)
	draw_part_head(center + Vector2(0, 35), 27.0)
	draw_part_torso(center)
	draw_part_limb("arms", PackedVector2Array([
		center + Vector2(-49, 111), center + Vector2(-79, 181), center + Vector2(-88, 247)
	]), 25.0)
	draw_part_limb("arms", PackedVector2Array([
		center + Vector2(49, 111), center + Vector2(79, 181), center + Vector2(88, 247)
	]), 25.0)
	draw_part_limb("legs", PackedVector2Array([
		center + Vector2(-24, 238), center + Vector2(-30, 313), center + Vector2(-42, 382)
	]), 31.0)
	draw_part_limb("legs", PackedVector2Array([
		center + Vector2(24, 238), center + Vector2(30, 313), center + Vector2(42, 382)
	]), 31.0)
	draw_bandages(center)

func draw_part_head(head_center: Vector2, radius: float) -> void:
	var color := part_color("head")
	draw_circle(head_center, radius + (4.0 if selected_part == "head" else 2.0), outline_color("head"))
	draw_circle(head_center, radius, color)

func draw_part_torso(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(-38, 77), center + Vector2(38, 77),
		center + Vector2(51, 143), center + Vector2(33, 239),
		center + Vector2(-33, 239), center + Vector2(-51, 143),
	])
	if selected_part == "torso":
		var outline := PackedVector2Array()
		for point: Vector2 in points:
			outline.append(center + (point - center) * 1.055)
		draw_colored_polygon(outline, outline_color("torso"))
	draw_colored_polygon(points, part_color("torso"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[5], points[0]]), Color("18211e"), 2.0, true)

func draw_part_limb(part: String, points: PackedVector2Array, width: float) -> void:
	draw_polyline(points, outline_color(part), width + (9.0 if selected_part == part else 5.0), true)
	draw_polyline(points, part_color(part), width, true)

func draw_bandages(center: Vector2) -> void:
	var bandage_color := Color("e2ddd0")
	if bool(injuries.head.get("bandaged", false)):
		draw_line(center + Vector2(-24, 31), center + Vector2(24, 31), bandage_color, 9.0, true)
	if bool(injuries.torso.get("bandaged", false)):
		draw_line(center + Vector2(-44, 158), center + Vector2(44, 158), bandage_color, 12.0, true)
	if bool(injuries.arms.get("bandaged", false)):
		for side in [-1.0, 1.0]:
			draw_line(center + Vector2(side * 66, 162), center + Vector2(side * 79, 189), bandage_color, 12.0, true)
	if bool(injuries.legs.get("bandaged", false)):
		for side in [-1.0, 1.0]:
			draw_line(center + Vector2(side * 27, 283), center + Vector2(side * 33, 314), bandage_color, 14.0, true)

func part_color(part: String) -> Color:
	var severity := int(injuries.get(part, {}).get("severity", 0))
	var base: Color = Color([Color("5e7f70"), Color("c6a34f"), Color("c96f45"), Color("9b4150")][clampi(severity, 0, 3)])
	if bool(injuries.get(part, {}).get("infected", false)):
		base = base.lerp(Color("77508d"), 0.45)
	return base

func outline_color(part: String) -> Color:
	return Color("f1d77d") if selected_part == part else Color("27342f")
