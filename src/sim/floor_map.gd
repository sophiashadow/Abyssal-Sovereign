class_name FloorMap
extends RefCounted
## One dungeon floor: terrain, exploration memory, and what stands on it.

var floor_id: String = ""
var depth: int = 1
var width: int = 0
var height: int = 0
var tiles := PackedByteArray()
var explored := PackedByteArray()
## Recomputed from state; never saved.
var visible := PackedByteArray()
var rooms: Array[Rect2i] = []
var up_pos := Vector2i(-1, -1)
var down_pos := Vector2i(-1, -1)
var exit_pos := Vector2i(-1, -1)
var actors: Array[Actor] = []
var items: Array[Item] = []
## Generation output consumed by World when the floor is first populated.
var spawns: Array[Dictionary] = []
## Ecology features (traps, secret doors, altars, shrines, vaults, merchants, challenges).
var features: Array[Dictionary] = []
## Branch & alternate-route portals: {"x", "y", "target", "label", "kind"}.
var portals: Array[Dictionary] = []


func setup(w: int, h: int, fill: int = Tiles.WALL) -> void:
	width = w
	height = h
	tiles.resize(w * h)
	tiles.fill(fill)
	explored.resize(w * h)
	explored.fill(0)
	visible.resize(w * h)
	visible.fill(0)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func idx(p: Vector2i) -> int:
	return p.y * width + p.x


func get_tile(p: Vector2i) -> int:
	return tiles[idx(p)] if in_bounds(p) else Tiles.WALL


func set_tile(p: Vector2i, t: int) -> void:
	if in_bounds(p):
		tiles[idx(p)] = t


func is_walkable(p: Vector2i) -> bool:
	return in_bounds(p) and Tiles.is_walkable(tiles[idx(p)])


func is_transparent(p: Vector2i) -> bool:
	return in_bounds(p) and Tiles.is_transparent(tiles[idx(p)])


func is_visible(p: Vector2i) -> bool:
	return in_bounds(p) and visible[idx(p)] == 1


func is_explored(p: Vector2i) -> bool:
	return in_bounds(p) and explored[idx(p)] == 1


func set_explored(p: Vector2i) -> void:
	if in_bounds(p):
		explored[idx(p)] = 1


## A diagonal step may not squeeze between two blocking orthogonal tiles.
func can_step(from: Vector2i, to: Vector2i) -> bool:
	if not is_walkable(to) or Grid.chebyshev(from, to) != 1:
		return false
	if from.x != to.x and from.y != to.y:
		var a := Vector2i(to.x, from.y)
		var b := Vector2i(from.x, to.y)
		if not is_walkable(a) and not is_walkable(b):
			return false
	return true


func actor_at(p: Vector2i) -> Actor:
	for a in actors:
		if a.pos == p and a.hp > 0:
			return a
	return null


func items_at(p: Vector2i) -> Array[Item]:
	var out: Array[Item] = []
	for it in items:
		if it.pos == p:
			out.append(it)
	return out


func feature_at(p: Vector2i) -> Dictionary:
	for f in features:
		if int(f.get("x", -1)) == p.x and int(f.get("y", -1)) == p.y:
			return f
	return {}


func revealed_feature_at(p: Vector2i) -> Dictionary:
	var f := feature_at(p)
	if not f.is_empty() and bool(f.get("revealed", false)):
		return f
	return {}


func portal_at(p: Vector2i) -> Dictionary:
	for pt in portals:
		if int(pt.get("x", -1)) == p.x and int(pt.get("y", -1)) == p.y:
			return pt
	return {}


func to_dict() -> Dictionary:
	var acts := []
	for a in actors:
		if not a.is_player:
			acts.append(a.to_dict())
	var its := []
	for it in items:
		its.append(it.to_dict())
	return {
		"floor_id": floor_id,
		"depth": depth, "w": width, "h": height,
		"tiles": Marshalls.raw_to_base64(tiles),
		"explored": Marshalls.raw_to_base64(explored),
		"up": [up_pos.x, up_pos.y], "down": [down_pos.x, down_pos.y], "exit": [exit_pos.x, exit_pos.y],
		"actors": acts, "items": its, "features": features.duplicate(true),
		"portals": portals.duplicate(true),
	}


static func from_dict(d: Dictionary, db: ContentDB) -> FloorMap:
	var m := FloorMap.new()
	m.setup(int(d["w"]), int(d["h"]))
	m.floor_id = String(d.get("floor_id", ""))
	m.depth = int(d["depth"])
	m.tiles = Marshalls.base64_to_raw(String(d["tiles"]))
	m.explored = Marshalls.base64_to_raw(String(d["explored"]))
	if m.tiles.size() != m.width * m.height or m.explored.size() != m.width * m.height:
		push_error("FloorMap: corrupt tile data in save")
	m.up_pos = Vector2i(int(d["up"][0]), int(d["up"][1]))
	m.down_pos = Vector2i(int(d["down"][0]), int(d["down"][1]))
	m.exit_pos = Vector2i(int(d["exit"][0]), int(d["exit"][1]))
	for ad in d["actors"]:
		m.actors.append(Actor.from_dict(ad, db))
	for idd in d["items"]:
		m.items.append(Item.from_dict(idd))
	for fd in d.get("features", []):
		m.features.append(Actor._ints(fd))
	for pt in d.get("portals", []):
		m.portals.append(Actor._ints(pt))
	return m
