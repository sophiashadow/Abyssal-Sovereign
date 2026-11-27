class_name VfxLayer
extends RefCounted
## M8.6 non-blocking cosmetic animation & visual feedback scheduler.
## Consumes World.events lazily via serial; never delays simulation turns,
## never modifies World, and isolates all cosmetic jitter in its own RNG.

var anim_speed: float = 1.0
var instant_actions: bool = false
var reduced_motion: bool = false
var screen_shake: bool = true
var particles_on: bool = true
var floating_text: bool = true
var flash_intensity: float = 0.6

var actor_offsets: Dictionary = {} ## actor_id -> {from: Vector2i, to: Vector2i, ttl: float, dur: float}
var lunges: Dictionary = {} ## actor_id -> {dir: Vector2, ttl: float, dur: float}
var slashes: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var shake_ttl: float = 0.0
var shake_dur: float = 0.14
var shake_mag: float = 0.0
var flash_ttl: float = 0.0
var flash_dur: float = 0.18
var flash_color := Color.TRANSPARENT

var _cosmetic_rng := RandomNumberGenerator.new()


func _init() -> void:
	_cosmetic_rng.seed = 0x5EED86


func clear() -> void:
	actor_offsets.clear()
	lunges.clear()
	slashes.clear()
	projectiles.clear()
	rings.clear()
	popups.clear()
	particles.clear()
	shake_ttl = 0.0
	flash_ttl = 0.0


func has_active() -> bool:
	return not actor_offsets.is_empty() or not lunges.is_empty() or not slashes.is_empty() or not projectiles.is_empty() \
		or not rings.is_empty() or not popups.is_empty() or not particles.is_empty() \
		or shake_ttl > 0.0 or flash_ttl > 0.0


func _dur(base: float) -> float:
	return base / clampf(anim_speed, 0.5, 2.0)


func consume_events(events: Array[Dictionary], last_serial: int, skip_anims: bool = false) -> int:
	var latest := last_serial
	for ev in events:
		var ser := int(ev.get("serial", 0))
		if ser <= last_serial:
			continue
		latest = maxi(latest, ser)
		if instant_actions or skip_anims:
			continue
		_handle_event(ev)
	return latest


func _dmg_color(dtype: String, is_player: bool) -> Color:
	if is_player:
		return Palette.ALERT
	match dtype:
		"fire":
			return Color("#ff7a33")
		"cold":
			return Color("#6ec6ff")
		"radiant":
			return Palette.FALSE_SUN
		"void":
			return Palette.LUX
	return Palette.IVORY


func _handle_event(ev: Dictionary) -> void:
	var kind := String(ev.get("kind", ""))
	match kind:
		"move":
			if not reduced_motion:
				var aid := int(ev.get("actor_id", 0))
				var dur := _dur(0.09)
				actor_offsets[aid] = {"from": ev.get("from", Vector2i.ZERO), "to": ev.get("to", Vector2i.ZERO), "ttl": dur, "dur": dur}
		"melee_hit":
			var from_p: Vector2i = ev.get("from", Vector2i.ZERO)
			var to_p: Vector2i = ev.get("to", Vector2i.ZERO)
			var is_p := bool(ev.get("is_player", false))
			var crit := bool(ev.get("crit", false))
			var col := _dmg_color(String(ev.get("dmg_type", "physical")), not is_p)
			if not reduced_motion:
				var aid := int(ev.get("actor_id", 0))
				if aid > 0:
					_add_lunge(aid, from_p, to_p)
				var dur := _dur(0.14)
				slashes.append({"from": from_p, "to": to_p, "color": col, "ttl": dur, "dur": dur})
				if screen_shake and (crit or not is_p):
					_trigger_shake(4.5 if crit else 2.5)
				_spawn_burst(to_p, col, 6 if crit else 3)
		"melee_miss":
			if not reduced_motion:
				var aid := int(ev.get("actor_id", 0))
				if aid > 0:
					_add_lunge(aid, ev.get("from", Vector2i.ZERO), ev.get("to", Vector2i.ZERO))
			if floating_text:
				var to_p: Vector2i = ev.get("to", Vector2i.ZERO)
				_add_popup(to_p, "MISS", Palette.TEXT_DIM)
		"ranged_shot":
			var from_p: Vector2i = ev.get("from", Vector2i.ZERO)
			var to_p: Vector2i = ev.get("to", Vector2i.ZERO)
			var col := _dmg_color(String(ev.get("dmg_type", "physical")), false)
			if not reduced_motion:
				var dur := _dur(0.14)
				projectiles.append({"from": from_p, "to": to_p, "color": col, "ttl": dur, "dur": dur})
				_spawn_burst(to_p, col, 4)
		"damage":
			var amt := int(ev.get("amount", 0))
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			var col := _dmg_color(String(ev.get("dmg_type", "physical")), bool(ev.get("is_player", false)))
			if floating_text and amt > 0:
				_add_popup(pos, "-%d" % amt, col)
		"heal":
			var amt := int(ev.get("amount", 0))
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			if floating_text and amt > 0:
				_add_popup(pos, "+%d" % amt, Palette.GOOD)
		"status_apply":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			var sid := String(ev.get("status", ""))
			if floating_text and sid != "":
				_add_popup(pos, sid.replace("_", " ").to_upper().substr(0, 10), Palette.FALSE_SUN)
		"telegraph":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			var dur := _dur(0.24)
			rings.append({"pos": pos, "color": Palette.FALSE_SUN, "radius": 0.9, "ttl": dur, "dur": dur})
		"trap_trigger":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			rings.append({"pos": pos, "color": Palette.ALERT, "radius": 0.85, "ttl": _dur(0.2), "dur": _dur(0.2)})
			if not reduced_motion and screen_shake:
				_trigger_shake(3.0)
			_spawn_burst(pos, Palette.ALERT, 5)
		"door_open":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			rings.append({"pos": pos, "color": Palette.GOLD, "radius": 0.75, "ttl": _dur(0.22), "dur": _dur(0.22)})
		"relic_work", "relic_transmute":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			var col := Palette.LUX if kind == "relic_transmute" else Palette.FALSE_SUN
			rings.append({"pos": pos, "color": col, "radius": 1.1, "ttl": _dur(0.26), "dur": _dur(0.26)})
			_trigger_flash(col, 0.25)
		"mask_switch":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			rings.append({"pos": pos, "color": Palette.LUX, "radius": 0.8, "ttl": _dur(0.2), "dur": _dur(0.2)})
		"subjugation", "entangled":
			var pos: Vector2i = ev.get("pos", Vector2i.ZERO)
			rings.append({"pos": pos, "color": Palette.ALERT, "radius": 1.2 if kind == "entangled" else 0.8, "ttl": _dur(0.28), "dur": _dur(0.28)})
			if kind == "entangled":
				if floating_text:
					_add_popup(pos, "ENTANGLED", Palette.ALERT)
				_trigger_flash(Palette.ALERT, 0.35)
		"death":
			_trigger_flash(Palette.BLOOD, 0.55)
			if not reduced_motion and screen_shake:
				_trigger_shake(6.0)
		"victory":
			_trigger_flash(Palette.FALSE_SUN, 0.4)


func _add_lunge(actor_id: int, from_p: Vector2i, to_p: Vector2i) -> void:
	if reduced_motion or instant_actions:
		return
	var delta := Vector2(to_p - from_p)
	if delta.length_squared() <= 0.0:
		return
	var dur := _dur(0.09)
	lunges[actor_id] = {"dir": delta.normalized(), "ttl": dur, "dur": dur}


func _add_popup(pos: Vector2i, text: String, col: Color) -> void:
	var dur := _dur(0.55)
	popups.append({"pos": pos, "text": text, "color": col, "ttl": dur, "dur": dur})


func _trigger_shake(mag: float) -> void:
	if reduced_motion or not screen_shake:
		return
	shake_mag = maxf(shake_mag, mag)
	shake_dur = _dur(0.14)
	shake_ttl = shake_dur


func _trigger_flash(col: Color, weight: float) -> void:
	if reduced_motion or flash_intensity <= 0.0:
		return
	flash_color = col
	flash_color.a = clampf(weight * flash_intensity, 0.0, 0.55)
	flash_dur = _dur(0.18)
	flash_ttl = flash_dur


func _spawn_burst(pos: Vector2i, col: Color, count: int) -> void:
	if reduced_motion or not particles_on:
		return
	for _i in count:
		var ang := _cosmetic_rng.randf_range(0.0, TAU)
		var spd := _cosmetic_rng.randf_range(0.6, 1.8)
		var dur := _dur(0.22)
		particles.append({"pos": Vector2(pos) + Vector2(0.5, 0.5), "vel": Vector2(cos(ang), sin(ang)) * spd, "color": col, "ttl": dur, "dur": dur})


func step(delta: float) -> bool:
	var any := false
	for aid in actor_offsets.keys():
		var e: Dictionary = actor_offsets[aid]
		e["ttl"] = float(e["ttl"]) - delta
		if float(e["ttl"]) <= 0.0:
			actor_offsets.erase(aid)
		else:
			any = true
	for aid in lunges.keys():
		var l: Dictionary = lunges[aid]
		l["ttl"] = float(l["ttl"]) - delta
		if float(l["ttl"]) <= 0.0:
			lunges.erase(aid)
		else:
			any = true
	for arr in [slashes, projectiles, rings, popups]:
		for i in range(arr.size() - 1, -1, -1):
			arr[i]["ttl"] = float(arr[i]["ttl"]) - delta
			if float(arr[i]["ttl"]) <= 0.0:
				arr.remove_at(i)
			else:
				any = true
	for i in range(particles.size() - 1, -1, -1):
		var pt: Dictionary = particles[i]
		pt["ttl"] = float(pt["ttl"]) - delta
		if float(pt["ttl"]) <= 0.0:
			particles.remove_at(i)
		else:
			pt["pos"] = Vector2(pt["pos"]) + Vector2(pt["vel"]) * delta * 3.5
			any = true
	if shake_ttl > 0.0:
		shake_ttl = maxf(0.0, shake_ttl - delta)
		any = true
	if flash_ttl > 0.0:
		flash_ttl = maxf(0.0, flash_ttl - delta)
		any = true
	return any


func screen_shake_offset() -> Vector2:
	if reduced_motion or not screen_shake or shake_ttl <= 0.0:
		return Vector2.ZERO
	var k := shake_ttl / maxf(0.001, shake_dur)
	return Vector2(_cosmetic_rng.randf_range(-1.0, 1.0), _cosmetic_rng.randf_range(-1.0, 1.0)) * (shake_mag * k)


func actor_tile_offset(actor_id: int) -> Vector2:
	if reduced_motion or instant_actions:
		return Vector2.ZERO
	var off := Vector2.ZERO
	if actor_offsets.has(actor_id):
		var e: Dictionary = actor_offsets[actor_id]
		var t := clampf(float(e["ttl"]) / maxf(0.001, float(e["dur"])), 0.0, 1.0)
		var delta_tile := Vector2(Vector2i(e["from"]) - Vector2i(e["to"]))
		off += delta_tile * t
	if lunges.has(actor_id):
		var l: Dictionary = lunges[actor_id]
		var prog := 1.0 - clampf(float(l["ttl"]) / maxf(0.001, float(l["dur"])), 0.0, 1.0)
		off += Vector2(l["dir"]) * (sin(PI * prog) * 0.30)
	return off


func draw_effects(canvas: CanvasItem, origin: Vector2i, offset: Vector2, px: int, font: Font, fsize: int, canvas_size: Vector2) -> void:
	for sl in slashes:
		var t := clampf(float(sl["ttl"]) / maxf(0.001, float(sl["dur"])), 0.0, 1.0)
		var c := Color(sl["color"], t)
		var p1 := offset + (Vector2(Vector2i(sl["to"]) - origin) + Vector2(0.2, 0.2)) * px
		var p2 := offset + (Vector2(Vector2i(sl["to"]) - origin) + Vector2(0.8, 0.8)) * px
		canvas.draw_line(p1, p2, c, 2.5)
	for pr in projectiles:
		var t := 1.0 - clampf(float(pr["ttl"]) / maxf(0.001, float(pr["dur"])), 0.0, 1.0)
		var a := offset + (Vector2(Vector2i(pr["from"]) - origin) + Vector2(0.5, 0.5)) * px
		var b := offset + (Vector2(Vector2i(pr["to"]) - origin) + Vector2(0.5, 0.5)) * px
		var cur := a.lerp(b, t)
		canvas.draw_line(a, cur, Color(pr["color"], 0.45), 1.5)
		canvas.draw_circle(cur, maxf(2.5, px * 0.12), pr["color"])
	for rg in rings:
		var prog := 1.0 - clampf(float(rg["ttl"]) / maxf(0.001, float(rg["dur"])), 0.0, 1.0)
		var ctr := offset + (Vector2(Vector2i(rg["pos"]) - origin) + Vector2(0.5, 0.5)) * px
		canvas.draw_arc(ctr, px * float(rg["radius"]) * (0.4 + 0.6 * prog), 0.0, TAU, 20, Color(rg["color"], 1.0 - prog), 2.0)
	for pt in particles:
		var t := clampf(float(pt["ttl"]) / maxf(0.001, float(pt["dur"])), 0.0, 1.0)
		var p := offset + (Vector2(pt["pos"]) - Vector2(origin)) * px
		canvas.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(pt["color"], t))
	for pp in popups:
		var prog := 1.0 - clampf(float(pp["ttl"]) / maxf(0.001, float(pp["dur"])), 0.0, 1.0)
		var p := offset + (Vector2(Vector2i(pp["pos"]) - origin) + Vector2(0.1, 0.2 - prog * 0.55)) * px
		var a := 1.0 - prog * 0.6
		var col := Color(pp["color"], a)
		var ps := maxi(10, int(fsize * 0.68))
		canvas.draw_string(font, p + Vector2(1, 1), String(pp["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ps, Color(Palette.VOID, a * 0.9))
		canvas.draw_string(font, p, String(pp["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ps, col)
	if flash_ttl > 0.0 and flash_color.a > 0.0:
		var alpha := flash_color.a * (flash_ttl / maxf(0.001, flash_dur))
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas_size), Color(flash_color.r, flash_color.g, flash_color.b, alpha))
