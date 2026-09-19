extends SceneTree

const SOURCE_ROOT := "res://art/sources/generated/wood_wall"
const OUTPUT_ROOT := "res://art/wood_wall_v1"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	import_repeat_texture(
		SOURCE_ROOT + "/01_base/wood_house_blue_base-source.png",
		OUTPUT_ROOT + "/siding_blue.png"
	)
	import_standalone(
		SOURCE_ROOT + "/03_doors/wood_door_a-source.png",
		OUTPUT_ROOT + "/door_wood.png",
		Vector2i(220, 512),
		0.08
	)
	import_standalone(
		SOURCE_ROOT + "/04_windows/wood_window_a-source.png",
		OUTPUT_ROOT + "/window_double.png",
		Vector2i(512, 469),
		0.04
	)
	import_standalone(
		SOURCE_ROOT + "/05_barricades/wood_barricade_a-source.png",
		OUTPUT_ROOT + "/barricade.png",
		Vector2i(256, 512),
		0.08
	)
	for entry: Dictionary in [
		{"source": "wood_damage_peel_a-source.png", "target": "damage_peel.png"},
		{"source": "wood_damage_crack_a-source.png", "target": "damage_crack.png"},
		{"source": "wood_damage_stain_a-source.png", "target": "damage_stain.png"}
	]:
		import_standalone(
			SOURCE_ROOT + "/02_damage/" + str(entry.source),
			OUTPUT_ROOT + "/" + str(entry.target),
			Vector2i(256, 256),
			0.04,
			true
		)
	print("WOOD WALL IMPORT PASS: siding, door, window, barricade and 3 damage decals")
	quit()

func import_repeat_texture(source_path: String, target_path: String) -> void:
	var image := Image.load_from_file(source_path)
	assert(not image.is_empty(), "Missing texture source: " + source_path)
	image.convert(Image.FORMAT_RGBA8)
	image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	blend_opposite_edges(image, 48, true)
	blend_opposite_edges(image, 48, false)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			color.a = 1.0
			image.set_pixel(x, y, color)
	assert(image.save_png(target_path) == OK, "Cannot save " + target_path)

func blend_opposite_edges(image: Image, band: int, horizontal: bool) -> void:
	var source := image.duplicate()
	var long_size: int = image.get_height() if horizontal else image.get_width()
	var edge_size: int = image.get_width() if horizontal else image.get_height()
	for along: int in long_size:
		for offset: int in band:
			var strength := 1.0 - float(offset) / float(band - 1)
			var near_position := Vector2i(offset, along) if horizontal else Vector2i(along, offset)
			var far_position := Vector2i(edge_size - 1 - offset, along) if horizontal else Vector2i(along, edge_size - 1 - offset)
			var near_color: Color = source.get_pixelv(near_position)
			var far_color: Color = source.get_pixelv(far_position)
			var shared: Color = near_color.lerp(far_color, 0.5)
			image.set_pixelv(near_position, near_color.lerp(shared, strength))
			image.set_pixelv(far_position, far_color.lerp(shared, strength))

func import_standalone(
	source_path: String,
	target_path: String,
	target_size: Vector2i,
	alpha_cutoff: float,
	preserve_source_scale: bool = false
) -> void:
	var source := Image.load_from_file(source_path)
	assert(not source.is_empty(), "Missing sprite source: " + source_path)
	source.convert(Image.FORMAT_RGBA8)
	for y: int in source.get_height():
		for x: int in source.get_width():
			var color := source.get_pixel(x, y)
			if color.a < alpha_cutoff:
				color = Color(0.0, 0.0, 0.0, 0.0)
			elif color.a > 0.94:
				color.a = 1.0
			source.set_pixel(x, y, color)
	var used := source.get_used_rect()
	assert(used.size.x > 0 and used.size.y > 0, "Empty alpha after cleanup: " + source_path)
	var cropped := source.get_region(used)
	var output := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0.0, 0.0, 0.0, 0.0))
	var padding: int = 6 if preserve_source_scale else 2
	var available := Vector2i(target_size.x - padding * 2, target_size.y - padding * 2)
	var scale_factor: float = minf(
		float(available.x) / float(cropped.get_width()),
		float(available.y) / float(cropped.get_height())
	)
	var scaled_size := Vector2i(
		maxi(1, roundi(cropped.get_width() * scale_factor)),
		maxi(1, roundi(cropped.get_height() * scale_factor))
	)
	cropped.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_LANCZOS)
	var destination := Vector2i(
		(target_size.x - scaled_size.x) / 2,
		target_size.y - padding - scaled_size.y
	)
	output.blit_rect(cropped, Rect2i(Vector2i.ZERO, scaled_size), destination)
	assert(output.save_png(target_path) == OK, "Cannot save " + target_path)
