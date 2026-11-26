extends TestCase
## M5.5 Metaphysical depth: Eight Chains ability grammar, Subjugation clock,
## Masks/Relics/False Light/Apotheosis/Two Ways interactions, and Divine Contracts.


func test_eight_chains_grammar_and_subjugation_clock() -> void:
	var db := TestHelpers.content()
	for ctag in ["chain_isolation", "chain_fog", "chain_debility", "chain_threat",
			"chain_indulgence", "chain_omnipotence", "chain_degradation", "chain_trivial"]:
		var found := false
		for mid in db.ids("monsters"):
			if (db.get_def("monsters", mid).get("tags", []) as Array).has(ctag):
				found = true
				break
		ok(found, "at least one monster carries %s" % ctag)

	var w := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "human", "fallen_knight", 77)
	var statuses_to_check := ["isolation", "perception_fog", "debility", "dread",
		"false_light", "exposure", "degradation", "demanded"]
	for sid in statuses_to_check:
		w.subjugation = 0
		w._remove_status(w.player, sid)
		w._remove_status(w.player, "false_light")
		w._remove_status(w.player, "reckoning")
		w._remove_status(w.player, "entangled")
		w._chain_hit(sid)
		ok(w.player.has_status(sid), "_chain_hit(%s) applies status" % sid)

	# Clear false_light so the clock isn't cushioned, then drive clock to Entangled.
	w._remove_status(w.player, "false_light")
	w._remove_status(w.player, "entangled")
	w.subjugation = w.chain_limit() - 1
	w._chain_hit("debility")
	ok(w.player.has_status("entangled"), "reaching chain_limit triggers Entangled")
	eq(w.subjugation, w.chain_limit() / 2, "entangle resets subjugation to half limit")

	# Trivial Demand (demanded) blocks passive resource regeneration.
	w.player.resource = 2
	w.apply_status(w.player, "demanded")
	w.turns = 6
	w._tick_cooldowns()
	eq(w.player.resource, 2, "demanded blocks resource regeneration")
	w._remove_status(w.player, "demanded")
	w.turns = 12
	w._tick_cooldowns()
	eq(w.player.resource, 3, "resource regenerates once demanded is cleared")


func test_masks_relics_false_light_apotheosis_and_ways() -> void:
	# Masks: nyx reduces Subjugation gain; lilith blocks chain_fog; eris stops decay.
	var w := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "cambion", "occultist", 19)
	w.player.mask = "nyx"
	w.subjugation = 2
	w._chain_hit("debility")
	eq(w.subjugation, 2, "Nyx mask reduces chain subjugation gain by 1")

	w.player.mask = "lilith"
	w._chain_hit("perception_fog")
	ok(not w.player.has_status("perception_fog"), "Lilith mask blocks Monopolized Sight (chain_fog)")

	w.player.mask = "eris"
	w.subjugation = 3
	w.turns = 10
	w._tick_subjugation()
	eq(w.subjugation, 3, "Eris mask prevents Subjugation decay")
	w.player.mask = "bare_face"
	w.turns = 20
	w._tick_subjugation()
	eq(w.subjugation, 2, "Subjugation decays at turn % 10 without Eris")

	# False Light vs Reckoning & Apotheosis clock acceleration.
	w.subjugation = 1
	w.apply_status(w.player, "false_light")
	w._chain_hit("isolation")
	eq(w.subjugation, 1, "false_light cushions subjugation gain by 1")
	w._remove_status(w.player, "false_light")
	w.apply_status(w.player, "reckoning")
	w._chain_hit("dread")
	eq(w.subjugation, 3, "reckoning accelerates subjugation gain (+2)")
	w._remove_status(w.player, "reckoning")

	w.apotheosis = 4
	w._update_allegiance()
	ok(w.player.has_status("sovereign_mark"), "apotheosis >= 4 grants Sovereign's Mark")
	w.subjugation = 0
	w._chain_hit("degradation")
	eq(w.subjugation, 2, "apotheosis >= 4 accelerates subjugation gain (+2)")
	w.apotheosis = 0
	w._update_allegiance()

	# Relics: Broken Halo turns chains aside; Severed Crown blocks & clears Entangled.
	w.subjugation = 1
	w.apply_status(w.player, "halo_aegis")
	w._chain_hit("exposure")
	ok(not w.player.has_status("exposure"), "Broken Halo ward turns chains aside")
	eq(w.subjugation, 1, "Broken Halo keeps subjugation unchanged")
	w._remove_status(w.player, "halo_aegis")

	w.apply_status(w.player, "crown_decree")
	w.subjugation = w.chain_limit() - 1
	w._chain_hit("debility")
	ok(not w.player.has_status("entangled"), "Severed Crown ward refuses Entangled")
	w._remove_status(w.player, "crown_decree")

	w.apply_status(w.player, "entangled")
	w.subjugation = 4
	var crown := w._new_item("severed_crown")
	w.player.inventory.append(crown)
	var crown_idx := w.player.inventory.size() - 1
	ok(w.player_use(crown_idx), "used Severed Crown relic")
	ok(not w.player.has_status("entangled"), "working Severed Crown clears Entangled")
	eq(w.subjugation, 0, "working Severed Crown resets Subjugation to 0")

	# Two Ways: Return raises chain_limit & grants return_oriented; Serpent grants serpents_seam.
	var base_limit := w.chain_limit()
	w.way_return = 2
	w.way_serpent = 0
	w._update_allegiance()
	ok(w.player.has_status("return_oriented"), "Way of Return >= 2 grants Return-Oriented")
	eq(w.chain_limit(), base_limit + 2, "Return-Oriented raises chain_limit by 2")

	var crit_before := w.player.stat("crit")
	w.way_return = 0
	w.way_serpent = 2
	w._update_allegiance()
	ok(w.player.has_status("serpents_seam"), "Serpent's Way >= 2 grants Serpent's Seam")
	ok(w.player.stat("crit") >= crit_before + 8, "Serpent's Seam boosts crit chance")
	ok(w.player.resist("void") >= 15, "Serpent's Seam grants void resist")


func test_divine_contracts_sign_attest_fulfil_and_breach() -> void:
	var w := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#...#",
		"#####",
	], {}, "human", "fallen_knight", 31)
	var m := w.current_floor()
	var lectern_pos := Vector2i(2, 1)
	var circle1 := Vector2i(2, 2)
	var circle2 := Vector2i(1, 2)
	m.features.append({"kind": "contract_lectern", "sub": "rites", "x": lectern_pos.x, "y": lectern_pos.y, "revealed": true, "used": false})
	m.features.append({"kind": "ritual_circle", "sub": "circle", "x": circle1.x, "y": circle1.y, "revealed": true, "used": false})
	m.features.append({"kind": "ritual_circle", "sub": "circle", "x": circle2.x, "y": circle2.y, "revealed": true, "used": false})

	var will0: int = int(w.player.base["will"])
	var hp0 := w.player.stat("max_hp")

	# Sign The Fast via lectern, attest twice via ritual circles -> fulfilled.
	ok(w.player_interact(lectern_pos, "sign:the_fast"), "signed The Fast at lectern")
	eq(w.contract, "the_fast", "active contract set to the_fast")
	ok(w.player.has_status("boon_fast"), "signing grants Boon of the Fast")
	ok(not w.player_sign_contract("vow_of_poverty"), "cannot hold two contracts at once")

	ok(w.player_interact(circle1, "attest"), "attested contract at first ritual circle")
	eq(w.contract_progress, 1, "attest increments contract_progress")
	ok(w.player_interact(circle2, "attest"), "attested contract at second ritual circle")
	eq(w.contract, "", "contract cleared on fulfilment")
	eq(String(w.contract_log.get("the_fast", "")), "fulfilled", "contract logged as fulfilled")
	ok(not w.player.has_status("boon_fast"), "temporary boon replaced by permanent reward")
	eq(int(w.player.base["will"]), will0 + 1, "reward_mods grants permanent +1 will")
	eq(w.player.stat("max_hp"), hp0 + 3, "reward_mods grants permanent +3 max_hp")
	eq(w.way_return, 1, "Return contract fulfilment adds +1 way_return")

	# Forsake Vow of Poverty via lectern -> Forsworn.
	ok(w.player_interact(lectern_pos, "sign:vow_of_poverty"), "signed Vow of Poverty")
	ok(w.player.has_status("boon_poverty"), "signing grants Boon of Poverty")
	ok(w.player_interact(lectern_pos, "forsake"), "forsook Vow of Poverty")
	eq(w.contract, "", "contract cleared after forsake")
	eq(String(w.contract_log.get("vow_of_poverty", "")), "broken", "forsaken contract marked broken")
	ok(not w.player.has_status("boon_poverty"), "boon removed on forsake")
	ok(w.player.has_status("forsworn"), "forsake inflicts Forsworn")

	# Fresh world: breach The Fast by drinking a healing salve.
	var w2 := TestHelpers.ascii_world([
		"#####",
		"#@..#",
		"#####",
	], {}, "human", "fallen_knight", 32)
	ok(w2.player_sign_contract("the_fast"), "signed The Fast on w2")
	w2.player.inventory.append(w2._new_item("healing_salve"))
	w2.player.hp = maxi(1, w2.player.hp - 5)
	ok(w2.player_use(w2.player.inventory.size() - 1), "used healing salve while fasting")
	eq(w2.contract, "", "drinking healing item breaks The Fast")
	eq(String(w2.contract_log.get("the_fast", "")), "broken", "broken oath recorded in contract_log")
	ok(w2.player.has_status("forsworn"), "oath breach inflicts Forsworn")


func test_metaphysics_save_round_trip() -> void:
	var w := World.new_run(TestHelpers.content(), 5555, "human", "fallen_knight", "MetaSave")
	w.subjugation = 4
	w.way_serpent = 2
	w.apotheosis = 4
	ok(w.player_sign_contract("the_taken_name"), "signed The Taken Name")
	w.contract_progress = 1
	w.contract_log["the_fast"] = "fulfilled"
	w._update_allegiance()

	var json_str := JSON.stringify(w.to_dict())
	var parsed: Variant = JSON.parse_string(json_str)
	ok(typeof(parsed) == TYPE_DICTIONARY, "serialized dict parses")
	var problems := SaveCheck.problems(parsed, TestHelpers.content())
	eq(problems.size(), 0, "SaveCheck reports zero problems: %s" % ", ".join(problems))

	var errors: PackedStringArray = []
	var w2 := World.from_dict(TestHelpers.content(), parsed, errors)
	eq(errors.size(), 0, "World.from_dict loads cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "loaded world not null")
	if w2 != null:
		eq(w2.subjugation, 4, "subjugation preserved")
		eq(w2.contract, "the_taken_name", "contract preserved")
		eq(w2.contract_progress, 1, "contract_progress preserved")
		eq(String(w2.contract_log.get("the_fast", "")), "fulfilled", "contract_log preserved")
		eq(JSON.stringify(w2.to_dict()), json_str, "save round-trip matches identically")
