class_name Codex
extends RefCounted
## M6.8 Offline knowledge-only Codex and Run History.
## Never grants gameplay power or RNG input, and never reveals unseen secrets.

const CODEX_VERSION := 1
const MAX_RUNS := 50

var creatures: Dictionary = {} # monster_id -> {"seen": int}
var floors: Dictionary = {} # floor_id -> {"visits": int}
var items: Dictionary = {} # item_id -> true
var npcs: Dictionary = {} # npc_id -> {"best_standing": int}
var factions: Dictionary = {} # faction_id -> Array[String] (observed poles)
var threads: Dictionary = {} # thread_id -> String (status)
var contracts: Dictionary = {} # contract_id -> String (outcome)
var runs: Array[Dictionary] = []
var _recorded_runs: Dictionary = {} # internal dedup key -> true


func record_from_world(w: World) -> void:
	if w == null or w.db == null:
		return
	for fid in w.visited_floors:
		var prev := int(floors.get(String(fid), {}).get("visits", 0))
		floors[String(fid)] = {"visits": maxi(1, prev)}
	var cur := w.current_floor()
	if cur != null:
		floors[w.floor_id] = {"visits": maxi(1, int(floors.get(w.floor_id, {}).get("visits", 0)))}
		for a in cur.actors:
			if a.is_player:
				continue
			if cur.is_visible(a.pos) or w.state != World.State.PLAYING:
				var c_ent: Dictionary = creatures.get(a.template_id, {"seen": 0})
				c_ent["seen"] = maxi(1, int(c_ent.get("seen", 0)))
				creatures[a.template_id] = c_ent
		for it in cur.items:
			if cur.is_visible(it.pos) and w.is_item_identified(it):
				items[it.template_id] = true
	if w.player != null:
		for it in w.player.inventory:
			if w.is_item_identified(it):
				items[it.template_id] = true
		for slot in Actor.SLOTS:
			var eq := w.player.equipped(slot)
			if eq != null and w.is_item_identified(eq):
				items[eq.template_id] = true
	for tid in w.id_known:
		if bool(w.id_known[tid]):
			items[String(tid)] = true
	for nid in w.npcs_met:
		var s := w.npc_standing_of(String(nid))
		var best := int(npcs.get(String(nid), {}).get("best_standing", s))
		npcs[String(nid)] = {"best_standing": maxi(best, s)}
	for fid in w.faction_flags:
		var pole := String(w.faction_flags[fid])
		if pole != "":
			var arr: Array = factions.get(String(fid), [])
			if not arr.has(pole):
				arr.append(pole)
			factions[String(fid)] = arr
	for tid in w.threads_state.get("active", {}):
		if not threads.has(String(tid)):
			threads[String(tid)] = "discovered"
	for tid in w.threads_state.get("completed", []):
		threads[String(tid)] = "settled"
	for tid in w.threads_state.get("refused", []):
		threads[String(tid)] = "refused"
	for tid in w.threads_state.get("failed", []):
		if String(threads.get(String(tid), "")) != "settled":
			threads[String(tid)] = "abandoned"
	if w.contract != "":
		contracts[w.contract] = "signed"
	for cid in w.contract_log:
		contracts[String(cid)] = String(w.contract_log[cid])


func record_run_end(w: World) -> void:
	if w == null or w.state == World.State.PLAYING or w.player == null:
		return
	record_from_world(w)
	var key := "%d:%d:%s:%s" % [w.run_seed, w.turns, w.floor_id, w.player.name]
	if _recorded_runs.has(key):
		return
	_recorded_runs[key] = true
	var won := w.state == World.State.WON
	var summary := w.victory_kind() if won else w.named_loss()
	var entry := {
		"seed": w.run_seed,
		"hero": w.player.name,
		"species": w.player.species_id,
		"class_id": w.player.class_id,
		"outcome": "victory" if won else "loss",
		"title": String(summary.get("title", "")),
		"cause": "" if won else w.death_cause,
		"floor_id": w.floor_id,
		"depth": w.depth,
		"turns": w.turns,
		"level": w.player.level,
		"floors_visited": w.visited_floors.size(),
		"threads_settled": w.resolved_thread_count(),
	}
	runs.push_front(entry)
	while runs.size() > MAX_RUNS:
		runs.pop_back()


func to_dict() -> Dictionary:
	return {
		"codex_version": CODEX_VERSION,
		"creatures": creatures.duplicate(true),
		"floors": floors.duplicate(true),
		"items": items.duplicate(true),
		"npcs": npcs.duplicate(true),
		"factions": factions.duplicate(true),
		"threads": threads.duplicate(true),
		"contracts": contracts.duplicate(true),
		"runs": runs.duplicate(true),
	}


static func from_dict(d: Variant) -> Codex:
	var c := Codex.new()
	if typeof(d) != TYPE_DICTIONARY or int(d.get("codex_version", 0)) != CODEX_VERSION:
		return c
	if typeof(d.get("creatures")) == TYPE_DICTIONARY:
		c.creatures = d["creatures"].duplicate(true)
	if typeof(d.get("floors")) == TYPE_DICTIONARY:
		c.floors = d["floors"].duplicate(true)
	if typeof(d.get("items")) == TYPE_DICTIONARY:
		c.items = d["items"].duplicate(true)
	if typeof(d.get("npcs")) == TYPE_DICTIONARY:
		c.npcs = d["npcs"].duplicate(true)
	if typeof(d.get("factions")) == TYPE_DICTIONARY:
		c.factions = d["factions"].duplicate(true)
	if typeof(d.get("threads")) == TYPE_DICTIONARY:
		c.threads = d["threads"].duplicate(true)
	if typeof(d.get("contracts")) == TYPE_DICTIONARY:
		c.contracts = d["contracts"].duplicate(true)
	if typeof(d.get("runs")) == TYPE_ARRAY:
		for r in d["runs"]:
			if typeof(r) == TYPE_DICTIONARY:
				c.runs.append(r.duplicate(true))
	return c
