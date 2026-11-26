class_name PolicyPlayer
extends AutoPlayer
## M7.1 deterministic policy bots. Each policy is a fixed rule set that plays
## through World's public API only, so a run is replayable from (seed, policy).
## Policies are measurements of different play styles, not of human play, and
## their parameters are never tuned against validation seeds.
##
##   baseline    the M6.10 AutoPlayer, unchanged (spine-direct)
##   aggressive  low heal threshold, throws everything, never retreats
##   defensive   heals and rests early, ranged first, retreats upstairs to recover
##   explorer    clears each floor (items, sites, secrets), then visits both branches
##   preserver   hoards consumables, relies on rest, no False Light or relic work
##   specialist  leans into the calling's signature tree and uses its whole kit
##   narrative   meets people, takes threads, signs a contract, pursues thread goals
##   random      uniformly random legal-ish actions (control; seeded independently)
##
## Where a policy navigates it may read the full floor map (known exits, feature
## locations). That is a bot convenience, as it was in M6.10, and is documented
## in docs/M7_SPEC.md; it is not a claim about what a human can see.

const POLICIES: Array[String] = ["baseline", "aggressive", "defensive", "explorer", "preserver", "specialist", "narrative", "random"]

## Signature tree per calling for the specialist policy.
const SIGNATURE_TREE := {
	"fallen_knight": "Oathbreaker", "occultist": "Mask Governance", "assassin": "Venom & Stiletto",
	"preliator_warden": "Iron Threshold", "tithe_marksman": "Quartermark Volley",
	"rite_weaver": "Chalk Geometry", "false_light_alchemist": "Volatile Flasks", "ophite_binder": "Seam Binding",
}
## Talent effects that heal, ward or purge; the specialist keeps them for low health.
const DEFENSIVE_EFFECTS: Array[String] = ["shield_brace", "unyielding_march", "threshold_hold", "volatile_salve", "transmute_pain",
		"sanctify_ground", "break_the_chain", "philosophers_loan", "summon_ward_sigil", "fade_to_ash", "backstep", "veil_step"]

var policy := "baseline"
var floor_budget := 700 ## actions one floor may consume before the explorer gives up on it
var _rng: Rng
var _fs: Dictionary = {} ## floor_id -> {actions, done, blacklist, handled, searched}
var _nav_floor := ""
var _nav_target := Vector2i(-1, -1)
var _nav_map := PackedInt32Array()
var _branch_done: Dictionary = {}
var _npc_stage: Dictionary = {} ## "fid:nid" -> stage int
var _thread_choice: Dictionary = {}
var _retreating := false
var _contract_tried := false


func _init(w: World, policy_name: String = "baseline") -> void:
	super._init(w)
	policy = policy_name
	_rng = Rng.new(Rng.derive(w.run_seed, "policy:" + policy_name))
	match policy:
		"aggressive":
			heal_mul = 5
			rest_below_pct = 40
			projectile_all = true
		"defensive":
			heal_mul = 2
			rest_below_pct = 95
			projectile_all = true
			approach_unaware = false
		"explorer":
			rest_below_pct = 80
		"preserver":
			heal_mul = 4
			rest_below_pct = 90
			false_light_vs_unique = false
		"specialist":
			projectile_all = true
		"narrative":
			rest_below_pct = 80


func step() -> bool:
	if policy == "random":
		return _random_step()
	return super.step()


# ------------------------------------------------------------------ hooks

func _fstate() -> Dictionary:
	var fid := world.floor_id
	if not _fs.has(fid):
		_fs[fid] = {"actions": 0, "done": false, "blacklist": {}, "handled": {}, "searched": 0}
	return _fs[fid]


func _is_spine() -> bool:
	return String(world.current_floor_def().get("region_kind", "spine")) == "spine"


func _may_descend() -> bool:
	match policy:
		"explorer", "narrative":
			return bool(_fstate()["done"]) and _is_spine()
	return true


func _policy_pre() -> int:
	match policy:
		"defensive":
			return _defensive_pre()
		"narrative":
			return _narrative_pre()
		"preserver":
			return _preserver_pre()
	return -1


func _policy_goal() -> int:
	match policy:
		"explorer":
			return _explore_goal(true)
		"narrative":
			var g := _narrative_goal()
			if g >= 0:
				return g
			return _explore_goal(true)
		"specialist", "aggressive", "defensive", "preserver":
			return _site_goal()
	return -1


# ------------------------------------------------------------------ talents

func _learn_next_talent() -> bool:
	if policy != "specialist":
		return super._learn_next_talent()
	var p := world.player
	var sig := String(SIGNATURE_TREE.get(p.class_id, ""))
	var best_id := ""
	var best_key := 1 << 30
	for tid in world.db.ids("talents"):
		var td := world.db.get_def("talents", tid)
		if String(td["class_id"]) != p.class_id or world.can_learn_talent(tid) != "":
			continue
		var key := (0 if String(td["tree"]) == sig else 1000) + int(td["tier"]) * 10 + (0 if String(td["kind"]) == "active" else 1)
		if key < best_key:
			best_key = key
			best_id = tid
	return best_id != "" and world.player_learn_talent(best_id)


func _kit_talent(foe: Actor, defensive: bool) -> bool:
	var p := world.player
	var dist := Grid.chebyshev(p.pos, foe.pos)
	var cands: Array[String] = []
	for tid in p.talents:
		var td := world.db.get_def("talents", String(tid))
		if String(td["kind"]) != "active":
			continue
		var eff := String(td.get("effect", tid))
		if DEFENSIVE_EFFECTS.has(eff) != defensive:
			continue
		cands.append(String(tid))
	cands.sort_custom(func(a: String, b: String) -> bool:
		var ta := int(world.db.get_def("talents", a)["tier"])
		var tb := int(world.db.get_def("talents", b)["tier"])
		return ta > tb if ta != tb else a < b)
	for tid in cands:
		if not _can_use_talent(tid):
			continue
		var rng_max := int(world.db.get_def("talents", tid).get("range", 0))
		if rng_max == 0 and not defensive and dist > 1:
			continue
		if rng_max > 0 and dist > rng_max:
			continue
		if world.player_use_talent(tid, foe.pos):
			return true
	return false


func _try_combat_talent(foe: Actor) -> bool:
	if policy != "specialist":
		return super._try_combat_talent(foe)
	var p := world.player
	if p.hp * 2 < p.stat("max_hp") and _kit_talent(foe, true):
		return true
	return _kit_talent(foe, false)


func _try_ranged_talent(foe: Actor) -> bool:
	if policy != "specialist":
		return super._try_ranged_talent(foe)
	return _kit_talent(foe, false)


# ------------------------------------------------------------------ defensive / preserver

func _defensive_pre() -> int:
	var p := world.player
	var m := world.current_floor()
	var hostiles := world.visible_hostiles()
	if p.hp * 100 >= p.stat("max_hp") * 35 or hostiles.is_empty() or _find_consumable("heal") >= 0:
		return -1
	var nearest := 99
	for h in hostiles:
		nearest = mini(nearest, Grid.chebyshev(h.pos, p.pos))
	if nearest < 3:
		return -1 # too close to run; fight
	var back := Vector2i(-1, -1)
	if _is_spine() and world.depth > 1:
		back = m.up_pos
	elif not _is_spine():
		back = _portal_pos_to(m, String(world.current_floor_def().get("parent", "")))
	if back.x < 0:
		return -1
	if p.pos == back:
		world._tel("retreat", "taken")
		return 1 if world.player_stairs() else 0
	var s := _step_toward(m, back)
	if s != p.pos:
		return 1 if world.player_move(s - p.pos) else 0
	return -1


func _preserver_pre() -> int:
	# Prefer resting to potions: step out of the potion threshold by resting early when safe.
	var p := world.player
	if world.visible_hostiles().is_empty() and p.hp * 100 < p.stat("max_hp") * 60 and world.can_rest():
		return 1 if world.player_rest(50) > 0 else 0
	return -1


# ------------------------------------------------------------------ navigation

func _step_toward(m: FloorMap, goal: Vector2i) -> Vector2i:
	var d := Pathing.distance_map(m, goal)
	return Pathing.step_down(m, d, world.player.pos, func(q: Vector2i) -> bool: return m.actor_at(q) != null)


func _portal_pos_to(m: FloorMap, target_floor: String) -> Vector2i:
	for pt in m.portals:
		if String(pt.get("target", "")) == target_floor:
			return Vector2i(int(pt["x"]), int(pt["y"]))
	return Vector2i(-1, -1)


## Walks one step toward `goal`, reusing a cached distance map while the goal
## is unchanged. Returns 1 (moved), 0 (move refused), or -1 (arrived/unreachable).
func _walk_to(goal: Vector2i, known_only: bool = true) -> int:
	var m := world.current_floor()
	var p := world.player
	if p.pos == goal:
		return -1
	if _nav_floor != world.floor_id or _nav_target != goal or _nav_map.is_empty():
		_nav_map = Pathing.distance_map(m, goal, known_only)
		_nav_target = goal
		_nav_floor = world.floor_id
	if _nav_map[m.idx(p.pos)] == Pathing.UNREACHED:
		return -1
	var s := Pathing.step_down(m, _nav_map, p.pos, func(q: Vector2i) -> bool: return m.actor_at(q) != null)
	if s == p.pos:
		# Blocked by an actor in a corridor: wait a turn rather than loop.
		return 1 if world.player_wait() else 0
	return 1 if world.player_move(s - p.pos) else 0


func _nearest_frontier(m: FloorMap, blacklist: Dictionary) -> Vector2i:
	var p := world.player
	var dist := Pathing.distance_map(m, p.pos, true)
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for y in range(1, m.height - 1):
		for x in range(1, m.width - 1):
			var q := Vector2i(x, y)
			var dq := dist[m.idx(q)]
			if dq < 0 or dq >= best_d or blacklist.has(q) or not m.is_walkable(q):
				continue
			for dir in Grid.DIRS_8:
				if not m.is_explored(q + dir):
					best = q
					best_d = dq
					break
	return best


func _nearest_item(m: FloorMap, blacklist: Dictionary) -> Vector2i:
	var p := world.player
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for it in m.items:
		if blacklist.has(it.pos) or not m.is_explored(it.pos) or not world._can_carry(p, it):
			continue
		var d := Grid.chebyshev(p.pos, it.pos)
		if d < best_d:
			best_d = d
			best = it.pos
	return best


## A cached explore target stays live while it still has something to offer.
func _target_live(m: FloorMap, q: Vector2i, st: Dictionary) -> bool:
	if (st["blacklist"] as Dictionary).has(q) or world.player.pos == q:
		return false
	for it in m.items:
		if it.pos == q:
			return true
	if (st["handled"] as Dictionary).has(q):
		return false
	for dir in Grid.DIRS_8:
		if not m.is_explored(q + dir):
			return true
	var f := m.revealed_feature_at(q)
	return not f.is_empty() and Ecology.is_interactive(f)


func _feature_of_interest(m: FloorMap, handled: Dictionary) -> Dictionary:
	var p := world.player
	var best := {}
	var best_d := 1 << 30
	for f in m.features:
		if not bool(f.get("revealed", false)) or not Ecology.is_interactive(f):
			continue
		var k := String(f["kind"])
		if k == "secret_door" or handled.has(Vector2i(int(f["x"]), int(f["y"]))):
			continue
		if k == "npc" and policy != "narrative":
			continue
		var d := Grid.chebyshev(p.pos, Vector2i(int(f["x"]), int(f["y"])))
		if d < best_d:
			best_d = d
			best = f
	return best


## Interacts with whatever site the player stands on that the base bot left alone.
func _site_goal() -> int:
	var m := world.current_floor()
	var p := world.player
	var f := m.revealed_feature_at(p.pos)
	if f.is_empty() or not Ecology.is_interactive(f):
		return -1
	var st := _fstate()
	if (st["handled"] as Dictionary).has(p.pos):
		return -1
	(st["handled"] as Dictionary)[p.pos] = true
	var k := String(f["kind"])
	var healthy := p.hp * 100 >= p.stat("max_hp") * 70
	match k:
		"contract_lectern":
			if world.contract == "" and not _contract_tried and policy in ["explorer", "narrative", "specialist"]:
				_contract_tried = true
				return 1 if world.player_interact(p.pos, "sign:the_crown_taken") else 0
		"altar":
			if healthy and p.hp > 8 and policy != "preserver":
				return 1 if world.player_interact(p.pos, "tithe") else 0
		"ritual_circle":
			if world.contract != "" and p.hp > 6:
				return 1 if world.player_interact(p.pos, "attest") else 0
			if healthy:
				return 1 if world.player_interact(p.pos, "inscribe") else 0
		"merchant":
			var stock: Array = f.get("stock", [])
			for i in stock.size():
				if not bool(stock[i].get("sold", false)):
					var mode := "blood" if p.hp > int(stock[i].get("price_hp", 5)) + p.stat("max_hp") / 2 else "barter"
					return 1 if world.player_interact(p.pos, "buy:%d:%s" % [i, mode]) else 0
		"challenge":
			if healthy and p.level >= 2 * world.depth - 1:
				return 1 if world.player_interact(p.pos, "") else 0
		"vault_gate":
			if healthy and p.hp > 12 and policy == "explorer":
				return 1 if world.player_interact(p.pos, "force") else 0
	return -1


# ------------------------------------------------------------------ explorer

func _explore_goal(allow_branches: bool) -> int:
	var m := world.current_floor()
	var p := world.player
	var st := _fstate()
	st["actions"] = int(st["actions"]) + 1
	var spine := _is_spine()
	var over_budget := int(st["actions"]) > floor_budget
	var bl: Dictionary = st["blacklist"]
	var site := _site_goal()
	if site >= 0:
		return site
	if not over_budget and not bool(st["done"]):
		var tgt: Vector2i = st.get("tgt", Vector2i(-1, -1))
		if tgt.x >= 0 and not _target_live(m, tgt, st):
			tgt = Vector2i(-1, -1)
		if tgt.x < 0:
			tgt = _nearest_item(m, bl)
			if tgt.x < 0:
				var f := _feature_of_interest(m, st["handled"])
				if not f.is_empty():
					tgt = Vector2i(int(f["x"]), int(f["y"]))
			if tgt.x < 0:
				tgt = _nearest_frontier(m, bl)
			st["tgt"] = tgt
		if tgt.x >= 0:
			var r := _walk_to(tgt)
			if r >= 0:
				return r
			bl[tgt] = true
			(st["handled"] as Dictionary)[tgt] = true
			st["tgt"] = Vector2i(-1, -1)
			return _explore_goal(allow_branches) if int(st["actions"]) < floor_budget else -1
		# Frontier exhausted: search a few room centres for hidden things.
		if int(st["searched"]) < 3 and not m.rooms.is_empty():
			var room: Rect2i = m.rooms[(int(st["searched"]) * 3 + 1) % m.rooms.size()]
			var c := room.position + room.size / 2
			if p.pos != c and m.is_walkable(c):
				var r2 := _walk_to(c)
				if r2 >= 0:
					return r2
			st["searched"] = int(st["searched"]) + 1
			world._tel("explore", "search_room")
			return 1 if world.player_search() else 0
	st["done"] = true
	if allow_branches and spine:
		for pt in m.portals:
			var tid := String(pt.get("target", ""))
			if String(pt.get("kind", "")) != "branch_in" or _branch_done.has(tid):
				continue
			if int(world.db.floor_def(tid).get("depth", world.depth)) > world.depth:
				continue
			var ppos := Vector2i(int(pt["x"]), int(pt["y"]))
			if p.pos == ppos:
				_branch_done[tid] = "entered"
				world._tel("branch", "enter:" + tid)
				return 1 if world.player_stairs() else 0
			var r3 := _walk_to(ppos)
			if r3 >= 0:
				return r3
			_branch_done[tid] = "unreachable"
	if not spine:
		var back := _portal_pos_to(m, String(world.current_floor_def().get("parent", "")))
		if back.x >= 0:
			if p.pos == back:
				world._tel("branch", "leave:" + world.floor_id)
				return 1 if world.player_stairs() else 0
			var r4 := _walk_to(back)
			if r4 >= 0:
				return r4
	return -1


# ------------------------------------------------------------------ narrative

func _narrative_pre() -> int:
	var m := world.current_floor()
	var p := world.player
	if not world.visible_hostiles().is_empty():
		return -1
	var f := {}
	for q in Grid.DIRS_8 + [Vector2i.ZERO]:
		var cand := m.revealed_feature_at(p.pos + q)
		if not cand.is_empty() and String(cand["kind"]) == "npc":
			f = cand
			break
	if f.is_empty():
		return -1
	return _npc_session(f)


## One action per call; the stage counter makes each NPC a short deterministic script.
func _npc_session(f: Dictionary) -> int:
	var p := world.player
	var pos := Vector2i(int(f["x"]), int(f["y"]))
	var nid := String(f.get("sub", ""))
	var key := world.floor_id + ":" + nid
	var stage := int(_npc_stage.get(key, 0))
	if not world.db.has("npcs", nid) or stage >= 6:
		return -1
	_npc_stage[key] = stage + 1
	match stage:
		0:
			return 1 if world.player_interact(pos, "talk") else 0
		1:
			# Threads this person offers: take them all (the bot is the engagement control).
			for tid in Threads.matching_threads_for_npc(world.threads_state, world.db, nid):
				if not Threads.is_known(world.threads_state, tid) and not _thread_choice.has(tid):
					_thread_choice[tid] = "accepted"
					_npc_stage[key] = 1
					return 1 if world.player_interact(pos, "thread_accept:" + tid) else 0
			return -1 if false else _npc_session(f)
		2:
			# Settle known threads by sacrifice when the goal is far from this floor and health allows.
			for tid in Threads.matching_threads_for_npc(world.threads_state, world.db, nid, true):
				if _thread_choice.get(tid, "") == "accepted" and String(world.db.get_def("threads", tid)["goal_kind"]) == "sacrifice_hp":
					_thread_choice[tid] = "sacrificed"
					return 1 if world.player_interact(pos, "thread_resolve:%s:sacrifice" % tid) else 0
			return _npc_session(f)
		3:
			if bool(f.get("used", false)) or world.npc_standing_of(nid) <= -2:
				return _npc_session(f)
			return 1 if world.player_interact(pos, "service") else 0
		4:
			if not world.faction_flags.has(String(world.db.get_def("npcs", nid)["faction"])) and p.hp > 3:
				return 1 if world.player_interact(pos, "pledge") else 0
			return _npc_session(f)
	return -1


## Cross-floor goals from active threads. Returns -1 when there is nothing to chase.
func _narrative_goal() -> int:
	var p := world.player
	var m := world.current_floor()
	# Relic goals: do them when a relic is in the pack.
	for tid in world.active_thread_ids():
		var tdef := world.db.get_def("threads", tid)
		var gk := String(tdef["goal_kind"])
		var gref := String(tdef["goal_ref"])
		if gk == "work_relic" or gk == "transmute_relic":
			for i in p.inventory.size():
				if p.inventory[i].template_id == gref or (gref == "any" and String(p.inventory[i].def(world.db)["kind"]) == "relic"):
					return 1 if (world.player_work_relic(i) if gk == "work_relic" else world.player_transmute_relic(i)) else 0
		var dest := _goal_floor(gk, gref)
		if dest == "" or not world.floors.has(dest) and not _reachable_floor(dest):
			continue
		if dest == world.floor_id:
			if gk == "visit_floor":
				continue
			return -1 # explore here (the kill/talk will land as the floor is cleared)
		var hop := _next_hop(world.floor_id, dest)
		if hop.is_empty():
			continue
		var tpos := Vector2i(int(hop["x"]), int(hop["y"]))
		if p.pos == tpos:
			world._tel("narrative", "travel:" + String(hop.get("kind", "")))
			if world.needs_gate_to_descend():
				return 1 if world.player_descend_gate("by_name") else 0
			return 1 if world.player_stairs() else 0
		var r := _walk_to(tpos, false)
		if r >= 0:
			return r
	return -1


func _goal_floor(goal_kind: String, goal_ref: String) -> String:
	if goal_kind == "visit_floor":
		return goal_ref if world.db.has("floors", goal_ref) else ""
	if goal_kind == "kill_monster":
		for fid in world.db.all_floor_ids():
			var fd := world.db.floor_def(fid)
			if String(fd.get("boss", "")) == goal_ref or String(fd.get("guardian", "")) == goal_ref:
				return fid
			for e in fd.get("monster_table", []):
				if String(e.get("id", "")) == goal_ref:
					return fid
	return ""


## Floors adjacent to `fid` in the travel graph (spine stairs, portals, atlas edges).
func _neighbors(fid: String) -> Array[String]:
	var out: Array[String] = []
	var fd := world.db.floor_def(fid)
	var kind := String(fd.get("region_kind", "spine"))
	var d := int(fd["depth"])
	if kind == "spine":
		if d > 1:
			out.append(world.db.spine_floor_id(d - 1))
		if d < world.db.max_depth():
			out.append(world.db.spine_floor_id(d + 1))
	elif fd.has("parent"):
		out.append(String(fd["parent"]))
	for e in world.atlas.get(fid, []):
		var t := String(e["target"])
		if not out.has(t):
			out.append(t)
	return out


func _reachable_floor(dest: String) -> bool:
	return world.atlas.has(dest)


func _next_hop(from_id: String, dest: String) -> Dictionary:
	# BFS over the floor graph; the first edge becomes a tile on the current map.
	var prev := {from_id: ""}
	var q: Array[String] = [from_id]
	var head := 0
	while head < q.size():
		var cur := q[head]
		head += 1
		if cur == dest:
			break
		for n in _neighbors(cur):
			if not prev.has(n) and world.atlas.has(n):
				prev[n] = cur
				q.append(n)
	if not prev.has(dest):
		return {}
	var step := dest
	while String(prev[step]) != from_id and String(prev[step]) != "":
		step = String(prev[step])
	var m := world.current_floor()
	var pp := _portal_pos_to(m, step)
	if pp.x >= 0:
		return {"x": pp.x, "y": pp.y, "kind": "portal"}
	var cur_d := world.depth
	var step_d := int(world.db.floor_def(step)["depth"])
	if step_d > cur_d and m.down_pos.x >= 0:
		return {"x": m.down_pos.x, "y": m.down_pos.y, "kind": "down"}
	if step_d < cur_d and m.up_pos.x >= 0:
		return {"x": m.up_pos.x, "y": m.up_pos.y, "kind": "up"}
	return {}


# ------------------------------------------------------------------ random control

func _random_step() -> bool:
	if world.state != World.State.PLAYING:
		return false
	var p := world.player
	var roll := _rng.range_i(0, 99)
	if p.stat_points > 0 and roll < 30:
		return world.player_spend_stat(String(_rng.pick(ContentSchema.ATTRIBUTES)))
	if p.talent_points > 0 and roll < 30:
		var ids := world.db.ids("talents")
		return world.player_learn_talent(String(_rng.pick(ids)))
	if world.needs_gate_to_descend() and world.current_floor().get_tile(p.pos) in [Tiles.STAIRS_DOWN, Tiles.BRANCH_IN]:
		return world.player_descend_gate(String(_rng.pick(World.GATE_METHODS)))
	if roll < 62:
		return world.player_move(Grid.DIRS_8[_rng.range_i(0, 7)])
	if roll < 70:
		return world.player_wait()
	if roll < 76:
		return world.player_pickup()
	if roll < 83 and not p.inventory.is_empty():
		return world.player_use(_rng.range_i(0, p.inventory.size() - 1))
	if roll < 88:
		return world.player_stairs()
	if roll < 92:
		return world.player_search()
	if roll < 96 and not p.talents.is_empty():
		var tid := String(_rng.pick(p.talents.keys()))
		return world.player_use_talent(tid, world.nearest_visible_hostile(8).pos if world.nearest_visible_hostile(8) != null else Vector2i(-1, -1))
	var f := world.current_floor().revealed_feature_at(p.pos)
	if not f.is_empty() and Ecology.is_interactive(f):
		return world.player_interact(p.pos, "")
	return world.player_wait()
