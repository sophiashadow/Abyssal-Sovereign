class_name Dice
extends RefCounted
## Dice notation: "NdS", "NdS+B", "NdS-B", or a plain integer "B".

static var _re: RegEx


static func _regex() -> RegEx:
	if _re == null:
		_re = RegEx.new()
		_re.compile("^\\s*(?:(\\d+)d(\\d+))?\\s*(?:([+-]?)\\s*(\\d+))?\\s*$")
	return _re


static func is_valid(text: String) -> bool:
	if text.strip_edges() == "":
		return false
	var m := _regex().search(text)
	if m == null:
		return false
	if m.get_string(1) == "" and m.get_string(4) == "":
		return false
	if m.get_string(1) != "" and (int(m.get_string(1)) <= 0 or int(m.get_string(2)) <= 0):
		return false
	return true


## Returns {"n": int, "sides": int, "bonus": int}. Invalid text parses to zero dice.
static func parse(text: String) -> Dictionary:
	var out := {"n": 0, "sides": 0, "bonus": 0}
	var m := _regex().search(text)
	if m == null:
		return out
	if m.get_string(1) != "":
		out["n"] = int(m.get_string(1))
		out["sides"] = int(m.get_string(2))
	if m.get_string(4) != "":
		var b := int(m.get_string(4))
		out["bonus"] = -b if m.get_string(3) == "-" else b
	return out


static func roll(text: String, rng: Rng) -> int:
	var d := parse(text)
	var total: int = d["bonus"]
	for i in int(d["n"]):
		total += rng.range_i(1, int(d["sides"]))
	return total


static func max_value(text: String) -> int:
	var d := parse(text)
	return int(d["n"]) * int(d["sides"]) + int(d["bonus"])


static func min_value(text: String) -> int:
	var d := parse(text)
	return int(d["n"]) + int(d["bonus"])
