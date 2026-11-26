class_name Telemetry
extends RefCounted
## M7.1 local-only run telemetry. An optional observer: `World.telemetry` is null
## in normal play and is never saved, never read by the simulation and never
## touches an Rng, so attaching one cannot change a run. Data stays in memory
## until a tool (tools/m7_soak.gd) writes it to a local file. Nothing is sent
## anywhere.

const RECENT_LIMIT := 12

## "category|key" -> count. Flat so it can be summed across runs.
var counters: Dictionary = {}
## Sum of damage the player took, keyed "source|type".
var damage_taken: Dictionary = {}
var damage_dealt: Dictionary = {}
## Last damage events against the player, oldest first.
var recent: Array = []
## One entry per floor entry: {fid, depth, turn, level, hp_pct}.
var floor_log: Array = []
var death: Dictionary = {}
var max_hit_pct := 0.0
var max_burst_pct := 0.0
var _burst_turn := -1
var _burst_sum := 0


func count(cat: String, key: String, n: int = 1) -> void:
	var k := cat + "|" + key
	counters[k] = int(counters.get(k, 0)) + n


func on_damage(w: World, target: Actor, amount: int, source: String, dmg_type: String) -> void:
	if amount <= 0:
		return
	if target.is_player:
		var k := source + "|" + dmg_type
		damage_taken[k] = int(damage_taken.get(k, 0)) + amount
		var mx := maxi(1, target.stat("max_hp"))
		max_hit_pct = maxf(max_hit_pct, float(amount) / mx)
		if _burst_turn != w.turns:
			_burst_turn = w.turns
			_burst_sum = 0
		_burst_sum += amount
		max_burst_pct = maxf(max_burst_pct, float(_burst_sum) / mx)
		recent.append({"turn": w.turns, "src": source, "type": dmg_type, "amt": amount, "hp_before": target.hp})
		if recent.size() > RECENT_LIMIT:
			recent.pop_front()
	else:
		var k2 := "player|" + dmg_type
		damage_dealt[k2] = int(damage_dealt.get(k2, 0)) + amount


func on_floor(w: World, fid: String) -> void:
	floor_log.append({
		"fid": fid, "depth": w.depth, "turn": w.turns, "level": w.player.level,
		"hp_pct": int(100.0 * w.player.hp / maxi(1, w.player.stat("max_hp"))),
	})


## Snapshot taken the moment the player dies. Explains the death rather than
## just naming the killer: how much of it was one burst, whether the player
## carried healing, and whether they were under-levelled for the depth.
func on_death(w: World) -> void:
	var p := w.player
	var heals := 0
	for it in p.inventory:
		var d := it.def(w.db)
		if String(d.get("kind", "")) == "consumable" and String(d.get("effect", "")) == "heal":
			heals += it.quantity
	var window_dmg := 0
	var sources := {}
	for ev in recent:
		if w.turns - int(ev["turn"]) <= 3:
			window_dmg += int(ev["amt"])
			sources[String(ev["src"])] = true
	var max_hp := maxi(1, p.stat("max_hp"))
	death = {
		"cause": w.death_cause, "depth": w.depth, "floor": w.floor_id, "level": p.level,
		"turns": w.turns, "max_hp": max_hp,
		"heals_in_pack": heals,
		"window_dmg_3": window_dmg,
		"window_pct_3": snappedf(float(window_dmg) / max_hp, 0.01),
		"window_sources": sources.size(),
		"last_hit_pct": snappedf(float(recent.back()["amt"]) / max_hp, 0.01) if not recent.is_empty() else 0.0,
		"max_burst_pct": snappedf(max_burst_pct, 0.01),
		"statuses": _status_ids(p),
		"loss": String(w.named_loss().get("id", "")),
		"classification": _classify(w, heals, window_dmg, max_hp),
	}


static func _status_ids(a: Actor) -> Array:
	var out: Array = []
	for s in a.statuses:
		out.append(String(s["id"]))
	out.sort()
	return out


## Coarse, rule-based cause tag used to separate legitimate difficulty from
## preparation and bot-behaviour problems. It is a triage label, not a verdict.
func _classify(w: World, heals: int, window_dmg: int, max_hp: int) -> String:
	if _burst_sum >= max_hp and not recent.is_empty() and recent.size() <= 2:
		return "unavoidable_burst"
	if window_dmg >= max_hp * 0.9 and heals == 0:
		return "no_healing_available"
	if heals > 0 and window_dmg >= max_hp * 0.5:
		return "healing_unused_or_too_slow"
	var expected := 1 + w.depth
	if w.player.level + 1 < expected:
		return "underlevelled"
	if w.player.has_status("false_light") or w.player.has_status("reckoning"):
		return "false_light_window"
	if w.player.has_status("entangled"):
		return "entangled"
	return "attrition"


func to_dict() -> Dictionary:
	return {
		"counters": counters, "damage_taken": damage_taken, "damage_dealt": damage_dealt,
		"floor_log": floor_log, "death": death,
		"max_hit_pct": snappedf(max_hit_pct, 0.01), "max_burst_pct": snappedf(max_burst_pct, 0.01),
	}
