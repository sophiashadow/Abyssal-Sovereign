extends SceneTree
## Drives the real main scene through every screen with synthetic input and
## fails on any engine error (tools/test.sh-style log check by the caller).
##   godot --path . --script res://tools/ui_smoke.gd -- [--shots=DIR]
## With a display (or xvfb-run), --shots saves a PNG of each step.
## It uses this project's real user:// save slot (it deletes it at start
## and end), so run it only on a development machine.

var main: Control
var step := 0
var wait := 0
var shots := ""
var failures: PackedStringArray = []
var _assist_turns := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots = arg.substr(8)
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
	SaveIO.delete()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)


func _shot(name: String) -> void:
	if shots == "":
		return
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(shots.path_join("%02d_%s.png" % [step, name]))


func _key(code: Key, unicode: int = 0) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.unicode = unicode
	e.pressed = true
	root.push_input(e)
	var up := e.duplicate()
	up.pressed = false
	root.push_input(up)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text and (node as Button).is_visible_in_tree():
		return node
	for c in node.get_children():
		var b := _find_button(c, text)
		if b != null:
			return b
	return null


func _find_search(node: Node) -> LineEdit:
	if node is LineEdit and (node as LineEdit).is_visible_in_tree():
		return node
	for c in node.get_children():
		var e := _find_search(c)
		if e != null:
			return e
	return null


func _press(text: String) -> bool:
	var b := _find_button(main, text)
	if b == null:
		failures.append("step %d: no button '%s'" % [step, text])
		return false
	b.pressed.emit()
	return true


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("step %d: %s" % [step, msg])


func _process(_delta: float) -> bool:
	if wait > 0:
		wait -= 1
		return false
	wait = 3
	step += 1
	match step:
		1:
			_check(main.screen == 0, "starts on title")
			_shot("title")
			_press("New Run")
		2:
			_check(main.screen == 1, "creation screen")
			_shot("create")
			for choice in ["Cambion", "Occultist"]:
				var b := _find_button(main, choice)
				_check(b != null and b.toggle_mode, "choice '%s' is a toggle" % choice)
				if b != null:
					b.button_pressed = true
		3:
			_shot("create_picked")
			_press("Begin the descent")
		4:
			_check(main.screen == 2 and main.world != null, "game screen")
			_check(main.world.player.species_id == "cambion" and main.world.player.class_id == "occultist", "choices applied")
			_check(SaveIO.exists(), "run saved at start")
			_shot("game")
			for _i in 4:
				_key(KEY_KP_5)
			_key(KEY_RIGHT)
			_key(KEY_L)
		5:
			_check(main.world.turns >= 4, "keyboard actions advance turns (%d)" % main.world.turns)
			_key(KEY_I)
		6:
			_check(main.overlay != null, "inventory opens")
			_shot("inventory")
			_press("healing salve")
		7:
			_shot("item")
			_press("Back")
		8:
			_press("Close")
			var mv: MapView = main.map
			var target: Vector2i = main.world.player.pos
			mv.tile_inspected.emit(target)
		9:
			_check(main.look_label.visible and main.look_label.text.begins_with("You:"), "inspect shows a description")
			_shot("inspect")
			_key(KEY_ESCAPE)
		10:
			_check(main.overlay != null, "escape opens pause")
			_shot("pause")
			_press("Settings")
		11:
			_shot("settings")
			_press("On-screen controls: %s" % ("on" if main.settings.touch_controls else "off"))
		12:
			_press("Done")
		13:
			_check(_find_button(main, "↑") != null or not main.settings.touch_controls, "touch pad follows the setting")
			_shot("game_touch")
			if _find_button(main, "↑") != null:
				_press("↑")
				_press("·")
		14:
			# Travel: tap a remembered floor tile two or more steps away.
			var m: FloorMap = main.world.current_floor()
			var far := Vector2i(-1, -1)
			for y in m.height:
				for x in m.width:
					var p := Vector2i(x, y)
					if m.is_explored(p) and m.get_tile(p) == Tiles.FLOOR and Grid.chebyshev(p, main.world.player.pos) >= 3:
						far = p
			_check(far.x >= 0, "a remembered tile exists")
			main._on_tile_tapped(far)
			wait = 40
		15:
			_check(main.world.turns > 6, "travel moved the player")
			_shot("after_travel")
		16:
			# M7.7: auto-explore starts from the key and stops on any key.
			_check(_find_button(main, "Auto") != null, "Auto button on the action grid")
			_assist_turns = main.world.turns
			_key(KEY_O)
			wait = 20
		17:
			var moved: bool = main.world.turns > _assist_turns
			_check(moved or main.look_label.text != "", "auto-explore moved or said why it would not (%s)" % main.look_label.text)
			if not main.auto.is_empty():
				_key(KEY_SPACE)
		18:
			_check(main.auto.is_empty(), "a key press stops auto-explore")
			_key(KEY_I)
		19:
			_check(main.overlay != null, "pack opens")
			_check(_find_button(main, "Sort: recent") != null, "sort control")
			_check(_find_button(main, "Show: all") != null, "filter control")
			_check(_find_search(main) != null, "search box")
			_shot("pack_controls")
			_press("Sort: recent")
		20:
			_check(_find_button(main, "Sort: name") != null, "sort cycles to name")
			_press("Show: all")
		21:
			_check(_find_button(main, "Show: weapon") != null, "filter cycles to weapon")
			main.settings.inv_sort_index = 0
			main.settings.inv_filter_index = 0
			_key(KEY_ESCAPE)
		22:
			_key(KEY_TAB)
		23:
			_check(main.overlay != null, "atlas opens on Tab")
			_shot("atlas")
			_key(KEY_ESCAPE)
		24:
			# M7.7: shortcuts can be rebound, collisions are refused, reset restores.
			main.settings.touch_controls = false
			_key(KEY_ESCAPE)
		25:
			_press("Settings")
		26:
			_press("Keyboard shortcuts...")
		27:
			_check(_find_button(main, "Get: G") != null, "default Get key shown")
			_press("Get: G")
		28:
			_key(KEY_Y)
		29:
			_check(main.settings.key_for("pickup") == KEY_G, "a movement key is refused")
			_press("Get: G")
		30:
			_key(KEY_V)
		31:
			_check(main.settings.key_for("pickup") == KEY_V, "pickup rebound to V")
			_check(_find_button(main, "Get: V") != null, "screen shows the new key")
			_press("Reset to defaults")
		32:
			_check(main.settings.key_for("pickup") == KEY_G, "reset restores G")
			main.settings.reset_shortcuts()
			_press("Back")
		33:
			_press("Done")
		34:
			if main.overlay == null:
				_key(KEY_ESCAPE)
		35:
			_press("Save and return to title")
		36:
			_check(main.screen == 0, "back on title")
			_check(_find_button(main, "Continue") != null, "continue offered")
			_press("Continue")
		37:
			_check(main.screen == 2 and main.world != null, "continued")
			main.world.apply_damage(main.world.player, 9999, "a smoke test")
			main._after_action()
		38:
			_check(main.screen == 3, "end screen")
			_check(not SaveIO.exists(), "permadeath erased the save")
			_shot("death")
			_press("Title")
		39:
			_check(main.screen == 0, "title again")
			_check(_find_button(main, "Continue") == null, "no continue after death")
			print("UI smoke: %d steps, %d failures" % [step, failures.size()])
			for f in failures:
				print("  FAIL " + f)
			SaveIO.delete()
			quit(1 if failures.size() > 0 else 0)
	return false
