class_name Actor
extends RefCounted
## Anything that takes turns: the player and monsters. Base numbers are stored;
## everything a rule reads goes through stat(), which folds in equipment,
## statuses and traits. That keeps modifiers in one place as systems grow.

const SLOTS: Array[String] = ["weapon", "ranged", "armor", "amulet"]
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
var stat_points: int = 0
var talent_points: int = 0
var resource: int = 0
## talent_id -> int rank
var talents: Dictionary = {}
## talent_id -> int remaining turns
var cooldowns: Dictionary = {}
## damage_type -> int percent resist (-100..100)
var resists: Dictionary = {}
var specials: Array[String] = []
var is_elite: bool = false
## Small per-actor rule state (for example, which floors 'deathless' was spent on).
var flags: Dictionary = {}


func talent_rank(tid: String) -> int:
	return int(talents.get(tid, 0))


func cooldown(tid: String) -> int:
	return int(cooldowns.get(tid, 0))


func resource_kind() -> String:
	if not is_player or class_id == "" or db == null or not db.has("classes", class_id):
		return ""
	return String(db.get_def("classes", class_id).get("resource", "stamina"))


func resource_label() -> String:
	match resource_kind():
		"stamina":
			return "Stamina"
		"resonance":
			return "Resonance"
		"poise":
			return "Poise"
	return ""


func max_resource() -> int:
	match resource_kind():
		"stamina":
			return 10 + maxi(0, stat("might")) * 2
		"resonance":
			return 10 + maxi(0, stat("will")) * 2
		"poise":
			return 10 + maxi(0, stat("agility")) * 2
	return 0


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
	if equipment.is_empty() and statuses.is_empty() and talents.is_empty() and not has_trait("mask_stances"):
		return 0
	var total := 0
	for slot in SLOTS:
		var it := equipped(slot)
		if it != null:
			total += it.total_mod(db, stat_name)
	total += ItemSets.mod_sum(self, db, stat_name)
	for s in statuses:
		total += int(db.get_def("statuses", s["id"]).get("mods", {}).get(stat_name, 0))
	if has_trait("mask_stances"):
		total += int(Masks.mods(mask).get(stat_name, 0))
		var cf := talent_rank("crowned_frequency")
		if cf > 0:
			if mask == "nyx" and stat_name == "evasion":
				total += cf
			elif mask == "eris" and stat_name == "damage":
				total += cf
			elif mask == "lilith" and stat_name == "will":
				total += cf
	for tid in talents:
		var rank := int(talents[tid])
		if rank > 0 and db.has("talents", String(tid)):
			total += int(db.get_def("talents", String(tid)).get("mods", {}).get(stat_name, 0)) * rank
	return total


func _item_field(slot: String, field: String) -> int:
	var it := equipped(slot)
	return int(it.def(db).get(field, 0)) if it != null else 0


func stat(stat_name: String) -> int:
	match stat_name:
		"might", "agility", "will":
			return int(base.get(stat_name, 0)) + _mod_sum(stat_name)
		"max_hp":
			var might_hp := maxi(0, stat("might")) * 2 if is_player else 0
			return maxi(1, int(base.get("max_hp", 1)) + might_hp + _mod_sum("max_hp"))
		"accuracy":
			return int(base.get("accuracy", 0)) + stat("agility") + _item_field("weapon", "accuracy") + _mod_sum("accuracy")
		"evasion":
			return int(base.get("evasion", 0)) + stat("agility") + _item_field("armor", "evasion") + _mod_sum("evasion")
		"defense":
			var d := int(base.get("defense", 0)) + _item_field("armor", "defense") + _mod_sum("defense")
			var oath_ok := hp * 20 < stat("max_hp") * 13 if talent_rank("tempered_plate") > 0 else hp * 2 < stat("max_hp")
			if has_trait("iron_oath") and oath_ok:
				d += 2
			return maxi(0, d)
		"damage_bonus":
			return stat("might") + _mod_sum("damage")
		"crit":
			return 5 + int(base.get("crit", 0)) + maxi(0, stat("agility")) * 2 + _item_field("weapon", "crit") + _mod_sum("crit")
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


func melee_damage_type() -> String:
	var w := equipped("weapon")
	if w != null:
		return w.effective_damage_type(db)
	return String(base.get("damage_type", "physical"))


func resist(dmg_type: String) -> int:
	if resists.is_empty() and equipment.is_empty() and statuses.is_empty() and not has_trait("mask_stances"):
		return 0
	var total := int(resists.get(dmg_type, 0))
	for slot in SLOTS:
		var it := equipped(slot)
		if it != null:
			total += it.total_resist(db, dmg_type)
	total += ItemSets.resist_sum(self, db, dmg_type)
	for s in statuses:
		total += int(db.get_def("statuses", s["id"]).get("resists", {}).get(dmg_type, 0))
	if has_trait("mask_stances"):
		total += int(Masks.resists(mask).get(dmg_type, 0))
	return clampi(total, -100, 100)


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
		"stat_points": stat_points, "talent_points": talent_points, "resource": resource,
		"talents": talents.duplicate(true), "cooldowns": cooldowns.duplicate(true),
		"resists": resists.duplicate(true), "specials": specials.duplicate(), "elite": is_elite,
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
	a.stat_points = int(d.get("stat_points", 0))
	a.talent_points = int(d.get("talent_points", 0))
	a.resource = int(d.get("resource", 0))
	a.talents = _ints(d.get("talents", {}))
	a.cooldowns = _ints(d.get("cooldowns", {}))
	a.resists = _ints(d.get("resists", {}))
	for sp in d.get("specials", []):
		a.specials.append(String(sp))
	a.is_elite = bool(d.get("elite", false))
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
