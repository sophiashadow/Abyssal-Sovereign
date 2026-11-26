extends TestCase
## Seven Spheres, Sphere Gates, Two Ways, and the Apotheosis Guard.


func test_seven_spheres_all_reachable_and_descendable() -> void:
	var w := World.new_run(db(), 1337, "human", "fallen_knight", "Sph")
	eq(db().max_depth(), 7, "seven spheres defined")
	var methods := ["stormed", "serpents_key", "given_back", "by_name", "stormed", "given_back"]
	for i in methods.size():
		var m := w.current_floor()
		w.player.pos = m.down_pos
		w.player.hp = w.player.stat("max_hp")
		ok(w.needs_gate_to_descend(), "depth %d requires gate" % w.depth)
		ok(w.player_descend_gate(methods[i]), "descended via %s" % methods[i])
		eq(w.depth, i + 2, "arrived at depth %d" % (i + 2))
		ok(not w.needs_gate_to_descend(), "already at down or sealed door")
	var deepest := w.current_floor()
	eq(deepest.get_tile(deepest.exit_pos), Tiles.DOOR_SEALED, "depth 7 holds the sealed door")


func test_apotheosis_guard_halts_xp_and_triggers_by_decree_win() -> void:
	var w := World.new_run(db(), 77, "human", "occultist", "Decree")
	w.apotheosis = World.APOTHEOSIS_THRESHOLD
	var xp_before := w.player.xp
	w.gain_xp(100)
	eq(w.player.xp, xp_before, "apotheosis guard halts XP gain")
	ok(w.player.flags.has("apotheosis_warned"), "apotheosis warning flagged")
	eq(String(w.victory_kind()["id"]), "by_decree", "high apotheosis gives By Decree victory")


func test_two_ways_and_balanced_victory_families() -> void:
	var w := World.new_run(db(), 88, "cambion", "assassin", "Ways")
	eq(String(w.victory_kind()["id"]), "unwritten", "balanced start gives unwritten victory")
	w.way_serpent = 2
	w.way_return = 1
	eq(String(w.victory_kind()["id"]), "serpent", "serpent majority gives Serpent's Way")
	w.way_return = 3
	eq(String(w.victory_kind()["id"]), "return", "return majority gives Way of Return")
	w.apotheosis = World.APOTHEOSIS_THRESHOLD
	eq(String(w.victory_kind()["id"]), "by_decree", "apotheosis overrides ways with By Decree")
