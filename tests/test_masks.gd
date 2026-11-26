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


func test_active_mask_switching_does_not_reset_risk() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	w.player_switch_mask("eris")
	for _i in 4:
		w.player_wait()
	var r := w.player.mask_risk
	ok(r >= 4, "risk accumulated in eris (%d)" % r)
	w.player_switch_mask("nyx")
	ok(w.player.mask_risk >= r, "switching active->active does not cool risk (%d -> %d)" % [r, w.player.mask_risk])


func test_lux_venefica_unlocks_without_naming_and_grants_union_benefits() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	ok(not w.player.is_venefica_unlocked(), "starts locked")
	ok(not w.player_switch_mask(Masks.UNION_ID), "cannot unify before unlock")
	w.player_switch_mask("nyx")
	w.player_switch_mask("eris")
	ok(not w.player.is_venefica_unlocked(), "two masks is not enough")
	w.player_switch_mask("lilith")
	ok(w.player.is_venefica_unlocked(), "all three masks unlock Lux Venefica without gate naming")
	ok(bool(w.player.flags.get("venefica_named_seen", false)), "naming recognition surfaces when all three masks are worn")

	var base_ev := w.player.stat("evasion")
	var base_dmg := w.player.stat("damage_bonus")
	var base_will := w.player.stat("will")
	ok(w.player_switch_mask(Masks.UNION_ID), "unifies into Lux Venefica")
	eq(w.player.mask, Masks.UNION_ID, "wearing Lux Venefica")
	eq(w.player.stat("evasion"), base_ev + 2, "unified evasion includes Nyx +2")
	eq(w.player.stat("damage_bonus"), base_dmg + 2, "unified damage includes Eris +2")
	eq(w.player.stat("will"), base_will, "unified will keeps Lilith +2")
	ok(w.player.resist("void") >= 20 and w.player.resist("fire") >= 20 and w.player.resist("radiant") >= 20, "unified elemental resistances active")

	# Unified cools mask risk and allows natural regeneration
	w.player.mask_risk = 5
	w.player.hp = 5
	for _i in 6:
		w.player_wait()
	ok(w.player.mask_risk < 5, "unified stance cools mask risk")
	ok(w.player.hp > 5, "unified stance does not halt natural regeneration")

	# Unified blocks perception_fog just like Lilith
	w._chain_hit("perception_fog")
	ok(not w.player.has_status("perception_fog"), "unified sight turns perception_fog aside")


func test_lux_venefica_early_unlock_by_name_gate() -> void:
	var w := World.new_run(db(), 303, "human", "occultist", "N")
	ok(not w.player.is_venefica_unlocked(), "locked initially")
	var gate_pos := w.current_floor().down_pos
	ok(gate_pos.x >= 0, "floor 1 has sphere gate")
	w.player.pos = gate_pos
	ok(w.player_descend_gate("by_name"), "traverse Sphere Gate by name")
	ok(w.player.is_venefica_unlocked(), "by_name gate unlocks Lux Venefica early")
	ok(w.player_switch_mask(Masks.UNION_ID), "can immediately unify after early unlock")


func test_lux_venefica_dissociative_fracture_reunification_and_save() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@....#",
		"#######",
	], {}, "human", "occultist")
	w.player_switch_mask("nyx")
	w.player_switch_mask("eris")
	w.player_switch_mask("lilith")

	# 1. False Light -> Lilith (exposure)
	ok(w.player_switch_mask(Masks.UNION_ID), "unify #1")
	w.apply_status(w.player, "false_light")
	eq(w.player.mask, "lilith", "False Light fractures into Lilith")
	ok(w.player.has_status("exposure"), "Lilith seizure applies exposure")
	ok(w.player.mask_seized_turns() > 0, "seized turn timer set")
	ok(not w.player_switch_mask(Masks.UNION_ID), "blocked while False Light / Exposure / seized")

	# Clear statuses & wait out seized timer -> can reunify
	w._remove_status(w.player, "false_light")
	w._remove_status(w.player, "reckoning")
	w._remove_status(w.player, "exposure")
	w.player.set_mask_seized_turns(0)
	ok(w.player_switch_mask(Masks.UNION_ID), "reunifies once free (#2)")

	# 2. Entanglement -> Eris (isolation)
	w._entangle()
	eq(w.player.mask, "eris", "Entanglement fractures into Eris")
	ok(w.player.has_status("isolation"), "Eris seizure applies isolation")
	ok(not w.player_switch_mask(Masks.UNION_ID), "blocked while Entangled")
	w._remove_status(w.player, "entangled")
	w._remove_status(w.player, "isolation")
	w.player.set_mask_seized_turns(0)
	ok(w.player_switch_mask(Masks.UNION_ID), "reunifies once Entanglement clears (#3)")

	# 3. Binding Contract -> Nyx (dissolution)
	var cids := db().ids("contracts")
	ok(cids.size() > 0, "has contracts")
	ok(w.player_sign_contract(String(cids[0])), "accept binding contract")
	eq(w.player.mask, "nyx", "binding contract fractures into Nyx")
	ok(w.player.has_status("dissolution"), "Nyx seizure applies dissolution")

	# 4. Save/load round-trip preserves Lux Venefica & flags cleanly
	w._remove_status(w.player, "dissolution")
	w.player.set_mask_seized_turns(0)
	ok(w.player_switch_mask(Masks.UNION_ID), "reunifies before save (#4)")
	var d := w.to_dict()
	var probs := SaveCheck.problems(d, db())
	eq(probs.size(), 0, "SaveCheck accepts lux_venefica: %s" % ", ".join(probs))
	var json_str := JSON.stringify(d)
	var errs: PackedStringArray = []
	var w2 := World.from_dict(db(), JSON.parse_string(json_str), errs)
	eq(errs.size(), 0, "World.from_dict loads lux_venefica cleanly")
	eq(w2.player.mask, Masks.UNION_ID, "mask preserved after load")
	ok(w2.player.is_venefica_unlocked(), "unlock flag preserved after load")
	ok(w2.player.all_three_masks_worn(), "masks_worn preserved after load")
