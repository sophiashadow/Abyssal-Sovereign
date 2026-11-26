extends TestCase
## M6.5 People, Institutions and Allegiances:
## 8 two-minded institutions, 18 recurring NPCs, deterministic placement,
## standing & service gating, faction pole shifts, and save v10 round-trip.


func test_factions_and_npcs_catalog_and_determinism() -> void:
	eq(db().ids("factions").size(), 8, "8 institutions defined")
	eq(db().ids("npcs").size(), 18, "18 recurring NPCs defined")
	var w1 := World.new_run(db(), 6501, "human", "occultist", "N1")
	var w2 := World.new_run(db(), 6501, "human", "occultist", "N2")
	var npcs1: Array = []
	var npcs2: Array = []
	for f in w1.current_floor().features:
		if String(f.get("kind", "")) == "npc":
			npcs1.append(f)
	for f in w2.current_floor().features:
		if String(f.get("kind", "")) == "npc":
			npcs2.append(f)
	ok(not npcs1.is_empty(), "at least one NPC placed deterministically on floor 1")
	eq(JSON.stringify(npcs1), JSON.stringify(npcs2), "same seed places identical NPCs")


func test_npc_interactions_standing_and_faction_poles() -> void:
	var w := World.new_run(db(), 6502, "human", "fallen_knight", "Rep")
	var npc_feat := {}
	for f in w.current_floor().features:
		if String(f.get("kind", "")) == "npc":
			npc_feat = f
			break
	ok(not npc_feat.is_empty(), "NPC feature present on floor 1")
	var pos := Vector2i(int(npc_feat["x"]), int(npc_feat["y"]))
	w.player.pos = pos
	var nid := String(npc_feat["sub"])
	var ndef := db().get_def("npcs", nid)
	var fid := String(ndef["faction"])
	ok(w.player_interact(pos, "talk"), "talked with NPC")
	ok(w.npcs_met.has(nid), "NPC recorded in npcs_met")
	ok(w.player_interact(pos, "pledge"), "aligned with NPC institution pole")
	eq(w.faction_pole_of(fid), String(ndef["faction_pole"]), "faction pole updated cleanly without moral scalar")
	eq(w.npc_standing_of(nid), 1, "standing increased by pledging")
	ok(w.player_interact(pos, "service"), "used NPC service")
	eq(w.npc_standing_of(nid), 2, "standing increased again")

	# Refusing repeatedly drops standing to -2 and locks out service on a fresh floor NPC.
	var w_bad := World.new_run(db(), 6503, "human", "fallen_knight", "Refuse")
	var bf := {}
	for f in w_bad.current_floor().features:
		if String(f.get("kind", "")) == "npc":
			bf = f
			break
	var bpos := Vector2i(int(bf["x"]), int(bf["y"]))
	w_bad.player.pos = bpos
	ok(w_bad.player_interact(bpos, "refuse"), "first refusal")
	ok(w_bad.player_interact(bpos, "refuse"), "second refusal")
	ok(w_bad.npc_standing_of(String(bf["sub"])) <= -2, "standing fell to lockout threshold")
	ok(not w_bad.player_interact(bpos, "service"), "hostile/refused NPC denies service")

	# Save v10 round-trip preserves npc_standing, faction_flags, and npcs_met.
	var json_str := JSON.stringify(w.to_dict())
	var errors: PackedStringArray = []
	var w_loaded := World.from_dict(db(), JSON.parse_string(json_str), errors)
	eq(errors.size(), 0, "v10 save loads cleanly: %s" % ", ".join(errors))
	ok(w_loaded != null and w_loaded.npcs_met.has(nid), "npcs_met preserved")
	eq(w_loaded.faction_pole_of(fid), String(ndef["faction_pole"]), "faction pole preserved")
