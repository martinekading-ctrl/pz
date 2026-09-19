extends RefCounted
static func run(game: Node2D) -> void:
	game.player.set_physics_process(false)
	var capture: bool="--expansion-capture" in OS.get_cmdline_user_args()
	var path: Array[Vector2]=[Vector2(48,49),Vector2(48,85),Vector2(120,80),Vector2(180,78),Vector2(232,93),Vector2(242,160),Vector2(240,172),Vector2(155,172),Vector2(125,183),Vector2(111,217),Vector2(111,279),Vector2(111,217),Vector2(125,183),Vector2(155,172),Vector2(240,172),Vector2(241,232),Vector2(236,289),Vector2(226,346),Vector2(234,372),Vector2(287,411),Vector2(350,451),Vector2(421,439)]
	var max_chunks:=0
	for destination in path:
		var target: Vector2=game.world_map.map_to_world(destination)
		var steps:=0
		while game.player.position.distance_to(target)>1.0 and steps<20000:
			var before: Vector2=game.player.position
			game.player.move_world((target-before).limit_length(12))
			if game.player.position.distance_to(before)<0.1:
				push_error("Expansion route blocked at "+str(game.world_map.world_to_map(before)))
				game.get_tree().quit(1)
				return
			steps+=1
		if steps>=20000:
			game.get_tree().quit(1)
			return
		game.world_map.expansion.update_chunks(destination)
		max_chunks=maxi(max_chunks,game.world_map.expansion.chunks.size())
		if capture and destination in [Vector2(48,85),Vector2(111,279),Vector2(421,439)]:
			game.camera.position_smoothing_enabled=false
			game.camera.zoom=Vector2(0.32,0.32)
			await game.get_tree().create_timer(0.4).timeout
			game.get_viewport().get_texture().get_image().save_png("res://build/expansion-"+str(int(destination.x))+"-v0101.png")
	if game.player.can_stand(game.world_map.map_to_world(Vector2(381,469))):
		push_error("Pond is not blocking")
		game.get_tree().quit(1)
		return
	if max_chunks>49:
		game.get_tree().quit(1)
		return
	print("EXPANSION PASS: continuous movement across old boundary, residential road and park paths; pond collision; max loaded chunks ",max_chunks)
	game.get_tree().quit()
