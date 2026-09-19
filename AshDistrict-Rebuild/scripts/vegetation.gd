extends Node2D
var world_map: Node2D
var trunks: Array[Vector2] = []
var crowns: Array[Sprite2D] = []
var grass_count := 0
var low_plants: Array[Sprite2D] = []
var anchor_cache: Dictionary = {}
var foliage_material: ShaderMaterial
func setup(map: Node2D) -> void:
	world_map=map
	foliage_material=ShaderMaterial.new()
	foliage_material.shader=load("res://shaders/foliage.gdshader")
	var rng:=RandomNumberGenerator.new()
	rng.seed=90210
	for x in range(5,94,7):
		for y in range(5,70,7):
			var cell:=Vector2(x+rng.randf_range(-2,2),y+rng.randf_range(-2,2))
			if not allowed(cell,4.0) or rng.randf()>0.7: continue
			trunks.append(cell)
			var path: String="res://art/nature/tree-"+str(rng.randi_range(0,5))+".png"
			if rng.randf()<0.25: path="res://art/nature/pine-"+str(rng.randi_range(0,2))+".png"
			var sprite:=plant(path,cell,rng.randf_range(6.0,8.0)*64.0)
			crowns.append(sprite)
	for i in 220:
		var center:=Vector2(rng.randf_range(2,94),rng.randf_range(2,70))
		# Sparse groups with empty space between them instead of isolated dots.
		for j in rng.randi_range(2,4):
			var cell:=center+Vector2(rng.randf_range(-0.7,0.7),rng.randf_range(-0.7,0.7))
			if not allowed(cell,0.9): continue
			var kind:=rng.randf()
			var bush:=kind>0.88
			var height_m:=rng.randf_range(0.6,1.2) if bush else (rng.randf_range(0.25,0.5) if kind>0.35 else rng.randf_range(0.1,0.25))
			var sprite:=plant("res://art/nature/"+("bush-" if bush else "grass-")+str(rng.randi_range(0,2))+".png",cell,height_m*64.0)
			sprite.material=foliage_material
			sprite.set_meta("height_m",height_m)
			sprite.set_meta("kind","bush" if bush else "grass")
			low_plants.append(sprite)
			grass_count+=1
	print("VEGETATION: ",trunks.size()," trees, ",grass_count," low plants")
func allowed(cell: Vector2,margin: float) -> bool:
	for surface in world_map.surfaces:
		if surface.z_index <= -30: continue
		var rect: Rect2=surface.get_meta("logical_rect")
		if rect.grow(margin).has_point(cell): return false
	for key in world_map.BUILDINGS:
		if Rect2(world_map.BUILDINGS[key]).grow(margin+1.0).has_point(cell): return false
	if margin>2 and Rect2(11,39,25,20).has_point(cell): return false
	return true
func plant(path: String,cell: Vector2,height: float) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.texture=load(path)
	sprite.position=world_map.map_to_world(cell)
	var texture_size:=Vector2(sprite.texture.get_size())
	var base_y:=texture_size.y
	var base_x:=texture_size.x*0.5
	if not anchor_cache.has(path):
		# Opaque trunk pixels define the ground anchor; soft baked shadows do not.
		var image:=sprite.texture.get_image()
		var bottom:=0
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x,y).a>0.9: bottom=maxi(bottom,y)
		var sum_x:=0.0
		var count:=0
		for y in range(maxi(0,bottom-4),bottom+1):
			for x in image.get_width():
				if image.get_pixel(x,y).a>0.9:
					sum_x+=x
					count+=1
		base_y=float(bottom+1)
		if count>0: base_x=sum_x/count
		anchor_cache[path]=Vector2(base_x,base_y)
	var anchor: Vector2=anchor_cache[path]
	base_y=anchor.y
	sprite.offset=texture_size*0.5-anchor
	sprite.scale=Vector2.ONE*height/base_y
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index=roundi((sprite.position.y)*0.2)
	add_child(sprite)
	return sprite
func blocks(cell: Vector2) -> bool:
	for trunk in trunks:
		if cell.distance_squared_to(trunk)<0.42*0.42: return true
	return false
func _process(delta: float) -> void:
	var player: Node2D=world_map.get_parent().get("player")
	if not is_instance_valid(player): return
	for crown in crowns:
		var local_box:=crown.get_rect()
		var box:=Rect2(crown.position+local_box.position*crown.scale,local_box.size*crown.scale)
		var obscured:=player.position.y<crown.position.y and box.has_point(player.position-Vector2(0,60))
		crown.modulate.a=move_toward(crown.modulate.a,0.28 if obscured else 1.0,delta*4)
