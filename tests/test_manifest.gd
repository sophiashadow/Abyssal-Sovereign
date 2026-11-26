extends TestCase
## M6.9 Portable Worldbuilding Manifest:
## Validates schema_version, provenance tags, clean separation of lore vs mechanics,
## internal relationship graph cross-references, ContentDB game_ref validity, and exclusion boundaries.

const MANIFEST_PATH := "res://content/lore/world_manifest.json"
const ALLOWED_PROV := ["canon", "canon_derived", "interpretation", "proposed"]


func test_manifest_schema_crossrefs_and_provenance() -> void:
	ok(FileAccess.file_exists(MANIFEST_PATH), "world_manifest.json exists")
	var raw := FileAccess.get_file_as_string(MANIFEST_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	ok(typeof(parsed) == TYPE_DICTIONARY, "manifest parses as JSON object")
	var m: Dictionary = parsed
	eq(int(m.get("schema_version", 0)), 1, "schema_version == 1")
	eq(String(m.get("world", "")), "FALSE LIGHT / Terra Tenebrae", "world identity")
	eq(String(m.get("source_game", "")), "Abyssal Sovereign", "source_game identity")
	ok((m.get("exclusions", []) as Array).size() >= 4, "explicit exclusion list present")

	var known_ids := {}
	var places: Array = m.get("places", [])
	var insts: Array = m.get("institutions", [])
	var people: Array = m.get("people", [])
	var relics: Array = m.get("relics", [])
	var threads: Array = m.get("threads", [])
	eq(places.size(), 28, "28 places exported")
	eq(insts.size(), 8, "8 institutions exported")
	eq(people.size(), 18, "18 people exported")
	eq(relics.size(), 16, "16 relics exported")
	eq(threads.size(), 24, "24 threads exported")

	var dice_re := RegEx.new()
	dice_re.compile("\\b\\d+d\\d+\\b")

	for sec in [places, insts, people, relics, threads]:
		for e in sec:
			var id_s := String(e.get("id", ""))
			ok(id_s != "" and not known_ids.has(id_s), "unique manifest id %s" % id_s)
			known_ids[id_s] = true
			ok(ALLOWED_PROV.has(String(e.get("provenance", ""))), "valid provenance on %s" % id_s)
			var lore_txt := String(e.get("lore", ""))
			ok(lore_txt != "" and dice_re.search(lore_txt) == null, "lore free of dice mechanics on %s" % id_s)
			var gref: Dictionary = e.get("game_ref", {})
			ok(not gref.is_empty(), "game_ref present on %s" % id_s)
			if gref.has("floor_id"):
				ok(db().has("floors", String(gref["floor_id"])), "valid floor game_ref %s" % String(gref["floor_id"]))
			if gref.has("faction_id"):
				ok(db().has("factions", String(gref["faction_id"])), "valid faction game_ref %s" % String(gref["faction_id"]))
			if gref.has("npc_id"):
				ok(db().has("npcs", String(gref["npc_id"])), "valid npc game_ref %s" % String(gref["npc_id"]))
			if gref.has("item_id"):
				ok(db().has("items", String(gref["item_id"])), "valid item game_ref %s" % String(gref["item_id"]))
			if gref.has("thread_id"):
				ok(db().has("threads", String(gref["thread_id"])), "valid thread game_ref %s" % String(gref["thread_id"]))

	for p in people:
		ok(known_ids.has(String(p["institution_id"])), "person institution ref %s" % String(p["institution_id"]))
		for pid in p.get("place_ids", []):
			ok(known_ids.has(String(pid)), "person place ref %s" % String(pid))

	var rels: Array = m.get("relationships", [])
	ok(rels.size() >= 40, "relationship graph populated (%d edges)" % rels.size())
	for r in rels:
		ok(known_ids.has(String(r.get("from", ""))), "edge from valid: %s" % String(r.get("from", "")))
		ok(known_ids.has(String(r.get("to", ""))), "edge to valid: %s" % String(r.get("to", "")))
		ok(ALLOWED_PROV.has(String(r.get("provenance", ""))), "edge provenance valid")
