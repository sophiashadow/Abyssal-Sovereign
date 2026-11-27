extends TestCase
## M8.9 narrative presentation and accessibility tests:
## - NarrativeFrames loads localization-ready frames for Opening Descent, all 7 Spheres,
##   Boss Sighting, Gate Threshold, Contract Pact, and Mask Aspect.
## - Proposed lore is never silently promoted to Canon by presentation copy.
## - GameSettings.narrative_banners defaults true and toggles cleanly.


func test_narrative_frames_schema_and_canon_safety() -> void:
	var nf := NarrativeFrames.new()
	nf.load_default()
	ok(bool(nf.data.get("localization_ready", false)), "narrative frames marked localization_ready")
	ok(not String(nf.data.get("canon_policy", "")).is_empty(), "canon_policy documented")

	var op := nf.opening_frame()
	ok(String(op.get("loc_key", "")).begins_with("frame."), "opening_descent has loc_key")
	ok(not String(op.get("title", "")).is_empty(), "opening_descent has title")
	ok(String(op.get("canon_status", "")) != "Canon", "opening framing is Canon-derived, never falsified Canon")

	for sp in range(1, 8):
		var sf := nf.sphere_frame(sp)
		ok(String(sf.get("loc_key", "")).begins_with("frame.sphere."), "sphere %d has loc_key" % sp)
		ok(not String(sf.get("title", "")).is_empty(), "sphere %d has title" % sp)
		ok(not String(sf.get("subtitle", "")).is_empty(), "sphere %d has subtitle" % sp)
		ok(String(sf.get("canon_status", "")) != "Canon", "sphere %d respects Canon tagging" % sp)

	ok(not nf.boss_kicker().is_empty(), "boss_sighting has kicker")
	for sec in ["boss_sighting", "gate_threshold", "contract_pact", "mask_aspect"]:
		ok(nf.data.has(sec) and String(nf.data[sec].get("loc_key", "")).begins_with("frame."), "%s has loc_key" % sec)


func test_narrative_banners_setting_default_and_toggle() -> void:
	var gs := GameSettings.new()
	eq(gs.narrative_banners, true, "narrative_banners enabled by default")
	gs.narrative_banners = false
	eq(gs.narrative_banners, false, "narrative_banners toggles cleanly")
