extends Node2D

var world_map: Node2D
var hinge: Vector2
var closed_vector: Vector2
var open_vector: Vector2
var opened := false
var amount := 0.0
var leaf: Polygon2D
var height := 136.0
var health := 120.0
var max_health := 120.0
var broken := false

func setup(map: Node2D,origin: Vector2,closed: Vector2,swing: Vector2,texture: Texture2D,region: Rect2,door_height: float = 136.0) -> void:
	world_map=map
	hinge=origin
	closed_vector=closed
	open_vector=swing
	height=door_height
	leaf=Polygon2D.new()
	leaf.texture=texture
	leaf.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.uv=PackedVector2Array([Vector2(region.position.x,region.end.y),region.end,Vector2(region.end.x,region.position.y),region.position])
	add_child(leaf)
	step(0.0)

func midpoint() -> Vector2:
	return world_map.map_to_world(hinge+closed_vector*0.5)

func near(point: Vector2) -> bool:
	return world_map.world_to_map(point).distance_to(hinge+closed_vector*.5)*.5<preload("res://scripts/player_metrics.gd").INTERACTION_METERS

func toggle(point: Vector2) -> bool:
	if not near(point): return false
	if broken: return false
	var logical: Vector2=world_map.world_to_map(point)
	if opened and logical.distance_to(Geometry2D.get_closest_point_to_segment(logical,hinge,hinge+closed_vector))<0.6: return false
	opened=not opened
	return true

func tip() -> Vector2:
	return hinge+closed_vector*cos(amount*PI*0.5)+open_vector*sin(amount*PI*0.5)

func blocks(point: Vector2) -> bool:
	if broken: return false
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,hinge,tip()))<0.1

func damage(value: float) -> Dictionary:
	if broken:
		return {"broken":true,"just_broken":false,"health":0.0}
	health=maxf(0.0,health-value)
	var just_broken:=health<=0.0
	if just_broken:
		broken=true
		opened=true
		amount=1.0
	return {"broken":broken,"just_broken":just_broken,"health":health}

func repair(value: float) -> bool:
	if health>=max_health and not broken:
		return false
	health=minf(max_health,health+value)
	if health>0.0:
		broken=false
	return true

func step(delta: float) -> void:
	if broken:
		opened=true
	amount=move_toward(amount,1.0 if opened else 0.0,delta*4.0)
	var a: Vector2=world_map.map_to_world(hinge)
	var b: Vector2=world_map.map_to_world(tip())
	leaf.polygon=PackedVector2Array([a,b,b-Vector2(0,height),a-Vector2(0,height)])
	leaf.z_index=roundi((maxf(a.y,b.y))*0.2)+5
	leaf.modulate=Color(0.42,0.35,0.30,0.62) if broken else Color.WHITE
