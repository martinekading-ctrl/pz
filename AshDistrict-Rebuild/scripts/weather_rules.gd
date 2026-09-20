extends RefCounted

const SLOT_MINUTES:=360.0
const TRANSITION_MINUTES:=45.0
const SCHEDULE:=["clear","cloudy","rain","cloudy","fog","clear","cloudy","rain"]
const DEFINITIONS:={
	"clear":{"name":"晴朗","icon":"☀","tint":Color(1.0,1.0,1.0),"rain":0.0,"fog":0.0,"overcast":0.0},
	"cloudy":{"name":"阴天","icon":"☁","tint":Color(0.82,0.87,0.91),"rain":0.0,"fog":0.02,"overcast":0.10},
	"rain":{"name":"雨天","icon":"☂","tint":Color(0.68,0.77,0.82),"rain":1.0,"fog":0.08,"overcast":0.18},
	"fog":{"name":"雾天","icon":"≋","tint":Color(0.88,0.91,0.88),"rain":0.0,"fog":0.34,"overcast":0.06},
}

static func sample(total_minutes: float) -> Dictionary:
	var safe_time:=maxf(0.0,total_minutes)
	var slot:=int(floor(safe_time/SLOT_MINUTES))
	var phase:=fmod(safe_time,SLOT_MINUTES)
	var from_id: String=SCHEDULE[slot%SCHEDULE.size()]
	var to_id: String=SCHEDULE[(slot+1)%SCHEDULE.size()]
	var blend:=smoothstep(SLOT_MINUTES-TRANSITION_MINUTES,SLOT_MINUTES,phase)
	var from_data: Dictionary=DEFINITIONS[from_id]
	var to_data: Dictionary=DEFINITIONS[to_id]
	var from_tint: Color=from_data.tint
	var to_tint: Color=to_data.tint
	return {
		"id":to_id if blend>=0.5 else from_id,
		"name":to_data.name if blend>=0.5 else from_data.name,
		"icon":to_data.icon if blend>=0.5 else from_data.icon,
		"tint":from_tint.lerp(to_tint,blend),
		"rain":lerpf(float(from_data.rain),float(to_data.rain),blend),
		"fog":lerpf(float(from_data.fog),float(to_data.fog),blend),
		"overcast":lerpf(float(from_data.overcast),float(to_data.overcast),blend),
		"blend":blend,
	}
