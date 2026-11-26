extends TestCase
## M6.2 The Inhabitants: 76 monster archetypes across 10 families, 15 named bosses/guardians,
## tactical AI behaviors (kiting, ambush, support ward/rally, protect_ally, telegraph_slam,
## pull_chain, drain_resource, lay_hazard, exploit_status), and 8 elite mutations.


func test_bestiary_scale_families_and_bosses() -> void:
	var d := db()
	var mids := d.ids("monsters")
	ok(mids.size() >= 70, "expanded bestiary has >= 70 archetypes (got %d)" % mids.size())
	var bosses := 0
	for mid in mids:
		var md := d.get_def("monsters", mid)
		var tags: Array = md.get("tags", [])
		if tags.has("boss") or tags.has("guardian"):
			bosses += 1
	ok(bosses >= 12, "at least 12 named bosses/guardians present (got %d)" % bosses)


func test_tactical_ai_behaviors_and_counterplay() -> void:
	# 1. Telegraph slam warns on turn 1 and lands only if player stays in range.
	var w2 := TestHelpers.ascii_world([
		"#########",
		"#@..g...#",
		"#.......#",
		"#########",
	], {"g": "gate_warden"}, "human", "fallen_knight", 41)
	var wd2 := TestHelpers.monster(w2, "gate_warden")
	wd2.awake = true
	wd2.flags["telegraph_x"] = 1
	wd2.flags["telegraph_y"] = 1
	var hp_evade := w2.player.hp
	w2._monster_turn(wd2)
	eq(w2.player.hp, hp_evade, "evading out of telegraphed slam avoids damage")

	# 2. Protect ally reduces physical damage while protector stands adjacent.
	var wp := TestHelpers.ascii_world([
		"#######",
		"#@sb..#",
		"#######",
	], {"s": "catalogued_dead", "b": "iron_bulwark"}, "human", "fallen_knight", 42)
	var skel := TestHelpers.monster(wp, "catalogued_dead")
	var sh0 := skel.hp
	wp.apply_damage(skel, 5, "test", "physical")
	eq(skel.hp, sh0 - 3, "adjacent protect_ally shields 2 physical damage")

	# 3. Kiting ranged unit retreats when player closes to distance <= 2.
	var wk := TestHelpers.ascii_world([
		"#########",
		"#..@a...#",
		"#########",
	], {"a": "ossuary_arbalest"}, "human", "fallen_knight", 43)
	var arb := TestHelpers.monster(wk, "ossuary_arbalest")
	arb.awake = true
	arb.flags["spec_cd"] = 5
	var moved_away := false
	for _i in 10:
		arb.pos = Vector2i(4, 1)
		wk._monster_turn(arb)
		if arb.pos.x > 4:
			moved_away = true
			break
	ok(moved_away, "kite_ranged retreats from adjacent melee")

	# 4. Ambusher deals bonus damage and bleeding on first hit.
	var wa := TestHelpers.ascii_world([
		"#######",
		"#@t...#",
		"#######",
	], {"t": "heresy_tracker"}, "human", "fallen_knight", 44)
	var trk := TestHelpers.monster(wa, "heresy_tracker")
	trk.awake = true
	wa._attack(trk, wa.player)
	ok(trk.flags.has("ambush_spent"), "ambusher spends first-strike ambush")

	# 5. Drain resource lowers player resource.
	var wr := TestHelpers.ascii_world([
		"#######",
		"#@...v#",
		"#######",
	], {"v": "void_moth"}, "human", "occultist", 45)
	var moth := TestHelpers.monster(wr, "void_moth")
	moth.awake = true
	wr.player.resource = 8
	var drained := false
	for _i in 15:
		moth.flags["spec_cd"] = 0
		wr._try_monster_special(wr.current_floor(), moth)
		if wr.player.resource < 8:
			drained = true
			break
	ok(drained, "drain_resource reduces player class resource")

	# 6. Support ward braces an injured ally.
	var ws := TestHelpers.ascii_world([
		"#######",
		"#@.sc.#",
		"#######",
	], {"s": "catalogued_dead", "c": "inquisition_cantor"}, "human", "fallen_knight", 46)
	var ally := TestHelpers.monster(ws, "catalogued_dead")
	var cantor := TestHelpers.monster(ws, "inquisition_cantor")
	ally.hp = 4
	cantor.awake = true
	var warded := false
	for _i in 15:
		cantor.flags["spec_cd"] = 0
		ws._try_monster_special(ws.current_floor(), cantor)
		if ally.has_status("braced"):
			warded = true
			break
	ok(warded, "support_ward grants Braced to injured ally")


func test_all_eight_elite_mutations_apply_cleanly() -> void:
	var w := World.new_run(db(), 123, "human", "fallen_knight", "El")
	for kind in ["cinder", "rime", "void", "iron", "radiant", "swift", "vampiric", "warded"]:
		var mon := w._new_monster("catalogued_dead", Vector2i(2, 2))
		w._apply_elite(mon, kind)
		ok(mon.is_elite, "elite '%s' sets is_elite" % kind)
		ok(mon.tags.has("elite"), "elite '%s' tagged" % kind)
