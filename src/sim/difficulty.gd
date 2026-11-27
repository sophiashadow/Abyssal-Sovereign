class_name Difficulty
extends RefCounted
## M7.8 run profiles. A profile changes how floors are populated and what the
## pack starts with. It never multiplies creature or player stats, and it never
## touches the combat rules, so permadeath and every mechanic are identical.
##
## Exile is the neutral profile: apply_to_floor returns the floor definition
## unchanged, so an Exile run generates exactly what it did before profiles.

const DEFAULT := "exile"
const SALVE := "healing_salve"


static func normalise(db: ContentDB, id: String) -> String:
	return id if db.has("difficulty", id) else DEFAULT


static func profile(db: ContentDB, id: String) -> Dictionary:
	if db.has("difficulty", id):
		return db.get_def("difficulty", id)
	return {}


## Profile ids easiest first.
static func ordered(db: ContentDB) -> Array[String]:
	var ids := db.ids("difficulty")
	ids.sort_custom(func(a: String, b: String) -> bool:
		var oa := int(db.get_def("difficulty", a).get("order", 0))
		var ob := int(db.get_def("difficulty", b).get("order", 0))
		return oa < ob if oa != ob else a < b)
	return ids


static func is_neutral(p: Dictionary) -> bool:
	return int(p.get("monsters_delta", 0)) == 0 and int(p.get("group_pct", 75)) == 75 \
		and int(p.get("elite_delta", 0)) == 0 and int(p.get("items_delta", 0)) == 0 \
		and int(p.get("heal_weight_pct", 100)) == 100


## The floor definition the generator should use for this profile.
static func apply_to_floor(db: ContentDB, id: String, fd: Dictionary) -> Dictionary:
	var p := profile(db, id)
	if p.is_empty() or is_neutral(p):
		return fd
	var out := fd.duplicate(true)
	var md := int(p.get("monsters_delta", 0))
	if md != 0:
		out["monsters_min"] = maxi(1, int(fd["monsters_min"]) + md)
		out["monsters_max"] = maxi(int(out["monsters_min"]), int(fd["monsters_max"]) + md)
	var idl := int(p.get("items_delta", 0))
	if idl != 0:
		out["items_min"] = maxi(1, int(fd["items_min"]) + idl)
		out["items_max"] = maxi(int(out["items_min"]), int(fd["items_max"]) + idl)
	out["group_pct"] = int(p.get("group_pct", 75))
	out["elite_delta"] = int(p.get("elite_delta", 0))
	var hw := int(p.get("heal_weight_pct", 100))
	if hw != 100 and out.get("item_table") is Array:
		for row in out["item_table"]:
			if _is_healing(db, String(row["id"])):
				row["weight"] = maxi(1, int(roundf(float(row["weight"]) * float(hw) / 100.0)))
	return out


static func _is_healing(db: ContentDB, item_id: String) -> bool:
	if not db.has("items", item_id):
		return false
	var d := db.get_def("items", item_id)
	return String(d.get("kind", "")) == "consumable" and String(d.get("effect", "")) == "heal"


## Adds or removes starting healing salves. Removal never goes below none.
static func adjust_starting_pack(w: World, a: Actor) -> void:
	var n := int(profile(w.db, w.difficulty).get("start_salves", 0))
	if n > 0:
		var it := w._new_item(SALVE)
		it.quantity = n
		w._add_to_inventory(a, it)
	elif n < 0:
		var left := -n
		for i in range(a.inventory.size() - 1, -1, -1):
			if left <= 0:
				break
			var own: Item = a.inventory[i]
			if own.template_id != SALVE:
				continue
			var take := mini(left, own.quantity)
			own.quantity -= take
			left -= take
			if own.quantity <= 0:
				a.inventory.remove_at(i)


## One-line description for the profile picker.
static func summary(db: ContentDB, id: String) -> String:
	var p := profile(db, id)
	if p.is_empty():
		return ""
	var bits: Array[String] = []
	var md := int(p.get("monsters_delta", 0))
	if md != 0:
		bits.append("%+d foes per floor" % md)
	var ed := int(p.get("elite_delta", 0))
	if ed != 0:
		bits.append("%+d elite" % ed)
	var gp := int(p.get("group_pct", 75))
	if gp != 75:
		bits.append("%s squads" % ("tighter" if gp > 75 else "looser"))
	var idl := int(p.get("items_delta", 0))
	if idl != 0:
		bits.append("%+d items per floor" % idl)
	var hw := int(p.get("heal_weight_pct", 100))
	if hw != 100:
		bits.append("%s healing loot" % ("more" if hw > 100 else "less"))
	var ss := int(p.get("start_salves", 0))
	if ss != 0:
		bits.append("%+d starting salve" % ss)
	return String(p.get("description", "")) if bits.is_empty() else "%s\n(%s)" % [p.get("description", ""), ", ".join(bits)]
