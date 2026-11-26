class_name DungeonGen
extends RefCounted
## Seeded rooms-and-corridors generator. Pure: same floor definition and seed
## always give the same FloorMap. It plans spawns but does not create actors;
## World turns the plan into entities, which keeps generation testable alone.
##
## Connectivity is guaranteed by construction: room i is always tunnelled to
## room i-1, and extra tunnels only add loops. Tests flood-fill to check it.

const ROOM_ATTEMPTS := 400
const LOOP_CHANCE_PCT := 18


static func generate(floor_def: Dictionary, seed_value: int, extra_portals: Array = []) -> FloorMap:
	var rng := Rng.new(seed_value)
	var m := FloorMap.new()
	m.floor_id = String(floor_def["id"])
	m.depth = int(floor_def["depth"])
	var w := int(floor_def["width"])
	var h := int(floor_def["height"])
	m.setup(w, h)

	var target := rng.range_i(int(floor_def["rooms_min"]), int(floor_def["rooms_max"]))
	for _attempt in ROOM_ATTEMPTS:
		if m.rooms.size() >= target:
			break
		var rw := rng.range_i(4, 10)
		var rh := rng.range_i(3, 7)
		var r := Rect2i(rng.range_i(1, w - rw - 2), rng.range_i(1, h - rh - 2), rw, rh)
		var ok := true
		for other in m.rooms:
			if r.grow(1).intersects(other):
				ok = false
				break
		if ok:
			m.rooms.append(r)
	# A tiny map that cannot fit two rooms still gets a playable layout.
	if m.rooms.size() < 2:
		m.rooms = [Rect2i(1, 1, 4, 3), Rect2i(w - 6, h - 5, 4, 3)]

	for r in m.rooms:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				m.set_tile(Vector2i(x, y), Tiles.FLOOR)
	for i in range(1, m.rooms.size()):
		_tunnel(m, _center(m.rooms[i - 1]), _center(m.rooms[i]), rng)
	for i in m.rooms.size():
		if rng.chance_pct(LOOP_CHANCE_PCT):
			var j := rng.range_i(0, m.rooms.size() - 1)
			if j != i:
				_tunnel(m, _center(m.rooms[i]), _center(m.rooms[j]), rng)

	# Start in room 0; the exit goes in the room farthest from it by walking distance.
	var rkind := String(floor_def.get("region_kind", "spine"))
	m.up_pos = _center(m.rooms[0])
	m.set_tile(m.up_pos, Tiles.STAIRS_UP if rkind == "spine" else Tiles.BRANCH_OUT)
	if rkind != "spine" and floor_def.has("parent"):
		m.portals.append({
			"x": m.up_pos.x, "y": m.up_pos.y,
			"target": String(floor_def["parent"]),
			"label": String(floor_def.get("parent_label", floor_def["parent"])),
			"kind": "branch_out",
		})
	var dist := Pathing.distance_map(m, m.up_pos)
	var far_room := 1
	var far_d := -1
	for i in range(1, m.rooms.size()):
		var d := dist[m.idx(_center(m.rooms[i]))]
		if d > far_d:
			far_d = d
			far_room = i
	var exit_c := _center(m.rooms[far_room])
	var occupied := {m.up_pos: true}
	var exit_kind := String(floor_def["exit"])
	if exit_kind == "sealed_door":
		m.exit_pos = exit_c
		m.set_tile(exit_c, Tiles.DOOR_SEALED)
		occupied[exit_c] = true
		var guard_pos := _guard_spot(m, exit_c, dist)
		occupied[guard_pos] = true
		m.spawns.append({"kind": "monster", "id": String(floor_def["guardian"]), "pos": guard_pos, "guardian": true})
	elif exit_kind == "stairs":
		m.down_pos = exit_c
		m.exit_pos = exit_c
		m.set_tile(exit_c, Tiles.STAIRS_DOWN)
		occupied[exit_c] = true
		var boss_id := String(floor_def.get("boss", ""))
		if boss_id != "":
			var boss_pos := _guard_spot(m, exit_c, dist)
			if boss_pos.x >= 0:
				occupied[boss_pos] = true
				m.spawns.append({"kind": "monster", "id": boss_id, "pos": boss_pos, "boss": true})
	else:
		# Branch end: reward cache or site in the farthest room instead of stairs down.
		m.exit_pos = exit_c
		var itable: Array = floor_def.get("item_table", [])
		if not itable.is_empty():
			occupied[exit_c] = true
			m.spawns.append({"kind": "item", "id": rng.pick_weighted(itable), "pos": exit_c, "magic": true})
		var boss_id := String(floor_def.get("boss", ""))
		if boss_id != "":
			var boss_pos := _guard_spot(m, exit_c, dist)
			if boss_pos.x >= 0:
				occupied[boss_pos] = true
				m.spawns.append({"kind": "monster", "id": boss_id, "pos": boss_pos, "boss": true})

	var portal_rooms: Array[int] = []
	for i in range(1, m.rooms.size()):
		portal_rooms.append(i)
	for ep in extra_portals:
		var p_room: Rect2i = m.rooms[rng.pick(portal_rooms)]
		var pp := _free_spot(m, p_room, occupied, rng)
		if pp.x < 0:
			for ri in portal_rooms:
				pp = _free_spot(m, m.rooms[ri], occupied, rng)
				if pp.x >= 0:
					break
		if pp.x >= 0:
			occupied[pp] = true
			var pkind := String(ep.get("kind", "branch_in"))
			m.set_tile(pp, Tiles.BRANCH_OUT if pkind == "branch_out" else Tiles.BRANCH_IN)
			m.portals.append({
				"x": pp.x, "y": pp.y,
				"target": String(ep["target"]),
				"label": String(ep.get("label", ep["target"])),
				"kind": pkind,
			})

	var monster_rooms: Array[int] = []
	for i in range(1, m.rooms.size()):
		monster_rooms.append(i)
	var regular_spawns: Array[int] = []
	var n_monsters := rng.range_i(int(floor_def["monsters_min"]), int(floor_def["monsters_max"]))
	var last_room := -1
	for i in n_monsters:
		# Group ~40% of encounters into multi-role squads inside the same room.
		var r_idx := last_room if (last_room >= 0 and i % 3 == 1 and rng.chance_pct(75)) else int(rng.pick(monster_rooms))
		last_room = r_idx
		var p := _free_spot(m, m.rooms[r_idx], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		regular_spawns.append(m.spawns.size())
		m.spawns.append({"kind": "monster", "id": rng.pick_weighted(floor_def["monster_table"]), "pos": p})
	if m.depth >= 2 and not regular_spawns.is_empty():
		var elite_count := 2 if m.depth >= 4 and regular_spawns.size() >= 4 else 1
		var chosen := {}
		for _e in elite_count:
			var idx := int(rng.pick(regular_spawns))
			if not chosen.has(idx):
				chosen[idx] = true
				m.spawns[idx]["elite"] = rng.pick(["cinder", "rime", "void", "iron", "radiant", "swift", "vampiric", "warded"])
	var n_items := rng.range_i(int(floor_def["items_min"]), int(floor_def["items_max"]))
	for _i in n_items:
		var p := _free_spot(m, m.rooms[rng.range_i(0, m.rooms.size() - 1)], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		m.spawns.append({"kind": "item", "id": rng.pick_weighted(floor_def["item_table"]), "pos": p})
	RoomArchetypes.apply_to_map(m, floor_def, occupied, rng)
	_place_ecology(m, floor_def, occupied, rng)
	return m


static func _place_ecology(m: FloorMap, floor_def: Dictionary, occupied: Dictionary, rng: Rng) -> void:
	var prof: Dictionary = Ecology.SPHERE_PROFILES.get(m.depth, Ecology.SPHERE_PROFILES[1])
	var non_start: Array[int] = []
	for i in range(1, m.rooms.size()):
		non_start.append(i)
	if non_start.is_empty():
		return
	var terrain := String(floor_def.get("terrain", "standard"))
	if terrain == "water":
		for _w in rng.range_i(4, 9):
			var wp := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
			if wp.x >= 0:
				occupied[wp] = true
				m.set_tile(wp, Tiles.WATER_SHALLOW)
	elif terrain == "sanctuary":
		var sr: Rect2i = m.rooms[rng.pick(non_start)]
		for sy in range(sr.position.y, sr.end.y):
			for sx in range(sr.position.x, sr.end.x):
				var sp := Vector2i(sx, sy)
				if m.get_tile(sp) == Tiles.FLOOR and not occupied.has(sp):
					m.set_tile(sp, Tiles.SANCTUARY_FLOOR)
	elif terrain == "iron_grate":
		for _g in rng.range_i(5, 10):
			var gp := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
			if gp.x >= 0:
				occupied[gp] = true
				m.set_tile(gp, Tiles.IRON_GRATE)
	var h_tile := int(prof["hazard"])
	if floor_def.has("hazard"):
		h_tile = Ecology.hazard_tile_from_name(String(floor_def["hazard"]))
	if h_tile >= 0:
		var n_haz := rng.range_i(int(prof["h_min"]), int(prof["h_max"]))
		for _h in n_haz:
			var p := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
			if p.x < 0:
				continue
			occupied[p] = true
			m.set_tile(p, h_tile)
	var trap_pool: Array = prof["traps"]
	var n_traps := 2 + m.depth / 2
	for _t in n_traps:
		var p := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		m.features.append({
			"kind": "trap", "sub": String(rng.pick(trap_pool)),
			"x": p.x, "y": p.y, "revealed": false, "used": false,
		})
	var sites_list: Array = []
	if floor_def.has("sites"):
		for skey in floor_def["sites"]:
			var sd := Ecology.site_def_from_key(String(skey))
			if not sd.is_empty():
				sites_list.append(sd)
	else:
		sites_list = prof["sites"]
	for sdef in sites_list:
		var p := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		var feat := {
			"kind": String(sdef["kind"]), "sub": String(sdef["sub"]),
			"x": p.x, "y": p.y, "revealed": true, "used": false,
		}
		if feat["kind"] == "merchant":
			var stock := []
			for _si in 3:
				stock.append({
					"id": String(rng.pick(Ecology.BROKER_POOL)),
					"price_hp": rng.range_i(4, 6),
					"sold": false,
				})
			feat["stock"] = stock
		m.features.append(feat)
	var emergent_kind := String(rng.pick(["rune_puzzle", "abandoned_rite", "sanctuary_hearth", "echo_cache"]))
	var ep := _free_spot(m, m.rooms[rng.pick(non_start)], occupied, rng)
	if ep.x >= 0:
		occupied[ep] = true
		m.features.append({"kind": emergent_kind, "sub": emergent_kind, "x": ep.x, "y": ep.y, "revealed": true, "used": false})
	var secret_candidates := _secret_wall_candidates(m)
	var n_secrets := mini(2, secret_candidates.size())
	for _s in n_secrets:
		var idx := rng.range_i(0, secret_candidates.size() - 1)
		var sp: Vector2i = secret_candidates[idx]
		secret_candidates.remove_at(idx)
		m.features.append({
			"kind": "secret_door", "sub": "cache",
			"x": sp.x, "y": sp.y, "revealed": false, "used": false,
		})


static func _secret_wall_candidates(m: FloorMap) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(2, m.height - 2):
		for x in range(2, m.width - 2):
			var p := Vector2i(x, y)
			if m.get_tile(p) != Tiles.WALL:
				continue
			var floor_nbrs := 0
			for d in Grid.DIRS_4:
				if m.get_tile(p + d) == Tiles.FLOOR:
					floor_nbrs += 1
			if floor_nbrs == 1:
				out.append(p)
	return out


static func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


static func _tunnel(m: FloorMap, a: Vector2i, b: Vector2i, rng: Rng) -> void:
	var corner := Vector2i(b.x, a.y) if rng.chance_pct(50) else Vector2i(a.x, b.y)
	_line(m, a, corner)
	_line(m, corner, b)


static func _line(m: FloorMap, a: Vector2i, b: Vector2i) -> void:
	var p := a
	var step := Grid.sign_vec(b - a)
	while true:
		if m.get_tile(p) == Tiles.WALL:
			m.set_tile(p, Tiles.FLOOR)
		if p == b:
			break
		p += step


## The guardian stands on the reachable tile next to the door that is closest to the start.
static func _guard_spot(m: FloorMap, door: Vector2i, dist: PackedInt32Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for d in Grid.DIRS_8:
		var n := door + d
		if m.get_tile(n) == Tiles.FLOOR and dist[m.idx(n)] >= 0 and dist[m.idx(n)] < best_d:
			best = n
			best_d = dist[m.idx(n)]
	return best


static func _free_spot(m: FloorMap, r: Rect2i, occupied: Dictionary, rng: Rng) -> Vector2i:
	for _t in 30:
		var p := Vector2i(rng.range_i(r.position.x, r.end.x - 1), rng.range_i(r.position.y, r.end.y - 1))
		if m.get_tile(p) == Tiles.FLOOR and not occupied.has(p):
			return p
	return Vector2i(-1, -1)
