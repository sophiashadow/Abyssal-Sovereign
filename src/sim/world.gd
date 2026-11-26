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

const SAVE_VERSION := 3
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
var floors: Dictionary = {} # depth -> FloorMap
var player: Actor
var rng: Rng
var time: int = 0
var turns: int = 0 # player actions taken
var state: State = State.PLAYING
var death_cause: String = ""
var apotheosis: int = 0
var way_serpent: int = 0
var way_return: int = 0
var next_entity_id: int = 2
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
	w._enter_floor(1, true)
	var fd := content.floor_for_depth(1)
	w.log_msg("You descend beneath Terra Tenebrae. %s." % fd.get("name", "The dark"), "lore")
	w.log_msg(String(fd.get("description", "")), "lore")
	w._begin_player_turn()
	return w


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
	a.hp = a.stat("max_hp")
	for tid in cl.get("starting_equipment", []):
		var it := _new_item(String(tid))
		a.equipment[_slot_for(it)] = it
	for tid in cl.get("starting_items", []):
		_add_to_inventory(a, _new_item(String(tid)))
	a.hp = a.stat("max_hp")
	a.awake = true
	return a


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
		"damage": String(d["damage"]), "speed": int(d["speed"]), "sight": 8, "crit": 0,
		"perception": int(d["perception"]),
	}
	a.hp = int(d["hp"])
	a.xp_value = int(d["xp"])
	a.unique = bool(d.get("unique", false))
	for t in d.get("tags", []):
		a.tags.append(String(t))
	return a


func _slot_for(it: Item) -> String:
	match String(it.def(db)["kind"]):
		"weapon":
			return "weapon"
		"armor":
			return "armor"
		"amulet":
			return "amulet"
	return ""


# ---------------------------------------------------------------- floors

func current_floor() -> FloorMap:
	return floors[depth]


func _floor_seed(d: int) -> int:
	return Rng.derive(run_seed, "floor:%d" % d)


func _build_floor(d: int) -> FloorMap:
	var m := DungeonGen.generate(db.floor_for_depth(d), _floor_seed(d))
	for s in m.spawns:
		if s["kind"] == "monster":
			var mon := _new_monster(String(s["id"]), s["pos"])
			mon.next_time = time + rng.range_i(0, 99)
			m.actors.append(mon)
		else:
			var it := _new_item(String(s["id"]))
			it.pos = s["pos"]
			m.items.append(it)
	m.spawns.clear()
	return m


func _enter_floor(d: int, arriving_from_above: bool) -> void:
	if floors.has(depth) and player in current_floor().actors:
		current_floor().actors.erase(player)
	depth = d
	if not floors.has(d):
		floors[d] = _build_floor(d)
	var m := current_floor()
	var target := m.up_pos if arriving_from_above else m.down_pos
	player.pos = _adjacent_free(m, target) if (d == 1 and arriving_from_above) else _nearest_free(m, target)
	m.actors.insert(0, player)
	for a in m.actors:
		if not a.is_player:
			a.next_time = maxi(a.next_time, time + 1)
	_player_dist_pos = Vector2i(-99999, -99999)


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
	if m.get_tile(target) == Tiles.DOOR_SEALED:
		log_msg("The Unwritten Door will not open while its warden stands.", "info")
		return false
	if not m.can_step(player.pos, target):
		return false
	player.pos = target
	_describe_floor_here()
	if m.get_tile(target) == Tiles.DOOR_OPEN:
		_win()
		return true
	return _finish_player_action(COST_MOVE)


func player_wait() -> bool:
	if state != State.PLAYING:
		return false
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
	var shown := it.display_name(db)
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
	log_msg("You drop the %s." % it.display_name(db))
	return _finish_player_action(COST_ITEM)


## Equips or uses the inventory item at `index`, depending on its kind.
func player_use(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) == "consumable":
		_consume(player, it, index)
		return _finish_player_action(COST_ITEM)
	if String(d["kind"]) == "relic":
		return player_work_relic(index)
	var slot := _slot_for(it)
	player.inventory.remove_at(index)
	var old := player.equipped(slot)
	var hp_frac := float(player.hp) / float(player.stat("max_hp"))
	player.equipment[slot] = it
	if old != null:
		player.inventory.insert(index, old)
	# Gear that changes max health keeps the same fraction of health.
	player.hp = clampi(int(roundf(hp_frac * player.stat("max_hp"))), 1, player.stat("max_hp"))
	log_msg("You ready the %s." % it.display_name(db), "good")
	return _finish_player_action(COST_ITEM)


func player_work_relic(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) != "relic":
		return false
	var sid := String(d["work_status"])
	var cost := int(d.get("work_cost_hp", 0))
	if player.has_status(sid):
		log_msg("The %s is already active." % d["name"])
		return false
	if cost > 0 and player.hp <= cost:
		log_msg("You lack the blood to work the %s." % d["name"], "danger")
		return false
	player.hp -= cost
	apotheosis += 1
	apply_status(player, sid)
	if sid == "confessors_clarity" and player.has_status("perception_fog"):
		_remove_status(player, "perception_fog")
		log_msg("The grey fog parts.", "good")
	update_fov()
	var msg := "You work the %s (-%d HP)." % [d["name"], cost] if cost > 0 else "You work the %s." % d["name"]
	log_msg(msg, "good")
	return _finish_player_action(COST_ITEM)


func player_transmute_relic(index: int) -> bool:
	if state != State.PLAYING or index < 0 or index >= player.inventory.size():
		return false
	var it := player.inventory[index]
	var d := it.def(db)
	if String(d["kind"]) != "relic":
		return false
	var mods: Dictionary = d.get("transmute_mods", {})
	for k in mods:
		player.base[k] = int(player.base.get(k, 0)) + int(mods[k])
	if mods.has("max_hp") and int(mods["max_hp"]) > 0:
		player.hp = mini(player.stat("max_hp"), player.hp + int(mods["max_hp"]))
	player.inventory.remove_at(index)
	apotheosis += 2
	way_serpent += 1
	update_fov()
	log_msg("You transmute the %s; its power stays with you." % d["name"], "lore")
	return _finish_player_action(COST_ITEM)


func player_unequip(slot: String) -> bool:
	if state != State.PLAYING:
		return false
	var it := player.equipped(slot)
	if it == null:
		return false
	if player.inventory.size() >= Actor.INVENTORY_LIMIT:
		log_msg("Your pack is full.", "danger")
		return false
	player.equipment.erase(slot)
	player.inventory.append(it)
	player.hp = mini(player.hp, player.stat("max_hp"))
	log_msg("You set aside the %s." % it.display_name(db))
	return _finish_player_action(COST_ITEM)


func needs_gate_to_descend() -> bool:
	return state == State.PLAYING and current_floor().get_tile(player.pos) == Tiles.STAIRS_DOWN and not floors.has(depth + 1)


func player_descend_gate(method: String) -> bool:
	if state != State.PLAYING:
		return false
	if current_floor().get_tile(player.pos) != Tiles.STAIRS_DOWN:
		log_msg("There are no stairs here.")
		return false
	if not GATE_METHODS.has(method):
		return false
	var first_visit := not floors.has(depth + 1)
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
	_enter_floor(depth + 1, true)
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
	var fd := db.floor_for_depth(depth)
	var sphere := String(fd.get("sphere", ""))
	var fname := "%s (%s)" % [fd.get("name", "the next floor"), sphere] if sphere != "" else String(fd.get("name", "the next floor"))
	log_msg("You descend to %s." % fname, "lore")
	log_msg(String(fd.get("description", "")), "lore")
	return _finish_player_action(COST_STAIRS)


## Takes the stairs under the player, if any.
func player_stairs() -> bool:
	if state != State.PLAYING:
		return false
	var t := current_floor().get_tile(player.pos)
	if t == Tiles.STAIRS_DOWN:
		return player_descend_gate("stormed")
	if t == Tiles.STAIRS_UP:
		if depth == 1:
			log_msg("Above is the Architect's daylight. You did not come down here to go back.")
			return false
		_enter_floor(depth - 1, false)
		log_msg("You climb back to %s." % db.floor_for_depth(depth).get("name", "the floor above"), "lore")
		return _finish_player_action(COST_STAIRS)
	log_msg("There are no stairs here.")
	return false


func player_switch_mask(mask_id: String) -> bool:
	if state != State.PLAYING or not player.has_trait("mask_stances") or not Masks.is_valid(mask_id):
		return false
	if player.mask == mask_id:
		return false
	player.mask = mask_id
	if mask_id == "bare_face":
		player.mask_risk = maxi(0, player.mask_risk - 2)
		log_msg("You drop the Mask and wear your Bare Face.", "info")
	else:
		player.mask_risk = maxi(0, player.mask_risk - 3)
		log_msg("You put on %s." % Masks.label(mask_id), "good")
	update_fov()
	return _finish_player_action(COST_WAIT)


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
	_tick_statuses(player)
	_tick_mask()
	_natural_regen()
	update_fov()


func _tick_mask() -> void:
	if turns <= 0 or not player.has_trait("mask_stances"):
		return
	if player.mask == "bare_face":
		player.mask_risk = maxi(0, player.mask_risk - 2)
		return
	player.mask_risk += 1
	if player.mask_risk >= MASK_RISK_MAX:
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
	if turns % interval == 0:
		player.hp += 1


## True when resting is safe: no hostile in view, not isolated, and health not full.
func can_rest() -> bool:
	if state != State.PLAYING or player.has_status("isolation"):
		return false
	return visible_hostiles().is_empty() and player.hp < player.stat("max_hp")


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
		var sd := db.get_def("statuses", s["id"])
		var regen := int(sd.get("regen", 0))
		if regen != 0:
			a.hp = clampi(a.hp + regen, 1, a.stat("max_hp"))
		s["turns"] = int(s["turns"]) - 1
		if int(s["turns"]) <= 0:
			expired.append(String(s["id"]))
	for sid in expired:
		_remove_status(a, sid)
		var sd := db.get_def("statuses", sid)
		if a.is_player:
			log_msg("%s fades." % sd["name"], "info")
		if sd.has("on_expire"):
			apply_status(a, String(sd["on_expire"]))
	a.hp = mini(a.hp, a.stat("max_hp"))


func apply_status(a: Actor, sid: String) -> void:
	var sd := db.get_def("statuses", sid)
	for s in a.statuses:
		if s["id"] == sid:
			s["turns"] = maxi(int(s["turns"]), int(sd["duration"]))
			return
	a.statuses.append({"id": sid, "turns": int(sd["duration"])})
	if a.is_player:
		log_msg("%s: %s" % [sd["name"], sd["description"]], "danger" if sid == "reckoning" else "good")


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
			elif player.mask == "nyx":
				notice_pct = NOTICE_PCT / 2
		if _monster_sees_player(m, mon) and dist <= perc and rng.chance_pct(notice_pct):
			mon.awake = true
			_remember_player(mon)
			log_msg("The %s notices you." % mon.name, "danger")
		return COST_WAIT
	var sees := _monster_sees_player(m, mon)
	if sees:
		_remember_player(mon)
	var fog_cd := int(mon.flags.get("fog_cd", 0))
	if fog_cd > 0:
		mon.flags["fog_cd"] = fog_cd - 1
	if mon.tags.has("chain_fog") and sees and fog_cd <= 0 and not player.has_status("perception_fog") and Grid.chebyshev(mon.pos, player.pos) <= 5 and rng.chance_pct(50):
		mon.flags["fog_cd"] = 8
		apply_status(player, "perception_fog")
		update_fov()
		log_msg("The %s recites a narrowing litany; the dark closes in." % mon.name, "danger")
		return COST_WAIT
	if Grid.is_adjacent(mon.pos, player.pos) and m.can_step(mon.pos, player.pos):
		_remember_player(mon)
		_attack(mon, player)
		return COST_ATTACK
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
		if mon.pos == target and not _monster_sees_player(m, mon):
			_forget_player(mon)
		return COST_MOVE
	return COST_WAIT


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
	var crit_note := " A grievous wound!" if r["crit"] else ""
	log_msg("%s %s %s for %d.%s" % [who, verb, whom, r["damage"], crit_note], "danger" if defender.is_player else "combat")
	apply_damage(defender, int(r["damage"]), attacker.name)
	if not attacker.is_player and defender.is_player and defender.is_alive() and attacker.tags.has("chain_isolation") and not defender.has_status("isolation") and rng.chance_pct(35):
		apply_status(defender, "isolation")


func apply_damage(target: Actor, amount: int, source: String) -> void:
	target.hp -= amount
	if target.hp > 0:
		return
	if target.is_player:
		if target.has_trait("deathless") and not _deathless_spent(target):
			target.flags["deathless_" + str(depth)] = 1
			target.hp = 1
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
	if player.has_trait("soul_siphon") and not player.has_status("isolation"):
		var heal := 1 + maxi(0, player.stat("will"))
		player.hp = mini(player.stat("max_hp"), player.hp + heal)
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
		player.hp = mini(player.stat("max_hp"), player.hp + gain + player.stat("max_hp") / 4)
		log_msg("You reach level %d. (+%d max health%s)" % [player.level, gain, ", +1 accuracy" if player.level % 2 == 1 else ""], "good")


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
			var amount := maxi(1, int(roundf(Dice.roll(String(d["heal"]), rng) * float(sp.get("heal_mult", 1.0)))))
			var before := a.hp
			a.hp = mini(a.stat("max_hp"), a.hp + amount)
			log_msg("You use the %s and recover %d health." % [d["name"], a.hp - before], "good")
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
			return "%s (%s, %d%% to hit). %s%s" % [a.name.capitalize(), cond, Combat.hit_chance(player, a), d["description"], aware]
		var its := m.items_at(p)
		if not its.is_empty():
			return "%s: %s" % [its[0].display_name(db).capitalize(), its[0].def(db)["description"]]
	return "%s." % String(Tiles.NAMES.get(m.get_tile(p), "unknown")).capitalize()


func _describe_floor_here() -> void:
	var its := current_floor().items_at(player.pos)
	if its.size() == 1:
		log_msg("You see here: %s." % its[0].display_name(db))
	elif its.size() > 1:
		log_msg("Several things lie here.")
	match current_floor().get_tile(player.pos):
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
	for d in floors:
		fl[str(d)] = (floors[d] as FloorMap).to_dict()
	return {
		"save_version": SAVE_VERSION,
		"content": db.fingerprint(),
		"seed": str(run_seed),
		"depth": depth, "time": time, "turns": turns,
		"state": int(state), "cause": death_cause,
		"apotheosis": apotheosis, "way_serpent": way_serpent, "way_return": way_return,
		"next_id": next_entity_id,
		"rng": rng.get_state_string(),
		"player": player.to_dict(),
		"floors": fl,
		"log": messages.duplicate(true),
	}


static func _migrate(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var ver := int(out.get("save_version", -1))
	if ver == 1:
		out["save_version"] = 2
		if typeof(out.get("player")) == TYPE_DICTIONARY:
			out["player"]["mask"] = out["player"].get("mask", "bare_face")
			out["player"]["mask_risk"] = int(out["player"].get("mask_risk", 0))
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
	return out


## Rebuilds a run from to_dict() output. Returns null and fills `errors`
## if the data cannot be used; never returns a half-built world.
static func from_dict(content: ContentDB, d: Dictionary, errors: PackedStringArray) -> World:
	if typeof(d) != TYPE_DICTIONARY:
		errors.append("save is not an object")
		return null
	var raw_ver := int(d.get("save_version", -1))
	if raw_ver < 1 or raw_ver > SAVE_VERSION:
		errors.append("save version %s is not supported (expected %d)" % [str(Actor._ints(d.get("save_version"))), SAVE_VERSION])
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
	w.time = int(d["time"])
	w.turns = int(d["turns"])
	w.state = int(d["state"]) as State
	w.death_cause = String(d.get("cause", ""))
	w.apotheosis = int(d.get("apotheosis", 0))
	w.way_serpent = int(d.get("way_serpent", 0))
	w.way_return = int(d.get("way_return", 0))
	w.next_entity_id = int(d["next_id"])
	w.rng = Rng.new(0)
	w.rng.set_state_string(String(d["rng"]))
	w.player = Actor.from_dict(d["player"], content)
	for key in d["floors"]:
		w.floors[int(key)] = FloorMap.from_dict(d["floors"][key], content)
	if not w.floors.has(w.depth):
		errors.append("save has no data for current depth %d" % w.depth)
		return null
	for msg in d["log"]:
		w.messages.append({"t": String(msg["t"]), "k": String(msg["k"]), "n": int(msg["n"])})
	w.current_floor().actors.insert(0, w.player)
	w.update_fov()
	if String(d.get("content", "")) != content.fingerprint():
		w.log_msg("(This run was saved with different content; it may behave differently.)", "info")
	return w
