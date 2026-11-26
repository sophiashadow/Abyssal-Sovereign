class_name RoomArchetypes
extends RefCounted
## M6.7 Composable room geometry and tactical layout archetypes.
## Stamps deterministic room interior layouts without breaking corridor connectivity.

const ARCHETYPES: Array[String] = [
	"pillared_hall",
	"cross_vault",
	"sanctuary_alcove",
	"ambush_choke",
	"ritual_chamber",
	"flooded_cistern",
	"archive_stacks",
	"gauntlet_corridor",
	"settlement_court",
	"broken_cloister",
]


static func apply_to_map(m: FloorMap, floor_def: Dictionary, occupied: Dictionary, rng: Rng) -> Array[String]:
	var chosen_list: Array[String] = []
	var terrain := String(floor_def.get("terrain", "standard"))
	var rkind := String(floor_def.get("region_kind", "spine"))
	for i in range(1, m.rooms.size()):
		var r: Rect2i = m.rooms[i]
		if r.size.x < 5 or r.size.y < 4:
			continue
		if not rng.chance_pct(65):
			continue
		var arch := _pick_for_region(terrain, rkind, r, rng)
		_stamp_room(m, r, arch, occupied)
		chosen_list.append(arch)
	return chosen_list


static func _pick_for_region(terrain: String, rkind: String, r: Rect2i, rng: Rng) -> String:
	var pool: Array[String] = ["pillared_hall", "ambush_choke", "archive_stacks", "broken_cloister"]
	if terrain == "water":
		pool.append("flooded_cistern")
	elif terrain == "sanctuary":
		pool.append("sanctuary_alcove")
		pool.append("settlement_court")
	elif terrain == "iron_grate":
		pool.append("gauntlet_corridor")
	if rkind == "vault" or rkind == "stronghold":
		pool.append("cross_vault")
	if rkind == "settlement":
		pool.append("settlement_court")
	if r.size.x >= 6 and r.size.y >= 5:
		pool.append("ritual_chamber")
	return String(rng.pick(pool))


static func _can_pillar(m: FloorMap, p: Vector2i, r: Rect2i, occupied: Dictionary) -> bool:
	if occupied.has(p) or p == m.up_pos or p == m.down_pos or p == m.exit_pos:
		return false
	if p.x <= r.position.x + 1 or p.x >= r.end.x - 2 or p.y <= r.position.y + 1 or p.y >= r.end.y - 2:
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := p + Vector2i(dx, dy)
			if not m.in_bounds(q):
				return false
			if dx != 0 or dy != 0:
				if m.get_tile(q) == Tiles.WALL:
					return false
	return true


static func _safe_floor_tile(m: FloorMap, p: Vector2i, tile_id: int, occupied: Dictionary) -> void:
	if m.in_bounds(p) and m.get_tile(p) == Tiles.FLOOR and not occupied.has(p):
		m.set_tile(p, tile_id)


static func _stamp_room(m: FloorMap, r: Rect2i, arch: String, occupied: Dictionary) -> void:
	var c := Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)
	match arch:
		"pillared_hall":
			for py in [r.position.y + 2, r.end.y - 3]:
				for px in [r.position.x + 2, r.end.x - 3]:
					var p := Vector2i(px, py)
					if _can_pillar(m, p, r, occupied):
						m.set_tile(p, Tiles.WALL)
		"cross_vault":
			for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				var dv: Vector2i = d
				var p := Vector2i(c.x + dv.x, c.y + dv.y)
				if _can_pillar(m, p, r, occupied):
					m.set_tile(p, Tiles.WALL)
		"sanctuary_alcove":
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0)]:
				_safe_floor_tile(m, c + d, Tiles.SANCTUARY_FLOOR, occupied)
		"ambush_choke":
			var p1 := Vector2i(c.x - 1, c.y)
			var p2 := Vector2i(c.x + 1, c.y)
			if _can_pillar(m, p1, r, occupied):
				m.set_tile(p1, Tiles.WALL)
			if _can_pillar(m, p2, r, occupied):
				m.set_tile(p2, Tiles.WALL)
		"ritual_chamber":
			for d in [Vector2i(-1, -1), Vector2i(1, 1)]:
				_safe_floor_tile(m, c + d, Tiles.MIASMA if m.depth >= 5 else Tiles.ASH_EMBER, occupied)
			_safe_floor_tile(m, c, Tiles.SANCTUARY_FLOOR, occupied)
		"flooded_cistern":
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var p := c + Vector2i(dx, dy)
					if p.x > r.position.x and p.x < r.end.x - 1 and p.y > r.position.y and p.y < r.end.y - 1:
						_safe_floor_tile(m, p, Tiles.WATER_SHALLOW, occupied)
		"archive_stacks":
			for px in range(r.position.x + 2, r.end.x - 2, 2):
				var p := Vector2i(px, c.y)
				if _can_pillar(m, p, r, occupied):
					m.set_tile(p, Tiles.WALL)
		"gauntlet_corridor":
			for px in range(r.position.x + 1, r.end.x - 1):
				_safe_floor_tile(m, Vector2i(px, c.y), Tiles.IRON_GRATE, occupied)
		"settlement_court":
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					_safe_floor_tile(m, c + Vector2i(dx, dy), Tiles.SANCTUARY_FLOOR, occupied)
		"broken_cloister":
			_safe_floor_tile(m, c, Tiles.SANCTUARY_FLOOR, occupied)
			for d in [Vector2i(-1, 1), Vector2i(1, -1)]:
				_safe_floor_tile(m, c + d, Tiles.RIME_ICE if m.depth <= 3 else Tiles.SOLAR_GLARE, occupied)
