class_name Item
extends RefCounted
## An item instance. Its rules come from the content definition `template_id`;
## the instance holds per-drop affixes, rarity, blessed/cursed state, and ID state.

var id: int = 0
var template_id: String = ""
var quantity: int = 1
var pos: Vector2i = Vector2i.ZERO
var rarity: String = "common" # common | uncommon | rare | artifact
var affixes: Array[String] = []
var buc: String = "uncursed" # blessed | uncursed | cursed
var identified: bool = true
var mods: Dictionary = {}
var resists: Dictionary = {}
var bonus_damage_type: String = ""
var bonus_status: String = ""


func def(db: ContentDB) -> Dictionary:
	return db.get_def("items", template_id)


func is_equippable(db: ContentDB) -> bool:
	return String(def(db).get("kind", "")) in ["weapon", "ranged", "armor", "amulet"]


func is_identified_in(db: ContentDB, id_known: Dictionary) -> bool:
	var d := def(db)
	var kind := String(d.get("kind", ""))
	if kind == "consumable":
		return bool(id_known.get(template_id, false))
	return identified


func total_mod(db: ContentDB, stat_name: String) -> int:
	var d := def(db)
	var total := int(d.get("mods", {}).get(stat_name, 0)) + int(mods.get(stat_name, 0))
	if buc == "uncursed" or not is_equippable(db):
		return total
	var delta := 1 if buc == "blessed" else -1
	var kind := String(d["kind"])
	if kind in ["weapon", "ranged"] and stat_name in ["accuracy", "damage"]:
		total += delta
	elif kind == "armor" and stat_name in ["defense", "evasion"]:
		total += delta
	elif kind == "amulet" and stat_name == ("will" if buc == "blessed" else "might"):
		total += delta
	return total


func total_resist(db: ContentDB, dmg_type: String) -> int:
	var d := def(db)
	var total := int(d.get("resists", {}).get(dmg_type, 0)) + int(resists.get(dmg_type, 0))
	if buc == "blessed" and is_equippable(db) and dmg_type in ["void", "radiant"]:
		total += 10
	return total


func effective_damage_type(db: ContentDB) -> String:
	if bonus_damage_type != "":
		return bonus_damage_type
	return String(def(db).get("damage_type", "physical"))


func effective_status(db: ContentDB) -> String:
	if bonus_status != "":
		return bonus_status
	return String(def(db).get("status", ""))


func effective_color(db: ContentDB) -> String:
	var base_c := String(def(db).get("color", "#eee5d3"))
	if rarity == "artifact":
		return "#f2c35c"
	if rarity == "rare":
		return "#c77dff"
	if rarity == "uncommon":
		return "#6ec6ff"
	return base_c


func display_name(db: ContentDB, id_known: Dictionary = {}, id_aliases: Dictionary = {}) -> String:
	var d := def(db)
	var base_name := String(d.get("name", template_id))
	var kind := String(d.get("kind", ""))
	if kind == "consumable" and not id_aliases.is_empty() and not bool(id_known.get(template_id, false)):
		var alias := String(id_aliases.get(template_id, "unknown " + ("scroll" if String(d.get("effect", "")) == "scroll" else "phial")))
		return alias if quantity <= 1 else "%d x %s" % [quantity, alias]
	if is_equippable(db) and not identified:
		var prefix_un := "glowing " if rarity != "common" or buc == "blessed" else "unidentified "
		return prefix_un + base_name
	var parts: PackedStringArray = []
	if identified and buc == "blessed":
		parts.append("Blessed")
	elif identified and buc == "cursed":
		parts.append("Cursed")
	var suffs: PackedStringArray = []
	for aid in affixes:
		if Affixes.is_prefix(aid):
			parts.append(Affixes.label(aid))
		else:
			suffs.append(Affixes.label(aid))
	parts.append(base_name)
	var label := " ".join(parts)
	if not suffs.is_empty():
		label += " " + " ".join(suffs)
	return label if quantity <= 1 else "%d x %s" % [quantity, label]


func to_dict() -> Dictionary:
	return {
		"id": id, "t": template_id, "q": quantity, "x": pos.x, "y": pos.y,
		"rar": rarity, "aff": affixes.duplicate(), "buc": buc, "idn": identified,
		"mods": mods.duplicate(true), "res": resists.duplicate(true),
		"dt": bonus_damage_type, "st": bonus_status,
	}


static func from_dict(d: Dictionary) -> Item:
	var it := Item.new()
	it.id = int(d["id"])
	it.template_id = String(d["t"])
	it.quantity = int(d["q"])
	it.pos = Vector2i(int(d["x"]), int(d["y"]))
	it.rarity = String(d.get("rar", "common"))
	for aid in d.get("aff", []):
		it.affixes.append(String(aid))
	it.buc = String(d.get("buc", "uncursed"))
	it.identified = bool(d.get("idn", true))
	it.mods = Actor._ints(d.get("mods", {}))
	it.resists = Actor._ints(d.get("res", {}))
	it.bonus_damage_type = String(d.get("dt", ""))
	it.bonus_status = String(d.get("st", ""))
	return it
