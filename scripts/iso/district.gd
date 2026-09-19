extends RefCounted

const WIDTH := 1792
const ZONES := ["cedar","junction","store","alley"]
const LABELS := {"cedar":"柳杉路住宅","junction":"十字路口","store":"青叶便利店","alley":"仓库后巷"}
const BOUNDS := Rect2(0,0,5760,3072)
const ORIGINS := {"cedar":Vector2.ZERO,"junction":Vector2(1792,640),"store":Vector2(3584,480),"alley":Vector2(3584,1792)}
const CENTERS := {"cedar":Vector2(748,563),"junction":Vector2(2560,1200),"store":Vector2(4544,990),"alley":Vector2(4320,2400)}
const ROADS := [
	{"a":"cedar","b":"junction","points":[Vector2(1450,976),Vector2(1648,976),Vector2(1840,970)],"width":120.0},
	{"a":"junction","b":"store","points":[Vector2(3296,800),Vector2(3456,800),Vector2(3632,810)],"width":140.0},
	{"a":"junction","b":"alley","points":[Vector2(3296,1600),Vector2(3460,1810),Vector2(3632,2140)],"width":150.0},
	{"a":"store","b":"alley","points":[Vector2(5080,1430),Vector2(5320,1530),Vector2(5410,2030),Vector2(5080,2450)],"width":180.0}
]

static func polygon(points: Array,origin := Vector2.ZERO) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points: result.append(Vector2(p[0],p[1])+origin)
	return result

static func region_paths(zone: String) -> Array:
	if zone == "junction":
		return [ [[0,190],[1535,900],[1535,1023],[1290,1023],[0,430]], [[300,1023],[0,860],[1270,0],[1535,90]], [[530,370],[870,340],[1020,555],[730,730],[480,555]] ]
	if zone == "store":
		return [ [[0,230],[1535,890],[1535,1023],[1160,1023],[0,460]], [[532,399],[884,230],[1340,447],[1015,612]], [[695,473],[844,537],[815,650],[656,571]] ]
	return [ [[0,245],[1535,585],[1535,775],[950,880],[0,475]], [[1100,485],[1450,540],[1450,690],[1100,650]], [[420,365],[820,460],[820,710],[420,590]] ]

static func zone_of(p: Vector2) -> String:
	for zone in ZONES:
		if Rect2(ORIGINS[zone],Vector2(1536,1024)).has_point(p): return zone
	var best := "cedar"
	var distance := INF
	for zone in ZONES:
		var d: float = p.distance_squared_to(CENTERS[zone])
		if d < distance:
			best = zone
			distance = d
	return best

static func migrate_position(p: Vector2,version: int) -> Vector2:
	if version >= 5: return p
	var zone: String = ZONES[clampi(int(p.x/1792),0,3)]
	return p-Vector2(ZONES.find(zone)*1792,0)+ORIGINS[zone]
