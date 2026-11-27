class_name Assist
extends RefCounted
## M7.7 player-agency helpers. Everything here is a pure function of the world
## (or advances it only through ordinary player actions), so it is testable
## without a UI and cannot do anything the player could not do by hand.
##
## Automation rules, in one place:
##   - It stops, before acting, for a hostile in view, a dangerous status, low
##     health, or damage it did not expect.
##   - It walks only over explored tiles, and never onto a known hazard or an
##     unused revealed trap.
##   - It never opens, uses, reads, signs, crosses a Sphere Gate, or makes any
##     irreversible narrative or metaphysical choice. It stops beside a
##     consequential feature instead.
##   - Warnings are advisory: nothing here blocks an action.

const LOW_HP_PCT := 35
## Statuses that make walking on or resting through them a mistake.
const STOP_STATUSES: Array[String] = ["bleeding", "burning", "pinned", "entangled", "isolation", "hexed", "dissolution"]

const SORTS: Array[String] = ["recent", "name", "kind", "rarity"]
const FILTERS: Array[String] = ["all", "weapon", "ranged", "armor", "amulet", "consumable", "relic", "key"]
const RARITY_ORDER := {"artifact": 0, "rare": 1, "uncommon": 2, "common": 3}
const KIND_ORDER := {"weapon": 0, "ranged": 1, "armor": 2, "amulet": 3, "consumable": 4, "relic": 5, "key": 6}
const LOG_KINDS: Array[String] = ["combat", "danger", "good", "lore", "info"]
const COMPARE_STATS: Array[String] = ["max_hp", "accuracy", "evasion", "defense", "damage_bonus", "crit", "sight", "speed", "might", "agility", "will"]


# ---------------------------------------------------------------- safety stops

## "" when it is safe to keep going, otherwise a one-line reason.
static func stop_reason(w: World) -> String:
	if w.state != World.State.PLAYING:
		return "The run has ended."
	var foes := w.visible_hostiles()
	if not foes.is_empty():
		return "%s is in view." % _article(foes[0].name).capitalize()
	for sid in STOP_STATUSES:
		if w.player.has_status(sid):
			return "You are %s." % String(w.db.get_def("statuses", sid)["name"]).to_lower()
	if w.player.hp * 100 < w.player.stat("max_hp") * LOW_HP_PCT:
		return "Your health is low."
	return ""


static func _article(n: String) -> String:
	return ("an " if n.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + n


## Tiles the automation will not path through: known hazards and revealed
## traps that have not been sprung.
static func avoid_set(m: FloorMap) -> Dictionary:
	var out := {}
	for y in m.height:
		for x in m.width:
			var p := Vector2i(x, y)
			if m.is_explored(p) and Tiles.is_hazard(m.get_tile(p)):
				out[p] = true
	for f in m.features:
		if String(f.get("kind", "")) == "trap" and bool(f.get("revealed", false)) and not bool(f.get("used", false)):
			out[Vector2i(int(f["x"]), int(f["y"]))] = true
	return out


# ---------------------------------------------------------------- auto-explore

static func new_state() -> Dictionary:
	return {"bl": {}, "seen": {}, "hp": -1, "floor": "", "target": Vector2i(-1, -1), "dist": PackedInt32Array()}


## One step of safe auto-explore. Returns {"acted": bool, "stop": String, "done": bool}.
## `stop` is "" while it can continue; `done` is true when nothing safe is left.
static func explore_step(w: World, st: Dictionary) -> Dictionary:
	var why := stop_reason(w)
	if why != "":
		st["hp"] = w.player.hp
		return _res(false, why)
	var hp_before := int(st.get("hp", -1))
	if hp_before >= 0 and w.player.hp < hp_before:
		st["hp"] = w.player.hp
		return _res(false, "You were hurt.")
	var m := w.current_floor()
	var me := w.player.pos
	if String(st.get("floor", "")) != w.floor_id:
		st["floor"] = w.floor_id
		st["bl"] = {}
		st["seen"] = {}
		st["target"] = Vector2i(-1, -1)
	var feat := _feature_near(m, me)
	if not feat.is_empty():
		var key := "%d,%d" % [int(feat["x"]), int(feat["y"])]
		if not (st["seen"] as Dictionary).has(key):
			(st["seen"] as Dictionary)[key] = true
			return _res(false, "%s is here. Decide for yourself; auto-explore never chooses for you." % Ecology.label(feat))
	var bl: Dictionary = st["bl"]
	if not m.items_at(me).is_empty() and not bl.has(me):
		var carried := w.player.inventory.size()
		if w.player_pickup() and (w.player.inventory.size() != carried or m.items_at(me).is_empty()):
			st["hp"] = w.player.hp
			return _res(true, "")
		bl[me] = true
	var avoid := avoid_set(m)
	var target: Vector2i = st["target"]
	if target.x < 0 or target == me or bl.has(target) or not _target_live(w, m, target):
		target = _pick_target(w, m, me, avoid, bl)
		st["target"] = target
		st["dist"] = PackedInt32Array()
		if target.x < 0:
			st["hp"] = w.player.hp
			return {"acted": false, "stop": "Nothing safe is left to explore here.", "done": true}
	var dist: PackedInt32Array = st["dist"]
	if dist.is_empty():
		dist = Pathing.distance_map(m, target, true, avoid)
		st["dist"] = dist
	var nxt := Pathing.step_down(m, dist, me, func(q: Vector2i) -> bool: return m.actor_at(q) != null or avoid.has(q))
	if nxt == me or not w.player_move(nxt - me):
		bl[target] = true
		st["target"] = Vector2i(-1, -1)
		return _res(false, "The way is blocked.")
	st["hp"] = w.player.hp
	return _res(true, "")


static func _res(acted: bool, stop: String) -> Dictionary:
	return {"acted": acted, "stop": stop, "done": false}


static func _feature_near(m: FloorMap, p: Vector2i) -> Dictionary:
	var spots: Array[Vector2i] = [p]
	for d in Grid.DIRS_8:
		spots.append(p + d)
	for q in spots:
		var f := m.revealed_feature_at(q)
		if not f.is_empty() and Ecology.is_interactive(f) and not bool(f.get("used", false)):
			return f
	return {}


static func _target_live(w: World, m: FloorMap, q: Vector2i) -> bool:
	for it in m.items_at(q):
		if w._can_carry(w.player, it):
			return true
	for d in Grid.DIRS_8:
		if m.in_bounds(q + d) and not m.is_explored(q + d):
			return true
	return false


## Nearest carriable item, else nearest frontier tile, over explored ground.
static func _pick_target(w: World, m: FloorMap, me: Vector2i, avoid: Dictionary, bl: Dictionary) -> Vector2i:
	var dist := Pathing.distance_map(m, me, true, avoid)
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for it in m.items:
		var q := it.pos
		if bl.has(q) or avoid.has(q) or q == me or not m.is_explored(q) or not w._can_carry(w.player, it):
			continue
		var dq := dist[m.idx(q)]
		if dq >= 0 and dq < best_d:
			best = q
			best_d = dq
	if best.x >= 0:
		return best
	for y in range(1, m.height - 1):
		for x in range(1, m.width - 1):
			var q := Vector2i(x, y)
			var dq := dist[m.idx(q)]
			if dq <= 0 or dq >= best_d or bl.has(q) or avoid.has(q) or not m.is_walkable(q):
				continue
			for d in Grid.DIRS_8:
				if not m.is_explored(q + d):
					best = q
					best_d = dq
					break
	return best


## Runs auto-explore until it stops. Returns {"steps", "stop", "done"}.
static func explore_run(w: World, st: Dictionary, max_steps: int = 400) -> Dictionary:
	var steps := 0
	var last := _res(false, "")
	while steps < max_steps:
		last = explore_step(w, st)
		if not bool(last["acted"]):
			break
		steps += 1
	return {"steps": steps, "stop": String(last["stop"]) if steps < max_steps else "Step limit reached.", "done": bool(last.get("done", false))}


# ---------------------------------------------------------------- rest

## Rests until whole, a hostile appears, a dangerous status begins, or health
## falls (bleeding, burning, an unseen attacker). Returns {"turns", "stop"}.
static func rest(w: World, max_turns: int = 200) -> Dictionary:
	var n := 0
	if not w.can_rest():
		return {"turns": 0, "stop": "You cannot rest now." if w.player.hp < w.player.stat("max_hp") else "You are already whole."}
	for sid in STOP_STATUSES:
		if w.player.has_status(sid):
			return {"turns": 0, "stop": "You are %s; resting will not mend that." % String(w.db.get_def("statuses", sid)["name"]).to_lower()}
	var stop := ""
	while n < max_turns and w.can_rest():
		var hp := w.player.hp
		w.player_wait()
		n += 1
		if w.state != World.State.PLAYING:
			return {"turns": n, "stop": "The run has ended."}
		if w.player.hp < hp:
			stop = "Something is hurting you."
			break
		stop = ""
	if stop == "" and not w.visible_hostiles().is_empty():
		stop = "%s comes into view." % _article(w.visible_hostiles()[0].name).capitalize()
	w.log_msg("You rest for %d turns." % n)
	return {"turns": n, "stop": stop}


# ---------------------------------------------------------------- travel between floors

## Visited floors other than this one, spine order first. Unvisited places are
## never listed, so this cannot spoil the Atlas.
static func travel_destinations(w: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for fid in w.visited_floors:
		if fid == w.floor_id:
			continue
		var fd := w.db.floor_def(fid)
		out.append({"floor_id": fid, "name": String(fd.get("name", fid)), "depth": int(fd.get("depth", 0)),
			"reachable": not next_hop(w, fid).is_empty()})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["depth"]) < int(b["depth"]) or (int(a["depth"]) == int(b["depth"]) and String(a["name"]) < String(b["name"])))
	return out


static func _neighbors(w: World, fid: String) -> Array[String]:
	var out: Array[String] = []
	var fd := w.db.floor_def(fid)
	var d := int(fd.get("depth", 1))
	if String(fd.get("region_kind", "spine")) == "spine":
		if d > 1:
			out.append(w.db.spine_floor_id(d - 1))
		if d < w.db.max_depth():
			out.append(w.db.spine_floor_id(d + 1))
	elif fd.has("parent"):
		out.append(String(fd["parent"]))
	for e in w.atlas.get(fid, []):
		var t := String(e["target"])
		if t != "" and not out.has(t):
			out.append(t)
	return out


## First hop from this floor toward `dest` over visited floors only:
## {"x", "y", "kind", "floor"} where (x, y) is the stairs or passage tile, or {}.
static func next_hop(w: World, dest: String) -> Dictionary:
	if dest == w.floor_id or not w.visited_floors.has(dest):
		return {}
	var prev := {w.floor_id: ""}
	var queue: Array[String] = [w.floor_id]
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		if cur == dest:
			break
		for n in _neighbors(w, cur):
			if not prev.has(n) and w.visited_floors.has(n):
				prev[n] = cur
				queue.append(n)
	if not prev.has(dest):
		return {}
	var step := dest
	while String(prev[step]) != w.floor_id and String(prev[step]) != "":
		step = String(prev[step])
	var m := w.current_floor()
	for pt in m.portals:
		if String(pt.get("target", "")) == step:
			return {"x": int(pt["x"]), "y": int(pt["y"]), "kind": "portal", "floor": step}
	var cur_d := w.depth
	var step_d := int(w.db.floor_def(step).get("depth", cur_d))
	if step_d > cur_d and m.down_pos.x >= 0:
		return {"x": m.down_pos.x, "y": m.down_pos.y, "kind": "down", "floor": step}
	if step_d < cur_d and m.up_pos.x >= 0:
		return {"x": m.up_pos.x, "y": m.up_pos.y, "kind": "up", "floor": step}
	if m.exit_pos.x >= 0 and step_d == cur_d:
		return {"x": m.exit_pos.x, "y": m.exit_pos.y, "kind": "exit", "floor": step}
	return {}


## One action toward `dest`: a step along explored ground, or taking a stairs or
## passage whose far side is already visited. Returns {"acted", "stop", "done"}.
static func travel_step(w: World, dest: String, st: Dictionary) -> Dictionary:
	if w.floor_id == dest:
		return {"acted": false, "stop": "You have arrived.", "done": true}
	var why := stop_reason(w)
	if why != "":
		return _res(false, why)
	var hop := next_hop(w, dest)
	if hop.is_empty():
		return {"acted": false, "stop": "You know no way there from here.", "done": true}
	var m := w.current_floor()
	var me := w.player.pos
	var tpos := Vector2i(int(hop["x"]), int(hop["y"]))
	if me == tpos:
		if not w.floors.has(String(hop["floor"])):
			return {"acted": false, "stop": "The way beyond is unvisited. Cross it yourself.", "done": true}
		if not w.player_stairs():
			return {"acted": false, "stop": "The way is shut.", "done": true}
		return _res(true, "")
	var avoid := avoid_set(m)
	if String(st.get("floor", "")) != w.floor_id or st.get("target", Vector2i(-1, -1)) != tpos:
		st["floor"] = w.floor_id
		st["target"] = tpos
		st["dist"] = Pathing.distance_map(m, tpos, true, avoid)
	var dist: PackedInt32Array = st["dist"]
	if dist[m.idx(me)] == Pathing.UNREACHED:
		return {"acted": false, "stop": "You know no safe way to the %s." % ("stairs" if hop["kind"] != "portal" else "passage"), "done": true}
	var nxt := Pathing.step_down(m, dist, me, func(q: Vector2i) -> bool: return m.actor_at(q) != null or avoid.has(q))
	if nxt == me or not w.player_move(nxt - me):
		return _res(false, "The way is blocked.")
	return _res(true, "")


static func travel_run(w: World, dest: String, max_steps: int = 600) -> Dictionary:
	var st := new_state()
	var steps := 0
	var last := _res(false, "")
	while steps < max_steps:
		last = travel_step(w, dest, st)
		if not bool(last["acted"]):
			break
		steps += 1
	return {"steps": steps, "stop": String(last["stop"]), "done": bool(last.get("done", false))}


# ---------------------------------------------------------------- quest navigation

## Where each active thread points, without naming a place the player has not
## seen. Only visit_floor and kill_monster goals name a floor; the rest say so.
static func thread_leads(w: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for tid in w.active_thread_ids():
		var tdef := w.db.get_def("threads", tid)
		var gk := String(tdef["goal_kind"])
		var gref := String(tdef["goal_ref"])
		var fid := goal_floor(w, gk, gref)
		var lead := {"thread": tid, "name": String(tdef["name"]), "floor_id": "", "floor_name": "", "visited": false, "note": ""}
		if fid == "":
			lead["note"] = "No fixed place; follow the people and signs involved."
		elif w.visited_floors.has(fid):
			lead["floor_id"] = fid
			lead["floor_name"] = String(w.db.floor_def(fid).get("name", fid))
			lead["visited"] = true
		else:
			lead["note"] = "It lies somewhere you have not yet been."
		out.append(lead)
	return out


static func goal_floor(w: World, goal_kind: String, goal_ref: String) -> String:
	if goal_kind == "visit_floor":
		return goal_ref if w.db.has("floors", goal_ref) else ""
	if goal_kind == "kill_monster":
		for fid in w.db.all_floor_ids():
			var fd := w.db.floor_def(fid)
			if String(fd.get("boss", "")) == goal_ref or String(fd.get("guardian", "")) == goal_ref:
				return fid
	return ""


# ---------------------------------------------------------------- warnings

## Advisory lines for a descent from where the player stands. Empty when
## nothing is worth saying. Never blocks.
static func descent_warnings(w: World) -> PackedStringArray:
	var out: PackedStringArray = []
	var target_depth := w.depth + 1
	var recommended := recommended_level(target_depth)
	if recommended > 0 and w.player.level < recommended:
		out.append("You are level %d; depth %d is gentler from level %d. Most early deaths there are characters who dived without gathering strength." % [w.player.level, target_depth, recommended])
	var max_hp := w.player.stat("max_hp")
	if w.player.hp * 100 < max_hp * 50:
		out.append("You are at %d/%d health." % [w.player.hp, max_hp])
	var heal := false
	for it in w.player.inventory:
		if String(it.def(w.db).get("effect", "")) == "heal":
			heal = true
			break
	if not heal:
		out.append("You carry no healing.")
	for sid in STOP_STATUSES:
		if w.player.has_status(sid):
			out.append("You are %s." % String(w.db.get_def("statuses", sid)["name"]).to_lower())
	return out


## Level at which arriving at `depth` stops being a gamble. Evidence exists only
## for depth 2 (balance/CHANGES.md, M7.3-1: 16% of depth 2 arrivals at level 1
## and 8% at level 2 died there, none from level 3). Deeper floors: no claim.
static func recommended_level(depth: int) -> int:
	return 3 if depth == 2 else 0


# ---------------------------------------------------------------- items

static func slot_of(w: World, it: Item) -> String:
	var kind := String(it.def(w.db).get("kind", ""))
	return kind if kind in Actor.SLOTS else ""


## Stat lines for putting `it` on in place of what is worn. Reads values by
## briefly swapping the actor's equipment and restoring it; no state is kept.
## Unidentified gear reports nothing numeric, so it cannot leak hidden properties.
static func compare_item(w: World, it: Item) -> Dictionary:
	var slot := slot_of(w, it)
	var res := {"slot": slot, "equipped": "", "lines": PackedStringArray(), "unknown": false, "warning": ""}
	if slot == "":
		return res
	var cur := w.player.equipped(slot)
	res["equipped"] = w.item_name(cur) if cur != null else ""
	if not w.is_item_identified(it):
		res["unknown"] = true
		res["lines"] = PackedStringArray(["Unidentified: its effect stays hidden until worn or witnessed."])
		return res
	if cur != null and cur.buc == "cursed" and cur.identified:
		res["warning"] = "Your %s is cursed and will not come off." % w.item_name(cur)
	if it.buc == "cursed":
		res["warning"] = "This is cursed: once worn it will not come off."
	var before := _snapshot(w)
	var saved: Variant = w.player.equipment.get(slot)
	w.player.equipment[slot] = it
	var after := _snapshot(w)
	if saved == null:
		w.player.equipment.erase(slot)
	else:
		w.player.equipment[slot] = saved
	var lines: PackedStringArray = []
	for k in before:
		var delta := int(after[k]) - int(before[k])
		if delta == 0:
			continue
		var label := String(k).replace("_", " ")
		if k.begins_with("avg_"):
			lines.append("%s %+.1f" % [label.replace("avg ", "average "), float(delta) / 10.0])
		elif k.begins_with("res_"):
			lines.append("%s resist %+d%%" % [String(k).substr(4), delta])
		else:
			lines.append("%s %+d" % [label, delta])
	if lines.is_empty():
		lines.append("No change to your numbers.")
	res["lines"] = lines
	return res


## Integers only; averages are in tenths so the comparison stays exact.
static func _snapshot(w: World) -> Dictionary:
	var p := w.player
	var s := {}
	for k in COMPARE_STATS:
		s[k] = p.stat(k)
	var dice := Dice.parse(p.damage_dice())
	s["avg_melee"] = int(roundf(10.0 * (float(dice["n"]) * (float(dice["sides"]) + 1.0) / 2.0 + float(dice["bonus"]))))
	for dt in ContentSchema.DAMAGE_TYPES:
		s["res_" + dt] = p.resist(dt)
	return s


## Indices into the player's pack, sorted and filtered. `query` matches the
## displayed (not hidden) name, case-insensitively.
static func inventory_view(w: World, sort_by: String = "recent", kind_filter: String = "all", query: String = "") -> Array[int]:
	var idx: Array[int] = []
	var q := query.strip_edges().to_lower()
	for i in w.player.inventory.size():
		var it := w.player.inventory[i]
		if kind_filter != "all" and String(it.def(w.db).get("kind", "")) != kind_filter:
			continue
		if q != "" and w.item_name(it).to_lower().find(q) < 0:
			continue
		idx.append(i)
	var inv := w.player.inventory
	match sort_by:
		"name":
			idx.sort_custom(func(a: int, b: int) -> bool:
				var na := w.item_name(inv[a]).to_lower()
				var nb := w.item_name(inv[b]).to_lower()
				return na < nb or (na == nb and a < b))
		"kind":
			idx.sort_custom(func(a: int, b: int) -> bool:
				var ka := int(KIND_ORDER.get(String(inv[a].def(w.db).get("kind", "")), 9))
				var kb := int(KIND_ORDER.get(String(inv[b].def(w.db).get("kind", "")), 9))
				return ka < kb or (ka == kb and a < b))
		"rarity":
			idx.sort_custom(func(a: int, b: int) -> bool:
				var ra := int(RARITY_ORDER.get(inv[a].rarity, 9))
				var rb := int(RARITY_ORDER.get(inv[b].rarity, 9))
				return ra < rb or (ra == rb and a < b))
		_:
			idx.reverse() # recent: newest pickup first
	return idx


# ---------------------------------------------------------------- log and inspection

## Messages whose kind is in `kinds` (empty means all), oldest first.
static func filter_log(messages: Array[Dictionary], kinds: Array, limit: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in messages:
		if kinds.is_empty() or kinds.has(String(m.get("k", "info"))):
			out.append(m)
	if limit > 0 and out.size() > limit:
		out = out.slice(out.size() - limit)
	return out


## A tactical read of a visible foe: how likely each side is to hit, and what it
## can do. Uses only what the player can see; no hidden numbers.
static func inspect_actor(w: World, a: Actor) -> String:
	var p := w.player
	var d := w.db.get_def("monsters", a.template_id) if w.db.has("monsters", a.template_id) else {}
	var parts: PackedStringArray = []
	parts.append("You hit %d%%, it hits you %d%%." % [Combat.hit_chance(p, a), Combat.hit_chance(a, p)])
	if d.has("damage"):
		parts.append("Strikes for %s." % String(d["damage"]))
	if not a.awake:
		parts.append("Unaware of you.")
	if not a.specials.is_empty():
		var names: PackedStringArray = []
		for sp in a.specials:
			names.append(sp.replace("_", " "))
		parts.append("Behaviours: %s." % ", ".join(names))
	var sts: PackedStringArray = []
	for s in a.statuses:
		sts.append(String(w.db.get_def("statuses", String(s["id"]))["name"]).to_lower())
	if not sts.is_empty():
		parts.append("Affected: %s." % ", ".join(sts))
	return " ".join(parts)
