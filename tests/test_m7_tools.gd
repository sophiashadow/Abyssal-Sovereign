extends TestCase
## M7.1 instrumentation: telemetry never changes a run, every policy is replayable
## from (seed, policy), the soak record has the documented shape, and the report
## aggregates it without touching the simulation.

const M7Soak := preload("res://tools/m7_soak.gd")
const M7Report := preload("res://tools/m7_report.gd")


func _fingerprint(w: World) -> String:
	return "%d|%d|%d|%d|%s|%s" % [w.state, w.turns, w.depth, w.player.hp, w.floor_id, w.rng.get_state_string()]


func test_telemetry_does_not_change_the_run() -> void:
	for pol in ["baseline", "explorer"]:
		var a := World.new_run(db(), 9001, "human", "occultist", "T")
		var b := World.new_run(db(), 9001, "human", "occultist", "T")
		b.telemetry = Telemetry.new()
		PolicyPlayer.new(a, pol).play(500)
		PolicyPlayer.new(b, pol).play(500)
		eq(_fingerprint(a), _fingerprint(b), "%s: telemetry is a pure observer" % pol)
		ok(not b.telemetry.counters.is_empty(), "%s: telemetry recorded something" % pol)


func test_policies_replay_deterministically() -> void:
	for pol in PolicyPlayer.POLICIES:
		var a := World.new_run(db(), 31337, "revenant", "rite_weaver", "T")
		var b := World.new_run(db(), 31337, "revenant", "rite_weaver", "T")
		PolicyPlayer.new(a, pol).play(300)
		PolicyPlayer.new(b, pol).play(300)
		eq(_fingerprint(a), _fingerprint(b), "%s replays identically" % pol)


func test_baseline_policy_matches_legacy_autoplayer() -> void:
	var a := World.new_run(db(), 12345, "human", "fallen_knight", "T")
	var b := World.new_run(db(), 12345, "human", "fallen_knight", "T")
	AutoPlayer.new(a).play(1200)
	PolicyPlayer.new(b, "baseline").play(1200)
	eq(_fingerprint(a), _fingerprint(b), "baseline PolicyPlayer == AutoPlayer")


func test_policies_differ() -> void:
	var seen := {}
	for pol in PolicyPlayer.POLICIES:
		var w := World.new_run(db(), 777, "human", "occultist", "T")
		PolicyPlayer.new(w, pol).play(400)
		seen[_fingerprint(w)] = true
	ok(seen.size() >= 5, "at least five distinct behaviours from eight policies (got %d)" % seen.size())


func test_soak_record_shape_and_seed_pairing() -> void:
	var r1: Dictionary = M7Soak.run_one(db(), "human", "assassin", "baseline", 0, "dev", "unit", 300)
	var r2: Dictionary = M7Soak.run_one(db(), "human", "assassin", "aggressive", 0, "dev", "unit", 300)
	eq(r1["seed"], r2["seed"], "policies share the dungeon seed for a (pair, index)")
	for k in ["pair", "policy", "state", "depth", "level", "turns", "cause", "victory", "floors", "branch_floors", "tel", "set", "salt"]:
		ok(r1.has(k), "record has " + k)
	var r3: Dictionary = M7Soak.run_one(db(), "human", "assassin", "baseline", 1, "dev", "unit", 300)
	ok(r1["seed"] != r3["seed"], "different index gives a different seed")
	var r4: Dictionary = M7Soak.run_one(db(), "human", "assassin", "baseline", 0, "validation", "unit", 300)
	ok(r1["seed"] != r4["seed"], "dev and validation namespaces do not collide")


func test_report_aggregates() -> void:
	var runs: Array = []
	for i in 2:
		runs.append(JSON.parse_string(JSON.stringify(M7Soak.run_one(db(), "human", "fallen_knight", "baseline", i, "dev", "unit", 300))))
	var sm: Dictionary = M7Report.summarize(runs, db())
	eq(sm["runs"], 2, "run count")
	ok(sm["by_policy"].has("baseline"), "policy table")
	ok(sm["coverage"].has("talents_learned"), "coverage table")
	ok(M7Report.to_markdown(sm).contains("M7 soak summary"), "markdown renders")
