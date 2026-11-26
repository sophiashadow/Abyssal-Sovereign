extends TestCase
## M7.2 regression: active talents that no bot policy ever used in the M7.1
## soaks (14 of them, mostly situational cleanses and repositioning). Bot
## silence is not proof they work, so each is driven directly here.

const CLASS_OF := {
	"unyielding_march": "fallen_knight", "unbroken_wall": "preliator_warden",
	"transmute_pain": "occultist", "quiet_absolution": "rite_weaver", "cleanse_vapor": "false_light_alchemist",
	"fade_to_ash": "assassin", "backstep": "assassin", "vault_step": "tithe_marksman",
	"chain_reversal": "rite_weaver", "unwork_chains": "ophite_binder",
	"rite_blink": "rite_weaver", "slip_the_margin": "ophite_binder",
	"volatile_salve": "false_light_alchemist", "philosophers_loan": "false_light_alchemist",
}


func _world(tid: String, rows: Array = ["#######", "#.....#", "#..@..#", "#.....#", "#######"], monsters: Dictionary = {}) -> World:
	var w := TestHelpers.ascii_world(rows, monsters, "human", String(CLASS_OF[tid]))
	w.player.talents[tid] = 1
	w.player.resource = 99
	return w


func test_every_previously_unused_talent_is_defined_and_class_matched() -> void:
	for tid in CLASS_OF:
		ok(db().has("talents", tid), "%s exists" % tid)
		eq(String(db().get_def("talents", tid)["class_id"]), String(CLASS_OF[tid]), "%s belongs to its calling" % tid)
		eq(String(db().get_def("talents", tid)["kind"]), "active", "%s is active" % tid)


func test_heal_and_brace_talents() -> void:
	for tid in ["unyielding_march", "unbroken_wall"]:
		var w := _world(tid)
		w.player.hp = 1
		ok(w.player_use_talent(tid), "%s usable" % tid)
		ok(w.player.hp > 1, "%s mends" % tid)
		ok(w.player.has_status("braced"), "%s braces" % tid)
		ok(w.player.cooldown(tid) > 0, "%s starts a cooldown" % tid)


func test_cleanse_and_heal_talents() -> void:
	for tid in ["transmute_pain", "quiet_absolution", "cleanse_vapor"]:
		var w := _world(tid)
		w.player.hp = 1
		w.apply_status(w.player, "reckoning")
		w.apply_status(w.player, "isolation")
		ok(w.player_use_talent(tid), "%s usable" % tid)
		ok(w.player.hp > 1, "%s heals" % tid)
		ok(not w.player.has_status("reckoning"), "%s clears reckoning" % tid)
		ok(not w.player.has_status("isolation"), "%s clears isolation" % tid)
	var w2 := _world("volatile_salve")
	w2.player.hp = 1
	w2.apply_status(w2.player, "bleeding")
	ok(w2.player_use_talent("volatile_salve"), "volatile_salve usable")
	ok(w2.player.hp > 1 and not w2.player.has_status("bleeding"), "volatile_salve mends and stops bleeding")


func test_chain_breaking_talents() -> void:
	for tid in ["chain_reversal", "unwork_chains"]:
		var w := _world(tid)
		w.apply_status(w.player, "isolation")
		w.apply_status(w.player, "bleeding")
		w.apply_status(w.player, "pinned")
		w.subjugation = 4
		ok(w.player_use_talent(tid), "%s usable" % tid)
		for sid in ["isolation", "bleeding", "pinned"]:
			ok(not w.player.has_status(sid), "%s clears %s" % [tid, sid])
		ok(w.subjugation < 4, "%s lowers Subjugation" % tid)


func test_repositioning_talents() -> void:
	for tid in ["backstep", "vault_step"]:
		var w := _world(tid, ["########", "#.@g...#", "########"], {"g": "ghoul"})
		var before := w.player.pos
		ok(w.player_use_talent(tid), "%s usable" % tid)
		ok(Grid.chebyshev(w.player.pos, TestHelpers.monster(w, "ghoul").pos) >= 1, "%s keeps a legal tile" % tid)
		ok(w.player.pos != before or w.player.has_status("veiled"), "%s moves or veils" % tid)
	var wf := _world("fade_to_ash")
	ok(wf.player_use_talent("fade_to_ash"), "fade_to_ash usable")
	ok(wf.player.has_status("veiled"), "fade_to_ash veils")
	for tid in ["rite_blink", "slip_the_margin"]:
		var w := _world(tid)
		w.apply_status(w.player, "pinned")
		var dest := w._best_blink_tile(w.current_floor(), 4)
		ok(dest.x >= 0, "%s finds a tile" % tid)
		ok(w.player_use_talent(tid, dest), "%s usable" % tid)
		eq(w.player.pos, dest, "%s lands on the target" % tid)
		ok(not w.player.has_status("pinned"), "%s frees a pinned player" % tid)


func test_philosophers_loan_adds_no_apotheosis() -> void:
	var w := _world("philosophers_loan")
	var apo := w.apotheosis
	ok(w.player_use_talent("philosophers_loan"), "usable")
	ok(w.player.has_status("false_light"), "brightens the hand")
	eq(w.apotheosis, apo, "borrowed light adds no Apotheosis")
