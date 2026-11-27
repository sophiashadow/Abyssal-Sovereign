class_name AssetRegistry
extends RefCounted
## M8.2/M8.4 presentation asset registry. Maps stable simulation content IDs
## (floors/Spheres, tiles, features, species, callings, masks, monsters, NPCs,
## items, statuses, icons, emblems) to Texture2D atlas regions, with safe
## graceful null fallback when any file or mapping is absent.
## Presentation-only: never touches World, Rng, or saves.

const REGISTRY_PATH := "res://content/presentation/asset_registry.json"
const PROVENANCE_PATH := "res://content/presentation/asset_provenance.json"

var data: Dictionary = {}
var provenance: Dictionary = {}
var _atlases: Dictionary = {} ## atlas_id -> Texture2D or null
var _load_errors: Array[String] = []


func _init(reg_path: String = REGISTRY_PATH, prov_path: String = PROVENANCE_PATH) -> void:
	load_manifests(reg_path, prov_path)


func load_manifests(reg_path: String = REGISTRY_PATH, prov_path: String = PROVENANCE_PATH) -> void:
	data.clear()
	provenance.clear()
	_atlases.clear()
	_load_errors.clear()
	if FileAccess.file_exists(reg_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(reg_path))
		if parsed is Dictionary:
			data = parsed
		else:
			_load_errors.append("Invalid JSON in " + reg_path)
	if FileAccess.file_exists(prov_path):
		var parsed_p: Variant = JSON.parse_string(FileAccess.get_file_as_string(prov_path))
		if parsed_p is Dictionary:
			provenance = parsed_p
		else:
			_load_errors.append("Invalid JSON in " + prov_path)


func get_atlas(atlas_id: String) -> Texture2D:
	if _atlases.has(atlas_id):
		return _atlases[atlas_id] as Texture2D
	var atlases: Dictionary = data.get("atlases", {})
	if not atlases.has(atlas_id):
		_atlases[atlas_id] = null
		return null
	var info: Variant = atlases[atlas_id]
	var path := String(info.get("path", "")) if info is Dictionary else ""
	var tex: Texture2D = null
	if path != "":
		if ResourceLoader.exists(path):
			var loaded := ResourceLoader.load(path)
			if loaded is Texture2D:
				tex = loaded
		if tex == null and FileAccess.file_exists(path):
			var img := Image.new()
			var abs_path := ProjectSettings.globalize_path(path)
			if img.load(abs_path) == OK and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	_atlases[atlas_id] = tex
	return tex


func _region_entry(section: String, key: String) -> Dictionary:
	var sec: Variant = data.get(section, {})
	if not (sec is Dictionary) or not (sec as Dictionary).has(key):
		return {}
	var e: Variant = (sec as Dictionary)[key]
	if not (e is Dictionary):
		return {}
	var d := e as Dictionary
	var atlas_id := String(d.get("atlas", ""))
	if atlas_id == "" or get_atlas(atlas_id) == null:
		return {}
	var r: Array = d.get("rect", [])
	if r.size() != 4:
		return {}
	return {
		"atlas": atlas_id,
		"texture": get_atlas(atlas_id),
		"rect": Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])),
	}


func tile_region(sphere: int, tile_id: int, variant: int = 0) -> Dictionary:
	var sp := clampi(sphere, 1, 7)
	var keys: Array[String] = []
	if tile_id == Tiles.FLOOR or tile_id == Tiles.WALL:
		keys.append("s%d:%d:%d" % [sp, tile_id, posmod(variant, 4)])
		keys.append("s%d:%d:0" % [sp, tile_id])
		keys.append("s1:%d:%d" % [tile_id, posmod(variant, 4)])
	else:
		keys.append("s%d:%d" % [sp, tile_id])
		keys.append("s1:%d" % tile_id)
	for k in keys:
		var res := _region_entry("tiles", k)
		if not res.is_empty():
			return res
	return {}


func feature_region(sphere: int, kind: String, used: bool = false) -> Dictionary:
	var sp := clampi(sphere, 1, 7)
	var suffix := "used" if used else "ready"
	for k in [
		"s%d:%s:%s" % [sp, kind, suffix],
		"s%d:%s" % [sp, kind],
		"s1:%s:%s" % [kind, suffix],
		"s1:%s" % kind,
	]:
		var res := _region_entry("features", k)
		if not res.is_empty():
			return res
	return {}


func player_layers(player: Actor) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if player == null:
		return out
	for k in ["origin:" + player.species_id, "origin:default"]:
		var r := _region_entry("avatars", k)
		if not r.is_empty():
			out.append(r)
			break
	for k in ["calling:" + player.class_id, "calling:default"]:
		var r := _region_entry("avatars", k)
		if not r.is_empty():
			out.append(r)
			break
	if player.mask != "" and player.mask != "bare_face":
		var mr := _region_entry("avatars", "mask:" + player.mask)
		if not mr.is_empty():
			out.append(mr)
	return out


func actor_region(actor: Actor, db: ContentDB = null) -> Dictionary:
	if actor == null:
		return {}
	var tid := actor.template_id
	if tid != "":
		var direct := _region_entry("monsters", tid)
		if not direct.is_empty():
			return direct
		for t in actor.tags:
			var tr := _region_entry("monsters", "tag:" + String(t))
			if not tr.is_empty():
				return tr
		if db != null and db.has("monsters", tid):
			for t in db.get_def("monsters", tid).get("tags", []):
				var tr2 := _region_entry("monsters", "tag:" + String(t))
				if not tr2.is_empty():
					return tr2
	return _region_entry("monsters", "default")


func elite_badge_region(elite_kind: String) -> Dictionary:
	var r := _region_entry("icons", "elite:" + elite_kind.to_lower())
	return r if not r.is_empty() else _region_entry("icons", "elite:default")


func tree_icon_region(tree_name: String) -> Dictionary:
	var r := _region_entry("icons", "tree:" + tree_name)
	return r if not r.is_empty() else _region_entry("icons", "default")


func chain_icon_region(chain_tag: String) -> Dictionary:
	var r := _region_entry("icons", "chain:" + chain_tag)
	return r if not r.is_empty() else _region_entry("icons", "default")


func faction_emblem_region(faction_id: String) -> Dictionary:
	var r := _region_entry("emblems", "faction:" + faction_id)
	return r if not r.is_empty() else _region_entry("emblems", "title_crest")


func npc_region(npc_id: String) -> Dictionary:
	var r := _region_entry("npcs", npc_id)
	if not r.is_empty():
		return r
	return _region_entry("npcs", "default")


func item_region(it: Item, db: ContentDB = null) -> Dictionary:
	if it == null:
		return {}
	var tid := it.template_id
	var direct := _region_entry("items", tid)
	if not direct.is_empty():
		return direct
	if db != null and db.has("items", tid):
		var d := db.get_def("items", tid)
		var kind := String(d.get("kind", ""))
		var eff := String(d.get("effect", ""))
		if eff != "":
			var er := _region_entry("items", "kind:%s:%s" % [kind, eff])
			if not er.is_empty():
				return er
		var kr := _region_entry("items", "kind:" + kind)
		if not kr.is_empty():
			return kr
	return _region_entry("items", "default")


func status_region(sid: String) -> Dictionary:
	var r := _region_entry("statuses", sid)
	if not r.is_empty():
		return r
	return _region_entry("statuses", "default")


func icon_region(icon_id: String) -> Dictionary:
	return _region_entry("icons", icon_id)


func emblem_region(emblem_id: String) -> Dictionary:
	return _region_entry("emblems", emblem_id)


func make_atlas_texture(entry: Dictionary) -> AtlasTexture:
	if entry.is_empty():
		return null
	var tex := entry.get("texture") as Texture2D
	if tex == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = entry["rect"]
	return at


func validate(db: ContentDB = null, require_complete: bool = false) -> Array[String]:
	var errs: Array[String] = _load_errors.duplicate()
	var atlases: Dictionary = data.get("atlases", {})
	var dims := {}
	for aid in atlases:
		var info: Dictionary = atlases[aid]
		var path := String(info.get("path", ""))
		if not FileAccess.file_exists(path):
			errs.append("Missing atlas file for '%s': %s" % [aid, path])
			continue
		var tex := get_atlas(String(aid))
		if tex == null:
			errs.append("Failed to load atlas image '%s': %s" % [aid, path])
			continue
		dims[aid] = tex.get_size()
	for sec_name in ["tiles", "features", "avatars", "monsters", "npcs", "items", "statuses", "icons", "emblems"]:
		var sec: Variant = data.get(sec_name, {})
		if not (sec is Dictionary):
			continue
		for k in (sec as Dictionary):
			var e: Variant = (sec as Dictionary)[k]
			if not (e is Dictionary):
				errs.append("%s.%s is not a dictionary" % [sec_name, k])
				continue
			var aid := String((e as Dictionary).get("atlas", ""))
			var rect: Array = (e as Dictionary).get("rect", [])
			if not dims.has(aid):
				errs.append("%s.%s references unloaded atlas '%s'" % [sec_name, k, aid])
				continue
			if rect.size() != 4:
				errs.append("%s.%s invalid rect" % [sec_name, k])
				continue
			var sz: Vector2 = dims[aid]
			var x := float(rect[0])
			var y := float(rect[1])
			var w := float(rect[2])
			var h := float(rect[3])
			if w <= 0 or h <= 0 or x < 0 or y < 0 or x + w > sz.x or y + h > sz.y:
				errs.append("%s.%s rect %s exceeds atlas '%s' size %s" % [sec_name, k, str(rect), aid, str(sz)])
	if require_complete and db != null:
		for sp in db.ids("species"):
			if _region_entry("avatars", "origin:" + sp).is_empty():
				errs.append("Missing avatar origin sprite for '%s'" % sp)
		for cl in db.ids("classes"):
			if _region_entry("avatars", "calling:" + cl).is_empty():
				errs.append("Missing avatar calling sprite for '%s'" % cl)
		for mk in ["bare_face", "nyx", "eris", "lilith", "lux_venefica"]:
			if _region_entry("avatars", "mask:" + mk).is_empty():
				errs.append("Missing mask overlay for '%s'" % mk)
		for mid in db.ids("monsters"):
			if _region_entry("monsters", mid).is_empty():
				errs.append("Missing monster sprite for '%s'" % mid)
		for nid in db.ids("npcs"):
			if _region_entry("npcs", nid).is_empty():
				errs.append("Missing NPC sprite for '%s'" % nid)
		for iid in db.ids("items"):
			if _region_entry("items", iid).is_empty():
				errs.append("Missing item sprite for '%s'" % iid)
		for sid in db.ids("statuses"):
			if _region_entry("statuses", sid).is_empty():
				errs.append("Missing status icon for '%s'" % sid)
		for tid in db.ids("talents"):
			var tree := String(db.get_def("talents", tid).get("tree", ""))
			if tree != "" and _region_entry("icons", "tree:" + tree).is_empty():
				errs.append("Missing talent tree icon for '%s'" % tree)
		for fid in db.ids("factions"):
			if _region_entry("emblems", "faction:" + fid).is_empty():
				errs.append("Missing faction emblem for '%s'" % fid)
		for cid in db.ids("contracts"):
			if _region_entry("icons", "contract:" + cid).is_empty():
				errs.append("Missing contract icon for '%s'" % cid)
	return errs


func validate_provenance() -> Array[String]:
	var errs: Array[String] = []
	var entries: Variant = provenance.get("entries", [])
	if not (entries is Array) or (entries as Array).is_empty():
		errs.append("asset_provenance.json has no entries")
		return errs
	var seen_paths := {}
	for e in (entries as Array):
		if not (e is Dictionary):
			errs.append("Non-dictionary provenance entry")
			continue
		var d := e as Dictionary
		for req in ["asset_id", "path", "source", "author_or_method", "license_status", "approval_status", "associated_entities", "modification_history"]:
			if not d.has(req):
				errs.append("Provenance entry missing '%s': %s" % [req, String(d.get("asset_id", "?"))])
		var p := String(d.get("path", ""))
		if p != "":
			seen_paths[p] = true
			if not FileAccess.file_exists(p):
				errs.append("Provenance path missing on disk: " + p)
	var atlases: Dictionary = data.get("atlases", {})
	for aid in atlases:
		var ap := String((atlases[aid] as Dictionary).get("path", ""))
		if ap != "" and not seen_paths.has(ap):
			errs.append("Atlas '%s' path not tracked in asset_provenance.json: %s" % [aid, ap])
	return errs
