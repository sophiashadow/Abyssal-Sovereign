class_name MapView
extends Control
## Dual-mode floor renderer ("tiles" or "glyph"), centred on the player, and
## input adapter turning taps/clicks into map coordinates. Short tap = tile_tapped;
## long press or right click = tile_inspected; scroll wheel = camera zoom.
## Presentation-only: never modifies World, Rng, or saves.

signal tile_tapped(pos: Vector2i)
signal tile_inspected(pos: Vector2i)
signal zoom_changed(new_zoom: float)

const LONG_PRESS_SEC := 0.45

var world: World
var registry: AssetRegistry
var tile_px: int = 32
var render_mode: String = "tiles" ## "tiles" or "glyph"
var integer_scale: bool = true
var camera_zoom: float = 1.0
var decorative_lighting: bool = true
var color_mode: int = 0
var high_contrast: bool = false
## Highlighted tile (look mode, travel target); (-1, -1) for none.
var marker := Vector2i(-1, -1)
var aim_path: Array[Vector2i] = []
var _font: Font
var _press_at := -1.0
var _press_pos := Vector2.ZERO


func _ready() -> void:
	_font = ThemeDB.fallback_font
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	# A held press turns into an inspect without waiting for release.
	if _press_at >= 0.0 and Time.get_ticks_msec() / 1000.0 - _press_at >= LONG_PRESS_SEC:
		_press_at = -1.0
		tile_inspected.emit(screen_to_tile(_press_pos))


func effective_tile_px() -> int:
	var raw := float(tile_px) * clampf(camera_zoom, 0.75, 2.0)
	if integer_scale:
		var snapped_mult := maxf(0.5, roundf(raw / 16.0) * 0.5)
		return clampi(int(roundf(snapped_mult * 32.0)), 12, 96)
	return clampi(int(roundf(raw)), 12, 96)


func _origin() -> Vector2i:
	var px := effective_tile_px()
	var cols := maxi(1, int(size.x / px))
	var rows := maxi(1, int(size.y / px))
	if world == null:
		return Vector2i.ZERO
	return world.player.pos - Vector2i(cols / 2, rows / 2)


func _offset() -> Vector2:
	var px := effective_tile_px()
	var cols := maxi(1, int(size.x / px))
	var rows := maxi(1, int(size.y / px))
	return Vector2((size.x - cols * px) / 2.0, (size.y - rows * px) / 2.0)


func screen_to_tile(p: Vector2) -> Vector2i:
	var px := effective_tile_px()
	var local := p - _offset()
	return _origin() + Vector2i(floori(local.x / px), floori(local.y / px))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			camera_zoom = clampf(camera_zoom + 0.25, 0.75, 2.0)
			zoom_changed.emit(camera_zoom)
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			camera_zoom = clampf(camera_zoom - 0.25, 0.75, 2.0)
			zoom_changed.emit(camera_zoom)
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			tile_inspected.emit(screen_to_tile(mb.position))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press_at = Time.get_ticks_msec() / 1000.0
				_press_pos = mb.position
			elif _press_at >= 0.0:
				_press_at = -1.0
				tile_tapped.emit(screen_to_tile(mb.position))
			accept_event()
	elif event is InputEventMouseMotion and _press_at >= 0.0:
		if (event as InputEventMouseMotion).position.distance_to(_press_pos) > effective_tile_px():
			_press_at = -1.0


## Pure spatial hash for cosmetic tile variants; never touches World.rng.
static func _tile_variant(p: Vector2i, floor_hash: int) -> int:
	var h := (p.x * 73856093) ^ (p.y * 19349663) ^ floor_hash
	return absi(h) & 3


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.VOID)
	if world == null:
		return
	var m := world.current_floor()
	var px := effective_tile_px()
	var cols := maxi(1, int(size.x / px))
	var rows := maxi(1, int(size.y / px))
	var o := _origin()
	var off := _offset()
	var fsize := maxi(10, int(px * 0.82))
	var floor_hash := int(m.floor_id.hash())
	var fdef := world.current_floor_def()
	var rkind := String(fdef.get("region_kind", "spine"))
	var use_tiles := render_mode == "tiles" and registry != null
	var sight := maxi(2, world.player.stat("sight"))

	var items := {}
	for it in m.items:
		items[it.pos] = it
	var actors := {}
	for a in m.actors:
		if a.is_alive():
			actors[a.pos] = a

	for cy in rows:
		for cx in cols:
			var p := o + Vector2i(cx, cy)
			if not m.in_bounds(p) or not m.is_explored(p):
				continue
			var vis := m.is_visible(p)
			var cell := off + Vector2(cx * px, cy * px)
			var rect := Rect2(cell, Vector2(px, px))
			var tile_id := m.get_tile(p)
			var feat := m.revealed_feature_at(p)
			var dist := Grid.chebyshev(world.player.pos, p)
			var shade := Color.WHITE
			if not vis:
				shade = Color(0.45, 0.43, 0.50, 1.0) if high_contrast else Color(0.32, 0.30, 0.37, 1.0)
			elif dist > sight - 2 and sight > 3:
				shade = Color(0.84, 0.82, 0.88, 1.0)
			if rkind == "sanctuary" and tile_id == Tiles.FLOOR:
				shade = shade.lerp(Color(0.88, 0.98, 0.94, 1.0), 0.14)
			elif rkind == "vault" and tile_id == Tiles.FLOOR:
				shade = shade.lerp(Color(0.98, 0.92, 0.82, 1.0), 0.12)
			elif rkind == "stronghold" and tile_id == Tiles.WALL:
				shade = shade.lerp(Color(0.96, 0.86, 0.86, 1.0), 0.12)

			if use_tiles:
				var treg := registry.tile_region(world.depth, tile_id, _tile_variant(p, floor_hash))
				if not treg.is_empty():
					draw_texture_rect_region(treg["texture"], rect, treg["rect"], shade)
					_draw_hazard_pattern(rect, tile_id, vis)
					var drew_top := false
					if not feat.is_empty():
						var fkind := String(feat.get("kind", ""))
						if fkind == "npc":
							if vis:
								var nreg := registry.npc_region(String(feat.get("sub", "")))
								if not nreg.is_empty():
									draw_texture_rect_region(nreg["texture"], rect, nreg["rect"], Color.WHITE)
									_draw_npc_signifier(rect)
									drew_top = true
						else:
							var freg := registry.feature_region(world.depth, fkind, bool(feat.get("used", false)))
							if not freg.is_empty():
								draw_texture_rect_region(freg["texture"], rect, freg["rect"], shade)
								if vis and Ecology.is_interactive(feat) and not bool(feat.get("used", false)):
									_draw_interactable_pip(rect)
					if items.has(p) and not actors.has(p):
						var it: Item = items[p]
						var ireg := registry.item_region(it, world.db)
						if not ireg.is_empty():
							var item_mod := Color.WHITE if vis else shade
							draw_texture_rect_region(ireg["texture"], rect, ireg["rect"], item_mod)
							_draw_item_frame(rect, it, vis)
							drew_top = true
					if vis and actors.has(p):
						var a: Actor = actors[p]
						if a.is_player:
							var layers := registry.player_layers(a)
							if not layers.is_empty():
								for lr in layers:
									draw_texture_rect_region(lr["texture"], rect, lr["rect"], Color.WHITE)
								_draw_player_ring(rect)
								drew_top = true
						else:
							var areg := registry.actor_region(a, world.db)
							if not areg.is_empty():
								_draw_actor_underlay(rect, a)
								draw_texture_rect_region(areg["texture"], rect, areg["rect"], Color.WHITE)
								_draw_actor_overlays(rect, a)
								drew_top = true
					if decorative_lighting and vis:
						_draw_lighting_tile(rect, tile_id, feat, dist)
					if drew_top or feat.is_empty() or not actors.has(p):
						continue
				# Fall through to glyph fallback if any atlas/region is missing.

			# Classic glyph renderer (also serves as graceful per-cell fallback).
			var glyph := String(Palette.TILE_GLYPH[tile_id])
			var col: Color = Palette.TILE_COLOR[tile_id]
			var role := "terrain"
			if Tiles.is_hazard(tile_id):
				role = "miasma" if tile_id == Tiles.MIASMA else ("danger" if tile_id == Tiles.ASH_EMBER else "hazard")
			elif tile_id == Tiles.STAIRS_DOWN:
				role = "gold"
			elif tile_id == Tiles.DOOR_SEALED:
				role = "danger"
			elif tile_id in [Tiles.DOOR_OPEN, Tiles.BRANCH_IN, Tiles.BRANCH_OUT]:
				role = "good"
			if vis and actors.has(p):
				var a: Actor = actors[p]
				glyph = a.glyph
				col = Color(a.color)
				role = "player" if a.is_player else "hostile"
			elif items.has(p):
				var it: Item = items[p]
				var d := it.def(world.db)
				glyph = String(d["glyph"])
				col = Color(it.effective_color(world.db)) if world.is_item_identified(it) else Color(String(d["color"]))
				if not world.is_item_identified(it) and (it.rarity != "common" or it.buc == "blessed"):
					col = col.lerp(Palette.FALSE_SUN, 0.35)
				role = "item"
			elif not feat.is_empty():
				glyph = Ecology.glyph(feat)
				col = Color(Ecology.color(feat))
				role = "friendly" if String(feat.get("kind", "")) == "npc" else ("danger" if String(feat.get("kind", "")) == "trap" else "feature")
			col = Palette.color_for_mode(col, role, color_mode, high_contrast)
			if not vis:
				col = Palette.remembered_hc(col, high_contrast)
			if vis and actors.has(p) and actors[p] != world.player:
				draw_rect(rect, Color(col, 0.18))
				if (actors[p] as Actor).tags.has("boss") or (actors[p] as Actor).is_elite:
					draw_rect(rect, Palette.color_for_mode(Palette.FALSE_SUN, "gold", color_mode, high_contrast), false, 1.5)
			_glyph(cell, glyph, col, fsize, px)

	if not aim_path.is_empty():
		var aim_col := Palette.color_for_mode(Palette.FALSE_SUN, "gold", color_mode, high_contrast)
		for ap in aim_path:
			if m.in_bounds(ap):
				var ac := off + Vector2(ap - o) * px
				draw_rect(Rect2(ac, Vector2(px, px)), Color(aim_col, 0.24))
				draw_rect(Rect2(ac + Vector2(3, 3), Vector2(px - 6, px - 6)), Color(aim_col, 0.65), false, 1.0)
	if m.in_bounds(marker):
		var mc := off + Vector2(marker - o) * px
		var mcol := Palette.color_for_mode(Palette.FALSE_SUN, "gold", color_mode, high_contrast)
		draw_rect(Rect2(mc, Vector2(px, px)), mcol, false, 2.0)


func _draw_hazard_pattern(rect: Rect2, tile_id: int, vis: bool) -> void:
	if not Tiles.is_hazard(tile_id):
		return
	var a := 0.35 if vis else 0.18
	var p := rect.position
	var s := rect.size
	match tile_id:
		Tiles.ASH_EMBER:
			var c := Palette.color_for_mode(Color("#ff7a33"), "danger", color_mode, high_contrast)
			draw_line(p + Vector2(3, s.y - 4), p + Vector2(9, s.y - 10), Color(c, a), 1.5)
		Tiles.RIME_ICE:
			draw_line(p + Vector2(3, 3), p + Vector2(8, 8), Color(Color("#6ec6ff"), a), 1.0)
		Tiles.MIASMA:
			var mc := Palette.color_for_mode(Color("#8f7ae0"), "miasma", color_mode, high_contrast)
			draw_circle(p + s * 0.5, s.x * 0.22, Color(mc, a * 0.5))
		Tiles.SOLAR_GLARE:
			draw_rect(rect, Color(Palette.FALSE_SUN, a * 0.25), false, 1.0)


func _draw_interactable_pip(rect: Rect2) -> void:
	var c := Palette.color_for_mode(Palette.FALSE_SUN, "gold", color_mode, high_contrast)
	var p := rect.position + Vector2(rect.size.x - 5, 4)
	draw_circle(p, 2.0, c)


func _draw_npc_signifier(rect: Rect2) -> void:
	var c := Palette.color_for_mode(Palette.GOOD, "friendly", color_mode, high_contrast)
	var top := rect.position + Vector2(rect.size.x - 5, 2)
	var pts := PackedVector2Array([top + Vector2(0, -2), top + Vector2(3, 1), top + Vector2(0, 4), top + Vector2(-3, 1)])
	draw_colored_polygon(pts, c)


func _draw_item_frame(rect: Rect2, it: Item, vis: bool) -> void:
	if not vis:
		return
	if it.rarity == "artifact":
		draw_rect(rect.grow(-1.0), Palette.LUX, false, 1.5)
	elif it.rarity == "rare" or (world.is_item_identified(it) and it.buc == "blessed"):
		draw_rect(rect.grow(-2.0), Palette.FALSE_SUN, false, 1.0)
	elif world.is_item_identified(it) and it.buc == "cursed":
		draw_rect(rect.grow(-2.0), Palette.color_for_mode(Palette.ALERT, "danger", color_mode, high_contrast), false, 1.0)


func _draw_player_ring(rect: Rect2) -> void:
	var c := Palette.color_for_mode(Palette.SILVER, "player", color_mode, high_contrast)
	draw_arc(rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 3), rect.size.x * 0.28, 0.0, TAU, 12, Color(c, 0.55), 1.0)


func _draw_actor_underlay(rect: Rect2, a: Actor) -> void:
	var hcol := Palette.color_for_mode(Palette.ALERT, "hostile", color_mode, high_contrast)
	var p := rect.position
	var w := rect.size.x
	var h := rect.size.y
	if a.tags.has("boss") or a.unique:
		var bcol := Palette.LUX if a.tags.has("boss") else Palette.FALSE_SUN
		draw_arc(rect.get_center(), w * 0.44, 0.0, TAU, 16, bcol, 1.5)
		draw_arc(rect.get_center(), w * 0.36, 0.0, TAU, 8, Color(hcol, 0.75), 1.0)
	elif a.is_elite:
		draw_rect(rect.grow(-1.0), Color(Palette.FALSE_SUN, 0.7), false, 1.2)
	# Hostile non-color corner brackets at bottom corners
	draw_line(p + Vector2(2, h - 6), p + Vector2(2, h - 2), hcol, 1.5)
	draw_line(p + Vector2(2, h - 2), p + Vector2(6, h - 2), hcol, 1.5)
	draw_line(p + Vector2(w - 2, h - 6), p + Vector2(w - 2, h - 2), hcol, 1.5)
	draw_line(p + Vector2(w - 6, h - 2), p + Vector2(w - 2, h - 2), hcol, 1.5)


func _draw_actor_overlays(rect: Rect2, a: Actor) -> void:
	var p := rect.position
	var w := rect.size.x
	if a.is_elite:
		var pts := PackedVector2Array([
			p + Vector2(w - 8, 5), p + Vector2(w - 6, 2), p + Vector2(w - 4, 5),
		])
		draw_colored_polygon(pts, Palette.FALSE_SUN)
	var max_hp := maxi(1, a.stat("max_hp"))
	if a.hp < max_hp:
		var frac := clampf(float(a.hp) / float(max_hp), 0.0, 1.0)
		var bar_w := w - 6.0
		var bar_p := p + Vector2(3.0, rect.size.y - 4.0)
		draw_rect(Rect2(bar_p, Vector2(bar_w, 2.5)), Palette.VOID)
		var hp_col := Palette.color_for_mode(Palette.ALERT, "hostile", color_mode, high_contrast)
		draw_rect(Rect2(bar_p, Vector2(bar_w * frac, 2.5)), hp_col)
	if bool(a.flags.get("telegraph_slam", false)) or a.has_status("telegraph_slam"):
		var warn := Palette.color_for_mode(Palette.FALSE_SUN, "gold", color_mode, high_contrast)
		draw_line(p + Vector2(4, 3), p + Vector2(4, 9), warn, 2.0)
		draw_circle(p + Vector2(4, 12), 1.2, warn)


func _draw_lighting_tile(rect: Rect2, tile_id: int, feat: Dictionary, dist: int) -> void:
	if dist <= 1:
		draw_rect(rect, Color(Palette.FALSE_SUN, 0.06))
	elif tile_id == Tiles.ASH_EMBER or String(feat.get("kind", "")) == "sanctuary_hearth":
		draw_rect(rect, Color(Color("#ff7a33"), 0.10))
	elif tile_id == Tiles.SOLAR_GLARE:
		draw_rect(rect, Color(Palette.FALSE_SUN, 0.09))


func _glyph(cell: Vector2, glyph: String, col: Color, fsize: int, px: int) -> void:
	var sz := _font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var asc := _font.get_ascent(fsize)
	var desc := _font.get_descent(fsize)
	var pos := cell + Vector2((px - sz.x) / 2.0, (px - (asc + desc)) / 2.0 + asc)
	draw_string(_font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
