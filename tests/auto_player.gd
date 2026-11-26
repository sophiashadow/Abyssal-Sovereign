class_name AutoPlayer
extends RefCounted
## A deterministic test bot that plays through World's public API only, the
## same calls the UI makes. Its decisions depend on world state alone, so a
## run can be replayed, saved and resumed. It knows the exit's location (a
## cheat the player does not get), which keeps soak runs short.
##
## Priorities: heal when low; fight an adjacent hostile; take stairs it stands
## on; equip better gear it carries; pick up what it stands on; walk toward
## the nearest visible hostile, else toward the exit.

var world: World
var _exit_map := PackedInt32Array()
var _exit_depth := -1


func _init(w: World) -> void:
	world = w


## Takes one action. Returns false if no action spent time (the bot is stuck).
func step() -> bool:
	if world.state != World.State.PLAYING:
		return false
	var p := world.player
	var m := world.current_floor()
	while p.stat_points > 0:
		var attr := "might" if p.class_id == "fallen_knight" else ("will" if p.class_id == "occultist" else "agility")
		if not world.player_spend_stat(attr):
			break
	while p.talent_points > 0:
		if not _learn_next_talent():
			break
	if p.hp * 3 < p.stat("max_hp"):
		var heal := _find_consumable("heal")
		if heal >= 0:
			return world.player_use(heal)
	if p.has_trait("mask_stances"):
		if p.mask != "bare_face" and p.mask_risk >= World.MASK_RISK_MAX - 2:
			return world.player_switch_mask("bare_face")
	for d in Grid.DIRS_8:
		var a := m.actor_at(p.pos + d)
		if a != null and a != p and m.can_step(p.pos, a.pos):
			if a.unique and not p.has_status("false_light") and not p.has_status("reckoning"):
				var vial := _find_consumable("status")
				if vial >= 0:
					return world.player_use(vial)
			if p.has_trait("mask_stances") and p.mask != "eris" and p.mask_risk < World.MASK_RISK_MAX - 3 and not p.has_status("isolation"):
				return world.player_switch_mask("eris")
			if _try_combat_talent(a):
				return true
			return world.player_move(d)
	if p.has_trait("mask_stances") and p.mask != "bare_face" and world.visible_hostiles().is_empty():
		return world.player_switch_mask("bare_face")
	if m.get_tile(p.pos) == Tiles.STAIRS_DOWN:
		if world.can_rest():
			return world.player_rest(200) > 0
		if world.needs_gate_to_descend():
			return world.player_descend_gate("given_back" if world.apotheosis >= World.APOTHEOSIS_THRESHOLD - 2 else "by_name")
		return world.player_stairs()
	if p.hp * 10 < p.stat("max_hp") * 7 and world.can_rest():
		return world.player_rest(50) > 0
	var upgrade := _find_upgrade()
	if upgrade >= 0:
		return world.player_use(upgrade)
	var relic := _find_relic()
	if relic >= 0:
		return world.player_transmute_relic(relic)
	if not m.items_at(p.pos).is_empty() and world._can_carry(p, m.items_at(p.pos)[0]):
		return world.player_pickup()
	var target := _nearest_visible_hostile()
	if target != null:
		if target.is_elite or target.unique or target.tags.has("boss"):
			var proj := _find_consumable("projectile")
			if proj >= 0 and Grid.chebyshev(p.pos, target.pos) <= int(p.inventory[proj].def(world.db).get("range", 4)):
				if world.player_use_at(proj, target.pos):
					return true
		if _try_ranged_talent(target):
			return true
		var rw := p.equipped("ranged")
		if rw != null:
			var r_max := int(rw.def(world.db).get("range", 5))
			var dist := Grid.chebyshev(p.pos, target.pos)
			if dist >= 2 and dist <= r_max and world.projectile_trace(p.pos, target.pos, r_max)["hit_actor"] == target:
				if world.player_fire(target.pos):
					return true
		if p.has_status("pinned"):
			return world.player_wait()
		var d := Pathing.distance_map(m, target.pos)
		var s := Pathing.step_down(m, d, p.pos, func(q: Vector2i) -> bool: return m.actor_at(q) != null and q != target.pos)
		if s != p.pos:
			return world.player_move(s - p.pos)
	if _exit_depth != world.depth:
		_exit_map = Pathing.distance_map(m, m.exit_pos)
		_exit_depth = world.depth
	var s2 := Pathing.step_down(m, _exit_map, p.pos, func(q: Vector2i) -> bool: return m.actor_at(q) != null)
	if s2 != p.pos:
		return world.player_move(s2 - p.pos)
	return world.player_wait()


## Plays until the run ends or `max_actions` actions have been taken.
func play(max_actions: int) -> void:
	for _i in max_actions:
		if not step():
			if world.state != World.State.PLAYING or not world.player_wait():
				return


func _find_consumable(effect: String) -> int:
	for i in world.player.inventory.size():
		var d := world.player.inventory[i].def(world.db)
		if String(d["kind"]) == "consumable" and String(d.get("effect", "")) == effect:
			return i
	return -1


func _find_relic() -> int:
	for i in world.player.inventory.size():
		var d := world.player.inventory[i].def(world.db)
		if String(d["kind"]) == "relic":
			return i
	return -1


func _score(it: Item) -> int:
	var d := it.def(world.db)
	match String(d["kind"]):
		"weapon":
			return Dice.max_value(String(d["damage"])) + Dice.min_value(String(d["damage"])) + int(d.get("accuracy", 0))
		"ranged":
			return Dice.max_value(String(d["damage"])) + Dice.min_value(String(d["damage"])) + int(d.get("range", 4)) + int(d.get("accuracy", 0))
		"armor":
			return int(d.get("defense", 0)) * 3 + int(d.get("evasion", 0))
		"amulet":
			return 1
	return -1


func _find_upgrade() -> int:
	for i in world.player.inventory.size():
		var it := world.player.inventory[i]
		var slot := world._slot_for(it)
		if slot == "":
			continue
		var cur := world.player.equipped(slot)
		if cur == null or _score(it) > _score(cur):
			return i
	return -1


func _nearest_visible_hostile() -> Actor:
	var best: Actor = null
	var best_d := 1 << 30
	for a in world.visible_hostiles():
		var d := Grid.chebyshev(a.pos, world.player.pos)
		if d < best_d:
			best = a
			best_d = d
	return best


func _learn_next_talent() -> bool:
	var p := world.player
	var best_id := ""
	var best_tier := 99
	for tid in world.db.ids("talents"):
		var td := world.db.get_def("talents", tid)
		if String(td["class_id"]) == p.class_id and world.can_learn_talent(tid) == "":
			var t := int(td["tier"])
			if t < best_tier:
				best_tier = t
				best_id = tid
	if best_id != "":
		return world.player_learn_talent(best_id)
	return false


func _can_use_talent(tid: String) -> bool:
	var p := world.player
	if p.talent_rank(tid) <= 0 or p.cooldown(tid) > 0:
		return false
	return p.resource >= int(world.db.get_def("talents", tid).get("cost", 0))


func _try_combat_talent(foe: Actor) -> bool:
	var p := world.player
	if (p.has_status("isolation") or p.has_status("perception_fog") or p.has_status("bleeding")) and _can_use_talent("break_the_chain"):
		return world.player_use_talent("break_the_chain")
	if p.has_status("reckoning") and p.hp * 2 < p.stat("max_hp") and _can_use_talent("transmute_pain"):
		return world.player_use_talent("transmute_pain")
	if p.hp * 2 < p.stat("max_hp"):
		for def_tid in ["unyielding_march", "shield_brace"]:
			if _can_use_talent(def_tid):
				return world.player_use_talent(def_tid)
	for off_tid in ["coup_de_grace", "flurry", "arterial_cut", "sunder_strike", "iron_cleave", "gaze_of_lilith", "siphon_surge", "unmake_record", "defiant_decree"]:
		if _can_use_talent(off_tid):
			return world.player_use_talent(off_tid)
	return false


func _try_ranged_talent(foe: Actor) -> bool:
	var dist := Grid.chebyshev(world.player.pos, foe.pos)
	for tid in ["crippling_shot", "vanguard_charge", "unmake_record", "gaze_of_lilith", "siphon_surge", "shadow_step", "defiant_decree"]:
		if _can_use_talent(tid) and dist <= int(world.db.get_def("talents", tid).get("range", 0)):
			return world.player_use_talent(tid, foe.pos)
	return false
