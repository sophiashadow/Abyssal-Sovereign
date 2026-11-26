extends TestCase
## Save format: round trip, resumed runs match uninterrupted ones, atomic
## file IO, and rejection of unsupported or corrupt saves.

const TEST_PATH := "user://test_run.save.json"


func _through_json(w: World) -> Dictionary:
	var json := JSON.new()
	json.parse(JSON.stringify(w.to_dict()))
	return json.data


func _reload(w: World) -> World:
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), _through_json(w), errors)
	eq(errors.size(), 0, "no load errors: %s" % ", ".join(errors))
	return w2


func test_v1_save_migrates_to_v2() -> void:
	var w := World.new_run(db(), 4242, "cambion", "occultist", "Mig")
	var d := _through_json(w)
	d["save_version"] = 1
	d["player"].erase("mask")
	d["player"].erase("mask_risk")
	d["player"]["traits"].erase("mask_stances")
	for k in d["floors"]:
		for a in d["floors"][k]["actors"]:
			a.erase("mask")
			a.erase("mask_risk")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v1 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated world loaded")
	if w2 != null:
		eq(w2.player.mask, "bare_face", "default mask applied")
		eq(w2.player.mask_risk, 0, "default mask_risk applied")
		ok(w2.player.has_trait("mask_stances"), "v1 occultist receives mask_stances trait")
		eq(w2.apotheosis, 0, "default apotheosis applied")
		eq(w2.way_serpent, 0, "default way_serpent applied")
		eq(w2.way_return, 0, "default way_return applied")


func test_v2_save_migrates_to_v3() -> void:
	var w := World.new_run(db(), 4242, "human", "assassin", "Mig2")
	var d := _through_json(w)
	d["save_version"] = 2
	d.erase("apotheosis")
	d.erase("way_serpent")
	d.erase("way_return")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v2 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v2 world loaded")
	if w2 != null:
		eq(w2.apotheosis, 0, "default apotheosis")
		eq(w2.way_serpent, 0, "default way_serpent")
		eq(w2.way_return, 0, "default way_return")


func test_v3_save_migrates_to_v4() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Mig3")
	var d := _through_json(w)
	d["save_version"] = 3
	d["player"].erase("stat_points")
	d["player"].erase("talent_points")
	d["player"].erase("resource")
	d["player"].erase("talents")
	d["player"].erase("cooldowns")
	d["player"]["traits"].erase("adaptable")
	for k in d["floors"]:
		for a in d["floors"][k]["actors"]:
			a.erase("stat_points")
			a.erase("talent_points")
			a.erase("resource")
			a.erase("talents")
			a.erase("cooldowns")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v3 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v3 world loaded")
	if w2 != null:
		eq(w2.player.talent_points, 1, "default talent_points applied")
		ok(w2.player.has_trait("adaptable"), "human receives adaptable trait")


func test_v4_save_migrates_to_v5() -> void:
	var w := World.new_run(db(), 4242, "revenant", "occultist", "Mig4")
	var d := _through_json(w)
	d["save_version"] = 4
	d["player"].erase("resists")
	d["player"].erase("specials")
	d["player"].erase("elite")
	for k in d["floors"]:
		for a in d["floors"][k]["actors"]:
			a.erase("resists")
			a.erase("specials")
			a.erase("elite")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v4 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v4 world loaded")
	if w2 != null:
		eq(w2.player.is_elite, false, "default elite flag applied")
		ok(w2.player.specials.is_empty(), "default specials empty")


func test_v5_save_migrates_to_v6() -> void:
	var w := World.new_run(db(), 4242, "human", "assassin", "Mig5")
	var d := _through_json(w)
	d["save_version"] = 5
	d.erase("id_known")
	d.erase("id_aliases")
	d.erase("uniques")
	for it in d["player"]["inv"]:
		for k in ["rar", "aff", "buc", "idn", "mods", "res", "dt", "st"]:
			it.erase(k)
	for slot in d["player"]["eq"]:
		for k in ["rar", "aff", "buc", "idn", "mods", "res", "dt", "st"]:
			d["player"]["eq"][slot].erase(k)
	for k in d["floors"]:
		for it in d["floors"][k]["items"]:
			for fk in ["rar", "aff", "buc", "idn", "mods", "res", "dt", "st"]:
				it.erase(fk)
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v5 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v5 world loaded")
	if w2 != null:
		eq(w2.player.inventory[0].buc, "uncursed", "default buc applied")
		ok(w2.player.inventory[0].identified, "default identified applied")


func test_v6_save_migrates_to_v7() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Mig6")
	var d := _through_json(w)
	d["save_version"] = 6
	for k in d["floors"]:
		d["floors"][k].erase("features")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v6 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v6 world loaded")
	if w2 != null:
		ok(w2.current_floor().features is Array, "features list restored")


func test_v7_save_migrates_to_v8() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Mig7")
	var d := _through_json(w)
	d["save_version"] = 7
	d.erase("subjugation")
	d.erase("contract")
	d.erase("contract_progress")
	d.erase("contract_log")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v7 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null, "migrated v7 world loaded")
	if w2 != null:
		eq(w2.subjugation, 0, "default subjugation applied")
		eq(w2.contract, "", "default contract empty")
		eq(w2.contract_progress, 0, "default contract_progress zero")
		ok(w2.contract_log.is_empty(), "default contract_log empty")


func test_round_trip_is_exact() -> void:
	var w := World.new_run(db(), 4242, "cambion", "occultist", "Rt")
	w.player_spend_stat("will")
	w.player_learn_talent("gaze_of_lilith")
	AutoPlayer.new(w).play(60)
	var w2 := _reload(w)
	eq(JSON.stringify(w2.to_dict()), JSON.stringify(w.to_dict()), "serializes identically after load")


## The strongest save test: a run saved and resumed midway must end exactly
## like the same run played straight through.
func test_resumed_run_matches_uninterrupted_run() -> void:
	for seed_value in [11, 2026, 90001]:
		var straight := World.new_run(db(), seed_value, "human", "fallen_knight", "S")
		AutoPlayer.new(straight).play(400)
		var resumed := World.new_run(db(), seed_value, "human", "fallen_knight", "S")
		AutoPlayer.new(resumed).play(150)
		resumed = _reload(resumed)
		AutoPlayer.new(resumed).play(250)
		eq(JSON.stringify(resumed.to_dict()), JSON.stringify(straight.to_dict()), "seed %d resumed == straight" % seed_value)


func test_save_io_writes_atomically_and_loads() -> void:
	var w := World.new_run(db(), 7, "revenant", "assassin", "Io")
	AutoPlayer.new(w).play(30)
	SaveIO.delete(TEST_PATH)
	eq(SaveIO.save(w, TEST_PATH), OK, "saved")
	ok(SaveIO.exists(TEST_PATH), "file exists")
	ok(not FileAccess.file_exists(TEST_PATH + ".tmp"), "no temp file left behind")
	var errors: PackedStringArray = []
	var w2 := SaveIO.load_world(db(), errors, TEST_PATH)
	ok(w2 != null, "loaded")
	if w2 != null:
		eq(JSON.stringify(w2.to_dict()), JSON.stringify(w.to_dict()), "identical")
	eq(SaveIO.save(w, TEST_PATH), OK, "overwrite works")
	SaveIO.delete(TEST_PATH)
	ok(not SaveIO.exists(TEST_PATH), "deleted")


func _expect_rejected(d: Variant, what: String) -> void:
	var errors: PackedStringArray = []
	var w := World.from_dict(db(), d, errors)
	ok(w == null, "%s: rejected" % what)
	ok(errors.size() > 0, "%s: explained" % what)


func test_unsupported_version_is_rejected() -> void:
	var d := _through_json(World.new_run(db(), 1, "human", "assassin", "V"))
	d["save_version"] = 99
	_expect_rejected(d, "future version")
	d.erase("save_version")
	_expect_rejected(d, "no version")


func test_corrupt_saves_are_rejected_not_crashed() -> void:
	var base := _through_json(World.new_run(db(), 3, "human", "occultist", "C"))
	var cases := {
		"missing player": func(d: Dictionary) -> void: d.erase("player"),
		"player missing hp": func(d: Dictionary) -> void: d["player"].erase("hp"),
		"unknown monster": func(d: Dictionary) -> void: d["floors"]["1"]["actors"][0]["t"] = "not_a_monster",
		"unknown item": func(d: Dictionary) -> void: d["player"]["inv"].append({"id": 999, "t": "nope", "q": 1, "x": 0, "y": 0}),
		"truncated terrain": func(d: Dictionary) -> void: d["floors"]["1"]["tiles"] = "AAAA",
		"floors not an object": func(d: Dictionary) -> void: d["floors"] = [],
		"bad rng": func(d: Dictionary) -> void: d["rng"] = "banana",
		"unknown species": func(d: Dictionary) -> void: d["player"]["species"] = "angel",
		"bad slot": func(d: Dictionary) -> void: d["player"]["eq"]["crown"] = d["player"]["eq"]["weapon"],
		"current floor missing": func(d: Dictionary) -> void: d["depth"] = 3,
		"out-of-range depth": func(d: Dictionary) -> void: d["depth"] = 99,
		"invalid mask": func(d: Dictionary) -> void: d["player"]["mask"] = "bogus",
		"string save_version": func(d: Dictionary) -> void: d["save_version"] = "3",
	}
	for what in cases:
		var d: Dictionary = base.duplicate(true)
		(cases[what] as Callable).call(d)
		_expect_rejected(d, what)


func test_unreadable_file_is_rejected() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{\"save_version\": 1, \"pla")
	f.close()
	var errors: PackedStringArray = []
	ok(SaveIO.load_world(db(), errors, TEST_PATH) == null, "truncated file rejected")
	ok(errors.size() > 0 and errors[0].contains("unreadable"), "explained")
	SaveIO.delete(TEST_PATH)
	errors.clear()
	ok(SaveIO.load_world(db(), errors, TEST_PATH) == null, "missing file")
	eq(errors[0] if errors.size() > 0 else "", "no saved run", "explained")
