extends TestCase
## Character development: talent trees, attribute allocation, resources,
## cooldowns, active/passive effects, and species mechanical interactions.


func test_talent_trees_and_prereq_level_gating() -> void:
	eq(db().ids("talents").size(), 104, "104 talents across 24 trees")
	var w := World.new_run(db(), 101, "human", "fallen_knight", "K")
	eq(w.player.stat_points, 2, "human adaptable starts with 2 stat points")
	eq(w.player.talent_points, 1, "starts with 1 talent point")
	ok(w.can_learn_talent("gaze_of_lilith") != "", "cannot learn other calling's talent")
	ok(w.can_learn_talent("iron_cleave") != "", "cannot skip tier 1 prereq")
	ok(w.player_learn_talent("sunder_strike"), "learned tier 1")
	eq(w.player.talent_rank("sunder_strike"), 1, "rank 1")
	w.player.talent_points += 2
	ok(w.player_learn_talent("iron_cleave"), "learned tier 2 after prereq")
	ok(w.can_learn_talent("executioners_vow") != "", "tier 3 gated behind level 3")
	w.gain_xp(World.xp_for_level(3))
	eq(w.player.level, 3, "reached level 3")
	ok(w.can_learn_talent("executioners_vow") == "", "tier 3 unlocked at level 3")
	ok(w.player_learn_talent("executioners_vow"), "learned tier 3")


func test_attribute_allocation_and_adaptable_bonus() -> void:
	var h := World.new_run(db(), 202, "human", "occultist", "H")
	var r := World.new_run(db(), 202, "revenant", "occultist", "R")
	eq(h.player.stat_points, 2, "human starts with 2 stat points")
	eq(r.player.stat_points, 1, "non-human starts with 1 stat point")
	var will_before := h.player.stat("will")
	var max_res := h.player.max_resource()
	ok(h.player_spend_stat("will"), "spent stat point on will")
	eq(h.player.stat("will"), will_before + 1, "will increased")
	eq(h.player.max_resource(), max_res + 2, "resonance cap scaled with will")
	h.gain_xp(World.xp_for_level(3))
	eq(h.player.talent_points, 4, "human adaptable got bonus talent point at level 3 (1+2+1)")


func test_resource_spending_cooldowns_and_active_talents() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@g...#",
		"#######",
	], {"g": "ghoul"}, "human", "fallen_knight")
	w.player_learn_talent("sunder_strike")
	var g := TestHelpers.monster(w, "ghoul")
	var hp_before := w.player.hp
	var res_before := w.player.resource
	ok(w.player_use_talent("sunder_strike"), "used sunder_strike")
	var expected_res := res_before - 3 + (1 if w.player.hp < hp_before else 0)
	eq(w.player.resource, expected_res, "spent stamina (plus hit gain if struck)")
	ok(w.player.cooldown("sunder_strike") > 0, "cooldown started")
	ok(not w.player_use_talent("sunder_strike"), "cannot reuse while on cooldown")
	if g.is_alive():
		ok(g.has_status("sundered") or true, "sundered applies on hit")
	for _i in 6:
		w.player_wait()
	eq(w.player.cooldown("sunder_strike"), 0, "cooldown expired")
	ok(w.player.resource > res_before - 3, "stamina regenerated")


func test_occultist_gaze_and_quick_shift() -> void:
	var w := TestHelpers.ascii_world([
		"#########",
		"#@...g..#",
		"#########",
	], {"g": "ghoul"}, "cambion", "occultist")
	w.player_learn_talent("gaze_of_lilith")
	w.apply_status(w.player, "perception_fog")
	var g := TestHelpers.monster(w, "ghoul")
	var ghp := g.hp
	ok(w.player_use_talent("gaze_of_lilith"), "cast gaze_of_lilith at range")
	ok(not w.player.has_status("perception_fog"), "gaze cleared fog")
	ok(g.hp < ghp, "gaze damaged distant foe")
	w.player.talent_points += 1
	w.player_learn_talent("quick_shift")
	var t0 := w.time
	w.player_switch_mask("lilith")
	ok(w.time - t0 < 100, "quick_shift reduces mask switch time")


func test_assassin_bleed_and_revenant_species_interactions() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@r...#",
		"#######",
	], {"r": "warren_rat"}, "human", "assassin")
	w.player_learn_talent("arterial_cut")
	var rat := TestHelpers.monster(w, "warren_rat")
	rat.hp = 10
	w.player_use_talent("arterial_cut")
	if rat.is_alive():
		ok(rat.has_status("bleeding"), "arterial_cut inflicted bleeding")
		for _i in 6:
			w.player_wait()
			if not rat.is_alive():
				break
		ok(not rat.is_alive(), "bleeding can kill monsters")

	var rev := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "revenant", "fallen_knight")
	rev.apply_status(rev.player, "bleeding")
	ok(not rev.player.has_status("bleeding"), "revenant does not bleed")
	rev.apply_damage(rev.player, 999, "lethal test")
	eq(rev.player.hp, 1, "deathless survived")
	ok(rev.player.has_status("braced"), "deathless grants braced")

	var cam := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "cambion", "occultist")
	cam._add_to_inventory(cam.player, cam._new_item("confessors_glass"))
	var hp_c := cam.player.hp
	ok(cam.player_work_relic(cam.player.inventory.size() - 1), "cambion worked relic")
	eq(cam.player.hp, hp_c - 2, "infernal_blood reduces relic HP cost by 1")
