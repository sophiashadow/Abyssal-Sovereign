class_name Rng
extends RefCounted
## Deterministic random stream. Wraps Godot's PCG32 RandomNumberGenerator so
## the full state can be saved (as a string, since JSON numbers lose 64-bit
## precision) and restored exactly.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func get_state_string() -> String:
	return str(_rng.state)


func set_state_string(s: String) -> void:
	_rng.state = s.to_int()


## Inclusive range.
func range_i(lo: int, hi: int) -> int:
	if hi <= lo:
		return lo
	return _rng.randi_range(lo, hi)


## Percentile roll, 1..100.
func d100() -> int:
	return _rng.randi_range(1, 100)


func chance_pct(pct: int) -> bool:
	return d100() <= pct


func pick(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]


## Weighted pick from an array of {"id": String, "weight": int}.
func pick_weighted(table: Array) -> String:
	var total := 0
	for row in table:
		total += int(row["weight"])
	if total <= 0:
		return ""
	var r := _rng.randi_range(1, total)
	for row in table:
		r -= int(row["weight"])
		if r <= 0:
			return String(row["id"])
	return String(table[table.size() - 1]["id"])


func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = t


## Stable 32-bit FNV-1a, used to derive independent sub-seeds
## (for example, one per dungeon floor) from the run seed.
static func derive(base_seed: int, salt: String) -> int:
	var h := 2166136261
	var bytes := (str(base_seed) + ":" + salt).to_utf8_buffer()
	for b in bytes:
		h = h ^ b
		h = (h * 16777619) & 0xFFFFFFFF
	return h
