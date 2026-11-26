extends TestCase
## Mask stances: switching, stat mods, risk accrual, seizures and cooling.


func test_only_mask_stances_trait_can_switch_masks() -> void:
	var knight := World.new_run(db(), 101, "human", "fallen_knight", "K")
	ok(not knight.player_switch_mask("eris"), "knight cannot switch masks")
	var occ := World.new_run(db(), 101, "human", "occultist", "O")
	eq(occ.player.mask, "bare_face", "occultist starts bare_face")
	ok(not occ.player_switch_mask("bare_face"), "switching to current mask is a no-op")
	ok(occ.player_switch_mask("eris"), "occultist switches to eris")
	eq(occ.player.mask, "eris", "mask updated")
	eq(occ.turns, 1, "switching costs 1 turn")


func test_mask_mods_and_sight() -> void:
	var w := World.new_run(db(), 202, "human", "occultist", "O")
	var base_ev := w.player.stat("evasion")
	var base_dmg := w.player.stat("damage_bonus")
	var base_sight := w.player.stat("sight")
	var base_will := w.player.stat("will")
	w.player_switch_mask("nyx")
	eq(w.player.stat("evasion"), base_ev + 2, "nyx +2 evasion")
	w.player_switch_mask("eris")
	eq(w.player.stat("damage_bonus"), base_dmg + 2, "eris +2 damage")
	eq(w.player.stat("evasion"), base_ev, "nyx bonus cleared")
	w.player_switch_mask("lilith")
	eq(w.player.stat("sight"), base_sight + 2, "lilith +2 sight")
	eq(w.player.stat("will"), base_will + 2, "lilith +2 will")


func test_mask_risk_builds_and_triggers_seizure() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	w.player_switch_mask("nyx")
	for _i in World.MASK_RISK_MAX - 1:
		w.player_wait()
	ok(w.player.has_status("dissolution"), "nyx seizes into dissolution")
	eq(w.player.mask, "bare_face", "seizure tears mask back to bare_face")
	eq(w.player.mask_risk, 0, "risk resets after seizure")


func test_bare_face_cools_risk_and_eris_halts_regen() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	w.player.hp = 5
	w.player_switch_mask("eris")
	for _i in 6:
		w.player_wait()
	eq(w.player.hp, 5, "eris halts natural regeneration")
	ok(w.player.mask_risk > 0, "risk built while wearing eris")
	var r := w.player.mask_risk
	w.player_switch_mask("bare_face")
	ok(w.player.mask_risk < r, "bare_face cools risk on switch and wait")
	for _i in 6:
		w.player_wait()
	ok(w.player.hp > 5, "regeneration resumes in bare_face")
