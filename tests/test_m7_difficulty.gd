extends TestCase
## M7.8 run profiles: Exile is the unchanged balance, profiles change encounter
## and resource generation only, and the profile survives save, load and the
## v11 to v12 migration.

const PROFILES := ["initiate", "exile", "adversary", "sovereign"]


func _through_json(w: World) -> Dictionary:
	var json := JSON.new()
	json.parse(JSON.stringify(w.to_dict()))
	return json.data


func _salves(w: World) -> int:
	var n := 0
	for it in w.player.inventory:
		if it.template_id == "healing_salve":
			n += it.quantity
	return n


func _foes(w: World) -> int:
	var n := 0
	for a in w.current_floor().actors:
		if not a.is_player:
			n += 1
	return n


func test_profiles_exist_in_display_order() -> void:
	eq(Difficulty.ordered(db()), PROFILES, "easiest to hardest")
	ok(Difficulty.is_neutral(Difficulty.profile(db(), "exile")), "Exile is neutral")
	eq(Difficulty.normalise(db(), "no_such_profile"), "exile", "unknown id falls back to Exile")


func test_exile_leaves_floor_definitions_untouched() -> void:
	var fd := db().floor_def("ossuary_warrens")
	var out := Difficulty.apply_to_floor(db(), "exile", fd)
	eq(JSON.stringify(out), JSON.stringify(fd), "Exile floor definition is byte-identical")
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "E")
	var w_exile := World.new_run(db(), 4242, "human", "fallen_knight", "E", "exile")
	var a := _through_json(w)
	var b := _through_json(w_exile)
	a.erase("log")
	b.erase("log")
	eq(JSON.stringify(a), JSON.stringify(b), "default run equals an explicit Exile run")


func test_profiles_change_counts_only_never_stats() -> void:
	var fd := db().floor_def("tithe_vaults")
	var allowed := ["monsters_min", "monsters_max", "items_min", "items_max", "item_table", "group_pct", "elite_delta"]
	for pid in PROFILES:
		var out := Difficulty.apply_to_floor(db(), pid, fd)
		for k in out:
			if not fd.has(k):
				ok(allowed.has(k), "%s adds only %s (saw %s)" % [pid, allowed, k])
			elif JSON.stringify(out[k]) != JSON.stringify(fd[k]):
				ok(allowed.has(k), "%s changes only %s (saw %s)" % [pid, allowed, k])
		eq(JSON.stringify(out["monster_table"]), JSON.stringify(fd["monster_table"]), "%s keeps the monster table" % pid)
		ok(int(out["monsters_min"]) >= 1 and int(out["items_min"]) >= 1, "%s keeps at least one foe and one item" % pid)
	var fd_before := JSON.stringify(fd)
	Difficulty.apply_to_floor(db(), "sovereign", fd)
	eq(JSON.stringify(fd), fd_before, "the source definition is not mutated")


func test_foe_count_rises_with_profile() -> void:
	var totals := {}
	for pid in PROFILES:
		var n := 0
		for s in [101, 202, 303, 404, 505, 606]:
			n += _foes(World.new_run(db(), s, "human", "fallen_knight", "F", pid))
		totals[pid] = n
	ok(totals["initiate"] < totals["exile"], "Initiate meets fewer foes than Exile: %s" % str(totals))
	ok(totals["exile"] < totals["adversary"], "Adversary meets more than Exile: %s" % str(totals))
	ok(totals["adversary"] < totals["sovereign"], "Sovereign meets more than Adversary: %s" % str(totals))


func test_healing_loot_weight_follows_profile() -> void:
	var fd := db().floor_def("ossuary_warrens")
	var base := 0
	for row in fd["item_table"]:
		if row["id"] == "healing_salve":
			base = int(row["weight"])
	var by := {}
	for pid in PROFILES:
		for row in Difficulty.apply_to_floor(db(), pid, fd)["item_table"]:
			if row["id"] == "healing_salve":
				by[pid] = int(row["weight"])
	eq(by["exile"], base, "Exile keeps the authored weight")
	ok(by["initiate"] > base and by["sovereign"] < base and by["sovereign"] >= 1, "weights move the intended way: %s" % str(by))


func test_starting_salves_follow_profile_and_never_go_negative() -> void:
	for cl in db().ids("classes"):
		var base := _salves(World.new_run(db(), 7, "human", cl, "S"))
		eq(_salves(World.new_run(db(), 7, "human", cl, "S", "initiate")), base + 1, "%s Initiate starts with one more salve" % cl)
		eq(_salves(World.new_run(db(), 7, "human", cl, "S", "adversary")), base, "%s Adversary keeps the kit" % cl)
		eq(_salves(World.new_run(db(), 7, "human", cl, "S", "sovereign")), maxi(0, base - 1), "%s Sovereign starts with one fewer, never below none" % cl)


func test_same_seed_and_profile_is_deterministic() -> void:
	for pid in PROFILES:
		var a := _through_json(World.new_run(db(), 31337, "revenant", "rite_weaver", "D", pid))
		var b := _through_json(World.new_run(db(), 31337, "revenant", "rite_weaver", "D", pid))
		eq(JSON.stringify(a), JSON.stringify(b), "%s replays identically" % pid)


func test_profile_round_trips_through_a_save() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Rt", "adversary")
	AutoPlayer.new(w).play(40)
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), _through_json(w), errors)
	eq(errors.size(), 0, "loads: %s" % ", ".join(errors))
	eq(w2.difficulty, "adversary", "profile survives the save")
	eq(JSON.stringify(w2.to_dict()), JSON.stringify(w.to_dict()), "serializes identically after load")
	eq(World.SAVE_VERSION, 12, "save version is 12")


func test_v11_save_migrates_to_exile() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Mig11")
	var d := _through_json(w)
	d["save_version"] = 11
	d.erase("difficulty")
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	eq(errors.size(), 0, "v11 save migrates cleanly: %s" % ", ".join(errors))
	ok(w2 != null and w2.difficulty == "exile", "old runs are Exile runs")


func test_unknown_profile_in_a_save_is_refused_not_guessed() -> void:
	var w := World.new_run(db(), 4242, "human", "fallen_knight", "Bad")
	var d := _through_json(w)
	d["difficulty"] = "nightmare"
	var errors: PackedStringArray = []
	var w2 := World.from_dict(db(), d, errors)
	ok(w2 == null and errors.size() > 0, "refused with a reason")


func test_run_history_records_the_profile() -> void:
	var w := World.new_run(db(), 9, "human", "fallen_knight", "H", "sovereign")
	w.player.hp = 0
	w.state = World.State.DEAD
	var c := Codex.new()
	c.record_run_end(w)
	eq(c.runs.size(), 1, "one run recorded")
	if c.runs.size() == 1:
		eq(String(c.runs[0].get("difficulty", "")), "sovereign", "run history keeps the profile")


func test_every_calling_has_a_signature_tree_with_a_first_talent() -> void:
	for cl in db().ids("classes"):
		var tree := String(db().get_def("classes", cl).get("signature_tree", ""))
		ok(tree != "", "%s names a signature tree" % cl)
		ok(Hints.first_talent(db(), cl) != "", "%s has a first talent in %s" % [cl, tree])
