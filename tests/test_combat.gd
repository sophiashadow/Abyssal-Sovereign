extends TestCase
## Hit chance, damage, crits and the combat traits.

const ARENA := [
	"#######",
	"#.@m..#",
	"#######",
]


func _duel(species: String = "human", klass: String = "fallen_knight") -> World:
	return TestHelpers.ascii_world(ARENA, {"m": "catalogued_dead"}, species, klass)


## Strips the player to fixed numbers: flat damage, no crits, no attributes.
func _flatten(a: Actor, dmg: String) -> void:
	a.equipment.clear()
	a.base["damage"] = dmg
	a.base["crit"] = -1000
	for k in ["might", "agility", "will", "accuracy", "evasion"]:
		a.base[k] = 0


func test_hit_chance_formula_and_clamps() -> void:
	var w := _duel()
	var mon := TestHelpers.monster(w, "catalogued_dead")
	_flatten(w.player, "1")
	mon.base["evasion"] = 0
	eq(Combat.hit_chance(w.player, mon), 70, "even match")
	w.player.base["accuracy"] = 2
	eq(Combat.hit_chance(w.player, mon), 80, "+5 per point")
	w.player.base["accuracy"] = 100
	eq(Combat.hit_chance(w.player, mon), 95, "upper clamp")
	w.player.base["accuracy"] = -100
	eq(Combat.hit_chance(w.player, mon), 5, "lower clamp")


func test_damage_is_at_least_one_and_defense_subtracts() -> void:
	var w := _duel()
	var mon := TestHelpers.monster(w, "catalogued_dead")
	mon.awake = true
	_flatten(w.player, "5")
	w.player.base["accuracy"] = 100
	mon.base["defense"] = 2
	var rng := Rng.new(3)
	var hits := 0
	for _i in 300:
		var r := Combat.resolve(w.player, mon, rng)
		if r["hit"]:
			hits += 1
			eq(r["damage"], 3, "5 - 2 defense")
	ok(hits > 250, "95%% hits land (got %d/300)" % hits)
	mon.base["defense"] = 50
	for _i in 50:
		var r := Combat.resolve(w.player, mon, rng)
		if r["hit"]:
			eq(r["damage"], 1, "minimum damage")


func test_critical_hits_roll_damage_twice() -> void:
	var w := _duel()
	var mon := TestHelpers.monster(w, "catalogued_dead")
	mon.awake = true
	_flatten(w.player, "4")
	w.player.base["accuracy"] = 100
	w.player.base["crit"] = 1000
	mon.base["defense"] = 0
	var rng := Rng.new(9)
	for _i in 100:
		var r := Combat.resolve(w.player, mon, rng)
		if r["hit"]:
			ok(r["crit"], "always crit")
			eq(r["damage"], 8, "flat 4 rolled twice")


func test_sneak_attack_always_hits_the_unaware() -> void:
	var w := _duel("human", "assassin")
	var mon := TestHelpers.monster(w, "catalogued_dead")
	mon.base["evasion"] = 100
	mon.awake = false
	var rng := Rng.new(5)
	var crits := 0
	for _i in 200:
		var r := Combat.resolve(w.player, mon, rng)
		ok(r["hit"] and r["sneak"], "unaware target always hit")
		if r["crit"]:
			crits += 1
	ok(crits > 80, "+50%% crit against the unaware (got %d/200)" % crits)
	mon.awake = true
	var hits := 0
	for _i in 200:
		if Combat.resolve(w.player, mon, rng)["hit"]:
			hits += 1
	ok(hits < 30, "an aware dodger is hard to hit (got %d/200)" % hits)


func test_attacking_wakes_the_target() -> void:
	var w := _duel("human", "assassin")
	var mon := TestHelpers.monster(w, "catalogued_dead")
	mon.awake = false
	w.player_move(Vector2i(1, 0))
	ok(mon.awake or not mon.is_alive(), "struck monster is awake")


func test_infernal_blood_ignores_one_defense() -> void:
	var w := _duel("cambion", "fallen_knight")
	var mon := TestHelpers.monster(w, "catalogued_dead")
	mon.awake = true
	_flatten(w.player, "3")
	w.player.base["accuracy"] = 100
	mon.base["defense"] = 2
	var rng := Rng.new(1)
	for _i in 50:
		var r := Combat.resolve(w.player, mon, rng)
		if r["hit"]:
			eq(r["damage"], 2, "3 - (2 - 1)")


func test_iron_oath_hardens_below_half_health() -> void:
	var w := _duel("human", "fallen_knight")
	var p := w.player
	var full := p.stat("defense")
	p.hp = p.stat("max_hp") / 2 - 1
	eq(p.stat("defense"), full + 2, "+2 defense when wounded")


func test_deathless_survives_once_per_floor() -> void:
	var w := _duel("revenant", "fallen_knight")
	w.apply_damage(w.player, 999, "x")
	eq(w.state, World.State.PLAYING, "survived the first killing blow")
	eq(w.player.hp, 1, "left at 1 health")
	w.apply_damage(w.player, 999, "x")
	eq(w.state, World.State.DEAD, "second blow on the same floor kills")


func test_kills_award_xp_and_levels() -> void:
	eq(World.xp_for_level(1), 0, "level 1")
	eq(World.xp_for_level(2), 15, "level 2")
	eq(World.xp_for_level(3), 45, "level 3")
	eq(World.xp_for_level(4), 90, "level 4")
	var w := _duel("human", "fallen_knight")
	var mon := TestHelpers.monster(w, "catalogued_dead")
	var max_before := w.player.stat("max_hp")
	w.apply_damage(mon, 999, "test")
	ok(not mon.is_alive(), "killed")
	eq(w.player.xp, 8, "6 xp x 1.25 human bonus, rounded")
	w.gain_xp(7)
	eq(w.player.level, 2, "15 xp reaches level 2")
	eq(w.player.stat("max_hp"), max_before + 6, "knight 5 + human 1 per level")


func test_soul_siphon_heals_on_kill() -> void:
	var w := _duel("human", "occultist")
	var mon := TestHelpers.monster(w, "catalogued_dead")
	w.player.hp = 3
	w.apply_damage(mon, 999, "test")
	eq(w.player.hp, 3 + 1 + w.player.stat("will"), "heal 1 + will")


func test_guardian_opens_the_door_and_stepping_through_wins() -> void:
	var w := TestHelpers.ascii_world([
		"#######",
		"#@P+..#",
		"#.....#",
		"#######",
	], {"P": "preliator_sentinel"})
	var guard := TestHelpers.monster(w, "preliator_sentinel")
	var door := Vector2i(3, 1)
	w.player.pos = Vector2i(2, 2)
	guard.pos = Vector2i(1, 2)
	ok(not w.player_move(Vector2i(1, -1)), "sealed door blocks while the warden stands")
	w.apply_damage(guard, 999, "test")
	eq(w.current_floor().get_tile(door), Tiles.DOOR_OPEN, "door opens")
	ok(w.player_move(Vector2i(1, -1)), "step through")
	eq(w.state, World.State.WON, "victory")
