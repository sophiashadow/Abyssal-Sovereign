class_name Pathing
extends RefCounted
## Breadth-first distance maps over the 8-connected grid. One map toward the
## player serves every monster in a turn, so chasing costs one flood fill per
## player action regardless of monster count.

const UNREACHED := -1


## Distance (in steps) from every tile to `goal`. When `known_only` is true,
## only explored tiles are crossed (used for tap-to-travel, so the player's
## route never reveals the unexplored map).
static func distance_map(map: FloorMap, goal: Vector2i, known_only: bool = false) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(map.width * map.height)
	dist.fill(UNREACHED)
	if not map.in_bounds(goal):
		return dist
	dist[map.idx(goal)] = 0
	var frontier: Array[Vector2i] = [goal]
	var head := 0
	while head < frontier.size():
		var cur := frontier[head]
		head += 1
		var cd := dist[map.idx(cur)]
		for d in Grid.DIRS_8:
			var n := cur + d
			if not map.in_bounds(n) or dist[map.idx(n)] != UNREACHED:
				continue
			if known_only and not map.is_explored(n):
				continue
			# Steps are symmetric, so "can step n -> cur" equals "cur -> n".
			if not map.can_step(cur, n):
				continue
			dist[map.idx(n)] = cd + 1
			frontier.append(n)
	return dist


## Best neighbouring step from `from` that lowers the distance. Tiles for
## which `blocked.call(pos)` is true are skipped (occupied tiles). Returns
## `from` when no step improves.
static func step_down(map: FloorMap, dist: PackedInt32Array, from: Vector2i, blocked: Callable) -> Vector2i:
	var best := from
	var best_d := dist[map.idx(from)] if map.in_bounds(from) else UNREACHED
	if best_d == UNREACHED:
		best_d = 1 << 30
	for d in Grid.DIRS_8:
		var n := from + d
		if not map.in_bounds(n):
			continue
		var nd := dist[map.idx(n)]
		if nd == UNREACHED or nd >= best_d:
			continue
		if not map.can_step(from, n) or blocked.call(n):
			continue
		best = n
		best_d = nd
	return best


## Full path from `from` to `to` (excluding `from`), or [] if unreachable.
static func path_to(map: FloorMap, from: Vector2i, to: Vector2i, known_only: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not map.in_bounds(to) or not map.is_walkable(to):
		return out
	var dist := distance_map(map, to, known_only)
	if dist[map.idx(from)] == UNREACHED:
		return out
	var cur := from
	var never := func(_p: Vector2i) -> bool: return false
	while cur != to:
		var nxt := step_down(map, dist, cur, never)
		if nxt == cur:
			return []
		out.append(nxt)
		cur = nxt
	return out
