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
var _last_floor_id := ""
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
	var foot := _label("Set in the world of FALSE LIGHT. v0.6 (M6.3 Origins & Callings)", Palette.TEXT_DIM, 0.75)
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
	var col := _menu_column(1080.0)
	col.add_theme_constant_override("separation", int(8 * settings.text_scale()))
	col.add_child(_label("Who descends?", Palette.LUX, 1.4))

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Name (optional)"
	name_edit.max_length = 24
	name_edit.custom_minimum_size.y = 44.0 * settings.text_scale()
	col.add_child(name_edit)

	col.add_child(_label("Origin", Palette.GOLD, 1.05))
	var sp_desc := _label("", Palette.TEXT_DIM, 0.85)
	col.add_child(_choice_row("species", sp_desc))
	col.add_child(sp_desc)

	col.add_child(_label("Calling", Palette.GOLD, 1.05))
	var cl_desc := _label("", Palette.TEXT_DIM, 0.85)
	col.add_child(_choice_row("classes", cl_desc))
	col.add_child(cl_desc)

	var seed_edit := LineEdit.new()
	seed_edit.placeholder_text = "Seed (blank for random)"
	seed_edit.custom_minimum_size.y = 44.0 * settings.text_scale()
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
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	var group := ButtonGroup.new()
	for id in db.ids(kind):
		var d := db.get_def(kind, id)
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = String(d["name"])
		b.custom_minimum_size = Vector2(172.0 * settings.text_scale(), 44.0 * settings.text_scale())
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
	_last_floor_id = world.floor_id
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
			["Fire", _act_fire], ["Stairs", _act_stairs], ["Rest", _act_rest], ["Srch", _act_search], ["Look", _toggle_look], ["Menu", _show_pause]]
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
		side.add_child(_label("Move: arrows, numpad or hjklyubn\nWait: . or 5   Get: g   Bag: i%s\nBuild: c   Act: a (1-6)   Fire: f\nStairs: Enter   Rest: r   Srch: s\nUse: e   Look: x   Atlas: Tab\nMenu: Esc   Tap to travel; hold/right-click to look." % mask_hint, Palette.TEXT_DIM, 0.7))
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
	var fd := world.current_floor_def()
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
	var rkind := String(fd.get("region_kind", "spine"))
	var rtag := "" if rkind == "spine" else " [%s]" % rkind.capitalize()
	t.append("Sphere %d (%s): %s%s" % [world.depth, sphere, fd.get("name", ""), rtag] if sphere != "" else "Depth %d: %s%s" % [world.depth, fd.get("name", ""), rtag])
	t.append("Attack %+d  Defense %d  Evasion %+d" % [p.stat("accuracy"), p.stat("defense"), p.stat("evasion")])
	var w := p.equipped("weapon")
	t.append("Wielding: %s (%s)" % [world.item_name(w), p.damage_dice()] if w != null else "Wielding: bare hands (1d2)")
	var rw := p.equipped("ranged")
	if rw != null:
		var rwd := rw.def(db)
		t.append("Ranged: %s (%s, rng %d)" % [world.item_name(rw), rwd["damage"], int(rwd["range"])])
	if p.has_trait("mask_stances"):
		t.append("Mask: [color=%s]%s[/color] (risk %d/%d)" % [Masks.color(p.mask), Masks.label(p.mask), p.mask_risk, World.MASK_RISK_MAX])
	if world.subjugation > 0:
		var clim := world.chain_limit()
		var scol := Palette.ALERT.to_html(false) if world.subjugation >= clim - 1 else Palette.FALSE_SUN.to_html(false)
		t.append("[color=#%s]Subjugation %d/%d[/color]" % [scol, world.subjugation, clim])
	if world.contract != "":
		var cdef: Dictionary = db.get_def("contracts", world.contract)
		t.append("[color=%s]Contract: %s (%d/%d)[/color]" % ["#c77dff", String(cdef.get("name", world.contract)), world.contract_progress, int(cdef.get("floors", 2))])
	if p.has_status("return_oriented"):
		t.append("[color=#7ce8b0]Way: Return[/color]")
	elif p.has_status("serpents_seam"):
		t.append("[color=#c77dff]Way: Serpent[/color]")
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
	if world.depth != _last_depth or world.floor_id != _last_floor_id or world.turns - _last_save_turn >= AUTOSAVE_EVERY_TURNS:
		_last_depth = world.depth
		_last_floor_id = world.floor_id
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


func _act_search() -> void:
	if overlay == null:
		world.player_search()
		_after_action()


func _act_interact() -> void:
	if overlay != null or world.state != World.State.PLAYING:
		return
	var m := world.current_floor()
	var candidates: Array[Vector2i] = [world.player.pos]
	for d in Grid.DIRS_8:
		candidates.append(world.player.pos + d)
	for fp in candidates:
		var feat := m.revealed_feature_at(fp)
		if Ecology.is_interactive(feat):
			if String(feat["kind"]) == "secret_door":
				if world.player_interact(fp, "open"):
					_after_action()
			else:
				_show_feature(feat)
			return
	world.log_msg("There is nothing interactive nearby.", "info")
	_refresh()


func _act_fire() -> void:
	if overlay != null or world.state != World.State.PLAYING:
		return
	var w := world.player.equipped("ranged")
	if w == null:
		world.log_msg("You have no ranged weapon equipped.", "info")
		_after_action()
		return
	var d := w.def(db)
	var r_bonus := 1 if world.player.has_trait("steady_aim") else 0
	_start_aim("fire", {"range": int(d.get("range", 5)) + r_bonus, "name": String(d["name"]),
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
	var fm := world.current_floor()
	if p == me:
		var feat_here := fm.revealed_feature_at(me)
		if not fm.items_at(me).is_empty():
			world.player_pickup()
		elif Ecology.is_interactive(feat_here):
			_show_feature(feat_here)
			return
		elif fm.get_tile(me) in [Tiles.STAIRS_DOWN, Tiles.STAIRS_UP, Tiles.BRANCH_IN, Tiles.BRANCH_OUT]:
			_act_stairs()
			return
		else:
			world.player_wait()
		_after_action()
		return
	if Grid.is_adjacent(me, p):
		var feat_adj := fm.revealed_feature_at(p)
		if fm.actor_at(p) == null and Ecology.is_interactive(feat_adj):
			if String(feat_adj["kind"]) == "secret_door":
				world.player_interact(p, "open")
				_after_action()
			else:
				_show_feature(feat_adj)
			return
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
		var fm := world.current_floor()
		if not Grid.is_adjacent(me, next) or fm.actor_at(next) != null:
			travel.clear()
			break
		var next_feat := fm.revealed_feature_at(next)
		var danger_trap := String(next_feat.get("kind", "")) == "trap" and not bool(next_feat.get("used", false))
		if Tiles.is_hazard(fm.get_tile(next)) or danger_trap:
			travel.clear()
			look_label.text = "You stop before the %s." % (Ecology.label(next_feat) if danger_trap else String(Tiles.NAMES.get(fm.get_tile(next), "hazard")))
			look_label.visible = true
			map.marker = next
			map.queue_redraw()
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
	elif k.keycode == KEY_S:
		_act_search()
	elif k.keycode == KEY_E:
		_act_interact()
	elif k.keycode == KEY_TAB:
		_show_atlas()
	elif k.keycode == KEY_P:
		_show_people()
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
	for sline in ItemSets.summaries(p, db):
		col.add_child(_label("Set: " + sline, Palette.GOOD, 0.85))
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


func _show_feature(feat: Dictionary) -> void:
	if world == null or world.state != World.State.PLAYING or overlay != null:
		return
	var pos := Vector2i(int(feat["x"]), int(feat["y"]))
	var kind := String(feat["kind"])
	var col := _open_overlay(Ecology.label(feat), Color(Ecology.color(feat)))
	col.add_child(_label(Ecology.description(feat), Palette.TEXT_DIM, 0.9))
	match kind:
		"altar":
			col.add_child(_btn("Cleanse curses (-3 HP, -apotheosis, +Way of Return)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "cleanse")
				_after_action()))
			col.add_child(_btn("Offer tithe (-4 HP: +2 max HP, full resource, -apotheosis)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "tithe")
				_after_action()))
		"shrine":
			col.add_child(_btn("Witness the floor (ID pack, reveal all traps/secrets)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "witness")
				_after_action()))
			col.add_child(_btn("Claim the Eye (+1 permanent Will, +2 apotheosis, +Serpent)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "steal")
				_after_action()))
		"ritual_circle":
			col.add_child(_btn("Inscribe affix onto weapon/armor (-4 HP, +apotheosis)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "inscribe")
				_after_action()))
			col.add_child(_btn("Drain circle (heal 50% HP, reset cooldowns & Mask risk)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "drain")
				_after_action()))
			if world.contract != "":
				var cdef: Dictionary = db.get_def("contracts", world.contract)
				col.add_child(_btn("Attest %s (-3 HP, advances oath)" % String(cdef.get("name", world.contract)), func() -> void:
					_close_overlay()
					world.player_interact(pos, "attest")
					_after_action()))
		"contract_lectern":
			for cid in db.ids("contracts"):
				var cdef: Dictionary = db.get_def("contracts", cid)
				var way_label := "Way of Return" if String(cdef.get("way", "return")) == "return" else "Serpent's Way"
				var tag := ""
				if world.contract == cid:
					tag = " [Active]"
				elif world.contract_log.has(cid):
					tag = " [Kept]" if String(world.contract_log[cid]) == "fulfilled" else " [Broken]"
				var cname := String(cdef.get("name", cid))
				var req_floors := int(cdef.get("floors", 2))
				var b := _btn("%s (%s, %d floors)%s" % [cname, way_label, req_floors, tag], func() -> void:
					_close_overlay()
					world.player_interact(pos, "sign:%s" % cid)
					_after_action())
				if world.contract != "" or world.contract_log.has(cid):
					b.disabled = true
				col.add_child(b)
				col.add_child(_label("%s  Oath: %s" % [String(cdef.get("description", "")), String(cdef.get("oath_text", ""))], Palette.TEXT_DIM, 0.78))
			if world.contract != "":
				col.add_child(_btn("Forsake active contract (Forsworn)", func() -> void:
					_close_overlay()
					world.player_interact(pos, "forsake")
					_after_action()))
		"vault_gate":
			col.add_child(_btn("Unlock with vault key or Ophite Key", func() -> void:
				_close_overlay()
				world.player_interact(pos, "key")
				_after_action()))
			col.add_child(_btn("Force the iron bars (-4 HP, +apotheosis, wakes floor)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "force")
				_after_action()))
		"merchant":
			var stock: Array = feat.get("stock", [])
			for i in stock.size():
				var row: Dictionary = stock[i]
				if bool(row.get("sold", false)):
					continue
				var item_def := db.get_def("items", String(row["id"]))
				var price := int(row.get("price_hp", 5))
				var sidx := i
				var hb := HBoxContainer.new()
				hb.add_theme_constant_override("separation", 8)
				var b1 := _btn("Buy %s (-%d HP)" % [item_def["name"], price], func() -> void:
					_close_overlay()
					world.player_interact(pos, "buy:%d:blood" % sidx)
					_after_action())
				b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(b1)
				hb.add_child(_btn("Barter item", func() -> void:
					_close_overlay()
					world.player_interact(pos, "buy:%d:barter" % sidx)
					_after_action()))
				col.add_child(hb)
		"challenge":
			col.add_child(_btn("Ring the Trial Bell (ambush + elite loot +1 stat pt)", func() -> void:
				_close_overlay()
				world.player_interact(pos, "ring")
				_after_action()))
		"npc":
			var nid := String(feat.get("sub", ""))
			if db.has("npcs", nid):
				var ndef := db.get_def("npcs", nid)
				var fdef := db.get_def("factions", String(ndef["faction"]))
				var st := world.npc_standing_of(nid)
				col.add_child(_label("%s  (Standing %+d)" % [String(fdef["name"]), st], Palette.GOLD, 0.85))
				col.add_child(_label("\"%s\"" % String(ndef["greeting"]), Palette.TEXT, 0.88))
				col.add_child(_btn("Speak & ask counsel", func() -> void:
					_close_overlay()
					world.player_interact(pos, "talk")
					_after_action()))
				var svc_btn := _btn("Accept help (%s)" % String(ndef["service"]).replace("_", " "), func() -> void:
					_close_overlay()
					world.player_interact(pos, "service")
					_after_action())
				if st <= -2 or bool(feat.get("used", false)):
					svc_btn.disabled = true
				col.add_child(svc_btn)
				var pole_id := String(ndef["faction_pole"])
				var pole_lbl := String(fdef["pole_a_label"] if pole_id == String(fdef["pole_a"]) else fdef["pole_b_label"])
				col.add_child(_btn("Back their pole (%s)" % pole_lbl, func() -> void:
					_close_overlay()
					world.player_interact(pos, "pledge")
					_after_action()))
				col.add_child(_btn("Refuse their ledger (-standing)", func() -> void:
					_close_overlay()
					world.player_interact(pos, "refuse")
					_after_action()))
	col.add_child(_btn("Leave", _close_overlay))


func _show_gate() -> void:
	if not world.needs_gate_to_descend() or overlay != null:
		return
	var next_fd := world.gate_target_def()
	if next_fd.is_empty():
		next_fd = db.floor_for_depth(world.depth + 1)
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


func _show_atlas() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var col := _open_overlay("Atlas of Terra Tenebrae", Palette.FALSE_SUN)
	col.add_child(_label("Discovered places (%d visited). Unwalked branches remain hidden." % world.visited_floors.size(), Palette.TEXT_DIM, 0.85))
	for d in range(1, db.max_depth() + 1):
		var sid := db.spine_floor_id(d)
		var sdef := db.floor_def(sid)
		var sphere := String(sdef.get("sphere", str(d)))
		var visited_s := world.visited_floors.has(sid)
		var here_s := world.floor_id == sid
		var s_line := "Sphere %d (%s): %s%s" % [d, sphere, String(sdef["name"]) if visited_s or d <= world.max_sphere_reached else "???", "  [HERE]" if here_s else ""]
		col.add_child(_label(s_line, Palette.LUX if here_s else (Palette.TEXT if visited_s else Palette.TEXT_DIM), 0.92))
		for pt in world.atlas.get(sid, []):
			var bid := String(pt.get("target", ""))
			if bid == "":
				continue
			var bdef := db.floor_def(bid)
			var vis_b := world.visited_floors.has(bid)
			var here_b := world.floor_id == bid
			var bname := String(bdef.get("name", bid)) if vis_b else "Unvisited branch (%s)" % String(bdef.get("region_kind", "branch")).capitalize()
			if visited_s or vis_b:
				col.add_child(_label("  └ %s%s" % [bname, "  [HERE]" if here_b else ""], Palette.GOOD if here_b else Palette.TEXT_DIM, 0.82))
	var close := _btn("Close", _close_overlay)
	col.add_child(close)
	close.call_deferred("grab_focus")


func _show_people() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var col := _open_overlay("People & Institutions", Palette.FALSE_SUN)
	col.add_child(_label("Two-minded institutions (no single moral ledger):", Palette.GOLD, 0.88))
	for fid in db.ids("factions"):
		var fdef := db.get_def("factions", fid)
		var pole := world.faction_pole_of(fid)
		var leaning := "Uncommitted (%s vs %s)" % [String(fdef["pole_a_label"]), String(fdef["pole_b_label"])]
		if pole == String(fdef["pole_a"]):
			leaning = "Leaning: " + String(fdef["pole_a_label"])
		elif pole == String(fdef["pole_b"]):
			leaning = "Leaning: " + String(fdef["pole_b_label"])
		col.add_child(_label("  %s — %s" % [String(fdef["name"]), leaning], Palette.TEXT if pole != "" else Palette.TEXT_DIM, 0.84))
	col.add_child(_label("Met below (%d/%d known):" % [world.npcs_met.size(), db.ids("npcs").size()], Palette.GOLD, 0.88))
	if world.npcs_met.is_empty():
		col.add_child(_label("  No recurring figures spoken with yet.", Palette.TEXT_DIM, 0.82))
	else:
		for nid in world.npcs_met:
			if db.has("npcs", nid):
				var ndef := db.get_def("npcs", nid)
				var st := world.npc_standing_of(nid)
				col.add_child(_label("  %s (%s) — standing %+d" % [String(ndef["name"]), String(ndef["role"]), st], Palette.TEXT, 0.82))
	var close := _btn("Close", _close_overlay)
	col.add_child(close)
	close.call_deferred("grab_focus")


func _show_pause() -> void:
	if world == null or world.state != World.State.PLAYING:
		return
	var col := _open_overlay("Paused")
	var fd := world.current_floor_def()
	col.add_child(_label("%s. Seed %d." % [fd.get("name", ""), world.run_seed], Palette.TEXT_DIM, 0.85))
	var resume := _btn("Resume", _close_overlay)
	col.add_child(resume)
	col.add_child(_btn("Atlas", _show_atlas))
	col.add_child(_btn("People & Institutions", _show_people))
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
		var text := "%s: %s" % [slot.capitalize(), world.item_name(it) if it != null else "nothing"]
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
		var b := _btn(world.item_name(it), func() -> void: _show_item(it, idx, ""))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tint := Color(it.effective_color(db)) if world.is_item_identified(it) else Color(String(it.def(db)["color"]))
		b.add_theme_color_override("font_color", tint.lerp(Palette.TEXT, 0.35))
		col.add_child(b)
		if first == null:
			first = b
	var close := _btn("Close", _close_overlay)
	col.add_child(close)
	(first if first != null else close).call_deferred("grab_focus")


func _item_stats(it: Item) -> String:
	if not world.is_item_identified(it):
		return "Unidentified — equip, use, or read a scroll of witness to reveal its properties."
	var d := it.def(db)
	var parts: PackedStringArray = []
	if it.rarity != "common":
		parts.append("[%s]" % it.rarity.capitalize())
	if it.buc != "uncursed":
		parts.append(it.buc.capitalize())
	match String(d["kind"]):
		"weapon":
			parts.append("Damage %s (%s)" % [d["damage"], it.effective_damage_type(db)])
			if int(d.get("accuracy", 0)) != 0:
				parts.append("accuracy %+d" % int(d["accuracy"]))
			if int(d.get("crit", 0)) != 0:
				parts.append("critical %+d%%" % int(d["crit"]))
		"ranged":
			parts.append("Ranged %s (%s, range %d)" % [d["damage"], it.effective_damage_type(db), int(d["range"])])
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
	for stat_name in ContentSchema.MOD_STATS:
		var mv := it.total_mod(db, stat_name)
		if mv != 0:
			parts.append("%s %+d" % [stat_name.replace("_", " "), mv])
	for dt in ContentSchema.DAMAGE_TYPES:
		var rv := it.total_resist(db, dt)
		if rv != 0:
			parts.append("%s resist %+d%%" % [dt, rv])
	if it.effective_status(db) != "":
		parts.append("inflicts %s" % it.effective_status(db))
	var sid := String(d.get("set_id", ""))
	if sid != "":
		parts.append("Set: %s" % ItemSets.set_name(sid))
	return ", ".join(parts)


func _show_item(it: Item, index: int, slot: String) -> void:
	if it == null:
		return
	var d := it.def(db)
	var shown := world.item_name(it).capitalize()
	var col := _open_overlay(shown, Color(it.effective_color(db)).lerp(Palette.TEXT, 0.3))
	var desc_txt := String(d["description"]) if world.is_item_identified(it) else "An unfamiliar article. Its properties are hidden until tested or witnessed."
	col.add_child(_label(desc_txt, Palette.TEXT_DIM))
	col.add_child(_label(_item_stats(it), Palette.RECORD, 0.9))
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
				var r_bonus := 1 if world.player.has_trait("steady_aim") else 0
				_start_aim("item", {"index": index, "range": int(d.get("range", 4)) + r_bonus, "name": world.item_name(it),
					"acc": 2, "dtype": String(d.get("damage_type", "physical"))}))
			col.add_child(main)
		elif String(d["kind"]) == "consumable" and String(d.get("effect", "")) == "scroll" and not (String(d.get("spell", "")) in ["cinder_ward", "identify", "unbind"]):
			main = _btn("Cast", func() -> void:
				_close_overlay()
				var targ := "tile" if String(d.get("spell", "")) == "phase_step" else "enemy"
				_start_aim("item", {"index": index, "range": int(d.get("range", 5)), "name": world.item_name(it),
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
	var fd := world.current_floor_def()
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
