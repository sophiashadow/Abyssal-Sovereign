class_name ContentDB
extends RefCounted
## Loads and validates data-driven content. Content lives in JSON files under
## one or more pack directories (res://content/core first). Each file is:
##   {"schema": "<kind>", "version": 1, "entries": [ {...}, ... ]}
## A later pack may add entries, or replace an earlier entry by reusing its id.
## Validation never stops at the first problem: every error is collected with
## file, entry id and field, so a broken pack is diagnosable in one pass.

const SCHEMA_VERSION := 1
const CORE_PACK := "res://content/core"

var errors: PackedStringArray = []
var warnings: PackedStringArray = []
## kind -> { id -> Dictionary }
var _data: Dictionary = {}
## kind -> id -> source file (for diagnostics)
var _origin: Dictionary = {}
var _id_re := RegEx.new()
var _color_re := RegEx.new()


func _init() -> void:
	_id_re.compile("^[a-z][a-z0-9_]*$")
	_color_re.compile("^#[0-9a-fA-F]{6}$")
	for k in ContentSchema.KINDS:
		_data[k] = {}
		_origin[k] = {}


## Convenience: load the core pack (plus any extra packs) and validate.
static func load_default(extra_packs: PackedStringArray = []) -> ContentDB:
	var db := ContentDB.new()
	db.load_pack(CORE_PACK)
	for p in extra_packs:
		db.load_pack(p)
	db.validate()
	return db


func is_valid() -> bool:
	return errors.is_empty()


func load_pack(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		errors.append("%s: content pack directory not found" % dir_path)
		return
	var files: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".json"):
			files.append(f)
	files.sort()
	for f in files:
		load_file(dir_path.path_join(f))


func load_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text == "" and FileAccess.get_open_error() != OK:
		errors.append("%s: cannot read file" % path)
		return
	load_text(text, path)


## Parses one content document. `source` is used only for diagnostics.
func load_text(text: String, source: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK:
		errors.append("%s:%d: invalid JSON: %s" % [source, json.get_error_line() + 1, json.get_error_message()])
		return
	var doc: Variant = json.data
	if typeof(doc) != TYPE_DICTIONARY:
		errors.append("%s: top level must be an object" % source)
		return
	var kind := String(doc.get("schema", ""))
	if not ContentSchema.KINDS.has(kind):
		errors.append("%s: unknown schema '%s' (expected one of %s)" % [source, kind, ", ".join(ContentSchema.KINDS)])
		return
	if int(doc.get("version", 0)) != SCHEMA_VERSION:
		errors.append("%s: schema version %s is not supported (expected %d)" % [source, str(_normalize(doc.get("version"))), SCHEMA_VERSION])
		return
	var entries: Variant = doc.get("entries")
	if typeof(entries) != TYPE_ARRAY:
		errors.append("%s: 'entries' must be an array" % source)
		return
	var seen_here := {}
	for i in entries.size():
		var e: Variant = entries[i]
		if typeof(e) != TYPE_DICTIONARY:
			errors.append("%s: entry #%d is not an object" % [source, i])
			continue
		var id := String(e.get("id", ""))
		if id == "":
			errors.append("%s: entry #%d has no id" % [source, i])
			continue
		if seen_here.has(id):
			errors.append("%s: duplicate id '%s' in the same file" % [source, id])
			continue
		seen_here[id] = true
		if _data[kind].has(id):
			warnings.append("%s: '%s' overrides the definition from %s" % [source, id, _origin[kind][id]])
		_data[kind][id] = _normalize(e)
		_origin[kind][id] = source


## JSON numbers arrive as floats; store whole numbers as ints so content
## values are exact and saves stay stable.
func _normalize(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			if is_equal_approx(v, roundf(v)) and absf(v) < 9.0e15:
				return int(v)
			return v
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = _normalize(v[k])
			return d
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(_normalize(x))
			return a
	return v


func validate() -> void:
	for kind in ContentSchema.KINDS:
		var fields: Dictionary = ContentSchema.FIELDS[kind]
		for id in _data[kind]:
			var e: Dictionary = _data[kind][id]
			var where := "%s: %s '%s'" % [_origin[kind][id], kind, id]
			if not _id_re.search(id):
				errors.append("%s: id must be lowercase snake_case" % where)
			for fname in fields:
				var spec: Dictionary = fields[fname]
				if not e.has(fname):
					if spec.get("required", false):
						errors.append("%s: missing required field '%s'" % [where, fname])
					continue
				var problem := _check(e[fname], String(spec["type"]))
				if problem != "":
					errors.append("%s: field '%s' %s" % [where, fname, problem])
				elif spec.has("min") and typeof(e[fname]) == TYPE_INT and int(e[fname]) < int(spec["min"]):
					errors.append("%s: field '%s' must be >= %d" % [where, fname, int(spec["min"])])
			for fname in e:
				if not fields.has(fname):
					warnings.append("%s: unknown field '%s' is ignored" % [where, fname])
			_kind_rules(kind, e, where)
	_global_rules()


func _kind_rules(kind: String, e: Dictionary, where: String) -> void:
	if kind == "items":
		var item_kind := String(e.get("kind", ""))
		for req in ContentSchema.ITEM_KIND_REQUIRES.get(item_kind, []):
			if not e.has(req):
				errors.append("%s: %s items require field '%s'" % [where, item_kind, req])
		if e.get("effect", "") == "heal" and not e.has("heal"):
			errors.append("%s: effect 'heal' requires field 'heal'" % where)
		if e.get("effect", "") == "status" and not e.has("status"):
			errors.append("%s: effect 'status' requires field 'status'" % where)
	elif kind == "floors":
		for pair in [["rooms_min", "rooms_max"], ["monsters_min", "monsters_max"], ["items_min", "items_max"]]:
			if int(e.get(pair[0], 0)) > int(e.get(pair[1], 0)):
				errors.append("%s: '%s' is greater than '%s'" % [where, pair[0], pair[1]])
		if e.get("exit", "") == "sealed_door" and not e.has("guardian"):
			errors.append("%s: exit 'sealed_door' requires a 'guardian'" % where)


func _global_rules() -> void:
	# Floors must form an unbroken run of depths starting at 1, ending in a final exit.
	var depths := {}
	for id in _data["floors"]:
		var d := int(_data["floors"][id].get("depth", 0))
		if depths.has(d):
			errors.append("floors: depth %d is defined by both '%s' and '%s'" % [d, depths[d], id])
		depths[d] = id
	if _data["floors"].is_empty():
		errors.append("floors: no floors defined")
		return
	for d in range(1, depths.size() + 1):
		if not depths.has(d):
			errors.append("floors: depth %d is missing (depths must run 1..N)" % d)
	var last: Variant = depths.get(depths.size())
	if last != null and _data["floors"][last].get("exit", "") != "sealed_door":
		errors.append("floors: the deepest floor '%s' must use exit 'sealed_door'" % last)
	if _data["species"].is_empty():
		errors.append("species: none defined")
	if _data["classes"].is_empty():
		errors.append("classes: none defined")


## Returns "" if `v` matches `type`, else a short description of the problem.
func _check(v: Variant, type: String) -> String:
	if type.begins_with("list:"):
		if typeof(v) != TYPE_ARRAY:
			return "must be an array"
		var inner := type.substr(5)
		for i in v.size():
			var p := _check(v[i], inner)
			if p != "":
				return "element %d %s" % [i, p]
		return ""
	if type.begins_with("ref:"):
		var kind := type.substr(4)
		if typeof(v) != TYPE_STRING:
			return "must be a string id"
		if not _data[kind].has(v):
			return "references unknown %s id '%s'" % [kind, v]
		return ""
	if type.begins_with("table:"):
		if typeof(v) != TYPE_ARRAY or v.is_empty():
			return "must be a non-empty array of {id, weight}"
		var kind := type.substr(6)
		for row in v:
			if typeof(row) != TYPE_DICTIONARY or not row.has("id") or not row.has("weight"):
				return "rows must be objects with 'id' and 'weight'"
			if typeof(row["weight"]) != TYPE_INT or int(row["weight"]) <= 0:
				return "weight for '%s' must be a positive integer" % str(row["id"])
			if not _data[kind].has(row["id"]):
				return "references unknown %s id '%s'" % [kind, str(row["id"])]
		return ""
	if type.begins_with("enum:"):
		var allowed := type.substr(5).split("|")
		if typeof(v) != TYPE_STRING or not allowed.has(v):
			return "must be one of: %s" % ", ".join(allowed)
		return ""
	match type:
		"id":
			return "" if typeof(v) == TYPE_STRING and _id_re.search(v) != null else "must be a lowercase snake_case id"
		"string":
			return "" if typeof(v) == TYPE_STRING and String(v).strip_edges() != "" else "must be a non-empty string"
		"text":
			return "" if typeof(v) == TYPE_STRING else "must be a string"
		"int":
			return "" if typeof(v) == TYPE_INT else "must be a whole number"
		"number":
			return "" if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else "must be a number"
		"bool":
			return "" if typeof(v) == TYPE_BOOL else "must be true or false"
		"dice":
			return "" if typeof(v) == TYPE_STRING and Dice.is_valid(v) else "must be dice notation like '1d6+1'"
		"glyph":
			return "" if typeof(v) == TYPE_STRING and String(v).length() == 1 else "must be exactly one character"
		"color":
			return "" if typeof(v) == TYPE_STRING and _color_re.search(v) != null else "must be a color like '#e0008f'"
		"trait":
			return "" if typeof(v) == TYPE_STRING and Traits.is_known(v) else "is not a known trait (see src/sim/traits.gd)"
		"mods", "attrs":
			if typeof(v) != TYPE_DICTIONARY:
				return "must be an object"
			var allowed: Array[String] = ContentSchema.MOD_STATS if type == "mods" else ContentSchema.ATTRIBUTES
			for k in v:
				if not allowed.has(k):
					return "has unknown stat '%s' (allowed: %s)" % [k, ", ".join(allowed)]
				if typeof(v[k]) != TYPE_INT:
					return "value for '%s' must be a whole number" % k
			return ""
	return "has unsupported schema type '%s'" % type


func has(kind: String, id: String) -> bool:
	return _data.has(kind) and _data[kind].has(id)


func get_def(kind: String, id: String) -> Dictionary:
	if not has(kind, id):
		push_error("ContentDB: unknown %s '%s'" % [kind, id])
		return {}
	return _data[kind][id]


func ids(kind: String) -> Array[String]:
	var out: Array[String] = []
	for id in _data[kind]:
		out.append(id)
	out.sort()
	return out


func floor_for_depth(depth: int) -> Dictionary:
	for id in _data["floors"]:
		if int(_data["floors"][id]["depth"]) == depth:
			return _data["floors"][id]
	return {}


func max_depth() -> int:
	return _data["floors"].size()


## A short fingerprint of the loaded content, stored in saves so a resumed run
## can warn when its content has changed underneath it.
func fingerprint() -> String:
	var parts: PackedStringArray = []
	for kind in ContentSchema.KINDS:
		for id in ids(kind):
			parts.append(kind + "/" + id)
	return str(Rng.derive(parts.size(), ",".join(parts)))
