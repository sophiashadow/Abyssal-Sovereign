class_name World
extends RefCounted
## The whole simulation state of one run, and the only API the UI calls.
## No Nodes, no rendering, no input: tests and headless tools drive it the
## same way the game screen does.
##
## Turn model: every actor has `next_time`. The scheduler always runs the
## living actor with the lowest (next_time, id); acting adds the action's
## cost scaled by speed (100 = one normal turn at speed 100). The player has
## id 1, so the player wins ties. Player actions return true if they spent
## time; the world then runs monsters until it is the player's turn again.

const SAVE_VERSION := 11
const SUBJUGATION_LIMIT := 6
## Eight Chains grammar: monster tag -> status laid on the player and chance per hit.
## (chain_fog is delivered by the litany in _monster_turn.)
const CHAIN_TAGS := {
	"chain_isolation": {"status": "isolation", "pct": 35},
	"chain_debility": {"status": "debility", "pct": 30},
	"chain_threat": {"status": "dread", "pct": 30},
	"chain_indulgence": {"status": "false_light", "pct": 20},
	"chain_omnipotence": {"status": "exposure", "pct": 25},
	"chain_degradation": {"status": "degradation", "pct": 30},
	"chain_trivial": {"status": "demanded", "pct": 30},
}
const PLAYER_ID := 1
const COST_MOVE := 100
const COST_ATTACK := 100
const COST_WAIT := 100
const COST_ITEM := 100
const COST_STAIRS := 100
const NOTICE_PCT := 60
const MASK_RISK_MAX := 12
const APOTHEOSIS_THRESHOLD := 8
const GATE_METHODS: Array[String] = ["stormed", "serpents_key", "given_back", "by_name"]
const LOG_LIMIT := 300
## The player recovers 1 health every this many turns (scaled by the
## species' heal_mult: a revenant mends at half speed).
const REGEN_TURNS := 6

enum State { PLAYING, DEAD, WON }

var db: ContentDB
var run_seed: int = 0
var depth: int = 1
var floor_id: String = ""
var floors: Dictionary = {} # floor_id -> FloorMap
var atlas: Dictionary = {} # floor_id -> Array[{"target", "label", "kind"}]
var visited_floors: Array[String] = []
var max_sphere_reached: int = 1
var player: Actor
var rng: Rng
var time: int = 0
var turns: int = 0 # player actions taken
var state: State = State.PLAYING
var death_cause: String = ""
var apotheosis: int = 0
var way_serpent: int = 0
var way_return: int = 0
## Subjugation clock: every chain that lands advances it; at the limit you are Entangled.
var subjugation: int = 0
var contract: String = ""
var contract_progress: int = 0
## contract id -> "fulfilled" | "broken"
var contract_log: Dictionary = {}
var next_entity_id: int = 2
var id_known: Dictionary = {}
var id_aliases: Dictionary = {}
var spawned_uniques: Array[String] = []
var npc_standing: Dictionary = {} # npc_id -> int (-2..+3)
var faction_flags: Dictionary = {} # faction_id -> active pole id
var npcs_met: Array[String] = []
var threads_state: Dictionary = {"pool": [], "active": {}, "completed": [], "refused": [], "failed": [], "pending": []}
var messages: Array[Dictionary] = []
## Bumped whenever messages change, so the UI can redraw lazily.
var log_serial: int = 0

var _player_dist := PackedInt32Array()
var _player_dist_pos := Vector2i(-99999, -99999)


# ---------------------------------------------------------------- creation

static func new_run(content: ContentDB, seed_value: int, species_id: String, class_id: String, hero_name: String) -> World:
	var w := World.new()
	w.db = content
	w.run_seed = seed_value
	w.rng = Rng.new(Rng.derive(seed_value, "play"))
	w.player = w._make_player(species_id, class_id, hero_name)
	w._init_discovery()
	w._build_atlas()
	w.threads_state = Threads.init_state(content, w.atlas, seed_value)
	w._enter_floor(1, true)
	var fd := w.current_floor_def()
	w.log_msg("You descend beneath Terra Tenebrae. %s." % fd.get("name", "The dark"), "lore")
	w.log_msg(String(fd.get("description", "")), "lore")
	w._begin_player_turn()
	return w


func _build_atlas() -> void:
	atlas.clear()
	var arng := Rng.new(Rng.derive(run_seed, "atlas"))
	var active_ids: Dictionary = {}
	for d in range(1, db.max_depth() + 1):
		var sid := db.spine_floor_id(d)
		active_ids[sid] = true
		atlas[sid] = []
		var branches := db.branch_floors_for_depth(d)
		var pool := branches.duplicate()
		var chosen: Array[Dictionary] = []
		var count := mini(2, pool.size())
		for _i in count:
			var idx := arng.range_i(0, pool.size() - 1)
			chosen.append(pool[idx])
			pool.remove_at(idx)
		for bf in chosen:
			var bid := String(bf["id"])
			active_ids[bid] = true
			atlas[bid] = []
			(atlas[sid] as Array).append({"target": bid, "label": String(bf["name"]), "kind": "branch_in"})
	var active_keys := active_ids.keys()
	active_keys.sort()
	for fid in active_keys:
		var fdef := db.floor_def(String(fid))
		if fdef.has("alt_down"):
			var tgt := String(fdef["alt_down"])
			if active_ids.has(tgt):
				var tdef := db.floor_def(tgt)
				(atlas[fid] as Array).append({"target": tgt, "label": String(tdef["name"]), "kind": "alt_down"})
				(atlas[tgt] as Array).append({"target": String(fid), "label": String(fdef["name"]), "kind": "branch_out"})


func _make_player(species_id: String, class_id: String, hero_name: String) -> Actor:
	var sp := db.get_def("species", species_id)
	var cl := db.get_def("classes", class_id)
	var a := Actor.new()
	a.db = db
	a.id = PLAYER_ID
	a.is_player = true
	a.template_id = "player"
	a.name = hero_name if hero_name.strip_edges() != "" else "the Nameless"
	a.glyph = "@"
	a.color = "#e0008f"
	a.species_id = species_id
	a.class_id = class_id
	var attrs := {}
	for k in ContentSchema.ATTRIBUTES:
		attrs[k] = int(sp.get("attributes", {}).get(k, 0)) + int(cl.get("attributes", {}).get(k, 0))
	a.base = {
		"max_hp": int(sp["hp"]) + int(cl["hp"]),
		"might": attrs["might"], "agility": attrs["agility"], "will": attrs["will"],
		"accuracy": int(cl.get("accuracy", 0)), "evasion": int(cl.get("evasion", 0)),
		"defense": 0, "damage": "1d2", "speed": 100, "sight": 8, "crit": 0, "perception": 10,
	}
	for k in sp.get("mods", {}):
		a.base[k] = int(a.base.get(k, 0)) + int(sp["mods"][k])
	for t in sp.get("traits", []):
		a.traits.append(String(t))
	for t in cl.get("traits", []):
		a.traits.append(String(t))
	for dt in sp.get("resists", {}):
		a.resists[String(dt)] = int(sp["resists"][dt])
	a.hp = a.stat("max_hp")
	for tid in cl.get("starting_equipment", []):
		var it := _new_item(String(tid))
		a.equipment[_slot_for(it)] = it
	for tid in cl.get("starting_items", []):
		_add_to_inventory(a, _new_item(String(tid)))
	a.hp = a.stat("max_hp")
	a.stat_points = 2 if a.has_trait("adaptable") else 1
	a.talent_points = 1
	a.resource = a.max_resource()
	a.awake = true
	return a


func _init_discovery() -> void:
	var potions := Affixes.POTION_ALIASES.duplicate()
	var scrolls := Affixes.SCROLL_ALIASES.duplicate()
	_shuffle_strings(potions)
	_shuffle_strings(scrolls)
	var pi := 0
	var si := 0
	for tid in db.ids("items"):
		var d := db.get_def("items", tid)
		if String(d.get("kind", "")) != "consumable":
			continue
		if String(d.get("effect", "")) == "scroll":
			id_aliases[tid] = scrolls[si % scrolls.size()]
			si += 1
		else:
			id_aliases[tid] = potions[pi % potions.size()]
			pi += 1
	for it in player.inventory:
		id_known[it.template_id] = true


func _shuffle_strings(arr: Array[String]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.range_i(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func item_name(it: Item) -> String:
	return it.display_name(db, id_known, id_aliases)


func is_item_identified(it: Item) -> bool:
	return it.is_identified_in(db, id_known)


func identify_item(it: Item) -> bool:
	var changed := false
	if String(it.def(db).get("kind", "")) == "consumable":
		if not bool(id_known.get(it.template_id, false)):
			id_known[it.template_id] = true
			changed = true
	elif not it.identified:
		it.identified = true
		changed = true
	return changed


func identify_pack() -> int:
	var count := 0
	for slot in Actor.SLOTS:
		var eq_it := player.equipped(slot)
		if eq_it != null and identify_item(eq_it):
			count += 1
	for it in player.inventory:
		if identify_item(it):
			count += 1
	return count


func unbind_curses(only_equipped: bool = false) -> int:
	var uncursed := 0
	for slot in Actor.SLOTS:
		var it := player.equipped(slot)
		if it != null and it.buc == "cursed":
			it.buc = "uncursed"
			it.identified = true
			uncursed += 1
	if not only_equipped:
		for it in player.inventory:
			if it.buc == "cursed":
				it.buc = "uncursed"
				it.identified = true
				uncursed += 1
	if uncursed == 0 and not only_equipped:
		for slot in Actor.SLOTS:
			var it := player.equipped(slot)
			if it != null and it.buc == "uncursed":
				it.buc = "blessed"
				it.identified = true
				log_msg("Your %s shines with quiet blessing." % item_name(it), "good")
				return 1
	return uncursed


func _maybe_artifact_drop() -> Item:
	var pool: Array[String] = []
	for tid in db.ids("items"):
		if String(db.get_def("items", tid).get("rarity", "common")) == "artifact" and not spawned_uniques.has(tid):
			pool.append(tid)
	if pool.is_empty():
		return null
	var chosen := String(rng.pick(pool))
	spawned_uniques.append(chosen)
	var it := _new_item(chosen)
	Affixes.roll_equipment(it, db, depth, rng, true)
	return it


func _new_item(template_id: String) -> Item:
	var it := Item.new()
	it.id = next_entity_id
	next_entity_id += 1
	it.template_id = template_id
	return it


func _new_monster(template_id: String, p: Vector2i) -> Actor:
	var d := db.get_def("monsters", template_id)
	var a := Actor.new()
	a.db = db
	a.id = next_entity_id
	next_entity_id += 1
	a.template_id = template_id
	a.name = String(d["name"])
	a.glyph = String(d["glyph"])
	a.color = String(d["color"])
	a.pos = p
	a.base = {
		"max_hp": int(d["hp"]), "might": 0, "agility": 0, "will": 0,
		"accuracy": int(d["accuracy"]), "evasion": int(d["evasion"]), "defense": int(d["defense"]),
		"damage": String(d["damage"]), "damage_type": String(d.get("damage_type", "physical")),
		"speed": int(d["speed"]), "sight": 8, "crit": 0, "perception": int(d["perception"]),
	}
	if d.has("ranged_damage"):
		a.base["ranged_damage"] = String(d["ranged_damage"])
	if d.has("ranged_range"):
		a.base["ranged_range"] = int(d["ranged_range"])
	a.hp = int(d["hp"])
	a.xp_value = int(d["xp"])
	a.unique = bool(d.get("unique", false))
	for dt in d.get("resists", {}):
		a.resists[String(dt)] = int(d["resists"][dt])
	for sp in d.get("specials", []):
		a.specials.append(String(sp))
	for t in d.get("tags", []):
		a.tags.append(String(t))
	return a


func _slot_for(it: Item) -> String:
	match String(it.def(db)["kind"]):
		"weapon":
			return "weapon"
		"ranged":
			return "ranged"
		"armor":
			return "armor"
		"amulet":
			return "amulet"
	return ""


# ---------------------------------------------------------------- floors

func current_floor() -> FloorMap:
	return floors[floor_id]


func current_floor_def() -> Dictionary:
	return db.floor_def(floor_id)


func portal_at(p: Vector2i) -> Dictionary:
	return current_floor().portal_at(p)


func _floor_seed(d: int) -> int:
	return Rng.derive(run_seed, "floor:%d" % d)


func _floor_seed_for(fid: String) -> int:
	var fd := db.floor_def(fid)
	if String(fd.get("region_kind", "spine")) == "spine":
		return _floor_seed(int(fd["depth"]))
	return Rng.derive(run_seed, "floor:" + fid)


func _apply_elite(mon: Actor, kind: String) -> void:
	mon.is_elite = true
	if not mon.tags.has("elite"):
		mon.tags.append("elite")
	var bonus_hp := maxi(3, mon.hp / 3)
	mon.base["max_hp"] = int(mon.base["max_hp"]) + bonus_hp
	mon.hp = int(mon.base["max_hp"])
	mon.xp_value = int(roundf(float(mon.xp_value) * 1.6))
	match kind:
		"cinder":
			mon.name = "Ashen " + mon.name
			mon.color = "#ff7a33"
			mon.base["accuracy"] = int(mon.base["accuracy"]) + 1
			mon.base["damage_type"] = "fire"
			mon.resists["fire"] = maxi(50, int(mon.resists.get("fire", 0)))
			if not mon.specials.has("cinder_bolt"):
				mon.specials.append("cinder_bolt")
		"rime":
			mon.name = "Rime-bound " + mon.name
			mon.color = "#6ec6ff"
			mon.base["defense"] = int(mon.base["defense"]) + 1
			mon.base["damage_type"] = "cold"
			mon.resists["cold"] = maxi(50, int(mon.resists.get("cold", 0)))
			if not mon.specials.has("grave_chill"):
				mon.specials.append("grave_chill")
		"void":
			mon.name = "Apostate " + mon.name
			mon.color = "#c77dff"
			mon.base["evasion"] = int(mon.base["evasion"]) + 1
			mon.base["damage_type"] = "void"
			mon.resists["void"] = maxi(50, int(mon.resists.get("void", 0)))
			if not mon.specials.has("void_bolt"):
				mon.specials.append("void_bolt")
		"iron":
			mon.name = "Ironbound " + mon.name
			mon.color = "#e09f5a"
			mon.base["defense"] = int(mon.base["defense"]) + 1
			mon.base["accuracy"] = int(mon.base["accuracy"]) + 1
			mon.resists["physical"] = maxi(20, int(mon.resists.get("physical", 0)))
			if not mon.specials.has("iron_shackle"):
				mon.specials.append("iron_shackle")
		"radiant":
			mon.name = "Gilded " + mon.name
			mon.color = "#f2c35c"
			mon.base["accuracy"] = int(mon.base["accuracy"]) + 1
			mon.base["damage_type"] = "radiant"
			mon.resists["radiant"] = maxi(50, int(mon.resists.get("radiant", 0)))
			if not mon.specials.has("solar_bolt"):
				mon.specials.append("solar_bolt")
			if not mon.tags.has("chain_omnipotence"):
				mon.tags.append("chain_omnipotence")
		"swift":
			mon.name = "Fleet " + mon.name
			mon.color = "#78bea7"
			mon.base["speed"] = int(mon.base["speed"]) + 25
			mon.base["evasion"] = int(mon.base["evasion"]) + 2
			if not mon.specials.has("warren_pounce"):
				mon.specials.append("warren_pounce")
		"vampiric":
			mon.name = "Crimson " + mon.name
			mon.color = "#ff4d6d"
			mon.base["bonus_damage"] = int(mon.base.get("bonus_damage", 0)) + 1
			if not mon.specials.has("leech_bite"):
				mon.specials.append("leech_bite")
		"warded":
			mon.name = "Sealed " + mon.name
			mon.color = "#aab6c8"
			mon.base["defense"] = int(mon.base["defense"]) + 2
			for dt in ["fire", "cold", "void"]:
				mon.resists[dt] = maxi(25, int(mon.resists.get(dt, 0)))
			if not mon.specials.has("protect_ally"):
				mon.specials.append("protect_ally")


func _build_floor(d: int) -> FloorMap:
	return _build_floor_by_id(db.spine_floor_id(d))


func _build_floor_by_id(fid: String) -> FloorMap:
	var fd := db.floor_def(fid)
	var d := int(fd["depth"])
	var extra: Array = atlas.get(fid, [])
	var m := DungeonGen.generate(fd, _floor_seed_for(fid), extra)
	for pt in m.portals:
		var tid := String(pt.get("target", ""))
		if db.has("floors", tid):
			pt["label"] = String(db.floor_def(tid)["name"])
	for s in m.spawns:
		if s["kind"] == "monster":
			var mon := _new_monster(String(s["id"]), s["pos"])
			if s.has("elite"):
				_apply_elite(mon, String(s["elite"]))
			mon.next_time = time + rng.range_i(0, 99)
			m.actors.append(mon)
		else:
			var it: Item = null
			if d >= 3 and rng.chance_pct(8):
				it = _maybe_artifact_drop()
			if it == null:
				it = _new_item(String(s["id"]))
				Affixes.roll_equipment(it, db, d, rng, bool(s.get("magic", false)))
			it.pos = s["pos"]
			m.items.append(it)
	m.spawns.clear()
	_place_floor_npcs(m, fd)
	return m


func _free_npc_spot(m: FloorMap, nrng: Rng) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for r in m.rooms:
		for y in range(r.position.y + 1, r.end.y - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				var p := Vector2i(x, y)
				if not (m.get_tile(p) in [Tiles.FLOOR, Tiles.SANCTUARY_FLOOR]):
					continue
				if p == m.up_pos or p == m.down_pos or p == m.exit_pos:
					continue
				if not m.feature_at(p).is_empty() or m.actor_at(p) != null:
					continue
				candidates.append(p)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[nrng.range_i(0, candidates.size() - 1)]


func _place_floor_npcs(m: FloorMap, fd: Dictionary) -> void:
	var fid := String(fd["id"])
	var npc_pool: Array[String] = []
	for nid in db.ids("npcs"):
		var flist: Array = db.get_def("npcs", nid).get("floors", [])
		if flist.has(fid):
			npc_pool.append(String(nid))
	if npc_pool.is_empty():
		return
	npc_pool.sort()
	var nrng := Rng.new(_floor_seed_for(fid) ^ 0x4E5043)
	var count := 2 if String(fd.get("region_kind", "")) == "settlement" and npc_pool.size() >= 2 else 1
	for _i in count:
		if npc_pool.is_empty():
			break
		var nid := String(nrng.pick(npc_pool))
		npc_pool.erase(nid)
		var spot := _free_npc_spot(m, nrng)
		if spot.x < 0:
			break
		var ndef := db.get_def("npcs", nid)
		m.features.append({
			"kind": "npc",
			"sub": nid,
			"npc_name": "%s (%s)" % [String(ndef["name"]), String(ndef["role"])],
			"x": spot.x, "y": spot.y,
			"revealed": true, "used": false,
		})


func npc_standing_of(npc_id: String) -> int:
	return int(npc_standing.get(npc_id, 0))


func faction_pole_of(faction_id: String) -> String:
	return String(faction_flags.get(faction_id, ""))


func adjust_npc_standing(npc_id: String, delta: int) -> void:
	npc_standing[npc_id] = clampi(npc_standing_of(npc_id) + delta, -2, 3)


func set_faction_pole(faction_id: String, pole: String) -> void:
	faction_flags[faction_id] = pole


func _enter_floor(d: int, arriving_from_above: bool) -> void:
	_enter_floor_by_id(db.spine_floor_id(d), "above" if arriving_from_above else "below")


func _enter_floor_by_id(target_id: String, arrival_kind: String, from_id: String = "") -> void:
	if floor_id != "" and floors.has(floor_id) and player in current_floor().actors:
		current_floor().actors.erase(player)
	var first_ever := not floors.has(target_id)
	floor_id = target_id
	var fd := db.floor_def(target_id)
	depth = int(fd["depth"])
	max_sphere_reached = maxi(max_sphere_reached, depth)
	if not visited_floors.has(target_id):
		visited_floors.append(target_id)
	if first_ever:
		floors[target_id] = _build_floor_by_id(target_id)
	var m := current_floor()
	var target := m.up_pos if arrival_kind == "above" else (m.down_pos if m.down_pos.x >= 0 else m.up_pos)
	if from_id != "":
		for pt in m.portals:
			if String(pt.get("target", "")) == from_id:
				target = Vector2i(int(pt["x"]), int(pt["y"]))
				break
	if target_id == db.spine_floor_id(1) and arrival_kind == "above" and first_ever:
		player.pos = _adjacent_free(m, target)
	else:
		player.pos = _nearest_free(m, target)
	m.actors.insert(0, player)
	for a in m.actors:
		if not a.is_player:
			a.next_time = maxi(a.next_time, time + 1)
	_player_dist_pos = Vector2i(-99999, -99999)
	_thread_event("floor", target_id)
	_thread_event("visit_floor", target_id)
	if not first_ever or target_id != db.spine_floor_id(1):
		_maybe_surface_venefica_naming()


func _adjacent_free(m: FloorMap, p: Vector2i) -> Vector2i:
	for dir in Grid.DIRS_8:
		var q := p + dir
		if m.is_walkable(q) and m.actor_at(q) == null:
			return q
	return _nearest_free(m, p)


func _nearest_free(m: FloorMap, p: Vector2i) -> Vector2i:
	if m.actor_at(p) == null and m.is_walkable(p):
		return p
	var dist := Pathing.distance_map(m, p)
	var best := p
	var best_d := 1 << 30
	for y in m.height:
		for x in m.width:
			var q := Vector2i(x, y)
			var dq := dist[m.idx(q)]
			if dq > 0 and dq < best_d and m.actor_at(q) == null:
				best = q
				best_d = dq
	return best


# ---------------------------------------------------------------- log

func log_msg(text: String, kind: String = "info") -> void:
	if text == "":
		return
	messages.append({"t": text, "k": kind, "n": turns})
	if messages.size() > LOG_LIMIT:
		messages.pop_front()
	log_serial += 1


# ---------------------------------------------------------------- player actions
# Each returns true when the action spent time (and so advanced the world).

func player_move(dir: Vector2i) -> bool:
	if state != State.PLAYING or dir == Vector2i.ZERO:
		return false
	var m := current_floor()
	var target := player.pos + dir
	var other := m.actor_at(target)
	if other != null and other != player:
		if not m.can_step(player.pos, target):
			return false
		_attack(player, other)
		return _finish_player_action(COST_ATTACK)
	if player.has_status("pinned"):
		log_msg("You are shackled in place and cannot walk! (Attack adjacent foes or blink free.)", "danger")
		return false
	if m.get_tile(target) == Tiles.DOOR_SEALED:
		log_msg("The Unwritten Door will not open while its warden stands.", "info")
		return false
	var feat_ahead := m.revealed_feature_at(target)
	if feat_ahead.get("kind", "") == "secret_door" and not bool(feat_ahead.get("used", false)):
		_open_secret_door(target)
		return _finish_player_action(COST_ITEM)
	if not m.can_step(player.pos, target):
		return false
	var move_cost := COST_MOVE + (25 if m.get_tile(target) == Tiles.WATER_SHALLOW else 0)
	player.pos = target
	_on_actor_enter_tile(player, target)
	if state != State.PLAYING:
		return true
	_describe_floor_here()
	if m.get_tile(target) == Tiles.DOOR_OPEN:
		_win()
		return true
	return _finish_player_action(move_cost)


func player_wait() -> bool:
	if state != State.PLAYING:
		return false
	player.flags["wait_turn"] = turns + 1
	return _finish_player_action(COST_WAIT)


func player_pickup() -> bool:
	if state != State.PLAYING:
		return false
	var here := current_floor().items_at(player.pos)
	if here.is_empty():
		log_msg("There is nothing here to take.")
		return false
	var it := here[0]
	if not _can_carry(player, it):
		log_msg("Your pack is full.", "danger")
		return false
	current_floor().items.erase(it)
	var shown := item_name(it)
	_add_to_inventory(player, it)
	log_msg("You take the %s." % shown, "good")
	return _finish_player_action(COST_ITEM)


func player_drop(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	player.inventory.remove_at(index)
	it.pos = player.pos
	current_floor().items.append(it)
	log_msg("You drop the %s." % item_name(it))
	return _finish_player_action(COST_ITEM)


## Equips or uses the inventory item at `index`, depending on its kind.
func player_use(index: int) -> bool:
	return player_use_at(index, Vector2i(-1, -1))


func player_use_at(index: int, target_pos: Vector2i = Vector2i(-1, -1)) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) == "consumable":
		var eff := String(d["effect"])
		var acted := false
		if eff == "projectile":
			acted = _throw_consumable(it, index, d, target_pos)
		elif eff == "scroll":
			acted = _cast_scroll(it, index, d, target_pos)
		else:
			_consume(player, it, index)
			acted = _finish_player_action(COST_ITEM)
		if acted:
			id_known[it.template_id] = true
		return acted
	if String(d["kind"]) == "relic":
		return player_work_relic(index)
	var slot := _slot_for(it)
	var old := player.equipped(slot)
	if old != null and old.buc == "cursed":
		old.identified = true
		log_msg("The cursed %s will not let go! Read a scroll of unbinding or break the chain." % item_name(old), "danger")
		return false
	var was_unid := not it.identified
	it.identified = true
	player.inventory.remove_at(index)
	var hp_frac := float(player.hp) / float(player.stat("max_hp"))
	player.equipment[slot] = it
	if old != null:
		player.inventory.insert(index, old)
	# Gear that changes max health keeps the same fraction of health.
	player.hp = clampi(int(roundf(hp_frac * player.stat("max_hp"))), 1, player.stat("max_hp"))
	if was_unid and it.buc == "cursed":
		log_msg("You ready the %s—and feel a cold lock snap shut!" % item_name(it), "danger")
	else:
		log_msg("You ready the %s." % item_name(it), "good")
	return _finish_player_action(COST_ITEM)


func projectile_trace(from: Vector2i, to: Vector2i, max_range: int) -> Dictionary:
	var m := current_floor()
	var path: Array[Vector2i] = []
	var last_free := from
	var impact := from
	var hit_actor: Actor = null
	var blocked := false
	for p in Grid.line(from, to):
		if Grid.chebyshev(from, p) > max_range:
			break
		if not m.in_bounds(p) or not m.is_transparent(p) or not m.is_walkable(p):
			blocked = true
			impact = last_free
			break
		path.append(p)
		impact = p
		last_free = p
		var a := m.actor_at(p)
		if a != null and a.is_alive():
			hit_actor = a
			break
	return {"path": path, "hit_actor": hit_actor, "impact": impact, "last_free": last_free, "blocked": blocked}


func _resolve_target_pos(target_pos: Vector2i, max_range: int, need_clear_shot: bool = false) -> Vector2i:
	if target_pos.x >= 0:
		return target_pos
	var m := current_floor()
	var best: Actor = null
	var best_d := 1 << 30
	for a in m.actors:
		if not a.is_player and a.is_alive() and m.is_visible(a.pos):
			var dist := Grid.chebyshev(player.pos, a.pos)
			if dist <= max_range and dist < best_d:
				if need_clear_shot:
					var tr := projectile_trace(player.pos, a.pos, max_range)
					if tr["hit_actor"] != a:
						continue
				best = a
				best_d = dist
	if best != null:
		return best.pos
	var fallback := nearest_visible_hostile(max_range)
	return fallback.pos if fallback != null else Vector2i(-1, -1)


func player_fire(target_pos: Vector2i = Vector2i(-1, -1)) -> bool:
	if state != State.PLAYING:
		return false
	var w := player.equipped("ranged")
	if w == null:
		log_msg("You have no ranged weapon equipped.", "info")
		return false
	var d := w.def(db)
	var max_range := int(d.get("range", 5)) + (1 if player.has_trait("steady_aim") else 0)
	var tpos := _resolve_target_pos(target_pos, max_range, true)
	if tpos.x < 0:
		log_msg("No target in range.", "info")
		return false
	var m := current_floor()
	var dist := Grid.chebyshev(player.pos, tpos)
	if dist == 0 or dist > max_range or not m.is_visible(tpos):
		log_msg("Target is out of range or sight.", "info")
		return false
	var tr := projectile_trace(player.pos, tpos, max_range)
	var foe: Actor = tr["hit_actor"]
	if tr["blocked"] and foe == null:
		log_msg("Your line of fire is blocked.", "info")
		return false
	if foe == null:
		log_msg("Your shot flies into empty air.", "info")
		return _finish_player_action(COST_ATTACK)
	var dtype := w.effective_damage_type(db)
	var res := Combat.resolve_ranged(player, foe, Grid.chebyshev(player.pos, foe.pos),
		String(d["damage"]), int(d.get("accuracy", 0)) + w.total_mod(db, "accuracy"), int(d.get("crit", 0)), dtype, rng)
	foe.awake = true
	_remember_player(foe)
	if not res["hit"]:
		log_msg("Your shot misses the %s." % foe.name, "combat")
		return _finish_player_action(COST_ATTACK)
	var dmg := 0 if int(res["damage"]) == 0 else maxi(1, int(res["damage"]) + w.total_mod(db, "damage"))
	var note := _combat_note(res)
	log_msg("You shoot the %s for %d%s." % [foe.name, dmg, note], "combat")
	if player.resource_kind() == "poise" and (bool(res["crit"]) or bool(res["sneak"])):
		player.resource = mini(player.max_resource(), player.resource + 1)
	apply_damage(foe, dmg, player.name, dtype)
	var st := w.effective_status(db)
	if foe.is_alive() and st != "":
		apply_status(foe, st)
	return _finish_player_action(COST_ATTACK)


func _combat_note(res: Dictionary) -> String:
	var parts: PackedStringArray = []
	var dtype := String(res.get("type", "physical"))
	if dtype != "physical":
		parts.append(dtype)
	var r := int(res.get("resist", 0))
	if r > 0:
		parts.append("resisted")
	elif r < 0:
		parts.append("vulnerable")
	if bool(res.get("crit", false)):
		parts.append("critical")
	return " (%s)" % ", ".join(parts) if not parts.is_empty() else ""


func _throw_consumable(it: Item, index: int, d: Dictionary, target_pos: Vector2i) -> bool:
	var max_range := int(d.get("range", 4)) + (1 if player.has_trait("steady_aim") else 0)
	var tpos := _resolve_target_pos(target_pos, max_range, true)
	if tpos.x < 0:
		log_msg("No target in range for %s." % d["name"], "info")
		return false
	var m := current_floor()
	if Grid.chebyshev(player.pos, tpos) > max_range or not m.is_visible(tpos):
		log_msg("Target is out of range or sight.", "info")
		return false
	var tr := projectile_trace(player.pos, tpos, max_range)
	var foe: Actor = tr["hit_actor"]
	var aoe := int(d.get("aoe_radius", 0))
	if tr["blocked"] and foe == null and aoe <= 0:
		log_msg("Your throw is blocked by stone.", "info")
		return false
	var dtype := String(d.get("damage_type", "physical"))
	var flask_bonus := 2 if (player.has_trait("alchemical_potency") and String(d.get("glyph", "")) == "!") else 0
	if aoe > 0:
		var center: Vector2i = foe.pos if foe != null else Vector2i(tr["impact"])
		var targets: Array[Actor] = []
		for a in m.actors:
			if not a.is_player and a.is_alive() and Grid.chebyshev(center, a.pos) <= aoe:
				targets.append(a)
		if targets.is_empty():
			log_msg("The %s shatters harmlessly." % d["name"], "info")
		for a in targets:
			a.awake = true
			_remember_player(a)
			var raw := Dice.roll(String(d["damage"]), rng) + flask_bonus
			var mit := Combat.mitigate(raw, a, dtype)
			log_msg("The %s blasts the %s for %d (%s)." % [d["name"], a.name, int(mit["damage"]), dtype], "combat")
			apply_damage(a, int(mit["damage"]), player.name, dtype)
			if a.is_alive() and d.has("status"):
				apply_status(a, String(d["status"]))
	else:
		if foe == null:
			log_msg("Your %s hits nothing." % d["name"], "info")
		else:
			var res := Combat.resolve_ranged(player, foe, Grid.chebyshev(player.pos, foe.pos),
				String(d["damage"]), 2, 0, dtype, rng)
			foe.awake = true
			_remember_player(foe)
			if not res["hit"]:
				log_msg("Your %s misses the %s." % [d["name"], foe.name], "combat")
			else:
				var hit_d := int(res["damage"]) + flask_bonus
				log_msg("Your %s strikes the %s for %d%s." % [d["name"], foe.name, hit_d, _combat_note(res)], "combat")
				apply_damage(foe, hit_d, player.name, dtype)
				if foe.is_alive() and d.has("status"):
					apply_status(foe, String(d["status"]))
	it.quantity -= 1
	if it.quantity <= 0:
		player.inventory.remove_at(index)
	return _finish_player_action(COST_ITEM)


func _cast_scroll(it: Item, index: int, d: Dictionary, target_pos: Vector2i) -> bool:
	var m := current_floor()
	var spell := String(d["spell"])
	var max_range := int(d.get("range", 5))
	var will_v := maxi(0, player.stat("will"))
	match spell:
		"phase_step":
			var dest := target_pos
			if dest.x < 0:
				dest = _best_blink_tile(m, max_range)
			if dest.x < 0 or Grid.chebyshev(player.pos, dest) > max_range or not m.is_visible(dest) or not m.is_walkable(dest) or m.actor_at(dest) != null:
				log_msg("No valid open tile in phase range.", "info")
				return false
			player.pos = dest
			_remove_status(player, "pinned")
			update_fov()
			log_msg("You read the %s and fold through the air." % d["name"], "good")
		"abyssal_lance":
			var tpos := _resolve_target_pos(target_pos, max_range, false)
			if tpos.x < 0 or tpos == player.pos or not m.is_visible(tpos):
				log_msg("No target in line for the lance.", "info")
				return false
			var ray_end := player.pos
			for p in Grid.line(player.pos, player.pos + (tpos - player.pos) * max_range):
				if Grid.chebyshev(player.pos, p) > max_range or not m.in_bounds(p) or not m.is_transparent(p) or not m.is_walkable(p):
					break
				ray_end = p
			var hits: Array[Actor] = []
			for p in Grid.line(player.pos, ray_end):
				var a := m.actor_at(p)
				if a != null and not a.is_player and a.is_alive():
					hits.append(a)
			if hits.is_empty():
				log_msg("The lance of void cuts only stone and air.", "info")
			for a in hits:
				a.awake = true
				_remember_player(a)
				var raw := Dice.roll("2d6", rng) + will_v
				var mit := Combat.mitigate(raw, a, "void")
				log_msg("Abyssal lance pierces the %s for %d (void)." % [a.name, int(mit["damage"])], "combat")
				apply_damage(a, int(mit["damage"]), player.name, "void")
		"cinder_ward":
			var hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= max_range:
					a.awake = true
					_remember_player(a)
					var raw := Dice.roll("2d5", rng) + will_v
					var mit := Combat.mitigate(raw, a, "fire")
					apply_damage(a, int(mit["damage"]), player.name, "fire")
					if a.is_alive():
						apply_status(a, "burning")
					hits += 1
			apply_status(player, "braced")
			log_msg("Cinder ward erupts across %d foe%s and braces your stance." % [hits, "" if hits == 1 else "s"], "good")
		"identify":
			var n := identify_pack()
			log_msg("The witness sheds calm light: %d item%s identified." % [n, "" if n == 1 else "s"] if n > 0 else "Nothing in your pack remains hidden.", "good")
		"unbind":
			var n := unbind_curses(false)
			log_msg("Cold iron locks snap open (%d unbound)." % n if n > 0 else "No curses bound you.", "good")
		"sanctuary_ward":
			apply_status(player, "sanctuary_ward")
			subjugation = maxi(0, subjugation - 1)
			var healed := Dice.roll("1d6", rng) + 2
			player.hp = mini(player.stat("max_hp"), player.hp + healed)
			log_msg("Quiet sanctuary light steadies your guard (+%d HP, -1 Subjugation)." % healed, "good")
		"chain_break":
			for cid in ["pinned", "bleeding", "demanded", "dread", "debility", "degradation", "perception_fog", "entangled", "isolation", "exposure"]:
				_remove_status(player, cid)
			subjugation = maxi(0, subjugation - 2)
			log_msg("The writ strikes your name off the docket; the Chains slacken (-2 Subjugation).", "good")
		"map_reveal":
			for fy in range(maxi(0, player.pos.y - 18), mini(m.height, player.pos.y + 19)):
				for fx in range(maxi(0, player.pos.x - 18), mini(m.width, player.pos.x + 19)):
					m.set_explored(Vector2i(fx, fy))
			for f in m.features:
				if Grid.chebyshev(player.pos, Vector2i(int(f["x"]), int(f["y"]))) <= 18:
					f["revealed"] = true
			update_fov()
			log_msg("Survey lines flare briefly across the stone, revealing walls and seams.", "good")
		"blink_swap":
			var foe := nearest_visible_hostile(max_range)
			if foe == null:
				var dest := _best_blink_tile(m, max_range)
				if dest.x < 0:
					log_msg("No visible anchor for the translocation.", "info")
					return false
				player.pos = dest
			else:
				var foe_pos := foe.pos
				foe.pos = player.pos
				player.pos = foe_pos
				_remove_status(player, "pinned")
			update_fov()
			log_msg("You invert coordinates across the Geometry!", "good")
		"rime_nova":
			var r_hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= max_range:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(Dice.roll("2d5", rng) + will_v, a, "cold")
					apply_damage(a, int(mit["damage"]), player.name, "cold")
					if a.is_alive():
						apply_status(a, "chilled")
					r_hits += 1
			log_msg("An ossuary frost-wave sweeps %d foe%s." % [r_hits, "" if r_hits == 1 else "s"], "good")
		"false_dawn":
			var f_hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= max_range:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(Dice.roll("2d5", rng) + will_v, a, "radiant")
					apply_damage(a, int(mit["damage"]), player.name, "radiant")
					if a.is_alive():
						apply_status(a, "exposure")
					f_hits += 1
			log_msg("Harsh solar glare exposes %d foe%s." % [f_hits, "" if f_hits == 1 else "s"], "good")
		"void_snare":
			var v_hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= max_range:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(Dice.roll("2d4", rng) + will_v, a, "void")
					apply_damage(a, int(mit["damage"]), player.name, "void")
					if a.is_alive():
						apply_status(a, "pinned")
					v_hits += 1
			log_msg("Chalk threads pin %d foe%s in the Margin." % [v_hits, "" if v_hits == 1 else "s"], "good")
		"iron_skin":
			_remove_status(player, "sundered")
			apply_status(player, "iron_skin")
			log_msg("Your coat and guard set like cold pig-iron.", "good")
		"haste_litany":
			apply_status(player, "haste_litany")
			log_msg("Your stride slips ahead of the sentry's count.", "good")
		"reclaim_vigor":
			var h_amt := Dice.roll("3d4+4", rng)
			player.hp = mini(player.stat("max_hp"), player.hp + h_amt)
			player.resource = mini(player.max_resource(), player.resource + 6)
			log_msg("Quiet breath returns (+%d HP, +6 %s)." % [h_amt, player.resource_label()], "good")
		"consecrate_tile":
			for d8 in Grid.DIRS_8:
				var tp: Vector2i = player.pos + d8
				if m.in_bounds(tp) and m.get_tile(tp) in [Tiles.FLOOR, Tiles.ASH_EMBER, Tiles.RIME_ICE, Tiles.MIASMA, Tiles.SOLAR_GLARE]:
					m.set_tile(tp, Tiles.SANCTUARY_FLOOR)
			if m.get_tile(player.pos) == Tiles.FLOOR:
				m.set_tile(player.pos, Tiles.SANCTUARY_FLOOR)
			log_msg("Chalk dust settles; clean sanctuary stone rings your feet.", "good")
		"audit_banish":
			var foe := nearest_visible_hostile(max_range)
			if foe == null:
				log_msg("No visible foe to strike from the roll.", "info")
				return false
			if foe.unique:
				var mit := Combat.mitigate(Dice.roll("2d6+2", rng) + will_v, foe, "void")
				apply_damage(foe, int(mit["damage"]), player.name, "void")
				log_msg("The writ tears at %s for %d (void)!" % [foe.name, int(mit["damage"])], "combat")
			else:
				var far := _best_blink_tile(m, 6)
				if far.x >= 0:
					foe.pos = far
					apply_status(foe, "chilled")
					log_msg("A void warrant hurls the %s across the chamber." % foe.name, "good")
		"quiet_shroud":
			apply_status(player, "quiet_shroud")
			apply_status(player, "veiled")
			log_msg("Linen silence draws tightly around your silhouette.", "good")
		"cinder_storm":
			var c_hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= max_range:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(Dice.roll("2d6", rng) + will_v, a, "fire")
					apply_damage(a, int(mit["damage"]), player.name, "fire")
					if a.is_alive():
						apply_status(a, "burning")
					c_hits += 1
			log_msg("Dry furnace embers sweep %d foe%s." % [c_hits, "" if c_hits == 1 else "s"], "good")
		"oath_salve":
			_remove_status(player, "reckoning")
			_remove_status(player, "forsworn")
			apply_status(player, "apostate_focus")
			log_msg("You strike an unsigned tally; reckoning releases its grip.", "good")
	_trigger_ritual_cadence()
	it.quantity -= 1
	if it.quantity <= 0:
		player.inventory.remove_at(index)
	return _finish_player_action(COST_ITEM)


func _trigger_ritual_cadence() -> void:
	if player.has_trait("ritual_cadence"):
		player.resource = mini(player.max_resource(), player.resource + 4)
		apply_status(player, "braced")
		log_msg("Your ritual cadence steadies breath and guard (+4 Resonance, Braced).", "good")


func _best_blink_tile(m: FloorMap, max_range: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := -999999
	var foe := nearest_visible_hostile(max_range)
	for dy in range(-max_range, max_range + 1):
		for dx in range(-max_range, max_range + 1):
			var p := player.pos + Vector2i(dx, dy)
			if p == player.pos or Grid.chebyshev(player.pos, p) > max_range:
				continue
			if not m.is_visible(p) or not m.is_walkable(p) or m.actor_at(p) != null:
				continue
			var score := Grid.chebyshev(p, foe.pos) * 10 if foe != null else Grid.chebyshev(player.pos, p)
			if score > best_score:
				best_score = score
				best = p
	return best


func player_work_relic(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) != "relic":
		return false
	var sid := String(d["work_status"])
	var cost := int(d.get("work_cost_hp", 0))
	if cost > 0 and player.has_trait("infernal_blood"):
		cost = maxi(1, cost - 1)
	if player.has_status(sid):
		log_msg("The %s is already active." % d["name"])
		return false
	if cost > 0 and player.hp <= cost:
		log_msg("You lack the blood to work the %s." % d["name"], "danger")
		return false
	player.hp -= cost
	apotheosis += 1
	apply_status(player, sid)
	if sid in ["confessors_clarity", "lamp_vigil", "witness_mirror_work"]:
		if player.has_status("perception_fog"):
			_remove_status(player, "perception_fog")
			log_msg("The grey fog parts.", "good")
		if sid != "witness_mirror_work":
			var n := identify_pack()
			if n > 0:
				log_msg("Its light lays bare %d hidden item%s." % [n, "" if n == 1 else "s"], "good")
	if sid == "archive_lens_work":
		for f in current_floor().features:
			if Grid.chebyshev(player.pos, Vector2i(int(f["x"]), int(f["y"]))) <= 6:
				f["revealed"] = true
	if sid == "rime_bell_work":
		for a in current_floor().actors:
			if not a.is_player and a.is_alive() and Grid.chebyshev(player.pos, a.pos) <= 2:
				apply_status(a, "chilled")
	if sid in ["crown_decree", "unwritten_ledger_work"]:
		_remove_status(player, "entangled")
		subjugation = maxi(0, subjugation - (subjugation if sid == "crown_decree" else 2))
	if sid in ["almoners_grace", "salt_hourglass_work"]:
		player.resource = mini(player.max_resource(), player.resource + (4 if sid == "almoners_grace" else 3))
	if player.has_trait("penance_vigor"):
		player.resource = mini(player.max_resource(), player.resource + 2)
		player.hp = mini(player.stat("max_hp"), player.hp + 1)
	update_fov()
	var msg := "You work the %s (-%d HP)." % [d["name"], cost] if cost > 0 else "You work the %s." % d["name"]
	log_msg(msg, "good")
	_thread_event("relic", it.template_id)
	_thread_event("work_relic", it.template_id)
	return _finish_player_action(COST_ITEM)


func player_transmute_relic(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) != "relic":
		return false
	var mods: Dictionary = d.get("transmute_mods", {})
	_grant_permanent(mods)
	player.inventory.remove_at(index)
	var freed := unbind_curses(true)
	if freed > 0:
		log_msg("The transmutation snaps the curse on your gear!", "good")
	apotheosis += 2
	way_serpent += 1
	update_fov()
	log_msg("You transmute the %s; its power stays with you." % d["name"], "lore")
	_thread_event("relic", it.template_id)
	_thread_event("transmute_relic", it.template_id)
	return _finish_player_action(COST_ITEM)


func player_unequip(slot: String) -> bool:
	if state != State.PLAYING:
		return false
	var it := player.equipped(slot)
	if it == null:
		return false
	if it.buc == "cursed":
		it.identified = true
		log_msg("The cursed %s refuses to come off!" % item_name(it), "danger")
		return false
	if player.inventory.size() >= Actor.INVENTORY_LIMIT:
		log_msg("Your pack is full.", "danger")
		return false
	player.equipment.erase(slot)
	player.inventory.append(it)
	player.hp = mini(player.hp, player.stat("max_hp"))
	log_msg("You set aside the %s." % item_name(it))
	return _finish_player_action(COST_ITEM)


func _gate_target_id() -> String:
	var m := current_floor()
	var t := m.get_tile(player.pos)
	if t == Tiles.STAIRS_DOWN and depth < db.max_depth():
		return db.spine_floor_id(depth + 1)
	var pt := m.portal_at(player.pos)
	if not pt.is_empty():
		var tid := String(pt.get("target", ""))
		if tid != "" and int(db.floor_def(tid).get("depth", depth)) > depth:
			return tid
	return ""


func gate_target_def() -> Dictionary:
	var tid := _gate_target_id()
	return db.floor_def(tid) if tid != "" else {}


func needs_gate_to_descend() -> bool:
	if state != State.PLAYING:
		return false
	var tid := _gate_target_id()
	return tid != "" and not floors.has(tid)


func player_descend_gate(method: String) -> bool:
	if state != State.PLAYING:
		return false
	var tid := _gate_target_id()
	if tid == "":
		log_msg("There are no stairs here.")
		return false
	if not GATE_METHODS.has(method):
		return false
	var first_visit := not floors.has(tid)
	if first_visit:
		match method:
			"stormed":
				var cost := mini(3, maxi(0, player.hp - 1))
				player.hp -= cost
				apotheosis += 2
				log_msg("You force the Sphere Gate open.", "danger")
			"serpents_key":
				var cost := mini(2, maxi(0, player.hp - 1))
				player.hp -= cost
				way_serpent += 1
				apotheosis += 1
				log_msg("You slip the Serpent's Key into the seam of the gate.", "lore")
			"given_back":
				var cidx := -1
				for i in player.inventory.size():
					if String(player.inventory[i].def(db)["kind"]) == "consumable":
						cidx = i
						break
				if cidx >= 0:
					var cit := player.inventory[cidx]
					cit.quantity -= 1
					if cit.quantity <= 0:
						player.inventory.remove_at(cidx)
				else:
					player.hp -= mini(3, maxi(0, player.hp - 1))
				way_return += 1
				apotheosis = maxi(0, apotheosis - 2)
				log_msg("You lay down leverage at the threshold and pass.", "good")
			"by_name":
				apotheosis = maxi(0, apotheosis - 1)
				log_msg("You speak your own name to the gate; something below hears it.", "lore")
				if player.has_trait("mask_stances") and not player.is_venefica_unlocked():
					player.unlock_venefica(true)
					log_msg("The gate answers your spoken name — Lux Venefica can now unify early (m).", "good")
	if first_visit:
		_contract_event("gate:" + method)
		_contract_event("descend")
	var from_id := floor_id
	var via_portal := not current_floor().portal_at(player.pos).is_empty()
	_enter_floor_by_id(tid, "portal" if via_portal else "above", from_id if via_portal else "")
	if first_visit and method == "by_name":
		var nearest: Actor = null
		var best_d := 1 << 30
		for a in current_floor().actors:
			if not a.is_player and a.is_alive():
				var d_m := Grid.chebyshev(a.pos, player.pos)
				if d_m < best_d:
					best_d = d_m
					nearest = a
		if nearest != null:
			nearest.awake = true
			_remember_player(nearest)
	var fd := current_floor_def()
	var sphere := String(fd.get("sphere", ""))
	var fname := "%s (%s)" % [fd.get("name", "the next floor"), sphere] if sphere != "" else String(fd.get("name", "the next floor"))
	log_msg("You descend to %s." % fname, "lore")
	log_msg(String(fd.get("description", "")), "lore")
	return _finish_player_action(COST_STAIRS)


## Takes the stairs or branch passage under the player, if any.
func player_stairs() -> bool:
	if state != State.PLAYING:
		return false
	var m := current_floor()
	var pt := m.portal_at(player.pos)
	if not pt.is_empty():
		var tid := String(pt.get("target", ""))
		if tid == "" or not db.has("floors", tid):
			return false
		if int(db.floor_def(tid).get("depth", depth)) > depth:
			return player_descend_gate("stormed")
		var first_visit := not floors.has(tid)
		_enter_floor_by_id(tid, "portal", m.floor_id)
		var fd := current_floor_def()
		log_msg("You cross into %s." % fd.get("name", tid), "lore")
		if first_visit:
			log_msg(String(fd.get("description", "")), "lore")
		return _finish_player_action(COST_STAIRS)
	var t := m.get_tile(player.pos)
	if t == Tiles.STAIRS_DOWN:
		return player_descend_gate("stormed")
	if t == Tiles.STAIRS_UP:
		if depth == 1:
			log_msg("Above is the Architect's daylight. You did not come down here to go back.")
			return false
		_enter_floor(depth - 1, false)
		log_msg("You climb back to %s." % current_floor_def().get("name", "the floor above"), "lore")
		return _finish_player_action(COST_STAIRS)
	log_msg("There are no stairs here.")
	return false


static func fracture_mask_for(cause: String) -> String:
	if cause in ["false_light", "chain_indulgence", "exposure", "chain_omnipotence", "perception_fog", "philosophers_loan"]:
		return "lilith"
	if cause in ["entangled", "isolation", "dread", "pinned", "chain_isolation", "chain_threat"]:
		return "eris"
	return "nyx"


func can_unify_venefica() -> String:
	if player == null or not player.has_trait("mask_stances"):
		return "Requires Mask Governance."
	if not player.is_venefica_unlocked():
		return "Wear Nyx, Eris & Lilith (%d/3) or speak your Name at a gate." % player.masks_worn().size()
	if player.mask == Masks.UNION_ID:
		return "Already unified."
	if player.has_status("false_light"):
		return "Cannot unify under the False Light."
	if player.has_status("entangled"):
		return "Cannot unify while Entangled."
	if player.mask_seized_turns() > 0 or player.has_status("dissolution") or player.has_status("isolation") or player.has_status("exposure"):
		return "Resolve Mask seizure first."
	return ""


func fracture_venefica(cause: String, reason: String = "") -> String:
	if player == null or not player.has_trait("mask_stances") or player.mask != Masks.UNION_ID:
		return ""
	var pick := fracture_mask_for(cause)
	player.mask = pick
	player.set_mask_seized_turns(8)
	player.mask_risk = maxi(player.mask_risk, MASK_RISK_MAX / 2)
	player.flags["venefica_fractures"] = int(player.flags.get("venefica_fractures", 0)) + 1
	var sid := Masks.seizure_status(pick)
	if sid != "":
		apply_status(player, sid)
	var why := reason if reason != "" else cause
	log_msg("Lux Venefica fractures (%s)! %s seizes the wheel." % [why, Masks.label(pick)], "danger")
	update_fov()
	return pick


func _maybe_surface_venefica_naming() -> bool:
	if player == null or not player.has_trait("mask_stances"):
		return false
	if not player.all_three_masks_worn() or bool(player.flags.get("venefica_named_seen", false)):
		return false
	player.flags["venefica_named_seen"] = true
	player.unlock_venefica(false)
	log_msg("A whisper carries across the stone — 'Venefica.' All three Masks answer to one name; Lux Venefica stirs within you (m).", "lore")
	return true


func player_switch_mask(mask_id: String) -> bool:
	if state != State.PLAYING or not player.has_trait("mask_stances") or not Masks.is_valid(mask_id):
		return false
	if player.mask == mask_id:
		return false
	if mask_id == Masks.UNION_ID:
		var reason := can_unify_venefica()
		if reason != "":
			log_msg(reason, "info")
			return false
		player.mask = Masks.UNION_ID
		player.set_mask_seized_turns(0)
		log_msg("Nyx, Eris, and Lilith converge: you stand unified as Lux Venefica.", "good")
	else:
		player.mask = mask_id
		if mask_id == "bare_face":
			player.mask_risk = maxi(0, player.mask_risk - 2)
			if player.mask_seized_turns() > 0:
				player.set_mask_seized_turns(maxi(0, player.mask_seized_turns() - 2))
			log_msg("You drop the Mask and wear your Bare Face.", "info")
		else:
			var all_three := player.record_mask_worn(mask_id)
			log_msg("You put on %s." % Masks.label(mask_id), "good")
			if all_three:
				if not player.is_venefica_unlocked():
					player.unlock_venefica(false)
					log_msg("All three Masks have answered: Lux Venefica can now be unified (m).", "good")
				_maybe_surface_venefica_naming()
	update_fov()
	var cost := COST_WAIT / 2 if player.talent_rank("quick_shift") > 0 else COST_WAIT
	return _finish_player_action(cost)


func player_spend_stat(attr: String) -> bool:
	if state != State.PLAYING or player.stat_points <= 0 or not ContentSchema.ATTRIBUTES.has(attr):
		return false
	player.base[attr] = int(player.base.get(attr, 0)) + 1
	player.stat_points -= 1
	if attr == "might":
		player.hp = mini(player.stat("max_hp"), player.hp + 2)
	player.resource = mini(player.max_resource(), player.resource + 2)
	log_msg("Your %s rises to %d." % [attr.capitalize(), player.stat(attr)], "good")
	return true


func can_learn_talent(tid: String) -> String:
	if state != State.PLAYING:
		return "Run has ended."
	if not db.has("talents", tid):
		return "Unknown talent."
	var td := db.get_def("talents", tid)
	if String(td["class_id"]) != player.class_id:
		return "Not your calling."
	if player.talent_points <= 0:
		return "No talent points."
	var rank := player.talent_rank(tid)
	if rank >= int(td["max_rank"]):
		return "Already mastered."
	if int(td["tier"]) >= 3 and player.level < 3:
		return "Requires level 3."
	var prereq := String(td.get("prereq", ""))
	if prereq != "" and player.talent_rank(prereq) <= 0:
		return "Requires %s." % db.get_def("talents", prereq)["name"]
	return ""


func player_learn_talent(tid: String) -> bool:
	var reason := can_learn_talent(tid)
	if reason != "":
		log_msg(reason, "info")
		return false
	player.talents[tid] = player.talent_rank(tid) + 1
	player.talent_points -= 1
	update_fov()
	var td := db.get_def("talents", tid)
	log_msg("Learned %s (rank %d/%d)." % [td["name"], player.talent_rank(tid), int(td["max_rank"])], "good")
	return true


func nearest_visible_hostile(max_range: int = 99) -> Actor:
	var m := current_floor()
	var best: Actor = null
	var best_d := 1 << 30
	for a in m.actors:
		if not a.is_player and a.is_alive() and m.is_visible(a.pos):
			var d := Grid.chebyshev(player.pos, a.pos)
			if d <= max_range and d < best_d:
				best = a
				best_d = d
	return best


func learned_active_talents() -> Array[String]:
	var out: Array[String] = []
	for tid in db.ids("talents"):
		if player.talent_rank(tid) > 0 and String(db.get_def("talents", tid)["kind"]) == "active":
			out.append(tid)
	return out


func player_use_talent(tid: String, target_pos: Vector2i = Vector2i(-1, -1)) -> bool:
	if state != State.PLAYING or not db.has("talents", tid):
		return false
	var td := db.get_def("talents", tid)
	if String(td["kind"]) != "active" or player.talent_rank(tid) <= 0:
		return false
	var cd := player.cooldown(tid)
	if cd > 0:
		log_msg("%s is on cooldown (%d turns)." % [td["name"], cd], "info")
		return false
	var cost := int(td.get("cost", 0))
	if player.resource < cost:
		log_msg("Not enough %s for %s." % [player.resource_label().to_lower(), td["name"]], "danger")
		return false
	var rng_max := int(td.get("range", 0))
	var targeting := String(td.get("targeting", "enemy" if rng_max > 0 else "self"))
	var target: Actor = null
	if targeting == "enemy" and rng_max > 0:
		var tpos := _resolve_target_pos(target_pos, rng_max, false)
		if tpos.x >= 0 and Grid.chebyshev(player.pos, tpos) <= rng_max and current_floor().is_visible(tpos):
			var a := current_floor().actor_at(tpos)
			if a != null and not a.is_player and a.is_alive():
				target = a
		if target == null:
			log_msg("No target in range for %s." % td["name"], "info")
			return false
	var action_cost := _run_talent_effect(String(td.get("effect", tid)), td, target, target_pos)
	if action_cost < 0:
		return false
	player.resource -= cost
	var max_cd := int(td.get("cooldown", 0))
	if max_cd > 0:
		player.cooldowns[tid] = max_cd
	var eff_name := String(td.get("effect", tid))
	if player.has_trait("chain_binder") and eff_name in ["hex_sigil", "chain_shackle", "unmake_record", "crippling_shot", "warden_challenge", "alchemical_bomb", "frost_tincture", "pinning_volley", "sunder_strike"]:
		subjugation = maxi(0, subjugation - 1)
	return _finish_player_action(action_cost)


func _run_talent_effect(eff: String, td: Dictionary, target: Actor, target_pos: Vector2i = Vector2i(-1, -1)) -> int:
	var m := current_floor()
	var will_v := maxi(0, player.stat("will"))
	var might_v := maxi(0, player.stat("might"))
	var cambion_bonus := 2 if (player.has_trait("infernal_blood") and apotheosis >= 2) else (1 if (player.has_trait("infernal_blood") and apotheosis > 0) else 0)
	var dtype := String(td.get("damage_type", "physical"))
	match eff:
		"sunder_strike":
			var r := Combat.resolve(player, target, rng)
			target.awake = true
			_remember_player(target)
			if r["hit"]:
				var dmg := int(r["damage"]) + 2
				log_msg("You sunder the %s for %d!" % [target.name, dmg], "combat")
				apply_damage(target, dmg, player.name, String(r["type"]))
				if target.is_alive():
					apply_status(target, "sundered")
			else:
				log_msg("Your sunder misses the %s." % target.name, "combat")
			return COST_ATTACK
		"iron_cleave":
			var foes: Array[Actor] = []
			for d in Grid.DIRS_8:
				var a := m.actor_at(player.pos + d)
				if a != null and not a.is_player and a.is_alive() and m.can_step(player.pos, a.pos):
					foes.append(a)
			if foes.is_empty():
				log_msg("No adjacent foes to cleave.", "info")
				return -1
			for a in foes:
				_attack(player, a)
			return COST_ATTACK
		"vanguard_charge":
			if player.has_status("pinned"):
				log_msg("You cannot charge while shackled in place.", "danger")
				return -1
			if not Grid.is_adjacent(player.pos, target.pos):
				var spot := _adjacent_free(m, target.pos)
				if spot == target.pos or not m.is_walkable(spot) or m.actor_at(spot) != null:
					log_msg("No path to charge the %s." % target.name, "info")
					return -1
				player.pos = spot
			var r := Combat.resolve(player, target, rng)
			target.awake = true
			_remember_player(target)
			if r["hit"]:
				var dmg := int(r["damage"]) + 2
				log_msg("You charge into the %s for %d!" % [target.name, dmg], "combat")
				apply_damage(target, dmg, player.name, String(r["type"]))
				if target.is_alive():
					var pdir := Grid.sign_vec(target.pos - player.pos)
					var push_to := target.pos + pdir
					if m.can_step(target.pos, push_to) and m.actor_at(push_to) == null:
						target.pos = push_to
						_on_actor_enter_tile(target, push_to)
					elif not m.is_walkable(push_to):
						var slam := Combat.mitigate(3, target, "physical")
						log_msg("You slam the %s into the stone (+%d)!" % [target.name, int(slam["damage"])], "combat")
						apply_damage(target, int(slam["damage"]), player.name, "physical")
						if target.is_alive():
							apply_status(target, "sundered")
			else:
				log_msg("Your charge misses the %s." % target.name, "combat")
			update_fov()
			return COST_ATTACK
		"shield_brace":
			apply_status(player, "braced")
			log_msg("You brace behind your guard.", "good")
			return COST_WAIT
		"unyielding_march":
			var heal := 6 + might_v
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			apply_status(player, "braced")
			log_msg("You march unbroken, mending %d health." % heal, "good")
			return COST_WAIT
		"break_the_chain":
			for sid in ["isolation", "perception_fog", "bleeding", "pinned"]:
				_remove_status(player, sid)
			unbind_curses(true)
			subjugation = 0
			_remove_status(player, "entangled")
			apply_status(player, "apostate_focus")
			update_fov()
			log_msg("You shatter the chains upon you.", "good")
			return COST_WAIT
		"defiant_decree":
			var base_d := 4 + might_v / 2 + cambion_bonus
			var hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= 3:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(base_d, a, dtype)
					apply_damage(a, int(mit["damage"]), player.name, dtype)
					if a.is_alive():
						apply_status(a, "sundered")
					hits += 1
			if hits == 0:
				return -1
			log_msg("Your decree strikes %d foe%s (%s)!" % [hits, "" if hits == 1 else "s", dtype], "combat")
			return COST_ATTACK
		"veil_step":
			var max_r := int(td.get("range", 4))
			var dest := target_pos if target_pos.x >= 0 else _best_blink_tile(m, max_r)
			if dest.x < 0 or dest == player.pos or Grid.chebyshev(player.pos, dest) > max_r or not m.is_visible(dest) or not m.is_walkable(dest) or m.actor_at(dest) != null:
				log_msg("No valid open tile in Veil Step range.", "info")
				return -1
			player.pos = dest
			_remove_status(player, "pinned")
			if player.has_trait("mask_stances"):
				player.mask_risk = maxi(0, player.mask_risk - 1)
				if player.mask == "nyx" or player.mask == Masks.UNION_ID:
					apply_status(player, "veiled")
			update_fov()
			log_msg("You slip through the veil.", "good")
			return COST_WAIT
		"sovereign_vent":
			var risk := player.mask_risk
			var vent_type := "fire" if player.mask == "eris" else ("radiant" if player.mask == "lilith" else "void")
			var base_v := 4 + risk / 2 + will_v + cambion_bonus
			var hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= 3:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(base_v, a, vent_type)
					apply_damage(a, int(mit["damage"]), player.name, vent_type)
					hits += 1
			if hits == 0:
				return -1
			player.mask_risk = 0
			log_msg("You vent %d Mask risk across %d foe%s (%s)!" % [risk, hits, "" if hits == 1 else "s", vent_type], "combat")
			return COST_ATTACK
		"gaze_of_lilith":
			_remove_status(player, "perception_fog")
			update_fov()
			var base_d := 5 if (player.has_trait("mask_stances") and (player.mask == "lilith" or player.mask == Masks.UNION_ID)) else 3
			var mit := Combat.mitigate(base_d + will_v + cambion_bonus, target, dtype)
			var dmg := int(mit["damage"])
			target.awake = true
			_remember_player(target)
			log_msg("The Eye unblinks at the %s for %d (%s)!" % [target.name, dmg, dtype], "combat")
			apply_damage(target, dmg, player.name, dtype)
			return COST_ATTACK
		"unmake_record":
			var mit := Combat.mitigate(5 + will_v + cambion_bonus, target, dtype)
			var dmg := int(mit["damage"])
			target.awake = true
			_remember_player(target)
			log_msg("You unmake the %s's record for %d (%s)!" % [target.name, dmg, dtype], "combat")
			apply_damage(target, dmg, player.name, dtype)
			if target.is_alive():
				apply_status(target, "sundered")
			return COST_ATTACK
		"siphon_surge":
			var mit := Combat.mitigate(3 + will_v + cambion_bonus, target, dtype)
			var dmg := int(mit["damage"])
			target.awake = true
			_remember_player(target)
			apply_damage(target, dmg, player.name, dtype)
			var heal := maxi(1, dmg / 2)
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			log_msg("You drain %d from the %s, mending %d." % [dmg, target.name, heal], "good")
			return COST_ATTACK
		"transmute_pain":
			for sid in ["reckoning", "isolation", "dissolution", "exposure", "hexed"]:
				_remove_status(player, sid)
			unbind_curses(true)
			subjugation = maxi(0, subjugation - 3)
			var heal := 6 + will_v
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			log_msg("You transmute pain into %d health." % heal, "good")
			return COST_WAIT
		"fade_to_ash":
			apply_status(player, "veiled")
			for a in m.actors:
				if not a.is_player and a.is_alive() and Grid.chebyshev(a.pos, player.pos) > 1:
					_forget_player(a)
			log_msg("You slip into ash and vanish from distant eyes.", "good")
			return COST_WAIT
		"shadow_step":
			var spot := _adjacent_free(m, target.pos)
			if spot == target.pos and not Grid.is_adjacent(player.pos, target.pos):
				log_msg("No space beside the %s." % target.name, "info")
				return -1
			var old_pos := player.pos
			if not Grid.is_adjacent(player.pos, target.pos):
				player.pos = spot
			_remove_status(player, "pinned")
			var was_awake := target.awake
			if Grid.chebyshev(old_pos, target.pos) > 1:
				target.awake = false
			_attack(player, target)
			if target.is_alive() and was_awake:
				target.awake = true
			update_fov()
			return COST_ATTACK
		"crippling_shot":
			var max_r := int(td.get("range", 6))
			var tr := projectile_trace(player.pos, target.pos, max_r)
			var hit_foe: Actor = tr["hit_actor"]
			if tr["blocked"] and hit_foe == null:
				log_msg("Your line of fire is blocked.", "info")
				return -1
			var foe := hit_foe if hit_foe != null else target
			var w := player.equipped("ranged")
			var wd := w.def(db) if w != null else {}
			var dice := String(wd.get("damage", "1d6"))
			var acc := int(wd.get("accuracy", 2)) + 2
			var crit_b := int(wd.get("crit", 5))
			var s_dtype := String(wd.get("damage_type", "physical"))
			var was_awake := foe.awake
			var res := Combat.resolve_ranged(player, foe, Grid.chebyshev(player.pos, foe.pos), dice, acc, crit_b, s_dtype, rng)
			foe.awake = true
			_remember_player(foe)
			if not res["hit"]:
				log_msg("Your crippling shot misses the %s." % foe.name, "combat")
				return COST_ATTACK
			var dmg := int(res["damage"]) + 2
			log_msg("Crippling Shot strikes the %s for %d%s!" % [foe.name, dmg, _combat_note(res)], "combat")
			apply_damage(foe, dmg, player.name, s_dtype)
			if foe.is_alive():
				apply_status(foe, "chilled" if was_awake else "pinned")
				if not wd.is_empty() and wd.has("status") and foe.is_alive():
					apply_status(foe, String(wd["status"]))
			return COST_ATTACK
		"arterial_cut":
			_attack(player, target)
			if target.is_alive():
				apply_status(target, "bleeding")
				log_msg("The %s bleeds freely." % target.name, "combat")
			return COST_ATTACK
		"coup_de_grace":
			var dice := player.damage_dice()
			var raw := Dice.roll(dice, rng) + Dice.roll(dice, rng) + player.stat("damage_bonus")
			if target.has_status("bleeding") or target.has_status("sundered"):
				raw += 4
			var pierce := 1 if player.has_trait("infernal_blood") else 0
			var c_dtype := player.melee_damage_type()
			var mit := Combat.mitigate(raw, target, c_dtype, pierce)
			var dmg := int(mit["damage"])
			target.awake = true
			_remember_player(target)
			log_msg("Coup de Grace! You strike the %s for %d!" % [target.name, dmg], "combat")
			apply_damage(target, dmg, player.name, c_dtype)
			return COST_ATTACK
		"backstep":
			var foe := nearest_visible_hostile(1)
			if foe == null:
				apply_status(player, "veiled")
				log_msg("You tumble backward into shadow.", "good")
				return COST_WAIT
			var step_dir := Grid.sign_vec(player.pos - foe.pos)
			var moved := false
			for _s in 2:
				var next := player.pos + step_dir
				if m.can_step(player.pos, next) and m.actor_at(next) == null:
					player.pos = next
					moved = true
				else:
					break
			if not moved:
				var best := player.pos
				var best_d := 1
				for d in Grid.DIRS_8:
					var q := player.pos + d
					if m.can_step(player.pos, q) and m.actor_at(q) == null:
						var dist_f := Grid.chebyshev(q, foe.pos)
						if dist_f > best_d:
							best_d = dist_f
							best = q
				player.pos = best
			apply_status(player, "veiled")
			update_fov()
			log_msg("You vault back out of reach.", "good")
			return COST_WAIT
		"flurry":
			_attack(player, target)
			if target.is_alive():
				_attack(player, target)
			return COST_ATTACK
		"warden_bash":
			var r := Combat.resolve(player, target, rng)
			target.awake = true
			_remember_player(target)
			if r["hit"]:
				var dmg := int(r["damage"]) + 2
				log_msg("Bastion Bash strikes the %s for %d!" % [target.name, dmg], "combat")
				apply_damage(target, dmg, player.name, String(r["type"]))
				if target.is_alive():
					apply_status(target, "sundered")
					var push_to := target.pos + Grid.sign_vec(target.pos - player.pos)
					if m.can_step(target.pos, push_to) and m.actor_at(push_to) == null:
						target.pos = push_to
						_on_actor_enter_tile(target, push_to)
			else:
				log_msg("Your bash misses the %s." % target.name, "combat")
			return COST_ATTACK
		"threshold_hold":
			_remove_status(player, "pinned")
			_remove_status(player, "bleeding")
			apply_status(player, "braced")
			log_msg("You anchor the threshold and shake free of shackles.", "good")
			return COST_WAIT
		"bulwark_slam":
			var dice := player.damage_dice()
			var raw := Dice.roll(dice, rng) + 4 + player.stat("defense") + player.stat("damage_bonus")
			var b_dtype := player.melee_damage_type()
			var mit := Combat.mitigate(raw, target, b_dtype, 1 if player.has_trait("infernal_blood") else 0)
			target.awake = true
			_remember_player(target)
			log_msg("Threshold Slam crushes the %s for %d!" % [target.name, int(mit["damage"])], "combat")
			apply_damage(target, int(mit["damage"]), player.name, b_dtype)
			if target.is_alive():
				apply_status(target, "sundered")
			return COST_ATTACK
		"warden_challenge":
			var pull_to := target.pos + Grid.sign_vec(player.pos - target.pos)
			if m.can_step(target.pos, pull_to) and m.actor_at(pull_to) == null and pull_to != player.pos:
				target.pos = pull_to
				_on_actor_enter_tile(target, pull_to)
			target.awake = true
			_remember_player(target)
			if target.is_alive():
				apply_status(target, "sundered")
			log_msg("You haul the %s forward and break their guard!" % target.name, "combat")
			return COST_ATTACK
		"piercing_bolt", "barbed_quarrel", "beacon_shot", "execution_bolt":
			var max_r := int(td.get("range", 6)) + (1 if player.has_trait("steady_aim") else 0)
			var tr := projectile_trace(player.pos, target.pos, max_r)
			var foe: Actor = tr["hit_actor"] if tr["hit_actor"] != null else target
			if tr["blocked"] and tr["hit_actor"] == null:
				log_msg("Your line of fire is blocked.", "info")
				return -1
			var w := player.equipped("ranged")
			var wd := w.def(db) if w != null else {}
			var dice := String(wd.get("damage", "1d6"))
			var acc := int(wd.get("accuracy", 1)) + 2
			var crit_b := int(wd.get("crit", 5)) + (100 if eff == "execution_bolt" else 0)
			var s_dtype := dtype if eff == "beacon_shot" else String(wd.get("damage_type", "physical"))
			var res := Combat.resolve_ranged(player, foe, Grid.chebyshev(player.pos, foe.pos), dice, acc, crit_b, s_dtype, rng)
			foe.awake = true
			_remember_player(foe)
			if not res["hit"]:
				log_msg("%s misses the %s." % [td["name"], foe.name], "combat")
				return COST_ATTACK
			var dmg := int(res["damage"])
			if eff == "piercing_bolt":
				dmg = maxi(dmg, Dice.roll(dice, rng) + maxi(0, player.stat("agility") / 2))
			elif eff == "barbed_quarrel":
				dmg += 2
			elif eff == "execution_bolt" and (foe.has_status("bleeding") or foe.has_status("sundered") or foe.has_status("chilled")):
				dmg += 4
			log_msg("%s strikes the %s for %d%s!" % [td["name"], foe.name, dmg, _combat_note(res)], "combat")
			apply_damage(foe, dmg, player.name, s_dtype)
			if foe.is_alive():
				var st_map := {"piercing_bolt": "sundered", "barbed_quarrel": "bleeding", "beacon_shot": "exposure"}
				if st_map.has(eff):
					apply_status(foe, String(st_map[eff]))
			return COST_ATTACK
		"twin_quarrel":
			var w := player.equipped("ranged")
			var wd := w.def(db) if w != null else {}
			var dice := String(wd.get("damage", "1d6"))
			var s_dtype := String(wd.get("damage_type", "physical"))
			for _shot in 2:
				if not target.is_alive():
					break
				var res := Combat.resolve_ranged(player, target, Grid.chebyshev(player.pos, target.pos), dice, int(wd.get("accuracy", 1)), int(wd.get("crit", 0)), s_dtype, rng)
				target.awake = true
				_remember_player(target)
				if res["hit"]:
					var dmg := int(res["damage"])
					log_msg("Twin Quarrel hits the %s for %d." % [target.name, dmg], "combat")
					apply_damage(target, dmg, player.name, s_dtype)
				else:
					log_msg("Twin Quarrel misses the %s." % target.name, "combat")
			return COST_ATTACK
		"pinning_volley":
			var hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= int(td.get("range", 5)):
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(Dice.roll("1d6", rng) + maxi(0, player.stat("agility") / 2), a, "physical")
					apply_damage(a, int(mit["damage"]), player.name, "physical")
					if a.is_alive():
						apply_status(a, "chilled")
					hits += 1
			if hits == 0:
				return -1
			log_msg("Suppression Volley strikes %d foe%s!" % [hits, "" if hits == 1 else "s"], "combat")
			return COST_ATTACK
		"hex_sigil", "radiant_rebuke", "chain_shackle":
			var base_d := (5 if eff == "radiant_rebuke" else (4 if eff == "hex_sigil" else 3)) + will_v + cambion_bonus
			var mit := Combat.mitigate(base_d, target, dtype)
			var dmg := int(mit["damage"])
			target.awake = true
			_remember_player(target)
			log_msg("%s strikes the %s for %d (%s)!" % [td["name"], target.name, dmg, dtype], "combat")
			apply_damage(target, dmg, player.name, dtype)
			if target.is_alive():
				var st_id := "exposure" if eff == "radiant_rebuke" else ("hexed" if eff == "hex_sigil" else "pinned")
				apply_status(target, st_id)
			return COST_ATTACK
		"summon_ward_sigil":
			var existing := m.feature_at(player.pos)
			if not existing.is_empty():
				log_msg("Something already occupies this tile.", "info")
				return -1
			m.features.append({"kind": "ward_sigil", "sub": "ophite", "x": player.pos.x, "y": player.pos.y, "revealed": true, "used": false, "turns": 8})
			log_msg("You inscribe a humming Ophite Ward-Sigil underfoot.", "good")
			return COST_WAIT
		"place_snare":
			var existing := m.feature_at(player.pos)
			if not existing.is_empty():
				log_msg("Something already occupies this tile.", "info")
				return -1
			m.features.append({"kind": "trap", "sub": "snare", "x": player.pos.x, "y": player.pos.y, "revealed": true, "used": false})
			log_msg("You set an unrecorded Ophite snare underfoot.", "good")
			return COST_WAIT
		"unmaking_chorus", "thermal_catalysis":
			var base_a := (5 if eff == "thermal_catalysis" else 4) + will_v + cambion_bonus
			var hits := 0
			for a in visible_hostiles():
				if Grid.chebyshev(player.pos, a.pos) <= int(td.get("range", 3)):
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(base_a, a, dtype)
					apply_damage(a, int(mit["damage"]), player.name, dtype)
					if a.is_alive():
						apply_status(a, "sundered")
					hits += 1
			if hits == 0:
				return -1
			log_msg("%s erupts across %d foe%s!" % [td["name"], hits, "" if hits == 1 else "s"], "combat")
			return COST_ATTACK
		"sanctify_ground":
			if m.get_tile(player.pos) == Tiles.FLOOR:
				m.set_tile(player.pos, Tiles.SANCTUARY_FLOOR)
			var heal := 4 + will_v / 2
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			log_msg("You consecrate the flagstones and mend %d health." % heal, "good")
			return COST_WAIT
		"alchemical_bomb", "frost_tincture":
			var blast_dtype := "fire" if eff == "alchemical_bomb" else "cold"
			var blast_st := "burning" if eff == "alchemical_bomb" else "chilled"
			var hits := 0
			for a in m.actors:
				if not a.is_player and a.is_alive() and Grid.chebyshev(target.pos, a.pos) <= 1:
					a.awake = true
					_remember_player(a)
					var mit := Combat.mitigate(4 + will_v + cambion_bonus, a, blast_dtype)
					apply_damage(a, int(mit["damage"]), player.name, blast_dtype)
					if a.is_alive():
						apply_status(a, blast_st)
					hits += 1
			log_msg("%s bursts across %d foe%s (%s)!" % [td["name"], hits, "" if hits == 1 else "s", blast_dtype], "combat")
			return COST_ATTACK
		"volatile_salve":
			for sid in ["bleeding", "burning", "chilled"]:
				_remove_status(player, sid)
			var heal := 6 + will_v
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			log_msg("Compound Salve mends %d health and steadies your humors." % heal, "good")
			return COST_WAIT
		"philosophers_loan":
			apply_status(player, "false_light")
			log_msg("Measured Gold brightens your hand without waking the Architect's eye.", "good")
			return COST_WAIT
	return -1


func _finish_player_action(cost: int) -> bool:
	turns += 1
	player.next_time = time + player.scaled_cost(cost)
	_run_until_player()
	return true


# ---------------------------------------------------------------- turn loop

func _run_until_player() -> void:
	var guard := 0
	while state == State.PLAYING:
		guard += 1
		if guard > 100000:
			push_error("World: scheduler made no progress")
			return
		var actor := _next_actor()
		time = actor.next_time
		if actor == player:
			_begin_player_turn()
			return
		_tick_statuses(actor)
		if not actor.is_alive():
			continue
		var cost := _monster_turn(actor)
		actor.next_time = time + actor.scaled_cost(cost)


func _next_actor() -> Actor:
	var best: Actor = null
	for a in current_floor().actors:
		if not a.is_alive():
			continue
		if best == null or a.next_time < best.next_time or (a.next_time == best.next_time and a.id < best.id):
			best = a
	return best


func _begin_player_turn() -> void:
	_tick_cooldowns()
	_tick_statuses(player)
	_tick_mask()
	_natural_regen()
	_passive_detect()
	_tick_subjugation()
	_tick_wards()
	_update_allegiance()
	_tick_threads()
	update_fov()


func _tick_wards() -> void:
	if turns <= 0 or state != State.PLAYING:
		return
	var m := current_floor()
	var will_v := maxi(0, player.stat("will"))
	for f in m.features:
		if String(f.get("kind", "")) != "ward_sigil" or bool(f.get("used", false)):
			continue
		var wp := Vector2i(int(f["x"]), int(f["y"]))
		var struck := false
		for a in m.actors:
			if not a.is_player and a.is_alive() and Grid.chebyshev(wp, a.pos) <= 1:
				var raw := Dice.roll("1d5", rng) + will_v / 2
				var mit := Combat.mitigate(raw, a, "void")
				log_msg("The Ophite Ward-Sigil strikes the %s for %d (void)!" % [a.name, int(mit["damage"])], "combat")
				apply_damage(a, int(mit["damage"]), "Ophite Ward-Sigil", "void")
				struck = true
				break
		var rem := int(f.get("turns", 1)) - 1
		f["turns"] = rem
		if rem <= 0:
			f["used"] = true
			if not struck:
				log_msg("An Ophite Ward-Sigil fades into chalk.", "info")


func _has_keen_sight() -> bool:
	if player.has_trait("liminal_sight"):
		return true
	var amu := player.equipped("amulet")
	if amu != null and amu.template_id == "eye_of_lilith":
		return true
	if player.has_status("confessors_clarity") or player.has_status("lamp_vigil"):
		return true
	return player.has_trait("mask_stances") and (player.mask == "lilith" or player.mask == Masks.UNION_ID)


func _passive_detect() -> void:
	var m := current_floor()
	var auto := _has_keen_sight()
	var pct := 100 if auto else clampi(20 + player.stat("sight") * 5, 15, 85)
	for f in m.features:
		if bool(f.get("revealed", false)):
			continue
		var fp := Vector2i(int(f["x"]), int(f["y"]))
		if Grid.chebyshev(player.pos, fp) <= 2 and rng.chance_pct(pct):
			f["revealed"] = true
			log_msg("You spot a %s!" % Ecology.label(f), "info")


func chain_limit() -> int:
	return SUBJUGATION_LIMIT + (2 if way_return - way_serpent >= 2 else 0) + (1 if player.has_trait("ledger_forged") else 0) + ItemSets.subjugation_cap_bonus(player, db)


## A chain lands on the player: apply its status, then advance the Subjugation clock.
## Masks, Relics, False Light, Apotheosis and the Two Ways all bend the clock.
func _chain_hit(sid: String) -> void:
	if sid == "perception_fog" and player.has_trait("liminal_sight"):
		log_msg("Your veil-touched sight ignores the narrowing fog.", "good")
		return
	if sid == "perception_fog" and player.has_trait("mask_stances") and (player.mask == "lilith" or player.mask == Masks.UNION_ID):
		log_msg("Lilith's Eye sees through the narrowing litany.", "good")
		return
	if player.has_status("halo_aegis"):
		log_msg("The Broken Halo turns the chain aside.", "good")
		return
	if sid == "false_light" and (player.has_status("false_light") or player.has_status("reckoning")):
		return
	apply_status(player, sid)
	if player.has_trait("penance_vigor"):
		player.resource = mini(player.max_resource(), player.resource + 2)
		player.hp = mini(player.stat("max_hp"), player.hp + 1)
	if player.has_trait("mask_stances") and player.mask == Masks.UNION_ID and sid in ["isolation", "dread", "exposure", "debility", "degradation", "demanded", "pinned", "perception_fog"]:
		fracture_venefica(sid, "bondage: " + sid)
	if player.has_status("entangled"):
		return
	var gain := 1
	if apotheosis >= 4 and apotheosis < APOTHEOSIS_THRESHOLD:
		gain += 1
	if player.has_status("false_light"):
		gain -= 1
	if player.has_status("reckoning"):
		gain += 1
	if player.has_trait("mask_stances") and (player.mask == "nyx" or player.mask == Masks.UNION_ID):
		gain -= 1
	if current_floor().get_tile(player.pos) == Tiles.SANCTUARY_FLOOR:
		gain -= 1
	if gain <= 0:
		return
	subjugation += gain
	if subjugation >= chain_limit():
		_entangle()


func _entangle() -> void:
	subjugation = chain_limit() / 2
	if player.has_status("crown_decree"):
		log_msg("The Severed Crown refuses the chain's last link.", "good")
		return
	apply_status(player, "entangled")
	log_msg("The chains close: you are Entangled.", "danger")
	if player.has_trait("mask_stances") and player.mask == Masks.UNION_ID:
		fracture_venefica("entangled", "Entanglement")


func _tick_subjugation() -> void:
	if turns <= 0 or subjugation <= 0 or turns % 10 != 0:
		return
	if player.has_trait("mask_stances") and player.mask == "eris":
		return
	subjugation -= 1


## Keeps allegiance, apotheosis and contract statuses in step with the run.
func _update_allegiance() -> void:
	var lean := way_return - way_serpent
	var want := "return_oriented" if lean >= 2 else ("serpents_seam" if lean <= -2 else "")
	for sid in ["return_oriented", "serpents_seam"]:
		if sid != want:
			_remove_status(player, sid)
	if want != "":
		apply_status(player, want)
	if apotheosis >= 4 and apotheosis < APOTHEOSIS_THRESHOLD:
		apply_status(player, "sovereign_mark")
	else:
		_remove_status(player, "sovereign_mark")
	if contract != "" and db.has("contracts", contract):
		apply_status(player, String(db.get_def("contracts", contract)["boon_status"]))


func _grant_permanent(mods: Dictionary) -> void:
	for k in mods:
		var key := "bonus_damage" if String(k) == "damage" else String(k)
		player.base[key] = int(player.base.get(key, 0)) + int(mods[k])
	if int(mods.get("max_hp", 0)) > 0:
		player.hp = mini(player.stat("max_hp"), player.hp + int(mods["max_hp"]))


func player_sign_contract(cid: String) -> bool:
	if state != State.PLAYING or not db.has("contracts", cid):
		return false
	if contract != "":
		log_msg("You are already bound by a contract.", "info")
		return false
	if contract_log.has(cid):
		log_msg("That rite has already been decided.", "info")
		return false
	var cd := db.get_def("contracts", cid)
	contract = cid
	contract_progress = 0
	apotheosis = maxi(0, apotheosis + int(cd.get("apotheosis", 0)))
	log_msg("You sign %s. Oath: %s" % [cd["name"], cd["oath_text"]], "lore")
	if player.has_trait("mask_stances") and player.mask == Masks.UNION_ID:
		fracture_venefica("contract", "binding contract")
	_thread_event("contract", cid)
	return true


func _contract_event(ev: String) -> void:
	if contract == "" or not db.has("contracts", contract):
		return
	var breach := false
	match String(db.get_def("contracts", contract)["oath"]):
		"no_healing_items":
			breach = ev == "heal_item"
		"light_pack":
			breach = ev == "descend" and player.inventory.size() > 6
		"no_return_rites":
			breach = ev == "gate:given_back" or ev == "cleanse"
		"no_by_name":
			breach = ev == "gate:by_name" or ev == "gate:given_back"
	if breach:
		_breach_contract("You break your oath.")
	elif ev == "descend":
		_advance_contract()


func _advance_contract() -> void:
	if contract == "" or not db.has("contracts", contract):
		return
	var signed_cid := contract
	contract_progress += 1
	var cd := db.get_def("contracts", contract)
	if contract_progress >= int(cd["floors"]):
		_grant_permanent(cd["reward_mods"])
		if String(cd["way"]) == "serpent":
			way_serpent += 1
		else:
			way_return += 1
		contract_log[contract] = "fulfilled"
		_remove_status(player, String(cd["boon_status"]))
		log_msg("%s is fulfilled; its reward stays with you." % cd["name"], "lore")
		contract = ""
		contract_progress = 0
	else:
		log_msg("%s: the oath holds (%d/%d)." % [cd["name"], contract_progress, int(cd["floors"])], "info")
	_thread_event("attest_contract", signed_cid)


func _breach_contract(reason: String) -> void:
	if contract == "" or not db.has("contracts", contract):
		return
	var cd := db.get_def("contracts", contract)
	_remove_status(player, String(cd["boon_status"]))
	apply_status(player, "forsworn")
	apotheosis += 1
	contract_log[contract] = "broken"
	log_msg("%s %s is void; you are Forsworn." % [reason, cd["name"]], "danger")
	contract = ""
	contract_progress = 0


func player_search() -> bool:
	if state != State.PLAYING:
		return false
	var m := current_floor()
	var found := 0
	var disarmed := 0
	for f in m.features:
		var fp := Vector2i(int(f["x"]), int(f["y"]))
		var dist := Grid.chebyshev(player.pos, fp)
		if dist <= 3 and not bool(f.get("revealed", false)):
			f["revealed"] = true
			found += 1
			log_msg("You uncover a %s!" % Ecology.label(f), "good")
		if f.get("kind", "") == "trap" and bool(f.get("revealed", false)) and not bool(f.get("used", false)) and dist <= 1:
			f["used"] = true
			disarmed += 1
			log_msg("You disarm the %s (+5 XP)." % Ecology.label(f), "good")
			gain_xp(5)
	if found == 0 and disarmed == 0:
		log_msg("You search the stonework and find nothing new.", "info")
	return _finish_player_action(COST_WAIT)


func _open_secret_door(pos: Vector2i) -> void:
	var m := current_floor()
	var f := m.feature_at(pos)
	if f.is_empty():
		return
	f["revealed"] = true
	f["used"] = true
	m.set_tile(pos, Tiles.FLOOR)
	update_fov()
	var table: Array = current_floor_def().get("item_table", [])
	if not table.is_empty():
		var loot := _new_item(rng.pick_weighted(table))
		Affixes.roll_equipment(loot, db, depth, rng, true)
		loot.pos = pos
		m.items.append(loot)
		log_msg("The secret stonework slides aside, revealing a %s!" % item_name(loot), "good")
	else:
		log_msg("The secret stonework slides aside.", "good")


func _on_actor_enter_tile(actor: Actor, pos: Vector2i) -> void:
	if not actor.is_alive():
		return
	var m := current_floor()
	var t := m.get_tile(pos)
	if t == Tiles.WATER_SHALLOW and actor.has_status("burning"):
		_remove_status(actor, "burning")
		if actor.is_player:
			log_msg("The shallow water douses the flames.", "good")
		elif m.is_visible(pos):
			log_msg("The shallow water douses the %s's flames." % actor.name, "info")
	elif t == Tiles.IRON_GRATE and actor.is_player:
		var alerted := 0
		for a in m.actors:
			if not a.is_player and a.is_alive() and not a.awake and Grid.chebyshev(pos, a.pos) <= 5:
				a.awake = true
				_remember_player(a)
				alerted += 1
		if alerted > 0:
			log_msg("The iron grate clangs underfoot, alerting nearby foes!", "danger")
	if Tiles.is_hazard(t):
		if t == Tiles.ASH_EMBER and actor.is_player and actor.has_trait("cinder_born"):
			pass
		else:
			var h: Dictionary = Ecology.HAZARDS[t]
			var htype := String(h["damage_type"])
			var mit := Combat.mitigate(2, actor, htype)
			var dmg := int(mit["damage"])
			if actor.is_player:
				log_msg("The %s sears you for %d (%s)." % [h["name"], dmg, htype], "danger")
			elif m.is_visible(pos):
				log_msg("The %s sears the %s for %d (%s)." % [h["name"], actor.name, dmg, htype], "combat")
			apply_damage(actor, dmg, String(h["name"]), htype)
			if actor.is_alive() and rng.chance_pct(45):
				apply_status(actor, String(h["status"]))
	if not actor.is_alive():
		return
	var f := m.feature_at(pos)
	if f.get("kind", "") == "trap" and not bool(f.get("used", false)) and not (actor.is_player and String(f.get("sub", "")) == "snare"):
		var tdef: Dictionary = Ecology.TRAPS.get(String(f.get("sub", "spike")), Ecology.TRAPS["spike"])
		f["revealed"] = true
		f["used"] = true
		var ttype := String(tdef["damage_type"])
		var mit := Combat.mitigate(Dice.roll(String(tdef["damage"]), rng), actor, ttype)
		var dmg := int(mit["damage"])
		if actor.is_player:
			log_msg("You trigger a %s for %d (%s)!" % [tdef["name"], dmg, ttype], "danger")
		elif m.is_visible(pos):
			log_msg("The %s springs a %s for %d!" % [actor.name, tdef["name"], dmg], "combat")
		apply_damage(actor, dmg, String(tdef["name"]), ttype)
		if actor.is_alive():
			apply_status(actor, String(tdef["status"]))


func player_interact(pos: Vector2i, choice: String = "") -> bool:
	if state != State.PLAYING or Grid.chebyshev(player.pos, pos) > 1:
		return false
	var m := current_floor()
	var f := m.feature_at(pos)
	if f.is_empty() or not bool(f.get("revealed", false)) or not Ecology.is_interactive(f):
		return false
	var kind := String(f["kind"])
	match kind:
		"secret_door":
			_open_secret_door(pos)
			return _finish_player_action(COST_ITEM)
		"altar":
			if choice == "tithe":
				if player.hp <= 4:
					log_msg("You lack the blood for the altar's tithe.", "danger")
					return false
				player.hp -= 4
				apotheosis = maxi(0, apotheosis - 1)
				player.base["max_hp"] = int(player.base.get("max_hp", 10)) + 2
				player.hp = mini(player.stat("max_hp"), player.hp + 2)
				player.resource = player.max_resource()
				f["used"] = true
				log_msg("You tithe blood outside the ledger (+2 max HP, full resource, -apotheosis).", "good")
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
			else:
				if player.hp <= 3:
					log_msg("You lack the blood to cleanse here.", "danger")
					return false
				player.hp -= 3
				apotheosis = maxi(0, apotheosis - 1)
				way_return += 1
				var n := unbind_curses(false)
				subjugation = maxi(0, subjugation - 3)
				f["used"] = true
				log_msg("The altar snaps iron bonds free (%d cleansed, +Way of Return)." % n, "good")
				_contract_event("cleanse")
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
		"shrine":
			if choice == "steal":
				player.base["will"] = int(player.base.get("will", 0)) + 1
				apotheosis += 2
				way_serpent += 1
				f["used"] = true
				log_msg("You claim the Eye's sight as your own (+1 Will, +apotheosis).", "lore")
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
			else:
				var nid := identify_pack()
				for ff in m.features:
					ff["revealed"] = true
				apply_status(player, "confessors_clarity")
				f["used"] = true
				update_fov()
				log_msg("The Shrine witnesses the floor (%d identified, all traps & secrets revealed)." % nid, "good")
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
		"ritual_circle":
			if choice == "attest":
				if contract == "" or player.hp <= 3:
					log_msg("There is no oath to attest (or too little blood).", "info")
					return false
				player.hp -= 3
				f["used"] = true
				log_msg("You attest your oath before the Geometry.", "lore")
				_advance_contract()
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
			if choice == "drain":
				var heal := maxi(4, player.stat("max_hp") / 2)
				player.hp = mini(player.stat("max_hp"), player.hp + heal)
				player.mask_risk = 0
				player.cooldowns.clear()
				f["used"] = true
				log_msg("The circle drinks your strain (+%d HP, cooldowns & Mask risk cleared)." % heal, "good")
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
			else:
				if player.hp <= 4:
					log_msg("You lack the blood to inscribe an affix.", "danger")
					return false
				var gear: Item = player.equipped("weapon")
				if gear == null:
					gear = player.equipped("ranged")
				if gear == null:
					gear = player.equipped("armor")
				if gear == null:
					log_msg("Equip a weapon or armor before inscribing.", "info")
					return false
				player.hp -= 4
				apotheosis += 1
				var gkind := String(gear.def(db)["kind"])
				var pool: Array[String] = []
				for aid in Affixes.PREFIXES:
					if (Affixes.PREFIXES[aid]["slots"] as Array).has(gkind) and not gear.affixes.has(aid):
						pool.append(String(aid))
				if pool.is_empty():
					for aid in Affixes.SUFFIXES:
						if (Affixes.SUFFIXES[aid]["slots"] as Array).has(gkind) and not gear.affixes.has(aid):
							pool.append(String(aid))
				if pool.is_empty():
					log_msg("That gear holds no room for another inscription.", "info")
					return false
				var picked := String(rng.pick(pool))
				Affixes.apply_affix(gear, picked)
				if gear.rarity == "common":
					gear.rarity = "uncommon"
				gear.identified = true
				f["used"] = true
				log_msg("You inscribe '%s' upon your %s." % [Affixes.label(picked), item_name(gear)], "lore")
				return _finish_player_action(COST_ITEM)
		"contract_lectern":
			if choice == "forsake":
				if contract == "":
					return false
				_breach_contract("You forsake the contract.")
				return _finish_player_action(COST_WAIT)
			if choice.begins_with("sign:"):
				if not player_sign_contract(choice.substr(5)):
					return false
				_trigger_ritual_cadence()
				return _finish_player_action(COST_ITEM)
			return false
		"vault_gate":
			var key_idx := -1
			var has_ophite := false
			for i in player.inventory.size():
				var item_i := player.inventory[i]
				if String(item_i.def(db).get("kind", "")) == "key":
					key_idx = i
					break
				elif item_i.template_id == "ophite_key":
					has_ophite = true
			if choice == "force":
				if player.hp <= 4:
					log_msg("You lack the strength to pry the vault bars.", "danger")
					return false
				player.hp -= 4
				apotheosis += 1
				for a in m.actors:
					if not a.is_player and a.is_alive() and Grid.chebyshev(pos, a.pos) <= 8:
						a.awake = true
						_remember_player(a)
				log_msg("You force the audit bars open with a clang that echoes!", "danger")
			else:
				if key_idx >= 0:
					var k := player.inventory[key_idx]
					k.quantity -= 1
					if k.quantity <= 0:
						player.inventory.remove_at(key_idx)
					log_msg("You unlock the audit vault with a vault key.", "good")
				elif has_ophite:
					log_msg("The Ophite Key turns silently in the vault lock.", "lore")
				else:
					log_msg("Locked: requires a vault key or Ophite Key (or force it).", "info")
					return false
			f["used"] = true
			var table: Array = current_floor_def().get("item_table", [])
			for n_i in 2:
				var loot: Item = null
				if n_i == 0 and depth >= 4:
					loot = _maybe_artifact_drop()
				if loot == null and not table.is_empty():
					loot = _new_item(rng.pick_weighted(table))
					Affixes.roll_equipment(loot, db, depth, rng, true)
				if loot != null:
					loot.pos = pos
					m.items.append(loot)
			return _finish_player_action(COST_ITEM)
		"merchant":
			var parts := choice.split(":")
			if parts.size() < 2 or parts[0] != "buy":
				return false
			var sidx := int(parts[1])
			var stock: Array = f.get("stock", [])
			if sidx < 0 or sidx >= stock.size() or bool(stock[sidx].get("sold", false)):
				return false
			var pay_mode := String(parts[2]) if parts.size() >= 3 else "blood"
			var entry: Dictionary = stock[sidx]
			var price := int(entry.get("price_hp", 5))
			if pay_mode == "barter":
				var b_idx := -1
				for i in range(player.inventory.size() - 1, -1, -1):
					var kd := String(player.inventory[i].def(db)["kind"])
					if kd != "key" and kd != "relic":
						b_idx = i
						break
				if b_idx < 0:
					log_msg("You carry nothing the broker will take in trade.", "info")
					return false
				var offered := player.inventory[b_idx]
				offered.quantity -= 1
				if offered.quantity <= 0:
					player.inventory.remove_at(b_idx)
			else:
				if player.hp <= price:
					log_msg("You lack the blood (%d HP) for that price." % price, "danger")
					return false
				player.hp -= price
			entry["sold"] = true
			var bought := _new_item(String(entry["id"]))
			Affixes.roll_equipment(bought, db, depth, rng, false)
			bought.identified = true
			if String(bought.def(db)["kind"]) == "consumable":
				id_known[bought.template_id] = true
			if _can_carry(player, bought):
				_add_to_inventory(player, bought)
			else:
				bought.pos = pos
				m.items.append(bought)
			log_msg("You acquire %s from the Debt-Broker." % item_name(bought), "good")
			return _finish_player_action(COST_ITEM)
		"challenge":
			f["used"] = true
			var fd := current_floor_def()
			var mtable: Array = fd.get("monster_table", [])
			var spawned := 0
			for d8 in Grid.DIRS_8:
				if spawned >= 2:
					break
				var q := pos + d8
				if m.is_walkable(q) and m.actor_at(q) == null and not mtable.is_empty():
					var mon := _new_monster(rng.pick_weighted(mtable), q)
					if spawned == 0:
						_apply_elite(mon, String(rng.pick(["cinder", "rime", "void", "iron"])))
					mon.awake = true
					_remember_player(mon)
					mon.next_time = time + rng.range_i(10, 60)
					m.actors.append(mon)
					spawned += 1
			var itable: Array = fd.get("item_table", [])
			var reward: Item = _maybe_artifact_drop()
			if reward == null and not itable.is_empty():
				reward = _new_item(rng.pick_weighted(itable))
				Affixes.roll_equipment(reward, db, depth + 2, rng, true)
			if reward != null:
				reward.pos = pos
				m.items.append(reward)
			player.stat_points += 1
			log_msg("The Trial Bell tolls! Guards rush out—and you gain +1 attribute point.", "lore")
			return _finish_player_action(COST_WAIT)
		"rune_puzzle":
			f["used"] = true
			if choice == "solve_force":
				subjugation = mini(chain_limit(), subjugation + 1)
				var r_table: Array = current_floor_def().get("item_table", [])
				if not r_table.is_empty():
					var it := _new_item(rng.pick_weighted(r_table))
					Affixes.roll_equipment(it, db, depth + 2, rng, true)
					it.pos = pos
					m.items.append(it)
				log_msg("You snap the rune lock violently! Salvage spills out (+1 Subjugation).", "lore")
			else:
				var nid := identify_pack()
				player.resource = mini(player.max_resource(), player.resource + 3)
				gain_xp(15)
				log_msg("The rings click silently (%d identified, +3 %s, +15 XP)." % [nid, player.resource_label()], "good")
			return _finish_player_action(COST_ITEM)
		"abandoned_rite":
			f["used"] = true
			if choice == "complete":
				player.hp = maxi(1, player.hp - 2)
				apotheosis += 1
				apply_status(player, "apostate_focus")
				log_msg("You close the unfinished circle (-2 HP, Apostate Focus gained).", "lore")
			else:
				subjugation = maxi(0, subjugation - 1)
				player.resource = mini(player.max_resource(), player.resource + 4)
				gain_xp(10)
				log_msg("You sweep the chalk lines clean (-1 Subjugation, +4 %s, +10 XP)." % player.resource_label(), "good")
			return _finish_player_action(COST_WAIT)
		"sanctuary_hearth":
			f["used"] = true
			if choice == "rest_blood":
				var spend_idx := -1
				for i in player.inventory.size():
					if String(player.inventory[i].def(db).get("kind", "")) == "consumable":
						spend_idx = i
						break
				if spend_idx >= 0:
					var sp := player.inventory[spend_idx]
					sp.quantity -= 1
					if sp.quantity <= 0:
						player.inventory.remove_at(spend_idx)
				var heal := maxi(8, player.stat("max_hp") / 2)
				player.hp = mini(player.stat("max_hp"), player.hp + heal)
				player.resource = player.max_resource()
				for st in ["bleeding", "chilled", "dread"]:
					_remove_status(player, st)
				log_msg("Warm ash-embers restore your vigor (+%d HP, full %s)." % [heal, player.resource_label()], "good")
			else:
				player.hp = mini(player.stat("max_hp"), player.hp + 6)
				subjugation = maxi(0, subjugation - 1)
				log_msg("You catch quiet breath by the hearth (+6 HP, -1 Subjugation).", "good")
			return _finish_player_action(COST_WAIT)
		"echo_cache":
			f["used"] = true
			if choice == "salvage":
				var c_table: Array = current_floor_def().get("item_table", [])
				if not c_table.is_empty():
					var item_c := _new_item(rng.pick_weighted(c_table))
					Affixes.roll_equipment(item_c, db, depth + 1, rng, false)
					item_c.pos = pos
					m.items.append(item_c)
					log_msg("You draw forgotten salvage from the wall hollow.", "good")
			else:
				for feat in m.features:
					feat["revealed"] = true
				for fy in range(maxi(0, pos.y - 10), mini(m.height, pos.y + 11)):
					for fx in range(maxi(0, pos.x - 10), mini(m.width, pos.x + 11)):
						m.set_explored(Vector2i(fx, fy))
				update_fov()
				log_msg("Scraps inside the wall reveal traps, caches, and stairs nearby.", "good")
			return _finish_player_action(COST_ITEM)
		"npc":
			return _interact_npc(pos, f, choice)
	return false


func _interact_npc(pos: Vector2i, f: Dictionary, choice: String) -> bool:
	var nid := String(f.get("sub", ""))
	if not db.has("npcs", nid):
		return false
	var ndef := db.get_def("npcs", nid)
	var fid := String(ndef["faction"])
	var fdef := db.get_def("factions", fid)
	var pole := String(ndef["faction_pole"])
	if not npcs_met.has(nid):
		npcs_met.append(nid)
	if choice.begins_with("thread_accept:"):
		var tid := choice.substr(14)
		if not discover_thread(tid):
			return false
		return _finish_player_action(COST_WAIT)
	if choice.begins_with("thread_resolve:"):
		var parts := choice.split(":")
		if parts.size() >= 3:
			var tid := parts[1]
			var method := parts[2]
			if method == "refuse":
				if not refuse_thread(tid):
					return false
				return _finish_player_action(COST_WAIT)
			if not resolve_thread(tid, method):
				return false
			return _finish_player_action(COST_ITEM)
	if choice == "talk" or choice == "":
		var pole_label := String(fdef["pole_a_label"] if pole == String(fdef["pole_a"]) else fdef["pole_b_label"])
		log_msg("%s: \"%s\" (%s — %s)" % [String(ndef["name"]), String(ndef["greeting"]), String(fdef["name"]), pole_label], "lore")
		if not npc_standing.has(nid):
			npc_standing[nid] = 1 if faction_pole_of(fid) == pole else 0
		_thread_event("npc", nid)
		_thread_event("npc_talk", nid)
		return _finish_player_action(COST_WAIT)
	if choice == "pledge":
		set_faction_pole(fid, pole)
		adjust_npc_standing(nid, 1)
		for other_id in db.ids("npcs"):
			if other_id != nid and String(db.get_def("npcs", other_id)["faction"]) == fid:
				if String(db.get_def("npcs", other_id)["faction_pole"]) != pole and npcs_met.has(other_id):
					adjust_npc_standing(other_id, -1)
		var pole_label := String(fdef["pole_a_label"] if pole == String(fdef["pole_a"]) else fdef["pole_b_label"])
		log_msg("You align with %s (%s). %s nods slowly." % [String(fdef["name"]), pole_label, String(ndef["name"])], "lore")
		return _finish_player_action(COST_WAIT)
	if choice == "refuse":
		adjust_npc_standing(nid, -1)
		var opp := String(fdef["pole_b"] if pole == String(fdef["pole_a"]) else fdef["pole_a"])
		set_faction_pole(fid, opp)
		log_msg("You refuse %s's counsel; they close their ledger against you." % String(ndef["name"]), "info")
		return _finish_player_action(COST_WAIT)
	if choice == "service":
		if npc_standing_of(nid) <= -2:
			log_msg("%s turns away and refuses all assistance." % String(ndef["name"]), "danger")
			return false
		if bool(f.get("used", false)):
			log_msg("%s has already extended their help on this floor." % String(ndef["name"]), "info")
			return false
		var st_bonus := 1 if npc_standing_of(nid) >= 2 else 0
		match String(ndef["service"]):
			"repair_curse":
				var freed := unbind_curses(true)
				if freed == 0:
					log_msg("%s finds your gear uncursed and reinforces a seam (+%d HP healed)." % [String(ndef["name"]), 2 + st_bonus * 2], "good")
					player.hp = mini(player.stat("max_hp"), player.hp + 2 + st_bonus * 2)
				else:
					log_msg("%s strips every iron lock and binding from your gear." % String(ndef["name"]), "good")
			"bless_gear":
				var blessed_any := false
				for slot in Actor.SLOTS:
					var eq_it := player.equipped(slot)
					if eq_it != null and eq_it.buc != "blessed":
						eq_it.buc = "blessed"
						eq_it.identified = true
						log_msg("%s blesses your %s." % [String(ndef["name"]), item_name(eq_it)], "good")
						blessed_any = true
						break
				if not blessed_any:
					player.resource = mini(player.max_resource(), player.resource + 4)
					log_msg("%s oils your kit (+4 %s)." % [String(ndef["name"]), player.resource_label()], "good")
			"identify_rumor":
				var id_n := identify_pack()
				for feat in current_floor().features:
					feat["revealed"] = true
				update_fov()
				log_msg("%s reads the margins (%d item%s identified, floor secrets marked)." % [String(ndef["name"]), id_n, "" if id_n == 1 else "s"], "good")
			"barter_gear":
				var table: Array = current_floor_def().get("item_table", [])
				if not table.is_empty():
					var gift := _new_item(rng.pick_weighted(table))
					Affixes.roll_equipment(gift, db, depth + 1 + st_bonus, rng, true)
					gift.identified = true
					if String(gift.def(db)["kind"]) == "consumable":
						id_known[gift.template_id] = true
					if _can_carry(player, gift):
						_add_to_inventory(player, gift)
					else:
						gift.pos = pos
						current_floor().items.append(gift)
					log_msg("%s trades salvaged stock: %s." % [String(ndef["name"]), item_name(gift)], "good")
			"heal_shelter":
				var heal := maxi(6, player.stat("max_hp") / 2) + st_bonus * 3
				player.hp = mini(player.stat("max_hp"), player.hp + heal)
				for neg in ["bleeding", "burning", "reckoning"]:
					_remove_status(player, neg)
				log_msg("%s tends your wounds under cover (+%d HP)." % [String(ndef["name"]), heal], "good")
			"reduce_chains":
				for cid in ["demanded", "dread", "debility", "degradation", "perception_fog", "entangled"]:
					_remove_status(player, cid)
				subjugation = maxi(0, subjugation - (2 + st_bonus))
				log_msg("%s slips the garrison watch; Subjugation eases." % String(ndef["name"]), "good")
			"contract_aid":
				if contract != "":
					_advance_contract()
					log_msg("%s notches a quiet tally toward your active contract." % String(ndef["name"]), "good")
				else:
					apotheosis = maxi(0, apotheosis - 1)
					log_msg("%s files down a false decree (-1 apotheosis)." % String(ndef["name"]), "good")
			"attest_way":
				if faction_pole_of(fid) == String(fdef["pole_b"]):
					way_serpent += 1 + st_bonus
					log_msg("%s cuts a marginal mark toward the Serpent's Way." % String(ndef["name"]), "lore")
				else:
					way_return += 1 + st_bonus
					log_msg("%s witnesses your stance toward the Way of Return." % String(ndef["name"]), "lore")
		f["used"] = true
		adjust_npc_standing(nid, 1)
		return _finish_player_action(COST_ITEM)
	return false


func active_thread_ids() -> Array[String]:
	var out: Array[String] = []
	for k in threads_state.get("active", {}):
		out.append(String(k))
	out.sort()
	return out


func resolved_thread_count() -> int:
	return (threads_state.get("completed", []) as Array).size()


func discover_thread(tid: String) -> bool:
	if not db.has("threads", tid):
		return false
	if Threads.is_known(threads_state, tid):
		return false
	if not Threads.activate(threads_state, tid, turns):
		return false
	var tdef := db.get_def("threads", tid)
	log_msg("Thread uncovered — %s: %s" % [String(tdef["name"]), String(tdef["lead_text"])], "lore")
	return true


func resolve_thread(tid: String, method: String = "goal") -> bool:
	if not db.has("threads", tid):
		return false
	if not Threads.is_known(threads_state, tid):
		discover_thread(tid)
	var act: Dictionary = threads_state.get("active", {})
	if not act.has(tid):
		return false
	var tdef := db.get_def("threads", tid)
	if method == "sacrifice":
		var spare_idx := -1
		for i in player.inventory.size():
			var d := player.inventory[i].def(db)
			if String(d.get("kind", "")) == "consumable" and String(d.get("effect", "")) != "heal":
				spare_idx = i
				break
		if spare_idx >= 0 and player.hp <= 4:
			var sp := player.inventory[spare_idx]
			sp.quantity -= 1
			if sp.quantity <= 0:
				player.inventory.remove_at(spare_idx)
			log_msg("You settle '%s' by bartering supplies." % String(tdef["name"]), "lore")
		elif player.hp > 4:
			player.hp -= 4
			log_msg("You settle '%s' in measured blood (-4 HP)." % String(tdef["name"]), "lore")
		else:
			log_msg("You lack vigor or barter goods to settle '%s' right now." % String(tdef["name"]), "danger")
			return false
	act.erase(tid)
	var comp: Array = threads_state.get("completed", [])
	if not comp.has(tid):
		comp.append(tid)
	_grant_thread_reward(tdef)
	return true


func refuse_thread(tid: String) -> bool:
	if not db.has("threads", tid):
		return false
	var comp: Array = threads_state.get("completed", [])
	var ref: Array = threads_state.get("refused", [])
	var fail_l: Array = threads_state.get("failed", [])
	if comp.has(tid) or ref.has(tid) or fail_l.has(tid):
		return false
	var act: Dictionary = threads_state.get("active", {})
	act.erase(tid)
	ref.append(tid)
	var tdef := db.get_def("threads", tid)
	var delay := maxi(4, int(tdef.get("delay_turns", 6)))
	(threads_state["pending"] as Array).append({
		"tid": tid,
		"effect": String(tdef["refusal_effect"]),
		"due_turn": turns + delay,
	})
	log_msg("You turn aside from '%s'. Consequences will catch up below." % String(tdef["name"]), "info")
	return true


func abandon_thread(tid: String) -> bool:
	var act: Dictionary = threads_state.get("active", {})
	if not act.has(tid) or not db.has("threads", tid):
		return false
	act.erase(tid)
	(threads_state["failed"] as Array).append(tid)
	var tdef := db.get_def("threads", tid)
	adjust_npc_standing(String(tdef["npc_id"]), -1)
	log_msg("Thread abandoned: %s." % String(tdef["name"]), "info")
	return true


func _thread_event(ev_kind: String, ev_ref: String) -> void:
	if state != State.PLAYING or threads_state.is_empty():
		return
	var pool: Array = threads_state.get("pool", [])
	for tid_v in pool:
		var tid := String(tid_v)
		if not db.has("threads", tid) or Threads.is_known(threads_state, tid):
			continue
		var tdef := db.get_def("threads", tid)
		if String(tdef["trigger_kind"]) == ev_kind and (String(tdef["trigger_ref"]) == ev_ref or String(tdef["trigger_ref"]) == "any"):
			discover_thread(tid)
	var act_keys := active_thread_ids()
	for tid in act_keys:
		if not db.has("threads", tid):
			continue
		var tdef := db.get_def("threads", tid)
		var gk := String(tdef["goal_kind"])
		var gref := String(tdef["goal_ref"])
		if gk == ev_kind and (gref == ev_ref or gref == "any"):
			resolve_thread(tid, "goal")


func _tick_threads() -> void:
	if turns <= 0 or state != State.PLAYING or threads_state.is_empty():
		return
	var pending: Array = threads_state.get("pending", [])
	var keep: Array = []
	for ev in pending:
		if turns >= int(ev.get("due_turn", 0)):
			_apply_thread_consequence(String(ev.get("effect", "")), String(ev.get("tid", "")))
		else:
			keep.append(ev)
	threads_state["pending"] = keep
	for tid in active_thread_ids():
		var entry: Dictionary = threads_state["active"][tid]
		if turns - int(entry.get("accepted_turn", turns)) > 350 and depth >= 5:
			abandon_thread(tid)


func _grant_thread_reward(tdef: Dictionary) -> void:
	var tname := String(tdef["name"])
	var nid := String(tdef["npc_id"])
	adjust_npc_standing(nid, 1)
	match String(tdef["reward_kind"]):
		"stat_point":
			player.stat_points += 1
			log_msg("Thread settled (%s): +1 attribute point!" % tname, "good")
		"talent_point":
			player.talent_points += 1
			log_msg("Thread settled (%s): +1 talent point!" % tname, "good")
		"heal_vigor":
			var heal := maxi(6, player.stat("max_hp") / 2)
			player.hp = mini(player.stat("max_hp"), player.hp + heal)
			player.resource = mini(player.max_resource(), player.resource + 6)
			log_msg("Thread settled (%s): +%d HP and +6 %s!" % [tname, heal, player.resource_label()], "good")
		"loot_magic":
			var table: Array = current_floor_def().get("item_table", [])
			var reward: Item = _maybe_artifact_drop()
			if reward == null and not table.is_empty():
				reward = _new_item(rng.pick_weighted(table))
				Affixes.roll_equipment(reward, db, depth + 2, rng, true)
			if reward != null:
				reward.identified = true
				if _can_carry(player, reward):
					_add_to_inventory(player, reward)
				else:
					reward.pos = player.pos
					current_floor().items.append(reward)
				log_msg("Thread settled (%s): received %s!" % [tname, item_name(reward)], "good")
		"reduce_chains":
			subjugation = maxi(0, subjugation - 2)
			for cid in ["demanded", "dread", "debility", "degradation", "perception_fog", "entangled"]:
				_remove_status(player, cid)
			log_msg("Thread settled (%s): Subjugation eases (-2) and chains loosen." % tname, "good")
		"way_return":
			way_return += 1
			log_msg("Thread settled (%s): your step turns toward the Way of Return." % tname, "lore")
		"way_serpent":
			way_serpent += 1
			log_msg("Thread settled (%s): you cut a mark toward the Serpent's Way." % tname, "lore")
		"faction_pole":
			var fid := String(tdef["faction"])
			var pole := String(db.get_def("npcs", nid)["faction_pole"])
			set_faction_pole(fid, pole)
			log_msg("Thread settled (%s): institution alignment shifted." % tname, "lore")


func _apply_thread_consequence(eff: String, tid: String) -> void:
	if not db.has("threads", tid):
		return
	var tdef := db.get_def("threads", tid)
	var nid := String(tdef["npc_id"])
	match eff:
		"standing_drop":
			adjust_npc_standing(nid, -1)
			log_msg("Word of your refusal over '%s' reaches %s (-standing)." % [String(tdef["name"]), String(db.get_def("npcs", nid)["name"])], "danger")
		"subjugation_spike":
			subjugation = mini(chain_limit(), subjugation + 2)
			log_msg("An unkept thread (%s) tightens the Dominion's audit (+2 Subjugation)!" % String(tdef["name"]), "danger")
		"faction_shift":
			var fid := String(tdef["faction"])
			var fdef := db.get_def("factions", fid)
			var npc_pole := String(db.get_def("npcs", nid)["faction_pole"])
			var opp := String(fdef["pole_b"] if npc_pole == String(fdef["pole_a"]) else fdef["pole_a"])
			set_faction_pole(fid, opp)
			log_msg("Your refusal tilts %s toward %s." % [String(fdef["name"]), String(fdef["pole_b_label"] if opp == String(fdef["pole_b"]) else fdef["pole_a_label"])], "lore")
		"ambush_alert":
			var alerted := 0
			for a in current_floor().actors:
				if not a.is_player and a.is_alive() and not a.awake and Grid.chebyshev(player.pos, a.pos) <= 10:
					a.awake = true
					_remember_player(a)
					alerted += 1
			log_msg("Whispers over '%s' draw nearby eyes (%d alerted)!" % [String(tdef["name"]), alerted], "danger")
		"curse_mark":
			_chain_hit("dread")
			log_msg("Refusal over '%s' leaves a bitter dread on your trail." % String(tdef["name"]), "danger")


func _tick_cooldowns() -> void:
	if turns <= 0:
		return
	if not player.cooldowns.is_empty():
		var done: Array[String] = []
		for tid in player.cooldowns:
			var rem := int(player.cooldowns[tid]) - 1
			if rem <= 0:
				done.append(String(tid))
			else:
				player.cooldowns[tid] = rem
		for tid in done:
			player.cooldowns.erase(tid)
	var rk := player.resource_kind()
	if player.has_status("demanded"):
		return
	if rk == "poise" and turns % 2 == 0:
		player.resource = mini(player.max_resource(), player.resource + 1)
	elif rk != "" and turns % 3 == 0:
		player.resource = mini(player.max_resource(), player.resource + 1)


func _tick_mask() -> void:
	if turns <= 0 or not player.has_trait("mask_stances"):
		return
	if player.mask_seized_turns() > 0:
		player.set_mask_seized_turns(player.mask_seized_turns() - 1)
	if player.mask == "bare_face":
		var cool := 2 + player.talent_rank("quick_shift")
		player.mask_risk = maxi(0, player.mask_risk - cool)
		return
	if player.mask == Masks.UNION_ID:
		player.mask_risk = maxi(0, player.mask_risk - 1)
		return
	player.mask_risk += 1
	var risk_max := MASK_RISK_MAX + 2 * player.talent_rank("crowned_frequency") + ItemSets.mask_risk_bonus(player, db)
	if player.mask_risk >= risk_max:
		var old_mask := player.mask
		var sid := Masks.seizure_status(old_mask)
		player.mask = "bare_face"
		player.mask_risk = 0
		if sid != "":
			apply_status(player, sid)
		log_msg("%s seizes and tears away!" % Masks.label(old_mask), "danger")


func _natural_regen() -> void:
	if turns <= 0 or player.hp >= player.stat("max_hp"):
		return
	if (player.has_trait("mask_stances") and player.mask == "eris") or player.has_status("isolation"):
		return
	var mult := float(db.get_def("species", player.species_id).get("heal_mult", 1.0))
	var interval := maxi(1, int(roundf(REGEN_TURNS / maxf(mult, 0.1))))
	if current_floor().get_tile(player.pos) == Tiles.SANCTUARY_FLOOR:
		interval = maxi(1, interval / 2)
	if turns % interval == 0:
		player.hp += 1


## True when resting is safe: no hostile in view, not isolated, and health or resource not full.
func can_rest() -> bool:
	if state != State.PLAYING or player.has_status("isolation"):
		return false
	var need := player.hp < player.stat("max_hp") or player.resource < player.max_resource()
	return visible_hostiles().is_empty() and need


## Waits repeatedly until health is full, a hostile comes into view, or
## `max_turns` pass. Returns the number of turns rested.
func player_rest(max_turns: int = 200) -> int:
	var n := 0
	if not can_rest():
		log_msg("You cannot rest now." if state == State.PLAYING and player.hp < player.stat("max_hp") else "You are already whole.")
		return 0
	while n < max_turns and can_rest():
		player_wait()
		n += 1
	log_msg("You rest for %d turns." % n)
	return n


func update_fov() -> void:
	Fov.compute(current_floor(), player.pos, player.stat("sight"))


func _tick_statuses(a: Actor) -> void:
	if a.statuses.is_empty():
		return
	var expired: Array[String] = []
	for s in a.statuses:
		var sid := String(s["id"])
		var sd := db.get_def("statuses", sid)
		var regen := int(sd.get("regen", 0))
		if regen > 0:
			a.hp = clampi(a.hp + regen, 1, a.stat("max_hp"))
		elif regen < 0:
			if sid == "burning" and a.is_player and a.has_trait("cinder_born"):
				a.hp = clampi(a.hp + 1, 1, a.stat("max_hp"))
			else:
				var tick_dmg := -regen
				if sid == "burning" and a.is_player and a.has_trait("infernal_blood"):
					tick_dmg = maxi(1, tick_dmg / 2)
				var dtype := String(sd.get("damage_type", "physical"))
				apply_damage(a, tick_dmg, String(sd["name"]).to_lower(), dtype)
				if not a.is_alive():
					return
		s["turns"] = int(s["turns"]) - 1
		if int(s["turns"]) <= 0:
			expired.append(sid)
	for sid in expired:
		_remove_status(a, sid)
		var sd := db.get_def("statuses", sid)
		if a.is_player:
			log_msg("%s fades." % sd["name"], "info")
		if sd.has("on_expire"):
			apply_status(a, String(sd["on_expire"]))
	a.hp = mini(a.hp, a.stat("max_hp"))


func apply_status(a: Actor, sid: String) -> void:
	if sid == "bleeding" and a.is_player and a.has_trait("deathless"):
		log_msg("Your dead veins do not bleed.", "info")
		return
	if sid == "pinned" and a.is_player and a.has_trait("ledger_forged"):
		log_msg("Your iron vows refuse the shackle.", "info")
		return
	if sid == "burning" and a.has_status("chilled"):
		_remove_status(a, "chilled")
		log_msg("Thermal shock shatters the frost on %s!" % ("you" if a.is_player else "the " + a.name), "combat")
		apply_damage(a, 4, "thermal shock", "fire")
		if a.is_alive():
			apply_status(a, "sundered")
		return
	if sid == "chilled" and a.has_status("burning"):
		_remove_status(a, "burning")
		log_msg("Scalding steam erupts around %s!" % ("you" if a.is_player else "the " + a.name), "combat")
		apply_damage(a, 3, "scalding steam", "cold")
		if a.is_alive():
			apply_status(a, "perception_fog")
		return
	if sid == "bleeding" and a.has_status("sundered"):
		log_msg("Hemorrhage tears through %s's sundered guard!" % ("your" if a.is_player else "the " + a.name + "'s"), "combat")
		apply_damage(a, 3, "hemorrhage", "physical")
		if not a.is_alive():
			return
	var sd := db.get_def("statuses", sid)
	var dur := int(sd["duration"])
	if a.is_player:
		if sid == "perception_fog" and a.talent_rank("clear_witness") > 0:
			dur = maxi(2, dur / 2)
		elif sid == "reckoning":
			if a.talent_rank("alchemical_restraint") > 0:
				dur = maxi(8, dur - 8 * a.talent_rank("alchemical_restraint"))
			if a.has_trait("alchemical_potency"):
				dur = maxi(8, dur - 10)
	for s in a.statuses:
		if s["id"] == sid:
			s["turns"] = maxi(int(s["turns"]), dur)
			return
	a.statuses.append({"id": sid, "turns": dur})
	if a.is_player:
		log_msg("%s: %s" % [sd["name"], sd["description"]], "danger" if sid in ["reckoning", "bleeding", "isolation", "perception_fog", "sundered", "burning", "chilled", "pinned", "hexed"] else "good")
		if sid == "false_light" and a.mask == Masks.UNION_ID:
			fracture_venefica("false_light", "the False Light")


func _remove_status(a: Actor, sid: String) -> void:
	for i in range(a.statuses.size() - 1, -1, -1):
		if a.statuses[i]["id"] == sid:
			a.statuses.remove_at(i)


# ---------------------------------------------------------------- monsters

func _monster_sees_player(m: FloorMap, mon: Actor) -> bool:
	return m.is_visible(mon.pos) and Grid.chebyshev(mon.pos, player.pos) <= mon.stat("sight")


func _remember_player(mon: Actor) -> void:
	mon.flags["seen_x"] = player.pos.x
	mon.flags["seen_y"] = player.pos.y


func _forget_player(mon: Actor) -> void:
	mon.awake = false
	mon.flags.erase("seen_x")
	mon.flags.erase("seen_y")


func _monster_turn(mon: Actor) -> int:
	var m := current_floor()
	if not mon.awake:
		var dist := Grid.chebyshev(mon.pos, player.pos)
		var perc := mon.stat("perception")
		var notice_pct := NOTICE_PCT
		if player.has_trait("mask_stances"):
			if player.mask == "lilith":
				perc += 2
			elif player.mask == "nyx" or player.mask == Masks.UNION_ID:
				notice_pct = NOTICE_PCT / 2
		var ue := player.talent_rank("unseen_edge")
		if ue > 0:
			notice_pct = maxi(10, notice_pct - 15 * ue)
		if player.has_trait("unfiled"):
			notice_pct = maxi(10, notice_pct - 20)
		if _monster_sees_player(m, mon) and dist <= perc and rng.chance_pct(notice_pct):
			mon.awake = true
			_remember_player(mon)
			log_msg("The %s notices you." % mon.name, "danger")
		return COST_WAIT
	var sees := _monster_sees_player(m, mon)
	if sees:
		_remember_player(mon)
	if mon.flags.has("telegraph_x") and mon.flags.has("telegraph_y"):
		var tpos := Vector2i(int(mon.flags["telegraph_x"]), int(mon.flags["telegraph_y"]))
		mon.flags.erase("telegraph_x")
		mon.flags.erase("telegraph_y")
		if Grid.chebyshev(player.pos, tpos) <= 1 and Grid.chebyshev(mon.pos, player.pos) <= 2:
			var raw := Dice.roll(mon.damage_dice(), rng) + Dice.roll(mon.damage_dice(), rng) + mon.stat("damage_bonus")
			var dtype := mon.melee_damage_type()
			var mit := Combat.mitigate(raw, player, dtype)
			var dmg := int(mit["damage"])
			log_msg("The %s's telegraphed blow crushes you for %d (%s)!" % [mon.name, dmg, dtype], "danger")
			apply_damage(player, dmg, mon.name, dtype)
			if player.is_alive():
				apply_status(player, "sundered")
		else:
			log_msg("You evade the %s's telegraphed blow!" % mon.name, "good")
		return COST_ATTACK
	var fog_cd := int(mon.flags.get("fog_cd", 0))
	if fog_cd > 0:
		mon.flags["fog_cd"] = fog_cd - 1
	var spec_cd := int(mon.flags.get("spec_cd", 0))
	if spec_cd > 0:
		mon.flags["spec_cd"] = spec_cd - 1
	if mon.tags.has("chain_fog") and sees and fog_cd <= 0 and not player.has_status("perception_fog") and Grid.chebyshev(mon.pos, player.pos) <= 5 and rng.chance_pct(50):
		mon.flags["fog_cd"] = 8
		_chain_hit("perception_fog")
		update_fov()
		log_msg("The %s recites a narrowing litany; the dark closes in." % mon.name, "danger")
		return COST_WAIT
	if sees and spec_cd <= 0 and not mon.specials.is_empty():
		var spec_cost := _try_monster_special(m, mon)
		if spec_cost > 0:
			return spec_cost
	if mon.specials.has("kite_ranged") and sees and not mon.has_status("pinned") and Grid.chebyshev(mon.pos, player.pos) <= 2 and rng.chance_pct(60):
		var best_retreat := mon.pos
		var best_dist := Grid.chebyshev(mon.pos, player.pos)
		for d in Grid.DIRS_8:
			var q := mon.pos + d
			if m.can_step(mon.pos, q) and m.actor_at(q) == null:
				var qd := Grid.chebyshev(q, player.pos)
				if qd > best_dist:
					best_dist = qd
					best_retreat = q
		if best_retreat != mon.pos:
			mon.pos = best_retreat
			_on_actor_enter_tile(mon, best_retreat)
			return COST_MOVE
	if Grid.is_adjacent(mon.pos, player.pos) and m.can_step(mon.pos, player.pos):
		_remember_player(mon)
		_attack(mon, player)
		return COST_ATTACK
	if mon.has_status("pinned"):
		return COST_WAIT
	var target := player.pos
	if mon.flags.has("seen_x") and mon.flags.has("seen_y"):
		target = Vector2i(int(mon.flags["seen_x"]), int(mon.flags["seen_y"]))
	else:
		_remember_player(mon)
	if mon.pos == target and not sees:
		_forget_player(mon)
		return COST_WAIT
	var dmap := player_distance_map() if target == player.pos else Pathing.distance_map(m, target)
	var blocked := func(p: Vector2i) -> bool: return m.actor_at(p) != null
	var step := Pathing.step_down(m, dmap, mon.pos, blocked)
	if step != mon.pos:
		mon.pos = step
		_on_actor_enter_tile(mon, step)
		if mon.pos == target and not _monster_sees_player(m, mon):
			_forget_player(mon)
		return COST_MOVE
	return COST_WAIT


func _try_monster_special(m: FloorMap, mon: Actor) -> int:
	var dist := Grid.chebyshev(mon.pos, player.pos)
	var adj := Grid.is_adjacent(mon.pos, player.pos)
	if mon.specials.has("telegraph_slam") and dist <= 2 and rng.chance_pct(40):
		mon.flags["spec_cd"] = 5
		mon.flags["telegraph_x"] = player.pos.x
		mon.flags["telegraph_y"] = player.pos.y
		log_msg("The %s winds back a heavy blow toward (%d, %d)!" % [mon.name, player.pos.x, player.pos.y], "danger")
		return COST_WAIT
	if mon.specials.has("support_ward") and rng.chance_pct(50):
		var ally: Actor = null
		for a in m.actors:
			if not a.is_player and a != mon and a.is_alive() and Grid.chebyshev(mon.pos, a.pos) <= 4 and (a.hp < a.stat("max_hp") or not a.has_status("braced")):
				ally = a
				break
		if ally != null:
			mon.flags["spec_cd"] = 5
			apply_status(ally, "braced")
			ally.hp = mini(ally.stat("max_hp"), ally.hp + 3)
			log_msg("The %s wards and mends the %s." % [mon.name, ally.name], "danger")
			return COST_WAIT
	if mon.specials.has("support_rally") and rng.chance_pct(45):
		var rallied := 0
		for a in m.actors:
			if not a.is_player and a != mon and a.is_alive() and Grid.chebyshev(mon.pos, a.pos) <= 4:
				a.awake = true
				_remember_player(a)
				apply_status(a, "apostate_focus")
				rallied += 1
		if rallied > 0:
			mon.flags["spec_cd"] = 6
			log_msg("The %s rallies %d nearby companion%s!" % [mon.name, rallied, "" if rallied == 1 else "s"], "danger")
			return COST_WAIT
	if mon.specials.has("lay_hazard") and dist <= 4 and rng.chance_pct(45):
		var step := Grid.sign_vec(player.pos - mon.pos)
		var hp_tile := mon.pos + step
		if m.get_tile(hp_tile) == Tiles.FLOOR and hp_tile != player.pos and m.portal_at(hp_tile).is_empty():
			mon.flags["spec_cd"] = 5
			var dtype := mon.melee_damage_type()
			var htile := Tiles.ASH_EMBER if dtype == "fire" else (Tiles.RIME_ICE if dtype == "cold" else (Tiles.SOLAR_GLARE if dtype == "radiant" else Tiles.MIASMA))
			m.set_tile(hp_tile, htile)
			log_msg("The %s scatters %s across the flagstones!" % [mon.name, Tiles.NAMES[htile]], "danger")
			return COST_WAIT
	if mon.specials.has("judgment_nova") and dist <= 2 and rng.chance_pct(45):
		mon.flags["spec_cd"] = 7
		var raw := Dice.roll("1d6", rng) + maxi(1, depth / 2)
		var mit := Combat.mitigate(raw, player, "radiant")
		log_msg("The %s calls down a Judgment Nova for %d (radiant)!" % [mon.name, int(mit["damage"])], "danger")
		apply_damage(player, int(mit["damage"]), mon.name, "radiant")
		if player.is_alive():
			apply_status(player, "exposure")
		return COST_WAIT
	if adj:
		return -1
	if mon.specials.has("pull_chain") and not player.has_status("pinned") and dist >= 2 and dist <= 4 and rng.chance_pct(45):
		var tr_pull := projectile_trace(mon.pos, player.pos, 4)
		if tr_pull["hit_actor"] == player:
			var pull_dir := Grid.sign_vec(mon.pos - player.pos)
			var dest := player.pos + pull_dir
			if m.can_step(player.pos, dest) and m.actor_at(dest) == null:
				mon.flags["spec_cd"] = 5
				player.pos = dest
				_on_actor_enter_tile(player, dest)
				if player.is_alive():
					apply_status(player, "pinned")
				update_fov()
				log_msg("The %s yanks a chain and drags you closer!" % mon.name, "danger")
				return COST_ATTACK
	if mon.specials.has("warren_pounce") and not mon.has_status("pinned") and dist >= 2 and dist <= 3 and rng.chance_pct(55):
		var step := Grid.sign_vec(player.pos - mon.pos)
		var dest := mon.pos
		for _s in 2:
			var q := dest + step
			if q == player.pos or not m.can_step(dest, q) or m.actor_at(q) != null:
				break
			dest = q
		if Grid.is_adjacent(dest, player.pos) and m.can_step(dest, player.pos):
			mon.pos = dest
			mon.flags["spec_cd"] = 6
			log_msg("The %s pounces across the stone!" % mon.name, "danger")
			_attack(mon, player)
			return COST_ATTACK
	var r_max := int(mon.base.get("ranged_range", 5))
	if dist > r_max:
		return -1
	var tr := projectile_trace(mon.pos, player.pos, r_max)
	if tr["hit_actor"] != player:
		return -1
	var rdice := String(mon.base.get("ranged_damage", mon.damage_dice()))
	var dtype := ""
	var sid := ""
	var cd := 4
	var label := "strikes"
	var drain_res := false
	if mon.specials.has("drain_resource"):
		dtype = "void"; sid = "demanded"; cd = 5; label = "drains your resolve with a void bolt at"; drain_res = true
	elif mon.specials.has("iron_shackle"):
		dtype = "physical"; sid = "pinned"; cd = 6; label = "hurls an iron shackle at"
	elif mon.specials.has("cinder_bolt"):
		dtype = "fire"; sid = "burning"; cd = 4; label = "casts a cinder bolt at"
	elif mon.specials.has("grave_chill"):
		dtype = "cold"; sid = "chilled"; cd = 4; label = "breathes grave-frost at"
	elif mon.specials.has("void_bolt"):
		dtype = "void"; sid = "hexed"; cd = 4; label = "casts a void spike at"
	elif mon.specials.has("solar_bolt"):
		dtype = "radiant"; cd = 4; label = "looses a false-sun bolt at"
	elif mon.specials.has("ranged_shot"):
		dtype = "physical"; cd = 2; label = "fires a bolt at"
	else:
		return -1
	if not rng.chance_pct(65):
		return -1
	mon.flags["spec_cd"] = cd
	var res := Combat.resolve_ranged(mon, player, dist, rdice, int(mon.base.get("accuracy", 0)), 0, dtype, rng)
	if not res["hit"]:
		log_msg("The %s %s you and misses." % [mon.name, label], "combat")
		return COST_ATTACK
	var dmg := int(res["damage"])
	log_msg("The %s %s you for %d%s!" % [mon.name, label, dmg, _combat_note(res)], "danger")
	if drain_res and player.resource > 0:
		player.resource = maxi(0, player.resource - 2)
		log_msg("Your %s drains by 2!" % player.resource_label().to_lower(), "danger")
	apply_damage(player, dmg, mon.name, dtype)
	if player.is_alive() and sid != "" and rng.chance_pct(70):
		apply_status(player, sid)
	return COST_ATTACK


func player_distance_map() -> PackedInt32Array:
	if _player_dist_pos != player.pos:
		_player_dist = Pathing.distance_map(current_floor(), player.pos)
		_player_dist_pos = player.pos
	return _player_dist


# ---------------------------------------------------------------- combat

func _attack(attacker: Actor, defender: Actor) -> void:
	defender.awake = true
	if attacker.is_player and not defender.is_player:
		_remember_player(defender)
	var r := Combat.resolve(attacker, defender, rng)
	var who := "You" if attacker.is_player else "The %s" % attacker.name
	var whom := "you" if defender.is_player else "the %s" % defender.name
	if not r["hit"]:
		log_msg("%s miss%s %s." % [who, "" if attacker.is_player else "es", whom], "combat")
		return
	var verb := "hit" if attacker.is_player else "hits"
	if r["sneak"]:
		verb = "strike unseen at" if attacker.is_player else "strikes unseen at"
	var dtype := String(r.get("type", "physical"))
	var hit_dmg := int(r["damage"])
	var note := _combat_note(r)
	if not attacker.is_player and attacker.specials.has("ambusher") and not attacker.flags.has("ambush_spent"):
		attacker.flags["ambush_spent"] = 1
		hit_dmg += 3
		log_msg("%s strikes from concealment!" % who, "danger")
		if defender.is_alive():
			apply_status(defender, "bleeding")
	if not attacker.is_player and attacker.specials.has("exploit_status") and (defender.has_status("sundered") or defender.has_status("exposure") or defender.has_status("pinned") or defender.has_status("entangled")):
		hit_dmg += 3
		log_msg("%s exploits your exposed guard!" % who, "danger")
	log_msg("%s %s %s for %d%s." % [who, verb, whom, hit_dmg, note], "danger" if defender.is_player else "combat")
	if attacker.is_player and attacker.resource_kind() == "poise" and (bool(r["crit"]) or bool(r["sneak"])):
		attacker.resource = mini(attacker.max_resource(), attacker.resource + 1)
	apply_damage(defender, hit_dmg, attacker.name, dtype)
	if attacker.is_player and defender.is_alive():
		var w := attacker.equipped("weapon")
		if w != null:
			var st := w.effective_status(db)
			if st != "":
				apply_status(defender, st)
	if not attacker.is_player and defender.is_player and defender.is_alive():
		for ctag in CHAIN_TAGS:
			if attacker.tags.has(ctag):
				var csid := String(CHAIN_TAGS[ctag]["status"])
				if not defender.has_status(csid) and rng.chance_pct(int(CHAIN_TAGS[ctag]["pct"])):
					_chain_hit(csid)
		if attacker.specials.has("leech_bite") and rng.chance_pct(35):
			attacker.hp = mini(attacker.stat("max_hp"), attacker.hp + 2)
			apply_status(defender, "bleeding")


func _apply_damage_combos(target: Actor, amount: int, dmg_type: String) -> int:
	if dmg_type == "fire" and target.has_status("chilled"):
		_remove_status(target, "chilled")
		amount += 4
		apply_status(target, "sundered")
		log_msg("Thermal shock shatters the frost on %s!" % ("you" if target.is_player else "the " + target.name), "combat")
	elif dmg_type == "cold" and target.has_status("burning"):
		_remove_status(target, "burning")
		amount += 3
		apply_status(target, "perception_fog")
		log_msg("Scalding steam erupts around %s!" % ("you" if target.is_player else "the " + target.name), "combat")
	elif dmg_type == "fire" and target.has_status("bleeding"):
		_remove_status(target, "bleeding")
		amount += 2
		log_msg("Fire cauterizes %s wounds!" % ("your" if target.is_player else "the " + target.name + "'s"), "combat")
	elif dmg_type == "void" and target.has_status("false_light"):
		amount += 3
		for s in target.statuses:
			if s["id"] == "false_light":
				s["turns"] = int(s["turns"]) - 3
				if int(s["turns"]) <= 0:
					_remove_status(target, "false_light")
					apply_status(target, "reckoning")
				break
		log_msg("Void fractures the False Light!", "danger" if target.is_player else "combat")
	return amount


func apply_damage(target: Actor, amount: int, source: String, dmg_type: String = "physical") -> void:
	if amount <= 0 and dmg_type != "physical":
		log_msg("%s resists completely." % ("You" if target.is_player else "The " + target.name), "info")
		return
	if not target.is_player and dmg_type == "physical" and amount > 1:
		for a in current_floor().actors:
			if not a.is_player and a != target and a.is_alive() and a.specials.has("protect_ally") and Grid.is_adjacent(a.pos, target.pos):
				amount = maxi(1, amount - 2)
				log_msg("The %s shields the %s!" % [a.name, target.name], "info")
				break
	if dmg_type == "cold" and amount > 0 and current_floor().get_tile(target.pos) == Tiles.WATER_SHALLOW:
		amount = maxi(1, int(roundf(float(amount) * 1.25)))
	if target.is_player and target.has_trait("bulwark_stance") and amount > 1 and (target.has_status("braced") or int(target.flags.get("wait_turn", -1)) == turns):
		amount = maxi(1, amount * 3 / 4)
	amount = _apply_damage_combos(target, amount, dmg_type)
	target.hp -= amount
	if target.hp > 0:
		if target.is_player and target.resource_kind() == "stamina":
			target.resource = mini(target.max_resource(), target.resource + 1)
		return
	if target.is_player:
		if target.has_trait("deathless") and not _deathless_spent(target):
			target.flags["deathless_" + str(depth)] = 1
			target.hp = 1
			for sid in ["bleeding", "isolation", "perception_fog"]:
				_remove_status(target, sid)
			target.statuses.append({"id": "braced", "turns": 3})
			log_msg("Death reaches for you and finds you already filed. You stand back up.", "good")
			return
		target.hp = 0
		state = State.DEAD
		death_cause = source
		log_msg("You die. The record closes over you.", "danger")
		return
	_kill_monster(target)


func _deathless_spent(a: Actor) -> bool:
	return a.flags.has("deathless_" + str(depth))


func _kill_monster(mon: Actor) -> void:
	var m := current_floor()
	m.actors.erase(mon)
	log_msg("The %s is destroyed." % mon.name, "good")
	var sp := db.get_def("species", player.species_id)
	gain_xp(int(roundf(mon.xp_value * float(sp.get("xp_mult", 1.0)))))
	_thread_event("boss", mon.template_id)
	_thread_event("kill_monster", mon.template_id)
	if player.has_trait("soul_siphon") and not player.has_status("isolation"):
		var heal := 1 + maxi(0, player.stat("will")) + player.talent_rank("alchemical_restraint")
		player.hp = mini(player.stat("max_hp"), player.hp + heal)
	if player.resource_kind() == "resonance":
		player.resource = mini(player.max_resource(), player.resource + 2)
	if mon.is_elite or mon.tags.has("boss"):
		var fd := current_floor_def()
		var table: Array = fd.get("item_table", [])
		var drop: Item = null
		if mon.tags.has("boss") and rng.chance_pct(30):
			drop = _maybe_artifact_drop()
		if drop == null and not table.is_empty():
			drop = _new_item(rng.pick_weighted(table))
			Affixes.roll_equipment(drop, db, depth, rng, true)
		if drop != null:
			drop.pos = mon.pos
			m.items.append(drop)
			log_msg("The %s drops a %s." % [mon.name, item_name(drop)], "good")
	if mon.tags.has("guardian") and m.exit_pos.x >= 0 and m.get_tile(m.exit_pos) == Tiles.DOOR_SEALED:
		m.set_tile(m.exit_pos, Tiles.DOOR_OPEN)
		log_msg("The Sentinel falls. Somewhere a seal that was never written down gives way.", "lore")
		log_msg("The Unwritten Door stands open.", "good")


# ---------------------------------------------------------------- progression

static func xp_for_level(lvl: int) -> int:
	# Total XP needed to reach `lvl`: 15 x the triangular number of (lvl - 1).
	var n := lvl - 1
	return 15 * n * (n + 1) / 2


func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	if apotheosis >= APOTHEOSIS_THRESHOLD:
		if not player.flags.has("apotheosis_warned"):
			player.flags["apotheosis_warned"] = 1
			log_msg("The record no longer measures you; you have begun to write it.", "lore")
		return
	player.xp += amount
	while player.xp >= xp_for_level(player.level + 1):
		player.level += 1
		var sp := db.get_def("species", player.species_id)
		var cl := db.get_def("classes", player.class_id)
		var gain := int(cl["hp_per_level"]) + int(sp["hp_per_level"])
		player.base["max_hp"] = int(player.base["max_hp"]) + gain
		if player.level % 2 == 1:
			player.base["accuracy"] = int(player.base["accuracy"]) + 1
		player.stat_points += 1
		player.talent_points += 1
		if player.has_trait("adaptable") and (player.level == 3 or player.level == 6):
			player.talent_points += 1
		player.resource = player.max_resource()
		player.hp = mini(player.stat("max_hp"), player.hp + gain + player.stat("max_hp") / 4)
		log_msg("You reach level %d. (+%d max health%s, +1 stat, +1 talent)" % [player.level, gain, ", +1 accuracy" if player.level % 2 == 1 else ""], "good")


# ---------------------------------------------------------------- items

func _can_carry(a: Actor, it: Item) -> bool:
	if bool(it.def(db).get("stackable", false)):
		for own in a.inventory:
			if own.template_id == it.template_id:
				return true
	return a.inventory.size() < Actor.INVENTORY_LIMIT


func _add_to_inventory(a: Actor, it: Item) -> void:
	if bool(it.def(db).get("stackable", false)):
		for own in a.inventory:
			if own.template_id == it.template_id:
				own.quantity += it.quantity
				return
	a.inventory.append(it)


func _consume(a: Actor, it: Item, index: int) -> void:
	var d := it.def(db)
	match String(d["effect"]):
		"heal":
			var sp := db.get_def("species", a.species_id) if a.is_player else {}
			var alch_mult := 1.35 if (a.is_player and a.has_trait("alchemical_potency")) else 1.0
			var amount := maxi(1, int(roundf(Dice.roll(String(d["heal"]), rng) * float(sp.get("heal_mult", 1.0)) * alch_mult)))
			var before := a.hp
			a.hp = mini(a.stat("max_hp"), a.hp + amount)
			log_msg("You use the %s and recover %d health." % [d["name"], a.hp - before], "good")
			if a.is_player:
				_contract_event("heal_item")
		"status":
			log_msg("You drink the %s." % d["name"], "info")
			if String(d["status"]) == "false_light":
				apotheosis += 2
			apply_status(a, String(d["status"]))
	it.quantity -= 1
	if it.quantity <= 0:
		a.inventory.remove_at(index)


# ---------------------------------------------------------------- queries for UI and tools

func visible_hostiles() -> Array[Actor]:
	var out: Array[Actor] = []
	var m := current_floor()
	for a in m.actors:
		if not a.is_player and a.is_alive() and m.is_visible(a.pos):
			out.append(a)
	return out


func describe_at(p: Vector2i) -> String:
	var m := current_floor()
	if not m.is_explored(p):
		return "You have not seen that place."
	if m.is_visible(p):
		var a := m.actor_at(p)
		if a == player:
			return "You: %s %s, level %d. %d/%d health." % [db.get_def("species", player.species_id)["name"], db.get_def("classes", player.class_id)["name"], player.level, player.hp, player.stat("max_hp")]
		if a != null:
			var d := db.get_def("monsters", a.template_id)
			var hurt := float(a.hp) / float(a.stat("max_hp"))
			var cond := "unhurt" if hurt >= 1.0 else ("wounded" if hurt > 0.5 else ("badly wounded" if hurt > 0.2 else "near death"))
			var aware := "" if a.awake else " It has not noticed you."
			var rank_tag := " [Boss]" if a.tags.has("boss") else (" [Elite]" if a.is_elite else "")
			var r_notes: PackedStringArray = []
			for dt in ContentSchema.DAMAGE_TYPES:
				var rv := a.resist(dt)
				if rv != 0:
					r_notes.append("%s %+d%%" % [dt.capitalize(), rv])
			var r_str := (" Resists: %s." % ", ".join(r_notes)) if not r_notes.is_empty() else ""
			return "%s%s (%s, %d%% to hit). %s%s%s" % [a.name.capitalize(), rank_tag, cond, Combat.hit_chance(player, a), d["description"], r_str, aware]
		var its := m.items_at(p)
		if not its.is_empty():
			var desc := String(its[0].def(db)["description"]) if is_item_identified(its[0]) else "Unidentified; pick up, equip, or read a scroll of witness."
			return "%s: %s" % [item_name(its[0]).capitalize(), desc]
		var feat := m.revealed_feature_at(p)
		if not feat.is_empty():
			return "%s: %s" % [Ecology.label(feat), Ecology.description(feat)]
	var feat_mem := m.revealed_feature_at(p)
	if not feat_mem.is_empty():
		return "%s." % Ecology.label(feat_mem)
	var pt := m.portal_at(p)
	if not pt.is_empty():
		return "Passage to %s." % String(pt.get("label", pt.get("target", "")))
	return "%s." % String(Tiles.NAMES.get(m.get_tile(p), "unknown")).capitalize()


func _describe_floor_here() -> void:
	var m := current_floor()
	var t := m.get_tile(player.pos)
	var feat := m.revealed_feature_at(player.pos)
	if not feat.is_empty() and Ecology.is_interactive(feat):
		log_msg("Here stands: %s (press 'e' or tap to use)." % Ecology.label(feat), "lore")
	var its := m.items_at(player.pos)
	if its.size() == 1:
		log_msg("You see here: %s." % item_name(its[0]))
	elif its.size() > 1:
		log_msg("Several things lie here.")
	var pt := m.portal_at(player.pos)
	if not pt.is_empty():
		log_msg("Passage to %s (press Enter or tap to cross)." % String(pt.get("label", pt.get("target", ""))), "lore")
		return
	match t:
		Tiles.STAIRS_DOWN:
			log_msg("Stairs lead down.")
		Tiles.STAIRS_UP:
			if depth > 1:
				log_msg("Stairs lead up.")


func _win() -> void:
	turns += 1
	state = State.WON
	var vic := victory_kind()
	if String(vic["id"]) == "by_decree":
		log_msg("The Unwritten Door opens and accepts your seal. You won. That is the problem.", "lore")
	else:
		log_msg("You step through the Unwritten Door, into a dark the Architect never mapped.", "lore")


func victory_kind() -> Dictionary:
	if apotheosis >= APOTHEOSIS_THRESHOLD:
		return {
			"id": "by_decree",
			"title": "Victory: By Decree",
			"epitaph": "You won. That's the problem. The Unwritten Door opens and accepts your seal; a smaller Rex Mundi wears your face.",
		}
	if way_serpent > way_return:
		return {
			"id": "serpent",
			"title": "Victory: The Serpent's Way",
			"epitaph": "You leave by the Serpent's seam—carrying the stolen key, uncounted and unanswered.",
		}
	if way_return > way_serpent:
		return {
			"id": "return",
			"title": "Victory: The Way of Return",
			"epitaph": "You leave by the Way of Return—empty-handed, oriented, and outside the ledger.",
		}
	return {
		"id": "unwritten",
		"title": "You passed through the Unwritten Door.",
		"epitaph": "The Sentinel is unmade and the door the Architect never wrote down stands behind you. Beyond it is a dark that is yours.",
	}


func named_loss() -> Dictionary:
	if player.has_status("false_light") or player.has_status("reckoning"):
		return {
			"id": "gilded",
			"title": "Gilded",
			"epitaph": "The False Light collected in full. Your name is entered in gold ink.",
		}
	if player.has_status("dissolution") or player.has_status("isolation") or player.has_status("exposure") or player.has_status("perception_fog"):
		return {
			"id": "fluent",
			"title": "Fluent",
			"epitaph": "You learned the Dominion's grammar too well; its chains closed before you could step free.",
		}
	return {
		"id": "catalogued",
		"title": "Catalogued",
		"epitaph": "The record closes over you. Another tithe number filed beneath Terra Tenebrae.",
	}


# ---------------------------------------------------------------- persistence

func to_dict() -> Dictionary:
	var fl := {}
	for fid in floors:
		fl[String(fid)] = (floors[fid] as FloorMap).to_dict()
	return {
		"save_version": SAVE_VERSION,
		"content": db.fingerprint(),
		"seed": str(run_seed),
		"depth": depth, "floor_id": floor_id,
		"atlas": atlas.duplicate(true),
		"visited_floors": visited_floors.duplicate(),
		"max_sphere_reached": max_sphere_reached,
		"time": time, "turns": turns,
		"state": int(state), "cause": death_cause,
		"apotheosis": apotheosis, "way_serpent": way_serpent, "way_return": way_return,
		"next_id": next_entity_id,
		"id_known": id_known.duplicate(true),
		"subjugation": subjugation, "contract": contract,
		"contract_progress": contract_progress, "contract_log": contract_log.duplicate(true),
		"id_aliases": id_aliases.duplicate(true),
		"uniques": spawned_uniques.duplicate(),
		"npc_standing": npc_standing.duplicate(true),
		"faction_flags": faction_flags.duplicate(true),
		"npcs_met": npcs_met.duplicate(),
		"threads_state": threads_state.duplicate(true),
		"rng": rng.get_state_string(),
		"player": player.to_dict(),
		"floors": fl,
		"log": messages.duplicate(true),
	}


const _LEGACY_SPINE_IDS := {
	"1": "ossuary_warrens",
	"2": "tithe_vaults",
	"3": "gilded_choir",
	"4": "false_solar_court",
	"5": "iron_scriptorium",
	"6": "chamber_of_decrees",
	"7": "sealed_stair",
}


static func _migrate(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var ver := int(out.get("save_version", -1))
	if ver == 1:
		out["save_version"] = 2
		if typeof(out.get("player")) == TYPE_DICTIONARY:
			out["player"]["mask"] = out["player"].get("mask", "bare_face")
			out["player"]["mask_risk"] = int(out["player"].get("mask_risk", 0))
			if String(out["player"].get("class", "")) == "occultist" and typeof(out["player"].get("traits")) == TYPE_ARRAY:
				if not out["player"]["traits"].has("mask_stances"):
					out["player"]["traits"].append("mask_stances")
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			for k in out["floors"]:
				var fl = out["floors"][k]
				if typeof(fl) == TYPE_DICTIONARY and typeof(fl.get("actors")) == TYPE_ARRAY:
					for a in fl["actors"]:
						if typeof(a) == TYPE_DICTIONARY:
							a["mask"] = a.get("mask", "bare_face")
							a["mask_risk"] = int(a.get("mask_risk", 0))
		ver = 2
	if ver == 2:
		out["save_version"] = 3
		out["apotheosis"] = int(out.get("apotheosis", 0))
		out["way_serpent"] = int(out.get("way_serpent", 0))
		out["way_return"] = int(out.get("way_return", 0))
		ver = 3
	if ver == 3:
		out["save_version"] = 4
		if typeof(out.get("player")) == TYPE_DICTIONARY:
			var p: Dictionary = out["player"]
			p["stat_points"] = int(p.get("stat_points", 0))
			p["talent_points"] = int(p.get("talent_points", 1))
			p["resource"] = int(p.get("resource", 10))
			p["talents"] = p.get("talents", {})
			p["cooldowns"] = p.get("cooldowns", {})
			if String(p.get("species", "")) == "human" and typeof(p.get("traits")) == TYPE_ARRAY:
				if not p["traits"].has("adaptable"):
					p["traits"].append("adaptable")
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			for k in out["floors"]:
				var fl = out["floors"][k]
				if typeof(fl) == TYPE_DICTIONARY and typeof(fl.get("actors")) == TYPE_ARRAY:
					for a in fl["actors"]:
						if typeof(a) == TYPE_DICTIONARY:
							a["stat_points"] = int(a.get("stat_points", 0))
							a["talent_points"] = int(a.get("talent_points", 0))
							a["resource"] = int(a.get("resource", 0))
							a["talents"] = a.get("talents", {})
							a["cooldowns"] = a.get("cooldowns", {})
		ver = 4
	if ver == 4:
		out["save_version"] = 5
		if typeof(out.get("player")) == TYPE_DICTIONARY:
			var p: Dictionary = out["player"]
			p["resists"] = p.get("resists", {})
			p["specials"] = p.get("specials", [])
			p["elite"] = bool(p.get("elite", false))
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			for k in out["floors"]:
				var fl = out["floors"][k]
				if typeof(fl) == TYPE_DICTIONARY and typeof(fl.get("actors")) == TYPE_ARRAY:
					for a in fl["actors"]:
						if typeof(a) == TYPE_DICTIONARY:
							a["resists"] = a.get("resists", {})
							a["specials"] = a.get("specials", [])
							a["elite"] = bool(a.get("elite", false))
		ver = 5
	if ver == 5:
		out["save_version"] = 6
		out["id_known"] = out.get("id_known", {})
		out["id_aliases"] = out.get("id_aliases", {})
		out["uniques"] = out.get("uniques", [])
		if typeof(out.get("player")) == TYPE_DICTIONARY:
			_migrate_actor_items_v6(out["player"])
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			for k in out["floors"]:
				var fl = out["floors"][k]
				if typeof(fl) == TYPE_DICTIONARY:
					if typeof(fl.get("items")) == TYPE_ARRAY:
						for it in fl["items"]:
							_migrate_item_v6(it)
					if typeof(fl.get("actors")) == TYPE_ARRAY:
						for a in fl["actors"]:
							_migrate_actor_items_v6(a)
		ver = 6
	if ver == 6:
		out["save_version"] = 7
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			for k in out["floors"]:
				var fl = out["floors"][k]
				if typeof(fl) == TYPE_DICTIONARY and not fl.has("features"):
					fl["features"] = []
		ver = 7
	if ver == 7:
		out["save_version"] = 8
		out["subjugation"] = int(out.get("subjugation", 0))
		out["contract"] = String(out.get("contract", ""))
		out["contract_progress"] = int(out.get("contract_progress", 0))
		out["contract_log"] = out.get("contract_log", {})
		ver = 8
	if ver == 8:
		out["save_version"] = 9
		var d_str := str(int(out.get("depth", 1)))
		var cur_fid := String(_LEGACY_SPINE_IDS.get(d_str, "ossuary_warrens"))
		out["floor_id"] = String(out.get("floor_id", cur_fid))
		out["atlas"] = out.get("atlas", {})
		out["max_sphere_reached"] = int(out.get("max_sphere_reached", int(out.get("depth", 1))))
		var visited := []
		if typeof(out.get("floors")) == TYPE_DICTIONARY:
			var new_floors := {}
			for k in out["floors"]:
				var fl = out["floors"][k]
				var fid := String(_LEGACY_SPINE_IDS.get(String(k), String(k)))
				if typeof(fl) == TYPE_DICTIONARY:
					fl["floor_id"] = String(fl.get("floor_id", fid))
					if not fl.has("portals"):
						fl["portals"] = []
				new_floors[fid] = fl
				visited.append(fid)
			visited.sort()
			out["floors"] = new_floors
		if not out.has("visited_floors"):
			out["visited_floors"] = visited if not visited.is_empty() else [out["floor_id"]]
		ver = 9
	if ver == 9:
		out["save_version"] = 10
		out["npc_standing"] = out.get("npc_standing", {})
		out["faction_flags"] = out.get("faction_flags", {})
		out["npcs_met"] = out.get("npcs_met", [])
		ver = 10
	if ver == 10:
		out["save_version"] = 11
		if not out.has("threads_state"):
			out["threads_state"] = {"pool": [], "active": {}, "completed": [], "refused": [], "failed": [], "pending": []}
	return out


static func _migrate_item_v6(it: Variant) -> void:
	if typeof(it) != TYPE_DICTIONARY:
		return
	it["rar"] = it.get("rar", "common")
	it["aff"] = it.get("aff", [])
	it["buc"] = it.get("buc", "uncursed")
	it["idn"] = bool(it.get("idn", true))
	it["mods"] = it.get("mods", {})
	it["res"] = it.get("res", {})
	it["dt"] = String(it.get("dt", ""))
	it["st"] = String(it.get("st", ""))


static func _migrate_actor_items_v6(a: Variant) -> void:
	if typeof(a) != TYPE_DICTIONARY:
		return
	if typeof(a.get("inv")) == TYPE_ARRAY:
		for it in a["inv"]:
			_migrate_item_v6(it)
	if typeof(a.get("eq")) == TYPE_DICTIONARY:
		for slot in a["eq"]:
			_migrate_item_v6(a["eq"][slot])


## Rebuilds a run from to_dict() output. Returns null and fills `errors`
## if the data cannot be used; never returns a half-built world.
static func from_dict(content: ContentDB, d: Dictionary, errors: PackedStringArray) -> World:
	if typeof(d) != TYPE_DICTIONARY:
		errors.append("save is not an object")
		return null
	var sv: Variant = d.get("save_version")
	if not (typeof(sv) in [TYPE_INT, TYPE_FLOAT]) or not is_equal_approx(float(sv), roundf(float(sv))):
		errors.append("save version %s is not supported (expected %d)" % [str(Actor._ints(sv)), SAVE_VERSION])
		return null
	var raw_ver := int(sv)
	if raw_ver < 1 or raw_ver > SAVE_VERSION:
		errors.append("save version %s is not supported (expected %d)" % [str(Actor._ints(sv)), SAVE_VERSION])
		return null
	d = _migrate(d)
	for key in ["seed", "depth", "time", "turns", "state", "next_id", "rng", "player", "floors", "log"]:
		if not d.has(key):
			errors.append("save is missing '%s'" % key)
	if not errors.is_empty():
		return null
	errors.append_array(SaveCheck.problems(d, content))
	if not errors.is_empty():
		return null
	var w := World.new()
	w.db = content
	w.run_seed = String(d["seed"]).to_int()
	w.depth = int(d["depth"])
	if w.depth < 1 or w.depth > content.max_depth():
		errors.append("save has out-of-range depth %d" % w.depth)
		return null
	w.floor_id = String(d.get("floor_id", content.spine_floor_id(w.depth)))
	if not content.has("floors", w.floor_id):
		errors.append("save has unknown floor_id '%s'" % w.floor_id)
		return null
	w.atlas = Actor._ints(d.get("atlas", {}))
	for vf in d.get("visited_floors", []):
		w.visited_floors.append(String(vf))
	w.max_sphere_reached = maxi(w.depth, int(d.get("max_sphere_reached", w.depth)))
	w.time = int(d["time"])
	w.turns = int(d["turns"])
	w.state = int(d["state"]) as State
	w.death_cause = String(d.get("cause", ""))
	w.apotheosis = int(d.get("apotheosis", 0))
	w.way_serpent = int(d.get("way_serpent", 0))
	w.way_return = int(d.get("way_return", 0))
	w.next_entity_id = int(d["next_id"])
	w.id_known = d.get("id_known", {}).duplicate(true)
	w.id_aliases = d.get("id_aliases", {}).duplicate(true)
	w.subjugation = int(d.get("subjugation", 0))
	w.contract = String(d.get("contract", ""))
	w.contract_progress = int(d.get("contract_progress", 0))
	w.contract_log = d.get("contract_log", {}).duplicate(true)
	if w.contract != "" and not content.has("contracts", w.contract):
		w.contract = ""
	for u in d.get("uniques", []):
		w.spawned_uniques.append(String(u))
	w.npc_standing = Actor._ints(d.get("npc_standing", {}))
	w.faction_flags = d.get("faction_flags", {}).duplicate(true)
	for mid in d.get("npcs_met", []):
		w.npcs_met.append(String(mid))
	w.threads_state = Actor._ints(d.get("threads_state", {"pool": [], "active": {}, "completed": [], "refused": [], "failed": [], "pending": []}))
	w.rng = Rng.new(0)
	w.rng.set_state_string(String(d["rng"]))
	w.player = Actor.from_dict(d["player"], content)
	for key in d["floors"]:
		var fm := FloorMap.from_dict(d["floors"][key], content)
		if fm.floor_id == "":
			fm.floor_id = String(key)
		w.floors[String(key)] = fm
	if not w.floors.has(w.floor_id):
		errors.append("save has no data for current floor '%s'" % w.floor_id)
		return null
	for msg in d["log"]:
		w.messages.append({"t": String(msg["t"]), "k": String(msg["k"]), "n": int(msg["n"])})
	w.current_floor().actors.insert(0, w.player)
	w.update_fov()
	if String(d.get("content", "")) != content.fingerprint():
		w.log_msg("(This run was saved with different content; it may behave differently.)", "info")
	return w
