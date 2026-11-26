class_name Actor
extends RefCounted
## Anything that takes turns: the player and monsters. Base numbers are stored;
## everything a rule reads goes through stat(), which folds in equipment,
## statuses and traits. That keeps modifiers in one place as systems grow.

const SLOTS: Array[String] = ["weapon", "armor", "amulet"]
const INVENTORY_LIMIT := 16

var db: ContentDB
var id: int = 0
var template_id: String = ""
var name: String = ""
var glyph: String = "?"
var color: String = "#ffffff"
var is_player: bool = false
var pos := Vector2i.ZERO
var hp: int = 1
## Base stats: max_hp, might, agility, will, accuracy, evasion, defense,
## damage (dice), speed, sight, crit, perception.
var base: Dictionary = {}
var level: int = 1
var xp: int = 0
var xp_value: int = 0
var next_time: int = 0
## Array of {"id": String, "turns": int}
var statuses: Array[Dictionary] = []
var inventory: Array[Item] = []
## slot -> Item (absent when empty)
var equipment: Dictionary = {}
var traits: Array[String] = []
var tags: Array[String] = []
var awake: bool = false
var unique: bool = false
var species_id: String = ""
var class_id: String = ""
var mask: String = "bare_face"
var mask_risk: int = 0
## Small per-actor rule state (for example, which floors 'deathless' was spent on).
var flags: Dictionary = {}


func has_trait(t: String) -> bool:
	return traits.has(t)


func has_status(sid: String) -> bool:
	for s in statuses:
		if s["id"] == sid:
			return true
	return false


func equipped(slot: String) -> Item:
	return equipment.get(slot) as Item


func _mod_sum(stat_name: String) -> int:
	var total := 0
	for slot in SLOTS:
		var it := equipped(slot)
		if it != null:
			total += int(it.def(db).get("mods", {}).get(stat_name, 0))
	for s in statuses:
		total += int(db.get_def("statuses", s["id"]).get("mods", {}).get(stat_name, 0))
	if has_trait("mask_stances"):
		total += int(Masks.mods(mask).get(stat_name, 0))
	return total


func _item_field(slot: String, field: String) -> int:
	var it := equipped(slot)
	return int(it.def(db).get(field, 0)) if it != null else 0


func stat(stat_name: String) -> int:
	match stat_name:
		"might", "agility", "will":
			return int(base.get(stat_name, 0)) + _mod_sum(stat_name)
		"max_hp":
			return maxi(1, int(base.get("max_hp", 1)) + _mod_sum("max_hp"))
		"accuracy":
			return int(base.get("accuracy", 0)) + stat("agility") + _item_field("weapon", "accuracy") + _mod_sum("accuracy")
		"evasion":
			return int(base.get("evasion", 0)) + stat("agility") + _item_field("armor", "evasion") + _mod_sum("evasion")
		"defense":
			var d := int(base.get("defense", 0)) + _item_field("armor", "defense") + _mod_sum("defense")
			if has_trait("iron_oath") and hp * 2 < stat("max_hp"):
				d += 2
			return maxi(0, d)
		"damage_bonus":
			return stat("might") + _mod_sum("damage")
		"crit":
			return 5 + int(base.get("crit", 0)) + _item_field("weapon", "crit") + _mod_sum("crit")
		"speed":
			return maxi(25, int(base.get("speed", 100)) + _mod_sum("speed"))
		"sight":
			return maxi(2, int(base.get("sight", 8)) + _mod_sum("sight"))
		"perception":
			return int(base.get("perception", 8))
	push_error("Actor.stat: unknown stat '%s'" % stat_name)
	return 0


func damage_dice() -> String:
	var w := equipped("weapon")
	if w != null:
		return String(w.def(db)["damage"])
	return String(base.get("damage", "1d2"))


func is_alive() -> bool:
	return hp > 0


## Time an action of `cost` (100 = one normal turn) takes this actor.
func scaled_cost(cost: int) -> int:
	return maxi(1, int(cost * 100 / stat("speed")))


func to_dict() -> Dictionary:
	var inv := []
	for it in inventory:
		inv.append(it.to_dict())
	var eq := {}
	for slot in equipment:
		eq[slot] = (equipment[slot] as Item).to_dict()
	var st := []
	for s in statuses:
		st.append({"id": s["id"], "turns": int(s["turns"])})
	return {
		"id": id, "t": template_id, "name": name, "glyph": glyph, "color": color,
		"player": is_player, "x": pos.x, "y": pos.y, "hp": hp, "base": base.duplicate(true),
		"level": level, "xp": xp, "xpv": xp_value, "next": next_time, "statuses": st,
		"inv": inv, "eq": eq, "traits": traits.duplicate(), "tags": tags.duplicate(),
		"awake": awake, "unique": unique, "species": species_id, "class": class_id,
		"mask": mask, "mask_risk": mask_risk,
		"flags": flags.duplicate(true),
	}


static func from_dict(d: Dictionary, content: ContentDB) -> Actor:
	var a := Actor.new()
	a.db = content
	a.id = int(d["id"])
	a.template_id = String(d["t"])
	a.name = String(d["name"])
	a.glyph = String(d["glyph"])
	a.color = String(d["color"])
	a.is_player = bool(d["player"])
	a.pos = Vector2i(int(d["x"]), int(d["y"]))
	a.hp = int(d["hp"])
	a.base = _ints(d["base"])
	a.level = int(d["level"])
	a.xp = int(d["xp"])
	a.xp_value = int(d["xpv"])
	a.next_time = int(d["next"])
	for s in d["statuses"]:
		a.statuses.append({"id": String(s["id"]), "turns": int(s["turns"])})
	for it in d["inv"]:
		a.inventory.append(Item.from_dict(it))
	for slot in d["eq"]:
		a.equipment[slot] = Item.from_dict(d["eq"][slot])
	for t in d["traits"]:
		a.traits.append(String(t))
	for t in d["tags"]:
		a.tags.append(String(t))
	a.awake = bool(d["awake"])
	a.unique = bool(d["unique"])
	a.species_id = String(d["species"])
	a.class_id = String(d["class"])
	a.mask = String(d.get("mask", "bare_face"))
	a.mask_risk = int(d.get("mask_risk", 0))
	a.flags = _ints(d["flags"])
	return a


## JSON turns every number into a float; restore whole numbers to ints,
## recursively, so a loaded state serializes byte-for-byte like the original.
static func _ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if is_equal_approx(v, roundf(v)) else v
		TYPE_DICTIONARY:
			var o := {}
			for k in v:
				o[k] = _ints(v[k])
			return o
		TYPE_ARRAY:
			var arr := []
			for x in v:
				arr.append(_ints(x))
			return arr
	return v
