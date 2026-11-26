extends TestCase
## M6.3 Origins and Callings: 8 origins, 8 callings, 104 talents,
## origin/calling traits, ward_sigil, place_snare, and save round-trips.


func test_eight_origins_eight_callings_and_talent_count() -> void:
	var d := db()
	eq(d.ids("species").size(), 8, "8 origins defined")
	eq(d.ids("classes").size(), 8, "8 callings defined")
	ok(d.ids("talents").size() >= 100, "at least 100 talents defined (got %d)" % d.ids("talents").size())
	for cid in d.ids("classes"):
		var count := 0
		var trees := {}
		for tid in d.ids("talents"):
			var td := d.get_def("talents", tid)
			if String(td["class_id"]) == cid:
				count += 1
				trees[String(td["tree"])] = true
		ok(count >= 12, "calling '%s' has >= 12 talents (got %d)" % [cid, count])
		eq(trees.size(), 3, "calling '%s' has 3 talent trees" % cid)


func test_new_origin_traits_beyond_stats() -> void:
	# Ash-Marked (cinder_born): immune to embers, burning heals +1 HP instead of draining.
	var wa := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "ashborn", "fallen_knight", 10)
	wa.current_floor().set_tile(Vector2i(2, 1), Tiles.ASH_EMBER)
	var hp_a0 := wa.player.hp
	ok(wa.player_move(Vector2i(1, 0)), "ashborn walks onto embers")
	eq(wa.player.hp, hp_a0, "cinder_born takes no ember damage")
	wa.player.hp = hp_a0 - 3
	wa.apply_status(wa.player, "burning")
	wa._tick_statuses(wa.player)
	eq(wa.player.hp, hp_a0 - 2, "cinder_born heals +1 HP from burning")

	# Veil-Touched (liminal_sight): blocks perception_fog and spots secrets passively.
	var wv := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "veilkin", "occultist", 11)
	wv._chain_hit("perception_fog")
	ok(not wv.player.has_status("perception_fog"), "liminal_sight blocks Monopolized Sight")
	ok(wv._has_keen_sight(), "liminal_sight grants passive keen sight")

	# Iron-Vowed (ledger_forged): immune to Pinned and +1 Subjugation threshold.
	var wi := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "ironbound_ward", "preliator_warden", 12)
	wi.apply_status(wi.player, "pinned")
	ok(not wi.player.has_status("pinned"), "ledger_forged blocks Pinned")
	eq(wi.chain_limit(), World.SUBJUGATION_LIMIT + 1, "ledger_forged raises Subjugation limit by 1")

	# Debt-Sworn (penance_vigor): Chain hit restores +2 resource and +1 HP.
	var wp := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "penitent", "rite_weaver", 13)
	wp.player.hp -= 4
	wp.player.resource = 2
	var hp_p0 := wp.player.hp
	wp._chain_hit("debility")
	eq(wp.player.resource, 4, "penance_vigor restores +2 resource on Chain")
	eq(wp.player.hp, hp_p0 + 1, "penance_vigor restores +1 HP on Chain")


func test_new_callings_ward_sigil_snare_and_save_roundtrip() -> void:
	# Ophite Binder: place_snare traps pursuing foe; summon_ward_sigil ticks adjacent foes.
	var w := TestHelpers.ascii_world([
		"#######",
		"#@...r#",
		"#######",
	], {"r": "warren_rat"}, "unrecorded", "ophite_binder", 14)
	w.player.level = 3
	w.player.talent_points = 3
	w.player.resource = 12
	ok(w.player_learn_talent("place_snare"), "learned place_snare")
	ok(w.player_learn_talent("binder_knack"), "learned binder_knack")
	ok(w.player_learn_talent("ophite_ward"), "learned ophite_ward")
	ok(w.player_use_talent("place_snare"), "Ophite Binder places snare")
	var trap := w.current_floor().feature_at(Vector2i(1, 1))
	eq(String(trap.get("sub", "")), "snare", "snare feature placed")
	# Player steps off snare safely, then moves onto next tile and summons ward.
	ok(w.player_move(Vector2i(1, 0)), "player steps off snare")
	ok(w.player_use_talent("ophite_ward"), "summoned Ophite Ward-Sigil")
	var ward := w.current_floor().feature_at(Vector2i(2, 1))
	eq(String(ward.get("kind", "")), "ward_sigil", "ward_sigil feature recorded")
	var json_str := JSON.stringify(w.to_dict())
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), JSON.parse_string(json_str), errors)
	eq(errors.size(), 0, "new origin/calling save loads cleanly: %s" % ", ".join(errors))
	ok(w2 != null and w2.player.species_id == "unrecorded" and w2.player.class_id == "ophite_binder", "species and class preserved")
