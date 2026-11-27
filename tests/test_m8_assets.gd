extends TestCase
## M8.4 asset registry and provenance validation tests:
## - 100% of species, callings, masks, monsters, NPCs, items, statuses,
##   talent trees, institutions, and contracts resolve to valid in-bounds rects.
## - Every asset atlas is tracked in asset_provenance.json with complete metadata.
## - Missing registry entries degrade gracefully.


func test_complete_content_asset_coverage_and_bounds() -> void:
	var reg := AssetRegistry.new()
	var errs := reg.validate(db(), true)
	if not errs.is_empty():
		for e in errs:
			fail(e)
	eq(errs.size(), 0, "100% of content entities map to valid in-bounds atlas regions")


func test_asset_provenance_complete_and_valid() -> void:
	var reg := AssetRegistry.new()
	var perrs := reg.validate_provenance()
	if not perrs.is_empty():
		for e in perrs:
			fail(e)
	eq(perrs.size(), 0, "every asset has complete provenance metadata")


func test_all_15_bosses_18_npcs_16_relics_and_emblems_resolve() -> void:
	var reg := AssetRegistry.new()
	var seen_boss_rects := {}
	for mid in db().ids("monsters"):
		var md := db().get_def("monsters", mid)
		if (md.get("tags", []) as Array).has("boss") or bool(md.get("unique", false)):
			var a := Actor.new()
			a.template_id = mid
			var r := reg.actor_region(a, db())
			ok(not r.is_empty(), "boss '%s' resolves" % mid)
			seen_boss_rects[str(r.get("rect", Rect2()))] = true
	ok(seen_boss_rects.size() >= 15, "all 15 bosses have distinct bespoke rects (got %d)" % seen_boss_rects.size())

	var seen_npc_rects := {}
	for nid in db().ids("npcs"):
		var nr := reg.npc_region(nid)
		ok(not nr.is_empty(), "NPC '%s' resolves" % nid)
		seen_npc_rects[str(nr.get("rect", Rect2()))] = true
	eq(seen_npc_rects.size(), 18, "all 18 NPCs have distinct sprites")

	var seen_relic_rects := {}
	for iid in db().ids("items"):
		var d := db().get_def("items", iid)
		if String(d.get("kind", "")) == "relic":
			var it := Item.new()
			it.template_id = iid
			var ir := reg.item_region(it, db())
			ok(not ir.is_empty(), "relic '%s' resolves" % iid)
			seen_relic_rects[str(ir.get("rect", Rect2()))] = true
	eq(seen_relic_rects.size(), 16, "all 16 relics have bespoke sprites")

	for em in ["title_crest", "sphere_1", "sphere_7", "boss_seal", "way_serpent", "way_return", "unwritten_door", "by_decree", "loss_catalogued", "loss_fluent", "loss_gilded"]:
		ok(not reg.emblem_region(em).is_empty(), "emblem '%s' resolves" % em)
