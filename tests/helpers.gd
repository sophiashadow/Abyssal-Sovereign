class_name TestHelpers
extends RefCounted
## Shared fixtures: cached content, and tiny hand-drawn worlds.

static var _db: ContentDB


static func content() -> ContentDB:
	if _db == null:
		_db = ContentDB.load_default()
	return _db


## Builds a one-floor world from ASCII art.
##   '#' wall  '.' floor  '>' stairs down  '<' stairs up  '+' sealed door  '@' player
##   any letter in `monsters` (letter -> monster id) places that monster on floor.
static func ascii_world(rows: Array, monsters: Dictionary = {}, species: String = "human",
		klass: String = "fallen_knight", seed_value: int = 1) -> World:
	var w := World.new()
	w.db = content()
	w.run_seed = seed_value
	w.rng = Rng.new(seed_value)
	w.player = w._make_player(species, klass, "Tester")
	var m := FloorMap.new()
	m.setup(String(rows[0]).length(), rows.size())
	m.depth = 1
	m.floor_id = "ossuary_warrens"
	for y in rows.size():
		var line := String(rows[y])
		for x in line.length():
			var c := line[x]
			var p := Vector2i(x, y)
			match c:
				"#":
					m.set_tile(p, Tiles.WALL)
				">":
					m.set_tile(p, Tiles.STAIRS_DOWN)
					m.down_pos = p
				"<":
					m.set_tile(p, Tiles.STAIRS_UP)
					m.up_pos = p
				"+":
					m.set_tile(p, Tiles.DOOR_SEALED)
					m.exit_pos = p
				_:
					m.set_tile(p, Tiles.FLOOR)
			if c == "@":
				w.player.pos = p
			elif monsters.has(c):
				m.actors.append(w._new_monster(String(monsters[c]), p))
	w.floors["ossuary_warrens"] = m
	w.floor_id = "ossuary_warrens"
	w.visited_floors = ["ossuary_warrens"]
	w.max_sphere_reached = 1
	w.depth = 1
	m.actors.insert(0, w.player)
	w.update_fov()
	return w


static func monster(w: World, template_id: String) -> Actor:
	for a in w.current_floor().actors:
		if a.template_id == template_id:
			return a
	return null
