class_name SaveCheck
extends RefCounted
## Structural check of a parsed save before any object is built from it.
## A corrupt or hand-edited save must produce a readable error, never a
## crash or a half-built world. World.from_dict calls this first.

const ACTOR_KEYS := ["id", "t", "name", "glyph", "color", "player", "x", "y", "hp", "base",
	"level", "xp", "xpv", "next", "statuses", "inv", "eq", "traits", "tags", "awake",
	"unique", "species", "class", "mask", "mask_risk",
	"stat_points", "talent_points", "resource", "talents", "cooldowns",
	"resists", "specials", "elite", "flags"]
const ITEM_KEYS := ["id", "t", "q", "x", "y", "rar", "aff", "buc", "idn", "mods", "res", "dt", "st"]
const FLOOR_KEYS := ["floor_id", "depth", "w", "h", "tiles", "explored", "up", "down", "exit", "actors", "items", "features", "portals"]


static func problems(d: Dictionary, db: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	if typeof(d.get("player")) != TYPE_DICTIONARY:
		out.append("player record is missing or not an object")
	else:
		_actor(d["player"], db, "player", out)
	if typeof(d.get("floors")) != TYPE_DICTIONARY or d["floors"].is_empty():
		out.append("floors are missing")
	else:
		for key in d["floors"]:
			_floor(d["floors"][key], db, "floor %s" % key, out)
	if typeof(d.get("log")) != TYPE_ARRAY:
		out.append("log is not a list")
	else:
		for msg in d["log"]:
			if typeof(msg) != TYPE_DICTIONARY or not (msg.has("t") and msg.has("k") and msg.has("n")):
				out.append("log entry is malformed")
				break
	if typeof(d.get("rng")) != TYPE_STRING or not String(d["rng"]).is_valid_int():
		out.append("random state is malformed")
	if typeof(d.get("id_known")) != TYPE_DICTIONARY or typeof(d.get("id_aliases")) != TYPE_DICTIONARY or typeof(d.get("uniques")) != TYPE_ARRAY:
		out.append("discovery state is malformed")
	if typeof(d.get("contract")) != TYPE_STRING or typeof(d.get("contract_log")) != TYPE_DICTIONARY or int(d.get("subjugation", -1)) < 0 or int(d.get("contract_progress", -1)) < 0:
		out.append("contract or subjugation state is malformed")
	if typeof(d.get("floor_id")) != TYPE_STRING or not db.has("floors", String(d.get("floor_id", ""))):
		out.append("floor_id is missing or unknown")
	if typeof(d.get("atlas")) != TYPE_DICTIONARY or typeof(d.get("visited_floors")) != TYPE_ARRAY or int(d.get("max_sphere_reached", 0)) < 1:
		out.append("atlas or visited_floors state is malformed")
	if typeof(d.get("npc_standing")) != TYPE_DICTIONARY or typeof(d.get("faction_flags")) != TYPE_DICTIONARY or typeof(d.get("npcs_met")) != TYPE_ARRAY:
		out.append("npc or faction state is malformed")
	return out


static func _has_keys(v: Variant, keys: Array, where: String, out: PackedStringArray) -> bool:
	if typeof(v) != TYPE_DICTIONARY:
		out.append("%s is not an object" % where)
		return false
	for k in keys:
		if not v.has(k):
			out.append("%s is missing '%s'" % [where, k])
			return false
	return true


static func _list(v: Variant, where: String, out: PackedStringArray) -> bool:
	if typeof(v) != TYPE_ARRAY:
		out.append("%s is not a list" % where)
		return false
	return true


static func _item(v: Variant, db: ContentDB, where: String, out: PackedStringArray) -> void:
	if not _has_keys(v, ITEM_KEYS, where, out):
		return
	if not db.has("items", String(v["t"])):
		out.append("%s refers to unknown item '%s'" % [where, str(v["t"])])
	if not (String(v["rar"]) in ["common", "uncommon", "rare", "artifact"]):
		out.append("%s has invalid rarity '%s'" % [where, str(v["rar"])])
	if not (String(v["buc"]) in ["blessed", "uncursed", "cursed"]):
		out.append("%s has invalid buc '%s'" % [where, str(v["buc"])])
	if typeof(v["aff"]) != TYPE_ARRAY or typeof(v["idn"]) != TYPE_BOOL or typeof(v["mods"]) != TYPE_DICTIONARY or typeof(v["res"]) != TYPE_DICTIONARY:
		out.append("%s has malformed affix or identification data" % where)


static func _actor(v: Variant, db: ContentDB, where: String, out: PackedStringArray) -> void:
	if not _has_keys(v, ACTOR_KEYS, where, out):
		return
	if typeof(v["base"]) != TYPE_DICTIONARY or typeof(v["flags"]) != TYPE_DICTIONARY or typeof(v["eq"]) != TYPE_DICTIONARY:
		out.append("%s has malformed stats, flags or equipment" % where)
		return
	if not Masks.is_valid(String(v["mask"])):
		out.append("%s has unknown mask '%s'" % [where, str(v["mask"])])
	if int(v["mask_risk"]) < 0:
		out.append("%s has negative mask risk" % where)
	if int(v["stat_points"]) < 0 or int(v["talent_points"]) < 0 or int(v["resource"]) < 0:
		out.append("%s has negative points or resource" % where)
	if typeof(v["talents"]) != TYPE_DICTIONARY or typeof(v["cooldowns"]) != TYPE_DICTIONARY:
		out.append("%s has malformed talents or cooldowns" % where)
		return
	for tid in v["talents"]:
		if not db.has("talents", String(tid)):
			out.append("%s refers to unknown talent '%s'" % [where, str(tid)])
		elif int(v["talents"][tid]) < 1:
			out.append("%s has non-positive rank for talent '%s'" % [where, str(tid)])
	if typeof(v["resists"]) != TYPE_DICTIONARY or typeof(v["specials"]) != TYPE_ARRAY or typeof(v["elite"]) != TYPE_BOOL:
		out.append("%s has malformed resistances or specials" % where)
		return
	for dt in v["resists"]:
		if not ContentSchema.DAMAGE_TYPES.has(String(dt)):
			out.append("%s has unknown damage type '%s'" % [where, str(dt)])
	if bool(v["player"]):
		if not db.has("species", String(v["species"])) or not db.has("classes", String(v["class"])):
			out.append("%s has unknown species or class" % where)
	elif not db.has("monsters", String(v["t"])):
		out.append("%s refers to unknown monster '%s'" % [where, str(v["t"])])
	for k in ["statuses", "inv", "traits", "tags"]:
		if not _list(v[k], "%s %s" % [where, k], out):
			return
	for s in v["statuses"]:
		if not _has_keys(s, ["id", "turns"], where + " status", out):
			return
		if not db.has("statuses", String(s["id"])):
			out.append("%s has unknown status '%s'" % [where, str(s["id"])])
	for it in v["inv"]:
		_item(it, db, where + " inventory item", out)
	for slot in v["eq"]:
		if not Actor.SLOTS.has(slot):
			out.append("%s has unknown equipment slot '%s'" % [where, str(slot)])
		_item(v["eq"][slot], db, "%s %s" % [where, slot], out)


static func _floor(v: Variant, db: ContentDB, where: String, out: PackedStringArray) -> void:
	if not _has_keys(v, FLOOR_KEYS, where, out):
		return
	if typeof(v["floor_id"]) != TYPE_STRING or not db.has("floors", String(v["floor_id"])):
		out.append("%s has unknown floor_id '%s'" % [where, str(v["floor_id"])])
	if not _list(v["portals"], where + " portals", out):
		return
	var cells := int(v["w"]) * int(v["h"])
	if cells <= 0 or typeof(v["tiles"]) != TYPE_STRING or typeof(v["explored"]) != TYPE_STRING:
		out.append("%s has malformed terrain" % where)
		return
	if Marshalls.base64_to_raw(String(v["tiles"])).size() != cells or Marshalls.base64_to_raw(String(v["explored"])).size() != cells:
		out.append("%s terrain does not match its size" % where)
	for k in ["up", "down", "exit"]:
		if typeof(v[k]) != TYPE_ARRAY or v[k].size() != 2:
			out.append("%s has a malformed '%s' position" % [where, k])
	if _list(v["actors"], where + " actors", out):
		for a in v["actors"]:
			_actor(a, db, where + " actor", out)
	if _list(v["items"], where + " items", out):
		for it in v["items"]:
			_item(it, db, where + " item", out)
	if not _list(v["features"], where + " features", out):
		return
	for f in v["features"]:
		if not _has_keys(f, ["kind", "sub", "x", "y", "revealed", "used"], where + " feature", out):
			return
