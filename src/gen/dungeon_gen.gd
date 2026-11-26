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


static func generate(floor_def: Dictionary, seed_value: int) -> FloorMap:
	var rng := Rng.new(seed_value)
	var m := FloorMap.new()
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
	m.up_pos = _center(m.rooms[0])
	m.set_tile(m.up_pos, Tiles.STAIRS_UP)
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
	if String(floor_def["exit"]) == "sealed_door":
		m.exit_pos = exit_c
		m.set_tile(exit_c, Tiles.DOOR_SEALED)
		occupied[exit_c] = true
		var guard_pos := _guard_spot(m, exit_c, dist)
		occupied[guard_pos] = true
		m.spawns.append({"kind": "monster", "id": String(floor_def["guardian"]), "pos": guard_pos, "guardian": true})
	else:
		m.down_pos = exit_c
		m.exit_pos = exit_c
		m.set_tile(exit_c, Tiles.STAIRS_DOWN)
		occupied[exit_c] = true

	var monster_rooms: Array[int] = []
	for i in range(1, m.rooms.size()):
		monster_rooms.append(i)
	var n_monsters := rng.range_i(int(floor_def["monsters_min"]), int(floor_def["monsters_max"]))
	for _i in n_monsters:
		var p := _free_spot(m, m.rooms[rng.pick(monster_rooms)], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		m.spawns.append({"kind": "monster", "id": rng.pick_weighted(floor_def["monster_table"]), "pos": p})
	var n_items := rng.range_i(int(floor_def["items_min"]), int(floor_def["items_max"]))
	for _i in n_items:
		var p := _free_spot(m, m.rooms[rng.range_i(0, m.rooms.size() - 1)], occupied, rng)
		if p.x < 0:
			continue
		occupied[p] = true
		m.spawns.append({"kind": "item", "id": rng.pick_weighted(floor_def["item_table"]), "pos": p})
	return m


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
