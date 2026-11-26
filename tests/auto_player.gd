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
	if p.hp * 3 < p.stat("max_hp"):
		var heal := _find_consumable("heal")
		if heal >= 0:
			return world.player_use(heal)
	for d in Grid.DIRS_8:
		var a := m.actor_at(p.pos + d)
		if a != null and a != p and m.can_step(p.pos, a.pos):
			if a.unique and not p.has_status("false_light") and not p.has_status("reckoning"):
				var vial := _find_consumable("status")
				if vial >= 0:
					return world.player_use(vial)
			return world.player_move(d)
	if m.get_tile(p.pos) == Tiles.STAIRS_DOWN:
		if world.can_rest():
			return world.player_rest(200) > 0
		return world.player_stairs()
	if p.hp * 10 < p.stat("max_hp") * 7 and world.can_rest():
		return world.player_rest(50) > 0
	var upgrade := _find_upgrade()
	if upgrade >= 0:
		return world.player_use(upgrade)
	if not m.items_at(p.pos).is_empty() and world._can_carry(p, m.items_at(p.pos)[0]):
		return world.player_pickup()
	var target := _nearest_visible_hostile()
	if target != null:
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


func _score(it: Item) -> int:
	var d := it.def(world.db)
	match String(d["kind"]):
		"weapon":
			return Dice.max_value(String(d["damage"])) + Dice.min_value(String(d["damage"])) + int(d.get("accuracy", 0))
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
