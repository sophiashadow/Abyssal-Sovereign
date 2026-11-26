extends TestCase
## M6.4 The Armory and Treasury: item counts, affixes, 12 sets, 26 artifacts, 16 relics, and new scrolls.


func test_armory_counts_sets_relics_and_affixes() -> void:
	var item_ids := db().ids("items")
	ok(item_ids.size() >= 150 and item_ids.size() <= 200, "base items within 150-200 (%d)" % item_ids.size())
	var artifacts := 0
	var relics := 0
	var scrolls := 0
	var ranged := 0
	for tid in item_ids:
		var d := db().get_def("items", tid)
		if String(d.get("rarity", "common")) == "artifact":
			artifacts += 1
		if String(d.get("kind", "")) == "relic":
			relics += 1
		elif String(d.get("kind", "")) == "ranged":
			ranged += 1
		elif String(d.get("effect", "")) == "scroll":
			scrolls += 1
	ok(artifacts >= 25 and artifacts <= 35, "artifacts within 25-35 (%d)" % artifacts)
	ok(relics >= 15 and relics <= 20, "relics within 15-20 (%d)" % relics)
	ok(scrolls >= 18, "expanded scrolls (%d)" % scrolls)
	ok(ranged >= 20, "expanded ranged/implements (%d)" % ranged)
	eq(ItemSets.SETS.size(), 12, "12 equipment sets")
	eq(Affixes.PREFIXES.size() + Affixes.SUFFIXES.size(), 46, "46 procedural affixes")
	# Every prefix and suffix applies cleanly without type errors.
	for pid in Affixes.PREFIXES:
		var tmp := Item.new()
		Affixes.apply_affix(tmp, String(pid))
	for sid in Affixes.SUFFIXES:
		var tmp := Item.new()
		Affixes.apply_affix(tmp, String(sid))
	ok(true, "all 46 affixes apply cleanly")


func test_all_new_sets_relics_and_scrolls_work() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@...g#",
		"#.....#",
		"#######",
	], {"g": "ghoul"}, "human", "fallen_knight", 21)
	# Test Preliator Bastion 3pc adds +1 Subjugation limit.
	var base_limit := w.chain_limit()
	for tid in ["bastion_mace", "bastion_brigandine", "iron_gate_keytag"]:
		w._add_to_inventory(w.player, w._new_item(tid))
		ok(w.player_use(w.player.inventory.size() - 1), "equipped %s" % tid)
	eq(w.chain_limit(), base_limit + 1, "Preliator Bastion 3pc raises Subjugation limit by +1")

	# Test new relic Work vs Transmute (unwritten_ledger_leaf reduces subjugation and adds buff, or transmutes permanently).
	w.subjugation = 4
	var r_idx := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("unwritten_ledger_leaf"))
	ok(w.player_work_relic(r_idx), "worked unwritten_ledger_leaf")
	ok(w.player.has_status("unwritten_ledger_work"), "work status applied")
	eq(w.subjugation, 2, "unwritten_ledger_leaf work eased Subjugation by 2")

	var will_before := w.player.stat("will")
	ok(w.player_transmute_relic(r_idx), "transmuted unwritten_ledger_leaf")
	eq(w.player.stat("will"), will_before + 1, "transmute permanently raised Will")

	# Test new scroll spells (chain_break & sanctify/consecrate_tile & reclaim_vigor).
	w.subjugation = 3
	w.apply_status(w.player, "debility")
	var sc_idx := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("scroll_of_chain_break"))
	ok(w.player_use(sc_idx), "used scroll_of_chain_break")
	eq(w.subjugation, 1, "scroll_of_chain_break reduced Subjugation")
	ok(not w.player.has_status("debility"), "scroll_of_chain_break cleared debility")

	var sc2 := w.player.inventory.size()
	w._add_to_inventory(w.player, w._new_item("scroll_of_consecrate_tile"))
	ok(w.player_use(sc2), "used scroll_of_consecrate_tile")
	eq(w.current_floor().get_tile(w.player.pos), Tiles.SANCTUARY_FLOOR, "consecrate_tile drew sanctuary floor underfoot")
