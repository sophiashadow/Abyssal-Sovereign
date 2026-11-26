extends TestCase


func _fresh() -> ContentDB:
	var d := ContentDB.new()
	d.load_pack(ContentDB.CORE_PACK)
	return d


func _errors_with(d: ContentDB, needle: String) -> bool:
	for e in d.errors:
		if e.contains(needle):
			return true
	return false


func test_core_content_is_valid() -> void:
	var d := db()
	if not d.is_valid():
		for e in d.errors:
			fail(e)
	ok(d.is_valid(), "core content validates")
	eq(d.warnings.size(), 0, "no warnings in core content: %s" % str(d.warnings))
	for kind in ContentSchema.KINDS:
		ok(d.ids(kind).size() > 0, "%s has entries" % kind)
	eq(d.max_depth(), 3, "three floors")


func test_required_content_present() -> void:
	var d := db()
	for id in ["human", "revenant", "cambion"]:
		ok(d.has("species", id), "species " + id)
	for id in ["fallen_knight", "occultist", "assassin"]:
		ok(d.has("classes", id), "class " + id)
	for id in ["warren_rat", "catalogued_dead", "false_sun_cultist", "ghoul", "preliator_sentinel"]:
		ok(d.has("monsters", id), "monster " + id)


func test_missing_field_and_bad_types_are_reported() -> void:
	var d := _fresh()
	d.load_text(JSON.stringify({"schema": "monsters", "version": 1, "entries": [
		{"id": "bad_beast", "name": "x", "glyph": "xx", "color": "red", "description": "",
		 "hp": 0, "damage": "d6", "accuracy": 0, "evasion": 0, "defense": 0, "speed": 100, "perception": 5}]}), "fixture.json")
	d.validate()
	ok(_errors_with(d, "missing required field 'xp'"), "missing xp reported")
	ok(_errors_with(d, "field 'glyph' must be exactly one character"), "glyph reported")
	ok(_errors_with(d, "field 'color' must be a color"), "color reported")
	ok(_errors_with(d, "field 'damage' must be dice"), "dice reported")
	ok(_errors_with(d, "field 'hp' must be >= 1"), "min reported")
	ok(_errors_with(d, "fixture.json"), "diagnostic names the file")
	ok(_errors_with(d, "'bad_beast'"), "diagnostic names the entry")


func test_bad_references_are_reported() -> void:
	var d := _fresh()
	d.load_text(JSON.stringify({"schema": "classes", "version": 1, "entries": [
		{"id": "ghost_class", "name": "Ghost", "description": "", "attributes": {"might": 1, "luck": 2},
		 "hp": 5, "hp_per_level": 1, "starting_equipment": ["no_such_item"], "traits": ["flying"]}]}), "fixture.json")
	d.validate()
	ok(_errors_with(d, "references unknown items id 'no_such_item'"), "bad item ref")
	ok(_errors_with(d, "not a known trait"), "bad trait")
	ok(_errors_with(d, "unknown stat 'luck'"), "bad attribute")


func test_structural_errors_are_reported() -> void:
	var d := _fresh()
	d.load_text("{not json", "broken.json")
	d.load_text(JSON.stringify({"schema": "spells", "version": 1, "entries": []}), "spells.json")
	d.load_text(JSON.stringify({"schema": "items", "version": 9, "entries": []}), "future.json")
	d.load_text(JSON.stringify({"schema": "items", "version": 1, "entries": [
		{"id": "dupe", "name": "a", "glyph": "!", "color": "#ffffff", "kind": "consumable", "description": "", "effect": "heal"},
		{"id": "dupe", "name": "b", "glyph": "!", "color": "#ffffff", "kind": "consumable", "description": "", "effect": "heal", "heal": "1d4"}]}), "dupes.json")
	d.validate()
	ok(_errors_with(d, "broken.json:1: invalid JSON"), "invalid json")
	ok(_errors_with(d, "unknown schema 'spells'"), "unknown schema")
	ok(_errors_with(d, "schema version 9 is not supported"), "version")
	ok(_errors_with(d, "duplicate id 'dupe'"), "duplicate")
	ok(_errors_with(d, "effect 'heal' requires field 'heal'"), "conditional rule")


func test_pack_override_warns_and_replaces() -> void:
	var d := _fresh()
	d.load_text(JSON.stringify({"schema": "monsters", "version": 1, "entries": [
		{"id": "warren_rat", "name": "giant warren rat", "glyph": "R", "color": "#b79555", "description": "Bigger.",
		 "hp": 9, "damage": "1d4", "accuracy": 0, "evasion": 1, "defense": 0, "speed": 120, "xp": 4, "perception": 6}]}), "mypack/monsters.json")
	d.validate()
	ok(d.is_valid(), "override is valid: %s" % str(d.errors))
	eq(String(d.get_def("monsters", "warren_rat")["name"]), "giant warren rat", "override applied")
	ok(d.warnings.size() == 1 and d.warnings[0].contains("overrides"), "override is announced")


func test_schema_doc_lists_every_field() -> void:
	var doc := FileAccess.get_file_as_string("res://docs/CONTENT_SCHEMA.md")
	ok(doc != "", "docs/CONTENT_SCHEMA.md exists")
	for kind in ContentSchema.KINDS:
		ok(doc.contains("## " + kind), "doc has section for " + kind)
		for field in ContentSchema.FIELDS[kind]:
			ok(doc.contains("`%s`" % field), "doc mentions %s.%s" % [kind, field])
	for t in Traits.KNOWN:
		ok(doc.contains("`%s`" % t), "doc mentions trait " + t)
