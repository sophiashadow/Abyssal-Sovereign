extends Control
## Application shell: screens (title, creation, game, overlays), input, and
## autosave. Holds no rules: every game effect is a call on World. Screens
## are built in code so text and tile scaling apply everywhere uniformly.

const AUTOSAVE_EVERY_TURNS := 20
const LOG_LINES := 7

enum Screen { TITLE, CREATE, GAME, END, ERROR }

var db: ContentDB
var settings := GameSettings.new()
var world: World
var screen: Screen = Screen.TITLE

# Game screen widgets
var map: MapView
var hud: RichTextLabel
var log_view: RichTextLabel
var look_label: Label
var overlay: Control
var _log_seen := -1
var _last_depth := -1
var _last_save_turn := 0

# Interaction state
var look_mode := false
var aim_mode: Dictionary = {}
var travel: Array[Vector2i] = []
var _travel_seen := {}
var _travel_clock := 0.0

# Character creation choices
var _pick_species := ""
var _pick_class := ""


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	settings.load_from_disk()
	db = ContentDB.load_default()
	_apply_theme()
	if not db.is_valid():
		_show_error("The content pack failed validation:", db.errors)
		return
	_show_title()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_autosave()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_autosave()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if screen == Screen.GAME:
				if overlay != null:
					_close_overlay()
				else:
					_show_pause()
			elif screen == Screen.CREATE:
				_show_title()


# ================================================================ theme and widgets

func _fs(mult: float = 1.0) -> int:
	return int(round(20.0 * settings.text_scale() * mult))


func _apply_theme() -> void:
	var t := Theme.new()
	t.default_font_size = _fs()
	var normal := _box(Palette.PANEL, Palette.PANEL_EDGE)
	var hover := _box(Palette.PANEL.lightened(0.08), Palette.GOLD)
	var pressed := _box(Palette.PANEL_EDGE, Palette.FALSE_SUN)
	var focus := _box(Color(0, 0, 0, 0), Palette.FALSE_SUN)
	for state in ["normal", "disabled"]:
		t.set_stylebox(state, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.TEXT)
	t.set_color("font_pressed_color", "Button", Palette.FALSE_SUN)
	t.set_color("font_disabled_color", "Button", Palette.TEXT_DIM.darkened(0.3))
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(Palette.PANEL, Palette.PANEL_EDGE))
	t.set_stylebox("normal", "LineEdit", _box(Palette.VOID, Palette.PANEL_EDGE))
	t.set_stylebox("focus", "LineEdit", _box(Palette.VOID, Palette.FALSE_SUN))
	t.set_color("font_color", "LineEdit", Palette.TEXT)
	theme = t


func _box(bg: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(int(8 * settings.text_scale()))
	return s


func _btn(text: String, cb: Callable, min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 48.0 * settings.text_scale())
	b.pressed.connect(cb)
	return b


func _label(text: String, color: Color = Palette.TEXT, mult: float = 1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", _fs(mult))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _clear() -> void:
	for c in get_children():
		c.queue_free()
	map = null
	hud = null
	log_view = null
	look_label = null
	overlay = null
	travel.clear()
	look_mode = false
	aim_mode.clear()


func _background() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.VOID
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


## A centred, scrollable column for menu screens.
func _menu_column(max_width: float = 720.0) -> VBoxContainer:
	_background()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	center.add_child(margin)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(minf(max_width * settings.text_scale(), get_viewport_rect().size.x - 32.0), 0)
	col.add_theme_constant_override("separation", int(12 * settings.text_scale()))
	margin.add_child(col)
	return col


# ================================================================ title

func _show_title() -> void:
	_clear()
	screen = Screen.TITLE
	var col := _menu_column(520.0)
	var title := _label("ABYSSAL SOVEREIGN", Palette.LUX, 2.2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := _label("A descent beneath Terra Tenebrae", Palette.RECORD, 1.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(_label(""))
	if SaveIO.exists():
		var cont := _btn("Continue", _continue_run)
		col.add_child(cont)
		cont.call_deferred("grab_focus")
	var nb := _btn("New Run", _show_create)
	col.add_child(nb)
	if not SaveIO.exists():
		nb.call_deferred("grab_focus")
	col.add_child(_btn("Settings", func() -> void: _show_settings(_show_title)))
	if not OS.has_feature("web"):
		col.add_child(_btn("Quit", func() -> void: get_tree().quit()))
	var foot := _label("Set in the world of FALSE LIGHT. v0.5 (M5.2 Combat Depth)", Palette.TEXT_DIM, 0.75)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(foot)


func _continue_run() -> void:
	var errors: PackedStringArray = []
	var w := SaveIO.load_world(db, errors)
	if w == null:
		_show_error("The saved run could not be loaded:", errors, true)
		return
	_start_game(w)


func _show_error(heading: String, errors: PackedStringArray, offer_discard: bool = false) -> void:
	_clear()
	screen = Screen.ERROR
	var col := _menu_column()
	col.add_child(_label(heading, Palette.ALERT, 1.2))
	for i in mini(errors.size(), 20):
		col.add_child(_label("• " + errors[i], Palette.TEXT_DIM, 0.85))
	if errors.size() > 20:
		col.add_child(_label("(%d more)" % (errors.size() - 20), Palette.TEXT_DIM, 0.85))
	if offer_discard:
		col.add_child(_label("The file is left untouched unless you discard it.", Palette.TEXT_DIM, 0.85))
		col.add_child(_btn("Discard the saved run", func() -> void:
			SaveIO.delete()
			_show_title()))
	if db.is_valid():
		col.add_child(_btn("Back to title", _show_title))


# ================================================================ character creation

func _show_create() -> void:
	_clear()
	screen = Screen.CREATE
	if _pick_species == "":
		_pick_species = db.ids("species")[0]
	if _pick_class == "":
		_pick_class = db.ids("classes")[0]
	var col := _menu_column(900.0)
	col.add_child(_label("Who descends?", Palette.LUX, 1.5))

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Name (optional)"
	name_edit.max_length = 24
	name_edit.custom_minimum_size.y = 48.0 * settings.text_scale()
	col.add_child(name_edit)

	col.add_child(_label("Origin", Palette.GOLD, 1.1))
	var sp_desc := _label("", Palette.TEXT_DIM, 0.9)
	col.add_child(_choice_row("species", sp_desc))
	col.add_child(sp_desc)

	col.add_child(_label("Calling", Palette.GOLD, 1.1))
	var cl_desc := _label("", Palette.TEXT_DIM, 0.9)
	col.add_child(_choice_row("classes", cl_desc))
	col.add_child(cl_desc)

	var seed_edit := LineEdit.new()
	seed_edit.placeholder_text = "Seed (blank for random)"
	seed_edit.custom_minimum_size.y = 48.0 * settings.text_scale()
	col.add_child(seed_edit)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var begin := _btn("Begin the descent", func() -> void:
		var seed_text := seed_edit.text.strip_edges()
		var seed_value := seed_text.to_int() if seed_text.is_valid_int() else (Rng.derive(0, seed_text) if seed_text != "" else randi())
		_start_game(World.new_run(db, seed_value, _pick_species, _pick_class, name_edit.text)))
	begin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(begin)
	row.add_child(_btn("Back", _show_title, 140.0 * settings.text_scale()))
	col.add_child(row)
	begin.call_deferred("grab_focus")


func _choice_row(kind: String, desc: Label) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	var group := ButtonGroup.new()
	for id in db.ids(kind):
		var d := db.get_def(kind, id)
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = String(d["name"])
		b.custom_minimum_size = Vector2(200.0 * settings.text_scale(), 52.0 * settings.text_scale())
		var current := _pick_species if kind == "species" else _pick_class
		b.button_pressed = id == current
		b.toggled.connect(func(on: bool) -> void:
			if not on:
				return
			if kind == "species":
				_pick_species = id
			else:
				_pick_class = id
			desc.text = _describe_choice(kind, id))
		flow.add_child(b)
	desc.text = _describe_choice(kind, _pick_species if kind == "species" else _pick_class)
	return flow


func _describe_choice(kind: String, id: String) -> String:
	var d := db.get_def(kind, id)
	var parts: PackedStringArray = [String(d["description"])]
	var attrs: Dictionary = d.get("attributes", {})
	var a: PackedStringArray = []
	for k in ContentSchema.ATTRIBUTES:
		if int(attrs.get(k, 0)) != 0:
			a.append("%s %+d" % [k.capitalize(), int(attrs[k])])
	a.append("Health %+d" % int(d.get("hp", 0)))
	parts.append(", ".join(a))
	for t in d.get("traits", []):
		parts.append("%s: %s" % [String(t).capitalize(), Traits.describe(String(t))])
	if kind == "classes":
		var gear: PackedStringArray = []
		for g in d.get("starting_equipment", []) + d.get("starting_items", []):
			gear.append(String(db.get_def("items", String(g))["name"]))
		parts.append("Carries: " + ", ".join(gear))
	return "\n".join(parts)


# ================================================================ game screen

func _start_game(w: World) -> void:
	world = w
	_last_depth = world.depth
	_last_save_turn = world.turns
	_log_seen = -1
	SaveIO.save(world)
	_build_game_screen()


func _build_game_screen() -> void:
	_clear()
	_log_seen = -1
	screen = Screen.GAME
	_background()
	var s := settings.text_scale()
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	root.add_child(left)
	map = MapView.new()
	map.world = world
	map.tile_px = settings.tile_size()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.tile_tapped.connect(_on_tile_tapped)
	map.tile_inspected.connect(_on_tile_inspected)
	left.add_child(map)

	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size.y = _fs(0.85) * 1.45 * LOG_LINES + 16
	left.add_child(log_panel)
	var log_box := VBoxContainer.new()
	log_panel.add_child(log_box)
	look_label = _label("", Palette.FALSE_SUN, 0.85)
	look_label.visible = false
	log_box.add_child(look_label)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_following = true
	log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_view.add_theme_font_size_override("normal_font_size", _fs(0.85))
	log_view.mouse_filter = Control.MOUSE_FILTER_PASS
	log_box.add_child(log_view)

	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.custom_minimum_size.x = clampf(300.0 * s, 240.0, get_viewport_rect().size.x * 0.45)
	root.add_child(side_scroll)
	var side_panel := PanelContainer.new()
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(side_panel)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", int(8 * s))
	side_panel.add_child(side)
	hud = RichTextLabel.new()
	hud.bbcode_enabled = true
	hud.fit_content = true
	hud.scroll_active = false
	hud.add_theme_font_size_override("normal_font_size", _fs(0.85))
	hud.add_theme_font_size_override("bold_font_size", _fs(0.95))
	side.add_child(hud)

	var actions := GridContainer.new()
	actions.columns = 2 if settings.touch_controls else 3
	actions.add_theme_constant_override("h_separation", int(6 * s))
	actions.add_theme_constant_override("v_separation", int(6 * s))
	var action_specs: Array = [["Get", _act_pickup], ["Bag", _show_inventory], ["Build", _show_build], ["Act", _show_abilities],
			["Fire", _act_fire], ["Stairs", _act_stairs], ["Rest", _act_rest], ["Look", _toggle_look], ["Menu", _show_pause]]
	if world.player.has_trait("mask_stances"):
		action_specs.insert(5, ["Mask", _show_masks])
	for spec in action_specs:
		var b := _btn(spec[0], spec[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		actions.add_child(b)
	side.add_child(actions)

	if settings.touch_controls:
		var pad := GridContainer.new()
		pad.columns = 3
		pad.add_theme_constant_override("h_separation", int(4 * s))
		pad.add_theme_constant_override("v_separation", int(4 * s))
		var cell := 64.0 * s
		var arrows := ["↖", "↑", "↗", "←", "·", "→", "↙", "↓", "↘"]
		var dirs := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i.ZERO,
			Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
		for i in 9:
			var dir: Vector2i = dirs[i]
			var b := _btn(arrows[i], func() -> void: _act_dir(dir), cell)
			b.custom_minimum_size = Vector2(cell, cell)
			b.focus_mode = Control.FOCUS_NONE
			b.tooltip_text = "Wait" if dir == Vector2i.ZERO else ""
			pad.add_child(b)
		var pad_center := CenterContainer.new()
		pad_center.add_child(pad)
		side.add_child(pad_center)
	else:
		var mask_hint := "   Mask: m" if world.player.has_trait("mask_stances") else ""
		side.add_child(_label("Move: arrows, numpad or hjklyubn\nWait: . or 5   Get: g   Bag: i%s\nBuild: c   Act: a (1-6)   Fire: f\nStairs: Enter   Rest: r   Look: x\nTap a known tile to travel; hold or right-click to inspect. Menu: Esc" % mask_hint, Palette.TEXT_DIM, 0.7))
	_refresh()


func _refresh() -> void:
	if world == null or map == null:
		return
	map.queue_redraw()
	_update_hud()
	if world.log_serial != _log_seen:
		_log_seen = world.log_serial
		var lines: PackedStringArray = []
		var start := maxi(0, world.messages.size() - 60)
		for i in range(start, world.messages.size()):
			var msg: Dictionary = world.messages[i]
			lines.append("[color=#%s]%s[/color]" % [Palette.log_color(String(msg["k"])).to_html(false), _escape(String(msg["t"]))])
		log_view.text = "\n".join(lines)


func _escape(t: String) -> String:
	return t.replace("[", "[lb]")


func _update_hud() -> void:
	var p := world.player
	var fd := db.floor_for_depth(world.depth)
	var mx := p.stat("max_hp")
	var hp_col := Palette.GOOD if p.hp * 2 > mx else (Palette.FALSE_SUN if p.hp * 4 > mx else Palette.ALERT)
	var t: PackedStringArray = []
	t.append("[b][color=#%s]%s[/color][/b]" % [Palette.LUX.to_html(false), _escape(p.name)])
	t.append("%s %s, level %d" % [db.get_def("species", p.species_id)["name"], db.get_def("classes", p.class_id)["name"], p.level])
	t.append("Health [color=#%s]%d / %d[/color]" % [hp_col.to_html(false), p.hp, mx])
	if p.resource_label() != "":
		t.append("%s %d / %d" % [p.resource_label(), p.resource, p.max_resource()])
	t.append("XP %d / %d" % [p.xp, World.xp_for_level(p.level + 1)])
	if p.stat_points > 0 or p.talent_points > 0:
		t.append("[color=#%s]Unspent: %d stat, %d talent (Build)[/color]" % [Palette.FALSE_SUN.to_html(false), p.stat_points, p.talent_points])
	var sphere := String(fd.get("sphere", ""))
	t.append("Depth %d (%s): %s" % [world.depth, sphere, fd.get("name", "")] if sphere != "" else "Depth %d: %s" % [world.depth, fd.get("name", "")])
	t.append("Attack %+d  Defense %d  Evasion %+d" % [p.stat("accuracy"), p.stat("defense"), p.stat("evasion")])
	var w := p.equipped("weapon")
	t.append("Wielding: %s (%s)" % [w.display_name(db), p.damage_dice()] if w != null else "Wielding: bare hands (1d2)")
	var rw := p.equipped("ranged")
	if rw != null:
		var rwd := rw.def(db)
		t.append("Ranged: %s (%s, rng %d)" % [rw.display_name(db), rwd["damage"], int(rwd["range"])])
	if p.has_trait("mask_stances"):
		t.append("Mask: [color=%s]%s[/color] (risk %d/%d)" % [Masks.color(p.mask), Masks.label(p.mask), p.mask_risk, World.MASK_RISK_MAX])
	for s in p.statuses:
		var sd := db.get_def("statuses", s["id"])
		t.append("[color=%s]%s (%d)[/color]" % [String(sd.get("color", "#eee5d3")), sd["name"], int(s["turns"])])
	if world.apotheosis >= World.APOTHEOSIS_THRESHOLD:
		t.append("[color=#%s]Apotheosis guard active[/color]" % Palette.FALSE_SUN.to_html(false))
	var foes := world.visible_hostiles()
	if not foes.is_empty():
		t.append("[color=#%s]In view: %d[/color]" % [Palette.ALERT.to_html(false), foes.size()])
	t.append("[color=#%s]Turn %d[/color]" % [Palette.TEXT_DIM.to_html(false), world.turns])
	hud.text = "\n".join(t)


## Called after any player action: redraw, autosave, and end-of-run screens.
func _after_action() -> void:
	aim_mode.clear()
	look_label.visible = false
	if map != null:
		map.aim_path = []
		map.marker = Vector2i(-1, -1) if travel.is_empty() else travel[travel.size() - 1]
	if world.state != World.State.PLAYING:
		travel.clear()
		SaveIO.delete()
		_refresh()
		_show_end()
		return
	if world.depth != _last_depth or world.turns - _last_save_turn >= AUTOSAVE_EVERY_TURNS:
		_last_depth = world.depth
		_autosave()
	_refresh()


func _autosave() -> void:
	if world != null and world.state == World.State.PLAYING and screen == Screen.GAME:
		if SaveIO.save(world) == OK:
			_last_save_turn = world.turns


# ================================================================ actions

func _act_dir(dir: Vector2i) -> void:
	if overlay != null or world.state != World.State.PLAYING:
		return
	travel.clear()
	if dir == Vector2i.ZERO:
		world.player_wait()
	else:
		world.player_move(dir)
	_after_action()


func _act_pickup() -> void:
	if overlay == null:
		world.player_pickup()
		_after_action()


func _act_stairs() -> void:
	if overlay == null:
		if world.needs_gate_to_descend():
			_show_gate()
		else:
			world.player_stairs()
			_after_action()


func _act_rest() -> void:
	if overlay == null:
		world.player_rest()
		_after_action()


func _act_fire() -> void:
	if overlay != null or world.state != World.State.PLAYING:
		return
	var w := world.player.equipped("ranged")
	if w == null:
		world.log_msg("You have no ranged weapon equipped.", "info")
		_after_action()
		return
	var d := w.def(db)
	_start_aim("fire", {"range": int(d.get("range", 5)), "name": String(d["name"]),
		"acc": int(d.get("accuracy", 0)), "dtype": String(d.get("damage_type", "physical"))})


func _aim_targets(max_range: int) -> Array[Actor]:
	var foes: Array[Actor] = []
	for a in world.visible_hostiles():
		if Grid.chebyshev(world.player.pos, a.pos) <= max_range:
			foes.append(a)
	foes.sort_custom(func(a: Actor, b: Actor) -> bool:
		return Grid.chebyshev(world.player.pos, a.pos) < Grid.chebyshev(world.player.pos, b.pos))
	return foes


func _start_aim(kind: String, payload: Dictionary) -> void:
	travel.clear()
	look_mode = false
	aim_mode = payload.duplicate(true)
	aim_mode["kind"] = kind
	var max_r := int(aim_mode.get("range", 5))
	var foes := _aim_targets(max_r)
	if not foes.is_empty() and String(aim_mode.get("targeting", "enemy")) != "tile":
		aim_mode["target"] = foes[0].pos
	else:
		aim_mode["target"] = world.player.pos
	_update_aim_visual()


func _cancel_aim() -> void:
	aim_mode.clear()
	look_label.visible = false
	if map != null:
		map.aim_path = []
		map.marker = Vector2i(-1, -1)
		map.queue_redraw()


func _cycle_aim() -> void:
	var max_r := int(aim_mode.get("range", 5))
	var foes := _aim_targets(max_r)
	if foes.is_empty():
		return
	var cur: Vector2i = aim_mode.get("target", Vector2i(-1, -1))
	var next_idx := 0
	for i in foes.size():
		if foes[i].pos == cur:
			next_idx = (i + 1) % foes.size()
			break
	aim_mode["target"] = foes[next_idx].pos
	_update_aim_visual()


func _update_aim_visual() -> void:
	if aim_mode.is_empty() or map == null:
		return
	var t: Vector2i = aim_mode.get("target", world.player.pos)
	var max_r := int(aim_mode.get("range", 5))
	var tr := world.projectile_trace(world.player.pos, t, max_r)
	map.marker = t
	map.aim_path = tr["path"]
	map.queue_redraw()
	var foe := world.current_floor().actor_at(t)
	var hint := "Tap tile or Enter/f to confirm; Tab cycles foes; Esc cancels."
	if foe != null and not foe.is_player:
		var dist := Grid.chebyshev(world.player.pos, t)
		var pct := Combat.ranged_hit_chance(world.player, foe, dist, int(aim_mode.get("acc", 0)), String(aim_mode.get("dtype", "physical")))
		look_label.text = "Aim (%s): %s (%d%% hit). %s" % [aim_mode.get("name", ""), foe.name, pct, hint]
	else:
		look_label.text = "Aim (%s): (%d,%d). %s" % [aim_mode.get("name", ""), t.x, t.y, hint]
	look_label.visible = true


func _confirm_aim() -> void:
	if aim_mode.is_empty():
		return
	var kind := String(aim_mode.get("kind", ""))
	var t: Vector2i = aim_mode.get("target", Vector2i(-1, -1))
	var acted := false
	match kind:
		"fire":
			acted = world.player_fire(t)
		"item":
			acted = world.player_use_at(int(aim_mode.get("index", -1)), t)
		"talent":
			acted = world.player_use_talent(String(aim_mode.get("tid", "")), t)
	_cancel_aim()
	if acted:
		_after_action()
	else:
		_refresh()


func _toggle_look() -> void:
	_cancel_aim()
	look_mode = not look_mode
	look_label.visible = look_mode
	look_label.text = "Look: tap a tile to inspect it." if look_mode else ""


func _on_tile_inspected(p: Vector2i) -> void:
	look_mode = false
	map.marker = p
	look_label.text = world.describe_at(p)
	look_label.visible = true
	map.queue_redraw()


func _on_tile_tapped(p: Vector2i) -> void:
	if overlay != null or world.state != World.State.PLAYING:
		return
	if not aim_mode.is_empty():
		aim_mode["target"] = p
		_confirm_aim()
		return
	if look_mode:
		_on_tile_inspected(p)
		return
	travel.clear()
	var me := world.player.pos
	if p == me:
		if not world.current_floor().items_at(me).is_empty():
			world.player_pickup()
		elif world.current_floor().get_tile(me) in [Tiles.STAIRS_DOWN, Tiles.STAIRS_UP]:
			_act_stairs()
			return
		else:
			world.player_wait()
		_after_action()
		return
	if Grid.is_adjacent(me, p):
		world.player_move(p - me)
		_after_action()
		return
	var path := Pathing.path_to(world.current_floor(), me, p, true)
	if path.is_empty():
		look_label.text = "You know no way there."
		look_label.visible = true
		return
	travel = path
	_travel_seen = {}
	for a in world.visible_hostiles():
		_travel_seen[a.id] = true
	_travel_clock = 0.0
	map.marker = p
	map.queue_redraw()


func _process(delta: float) -> void:
	if travel.is_empty() or screen != Screen.GAME or overlay != null:
		return
	_travel_clock += delta
	var interval := 1.0 / float(settings.travel_speed)
	while _travel_clock >= interval and not travel.is_empty():
		_travel_clock -= interval
		var next: Vector2i = travel.pop_front()
		var me := world.player.pos
		if not Grid.is_adjacent(me, next) or world.current_floor().actor_at(next) != null:
			travel.clear()
			break
		world.player_move(next - me)
		var spotted: Actor = null
		for a in world.visible_hostiles():
			if not _travel_seen.has(a.id):
				spotted = a
				break
		if spotted != null:
			travel.clear()
		_after_action()
		if world.state != World.State.PLAYING:
			return
		if spotted != null:
			look_label.text = "You stop: the %s comes into view." % spotted.name
			look_label.visible = true
		if travel.is_empty():
			break


const KEY_DIRS := {
	KEY_UP: Vector2i(0, -1), KEY_KP_8: Vector2i(0, -1), KEY_K: Vector2i(0, -1),
	KEY_DOWN: Vector2i(0, 1), KEY_KP_2: Vector2i(0, 1), KEY_J: Vector2i(0, 1),
	KEY_LEFT: Vector2i(-1, 0), KEY_KP_4: Vector2i(-1, 0), KEY_H: Vector2i(-1, 0),
	KEY_RIGHT: Vector2i(1, 0), KEY_KP_6: Vector2i(1, 0), KEY_L: Vector2i(1, 0),
	KEY_KP_7: Vector2i(-1, -1), KEY_Y: Vector2i(-1, -1),
	KEY_KP_9: Vector2i(1, -1), KEY_U: Vector2i(1, -1),
	KEY_KP_1: Vector2i(-1, 1), KEY_B: Vector2i(-1, 1),
	KEY_KP_3: Vector2i(1, 1), KEY_N: Vector2i(1, 1),
}


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed():
		return
	var k := event as InputEventKey
	if k.keycode == KEY_ESCAPE:
		if screen == Screen.GAME:
			if overlay != null:
				_close_overlay()
			elif not aim_mode.is_empty():
				_cancel_aim()
			elif look_mode or not travel.is_empty():
				travel.clear()
				if look_mode:
					_toggle_look()
			else:
				_show_pause()
			get_viewport().set_input_as_handled()
		elif screen == Screen.CREATE:
			_show_title()
		return
	if screen != Screen.GAME or overlay != null or world.state != World.State.PLAYING:
		return
	if not aim_mode.is_empty():
		get_viewport().set_input_as_handled()
		if k.keycode == KEY_TAB:
			_cycle_aim()
		elif k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_F]:
			_confirm_aim()
		return
	get_viewport().set_input_as_handled()
	if k.unicode == 62 or k.unicode == 60 or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		_act_stairs()
	elif KEY_DIRS.has(k.keycode):
		_act_dir(KEY_DIRS[k.keycode])
	elif k.keycode in [KEY_PERIOD, KEY_KP_5, KEY_SPACE, KEY_KP_PERIOD]:
		_act_dir(Vector2i.ZERO)
	elif k.keycode in [KEY_G, KEY_COMMA]:
		_act_pickup()
	elif k.keycode == KEY_I:
		_show_inventory()
	elif k.keycode == KEY_R:
		_act_rest()
	elif k.keycode == KEY_X:
		_toggle_look()
	elif k.keycode == KEY_M:
		_show_masks()
	elif k.keycode == KEY_C:
		_show_build()
	elif k.keycode == KEY_A:
		_show_abilities()
	elif k.keycode == KEY_F:
		_act_fire()
	elif k.keycode >= KEY_1 and k.keycode <= KEY_6:
		var idx := k.keycode - KEY_1
		var acts := world.learned_active_talents()
		if idx < acts.size() and world.player_use_talent(acts[idx]):
			_after_action()


# ================================================================ overlays

func _show_build() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var p := world.player
	var col := _open_overlay("Character Build")
	col.add_child(_label("Stat points: %d   Talent points: %d   Level %d" % [p.stat_points, p.talent_points, p.level], Palette.FALSE_SUN, 0.9))
	col.add_child(_label("Attributes (Might %d, Agility %d, Will %d)" % [p.stat("might"), p.stat("agility"), p.stat("will")], Palette.GOLD, 0.9))
	var res_parts: PackedStringArray = []
	for dt in ContentSchema.DAMAGE_TYPES:
		var rv := p.resist(dt)
		if rv != 0:
			res_parts.append("%s %+d%%" % [dt.capitalize(), rv])
	if not res_parts.is_empty():
		col.add_child(_label("Resists: " + ", ".join(res_parts), Palette.RECORD, 0.85))
	var attr_row := HBoxContainer.new()
	attr_row.add_theme_constant_override("separation", 8)
	for attr in ContentSchema.ATTRIBUTES:
		var attr_name: String = attr
		var b := _btn("+1 %s" % attr_name.capitalize(), func() -> void:
			if world.player_spend_stat(attr_name):
				_refresh()
				_show_build())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = p.stat_points <= 0
		attr_row.add_child(b)
	col.add_child(attr_row)

	var by_tree := {}
	for tid in db.ids("talents"):
		var td := db.get_def("talents", tid)
		if String(td["class_id"]) != p.class_id:
			continue
		var tname := String(td["tree"])
		if not by_tree.has(tname):
			by_tree[tname] = []
		by_tree[tname].append(td)
	for tname in by_tree:
		col.add_child(_label(String(tname), Palette.GOLD, 1.0))
		var list: Array = by_tree[tname]
		list.sort_custom(func(a, b): return int(a["tier"]) < int(b["tier"]))
		for td in list:
			var tid := String(td["id"])
			var rank := p.talent_rank(tid)
			var max_r := int(td["max_rank"])
			var reason := world.can_learn_talent(tid)
			var tag := "Active (%d %s, %dcd)" % [int(td.get("cost", 0)), p.resource_label(), int(td.get("cooldown", 0))] if String(td["kind"]) == "active" else "Passive"
			var label_txt := "%s [%d/%d] — %s" % [td["name"], rank, max_r, tag]
			var b := _btn(label_txt, func() -> void:
				if world.player_learn_talent(tid):
					_refresh()
					_show_build())
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = reason != ""
			col.add_child(b)
			var desc := String(td["description"]) if reason == "" or rank >= max_r else "%s (%s)" % [td["description"], reason]
			col.add_child(_label(desc, Palette.TEXT_DIM, 0.78))
	col.add_child(_btn("Close", _close_overlay))


func _show_abilities() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var p := world.player
	var acts := world.learned_active_talents()
	var col := _open_overlay("Abilities (%s %d/%d)" % [p.resource_label(), p.resource, p.max_resource()])
	if acts.is_empty():
		col.add_child(_label("No active talents learned yet. Open Build to spend talent points.", Palette.TEXT_DIM))
	for i in acts.size():
		var tid := acts[i]
		var td := db.get_def("talents", tid)
		var cost := int(td.get("cost", 0))
		var cd := p.cooldown(tid)
		var key_tag := "[%d] " % (i + 1) if i < 6 else ""
		var status_tag := "CD %d" % cd if cd > 0 else ("%d %s" % [cost, p.resource_label()])
		var b := _btn("%s%s (%s)" % [key_tag, td["name"], status_tag], func() -> void:
			_close_overlay()
			if String(td.get("targeting", "")) == "tile":
				_start_aim("talent", {"tid": tid, "range": int(td.get("range", 4)), "name": String(td["name"]), "targeting": "tile"})
			elif world.player_use_talent(tid):
				_after_action())
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = cd > 0 or p.resource < cost
		col.add_child(b)
		col.add_child(_label(String(td["description"]), Palette.TEXT_DIM, 0.78))
	col.add_child(_btn("Close", _close_overlay))


func _show_gate() -> void:
	if not world.needs_gate_to_descend() or overlay != null:
		return
	var next_fd := db.floor_for_depth(world.depth + 1)
	var sphere := String(next_fd.get("sphere", "the next sphere"))
	var col := _open_overlay("Sphere Gate: %s" % sphere, Palette.FALSE_SUN)
	col.add_child(_label("Choose how to cross into %s:" % next_fd.get("name", sphere), Palette.TEXT_DIM, 0.85))
	var choices := [
		["stormed", "Stormed", "Force the gate (-3 HP, +apotheosis)."],
		["serpents_key", "Serpent's Key", "Slip the seam (-2 HP, Serpent's Way, +apotheosis)."],
		["given_back", "Given Back", "Surrender 1 consumable (or 3 HP); Way of Return, -apotheosis."],
		["by_name", "By Name", "Speak your name (-apotheosis; alerts the nearest foe below)."],
	]
	var first: Button = null
	for ch in choices:
		var method: String = ch[0]
		var b := _btn(ch[1], func() -> void:
			_close_overlay()
			if world.player_descend_gate(method):
				_after_action())
		col.add_child(b)
		col.add_child(_label(ch[2], Palette.TEXT_DIM, 0.78))
		if first == null:
			first = b
	col.add_child(_btn("Cancel", _close_overlay))
	if first != null:
		first.call_deferred("grab_focus")


func _show_masks() -> void:
	if not world.player.has_trait("mask_stances") or overlay != null:
		return
	var col := _open_overlay("Masks (risk %d/%d)" % [world.player.mask_risk, World.MASK_RISK_MAX])
	for mid in Masks.ORDER:
		var active := world.player.mask == mid
		var title := "%s (worn)" % Masks.label(mid) if active else Masks.label(mid)
		var b := _btn(title, func() -> void:
			_close_overlay()
			if world.player_switch_mask(mid):
				_after_action()
		)
		b.disabled = active
		col.add_child(b)
		col.add_child(_label(Masks.summary(mid), Palette.TEXT_DIM, 0.78))
	col.add_child(_btn("Close", _close_overlay))


## A modal panel over the game screen. Returns the column to fill.
func _open_overlay(title: String, title_color: Color = Palette.LUX) -> VBoxContainer:
	_close_overlay()
	travel.clear()
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(Palette.VOID, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	center.add_child(margin)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(640.0 * settings.text_scale(), get_viewport_rect().size.x - 32.0)
	margin.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", int(10 * settings.text_scale()))
	panel.add_child(col)
	col.add_child(_label(title, title_color, 1.3))
	return col


func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
	if screen == Screen.GAME:
		_refresh()


func _show_pause() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var col := _open_overlay("Paused")
	var fd := db.floor_for_depth(world.depth)
	col.add_child(_label("%s. Seed %d." % [fd.get("name", ""), world.run_seed], Palette.TEXT_DIM, 0.85))
	var resume := _btn("Resume", _close_overlay)
	col.add_child(resume)
	col.add_child(_btn("Settings", func() -> void: _show_settings(_build_game_screen)))
	col.add_child(_btn("Save and return to title", func() -> void:
		_autosave()
		world = null
		_show_title()))
	resume.call_deferred("grab_focus")


func _show_settings(back: Callable) -> void:
	var col: VBoxContainer
	if screen == Screen.GAME:
		col = _open_overlay("Settings")
	else:
		_clear()
		col = _menu_column(620.0)
		col.add_child(_label("Settings", Palette.LUX, 1.3))
	var rebuild := func() -> void:
		settings.save_to_disk()
		_apply_theme()
		_show_settings(back)
	col.add_child(_stepper("Text size", "%d%%" % int(round(settings.text_scale() * 100)),
		func(d: int) -> void:
			settings.text_scale_index = clampi(settings.text_scale_index + d, 0, GameSettings.TEXT_SCALES.size() - 1)
			rebuild.call()))
	col.add_child(_stepper("Map tile size", "%d px" % settings.tile_size(),
		func(d: int) -> void:
			settings.tile_size_index = clampi(settings.tile_size_index + d, 0, GameSettings.TILE_SIZES.size() - 1)
			rebuild.call()))
	col.add_child(_stepper("Travel speed", "%d steps/s" % settings.travel_speed,
		func(d: int) -> void:
			settings.travel_speed = clampi(settings.travel_speed + d * 5, 5, 60)
			rebuild.call()))
	var touch := _btn("On-screen controls: %s" % ("on" if settings.touch_controls else "off"), func() -> void:
		settings.touch_controls = not settings.touch_controls
		rebuild.call())
	col.add_child(touch)
	var done := _btn("Done", func() -> void:
		settings.save_to_disk()
		_apply_theme()
		back.call())
	col.add_child(done)
	done.call_deferred("grab_focus")


func _stepper(title: String, value: String, change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := _label(title)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_btn("−", func() -> void: change.call(-1), 56.0 * settings.text_scale()))
	var v := _label(value, Palette.FALSE_SUN)
	v.custom_minimum_size.x = 110.0 * settings.text_scale()
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(v)
	row.add_child(_btn("+", func() -> void: change.call(1), 56.0 * settings.text_scale()))
	return row


func _show_inventory() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var p := world.player
	var col := _open_overlay("Pack (%d/%d)" % [p.inventory.size(), Actor.INVENTORY_LIMIT])
	var first: Button = null
	col.add_child(_label("Equipped", Palette.GOLD, 1.0))
	for slot in Actor.SLOTS:
		var it := p.equipped(slot)
		var text := "%s: %s" % [slot.capitalize(), it.display_name(db) if it != null else "nothing"]
		var b := _btn(text, func() -> void: _show_item(it, -1, slot))
		b.disabled = it == null
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(b)
		if first == null and not b.disabled:
			first = b
	col.add_child(_label("Carried", Palette.GOLD, 1.0))
	if p.inventory.is_empty():
		col.add_child(_label("Nothing.", Palette.TEXT_DIM))
	for i in p.inventory.size():
		var it := p.inventory[i]
		var idx := i
		var b := _btn(it.display_name(db), func() -> void: _show_item(it, idx, ""))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", Color(String(it.def(db)["color"])).lerp(Palette.TEXT, 0.35))
		col.add_child(b)
		if first == null:
			first = b
	var close := _btn("Close", _close_overlay)
	col.add_child(close)
	(first if first != null else close).call_deferred("grab_focus")


func _item_stats(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	match String(d["kind"]):
		"weapon":
			parts.append("Damage %s (%s)" % [d["damage"], String(d.get("damage_type", "physical"))])
			if int(d.get("accuracy", 0)) != 0:
				parts.append("accuracy %+d" % int(d["accuracy"]))
			if int(d.get("crit", 0)) != 0:
				parts.append("critical %+d%%" % int(d["crit"]))
		"ranged":
			parts.append("Ranged %s (%s, range %d)" % [d["damage"], String(d.get("damage_type", "physical")), int(d["range"])])
			if int(d.get("accuracy", 0)) != 0:
				parts.append("accuracy %+d" % int(d["accuracy"]))
			if int(d.get("crit", 0)) != 0:
				parts.append("critical %+d%%" % int(d["crit"]))
		"armor":
			parts.append("Defense %d" % int(d["defense"]))
			if int(d.get("evasion", 0)) != 0:
				parts.append("evasion %+d" % int(d["evasion"]))
		"consumable":
			var eff := String(d["effect"])
			if eff == "heal":
				parts.append("Restores %s health" % d["heal"])
			elif eff == "projectile":
				parts.append("Thrown %s (%s, range %d)" % [d["damage"], String(d.get("damage_type", "physical")), int(d["range"])])
			elif eff == "scroll":
				parts.append("Scroll (range %d)" % int(d.get("range", 5)))
			else:
				var sd := db.get_def("statuses", String(d["status"]))
				parts.append("Grants %s for %d turns" % [sd["name"], int(sd["duration"])])
		"relic":
			parts.append("Work: %s\nTransmute: %s" % [d["work_desc"], d["transmute_desc"]])
	var mods: Dictionary = d.get("mods", {})
	for k in mods:
		parts.append("%s %+d" % [String(k).replace("_", " "), int(mods[k])])
	var rmap: Dictionary = d.get("resists", {})
	for k in rmap:
		parts.append("%s resist %+d%%" % [String(k), int(rmap[k])])
	return ", ".join(parts)


func _show_item(it: Item, index: int, slot: String) -> void:
	if it == null:
		return
	var d := it.def(db)
	var col := _open_overlay(it.display_name(db).capitalize(), Color(String(d["color"])).lerp(Palette.TEXT, 0.3))
	col.add_child(_label(String(d["description"]), Palette.TEXT_DIM))
	col.add_child(_label(_item_stats(d), Palette.RECORD, 0.9))
	var main: Button
	if slot != "":
		main = _btn("Take off", func() -> void:
			_close_overlay()
			world.player_unequip(slot)
			_after_action())
		col.add_child(main)
	else:
		if String(d["kind"]) == "relic":
			main = _btn("Work", func() -> void:
				_close_overlay()
				world.player_work_relic(index)
				_after_action())
			col.add_child(main)
			col.add_child(_btn("Transmute", func() -> void:
				_close_overlay()
				world.player_transmute_relic(index)
				_after_action()))
		elif String(d["kind"]) == "consumable" and String(d.get("effect", "")) == "projectile":
			main = _btn("Throw", func() -> void:
				_close_overlay()
				_start_aim("item", {"index": index, "range": int(d.get("range", 4)), "name": String(d["name"]),
					"acc": 2, "dtype": String(d.get("damage_type", "physical"))}))
			col.add_child(main)
		elif String(d["kind"]) == "consumable" and String(d.get("effect", "")) == "scroll" and String(d.get("spell", "")) != "cinder_ward":
			main = _btn("Cast", func() -> void:
				_close_overlay()
				var targ := "tile" if String(d.get("spell", "")) == "phase_step" else "enemy"
				_start_aim("item", {"index": index, "range": int(d.get("range", 5)), "name": String(d["name"]),
					"targeting": targ, "dtype": String(d.get("damage_type", "void"))}))
			col.add_child(main)
		else:
			var verb := "Use" if String(d["kind"]) == "consumable" else "Equip"
			main = _btn(verb, func() -> void:
				_close_overlay()
				world.player_use(index)
				_after_action())
			col.add_child(main)
		col.add_child(_btn("Drop", func() -> void:
			_close_overlay()
			world.player_drop(index)
			_after_action()))
	col.add_child(_btn("Back", _show_inventory))
	main.call_deferred("grab_focus")


func _show_end() -> void:
	var won := world.state == World.State.WON
	var vic := world.victory_kind() if won else {}
	var loss := {} if won else world.named_loss()
	var title := String(vic["title"]) if won else "Loss: %s" % String(loss["title"])
	var title_col := (Palette.FALSE_SUN if String(vic.get("id", "")) == "by_decree" else Palette.GOOD) if won else Palette.ALERT
	var col := _open_overlay(title, title_col)
	screen = Screen.END
	var p := world.player
	var fd := db.floor_for_depth(world.depth)
	if won:
		col.add_child(_label(String(vic["epitaph"]), Palette.LORE))
	else:
		col.add_child(_label(String(loss["epitaph"]), Palette.LORE))
		col.add_child(_label("Slain by %s in %s." % [world.death_cause, fd.get("name", "the dark")], Palette.TEXT))
	col.add_child(_label("%s, %s %s, level %d. %d turns. Seed %d." % [p.name.left(1).to_upper() + p.name.substr(1), db.get_def("species", p.species_id)["name"],
		db.get_def("classes", p.class_id)["name"], p.level, world.turns, world.run_seed], Palette.TEXT_DIM, 0.9))
	col.add_child(_label("Death is permanent: this run's save has been erased.", Palette.TEXT_DIM, 0.8) if not won else _label("This run's save has been erased.", Palette.TEXT_DIM, 0.8))
	var again := _btn("New run", func() -> void:
		world = null
		_show_create())
	col.add_child(again)
	col.add_child(_btn("Title", func() -> void:
		world = null
		_show_title()))
	again.call_deferred("grab_focus")
