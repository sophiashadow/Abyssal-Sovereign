class_name Threads
extends RefCounted
## M6.6 Organic world threads: per-run seeded subset selection, multi-stage progression,
## delayed aftermath ticks, refusal/abandonment consequences, and non-spoiler summaries.


static func init_state(db: ContentDB, atlas: Dictionary, run_seed: int) -> Dictionary:
	var trng := Rng.new(Rng.derive(run_seed, "threads"))
	var preferred: Array[String] = []
	var fallback: Array[String] = []
	var active_floors := {}
	for fid in atlas:
		active_floors[String(fid)] = true
		for pt in atlas[fid]:
			active_floors[String(pt.get("target", ""))] = true
	for tid in db.ids("threads"):
		var tdef := db.get_def("threads", tid)
		var tk := String(tdef["trigger_kind"])
		var gk := String(tdef["goal_kind"])
		var tref := String(tdef["trigger_ref"])
		var gref := String(tdef["goal_ref"])
		var fits := true
		if tk == "floor" and not active_floors.has(tref):
			fits = false
		if gk == "visit_floor" and not active_floors.has(gref):
			fits = false
		if fits:
			preferred.append(String(tid))
		else:
			fallback.append(String(tid))
	preferred.sort()
	fallback.sort()
	var pool: Array[String] = []
	var target_count := mini(8, db.ids("threads").size())
	while pool.size() < target_count and not preferred.is_empty():
		var idx := trng.range_i(0, preferred.size() - 1)
		pool.append(preferred[idx])
		preferred.remove_at(idx)
	while pool.size() < target_count and not fallback.is_empty():
		var idx := trng.range_i(0, fallback.size() - 1)
		pool.append(fallback[idx])
		fallback.remove_at(idx)
	return {
		"pool": pool,
		"active": {},
		"completed": [],
		"refused": [],
		"failed": [],
		"pending": [],
	}


static func is_known(state: Dictionary, tid: String) -> bool:
	return state.get("active", {}).has(tid) or (state.get("completed", []) as Array).has(tid) or (state.get("refused", []) as Array).has(tid) or (state.get("failed", []) as Array).has(tid)


static func activate(state: Dictionary, tid: String, turn: int) -> bool:
	if is_known(state, tid):
		return false
	var active: Dictionary = state.get("active", {})
	active[tid] = {"accepted_turn": turn, "progress": 0}
	state["active"] = active
	return true


static func matching_threads_for_npc(state: Dictionary, db: ContentDB, npc_id: String, active_only: bool = false) -> Array[String]:
	var out: Array[String] = []
	var candidate_ids: Array = []
	if active_only:
		candidate_ids = state.get("active", {}).keys()
	else:
		var seen := {}
		for tid in state.get("pool", []):
			seen[String(tid)] = true
			candidate_ids.append(String(tid))
		for tid in state.get("active", {}):
			if not seen.has(String(tid)):
				candidate_ids.append(String(tid))
	candidate_ids.sort()
	for tid in candidate_ids:
		if not db.has("threads", String(tid)):
			continue
		var tdef := db.get_def("threads", String(tid))
		if (String(tdef["npc_id"]) == npc_id or (String(tdef["goal_kind"]) == "npc_talk" and String(tdef["goal_ref"]) == npc_id)):
			if not (state.get("completed", []) as Array).has(tid) and not (state.get("refused", []) as Array).has(tid) and not (state.get("failed", []) as Array).has(tid):
				out.append(String(tid))
	return out
