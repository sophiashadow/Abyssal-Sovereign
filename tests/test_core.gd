extends TestCase


func test_dice_parsing() -> void:
	ok(Dice.is_valid("1d6"), "1d6 valid")
	ok(Dice.is_valid("2d4+3"), "2d4+3 valid")
	ok(Dice.is_valid("1d8-1"), "1d8-1 valid")
	ok(Dice.is_valid("5"), "plain number valid")
	ok(not Dice.is_valid(""), "empty invalid")
	ok(not Dice.is_valid("d6"), "d6 invalid")
	ok(not Dice.is_valid("0d6"), "0d6 invalid")
	ok(not Dice.is_valid("1d6+"), "trailing sign invalid")
	eq(Dice.parse("2d4+3"), {"n": 2, "sides": 4, "bonus": 3})
	eq(Dice.max_value("2d4+3"), 11)
	eq(Dice.min_value("1d8-1"), 0)


func test_dice_rolls_stay_in_range() -> void:
	var rng := Rng.new(42)
	for i in 2000:
		var r := Dice.roll("3d6+2", rng)
		if r < 5 or r > 20:
			fail("3d6+2 rolled %d" % r)
			return
	ok(true, "range")


func test_rng_is_deterministic_and_restorable() -> void:
	var a := Rng.new(1234)
	var b := Rng.new(1234)
	for i in 50:
		eq(a.range_i(0, 1000), b.range_i(0, 1000), "same seed same stream")
	var saved := a.get_state_string()
	var next_vals := []
	for i in 10:
		next_vals.append(a.range_i(0, 1 << 30))
	var c := Rng.new(0)
	c.set_state_string(saved)
	for i in 10:
		eq(c.range_i(0, 1 << 30), next_vals[i], "restored state continues identically")


func test_seed_derivation_is_stable() -> void:
	# Golden values: if these change, every existing seed produces different dungeons.
	eq(Rng.derive(0, ""), Rng.derive(0, ""), "pure")
	ok(Rng.derive(1, "floor:1") != Rng.derive(1, "floor:2"), "salts differ")
	ok(Rng.derive(1, "floor:1") != Rng.derive(2, "floor:1"), "seeds differ")
	eq(Rng.derive(12345, "floor:1"), 868460085, "golden value")
