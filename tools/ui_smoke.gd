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
			_key(KEY_ESCAPE)
		16:
			if main.overlay == null:
				_key(KEY_ESCAPE)
		17:
			_press("Save and return to title")
		18:
			_check(main.screen == 0, "back on title")
			_check(_find_button(main, "Continue") != null, "continue offered")
			_press("Continue")
		19:
			_check(main.screen == 2 and main.world != null, "continued")
			main.world.apply_damage(main.world.player, 9999, "a smoke test")
			main._after_action()
		20:
			_check(main.screen == 3, "end screen")
			_check(not SaveIO.exists(), "permadeath erased the save")
			_shot("death")
			_press("Title")
		21:
			_check(main.screen == 0, "title again")
			_check(_find_button(main, "Continue") == null, "no continue after death")
			print("UI smoke: %d steps, %d failures" % [step, failures.size()])
			for f in failures:
				print("  FAIL " + f)
			SaveIO.delete()
			quit(1 if failures.size() > 0 else 0)
	return false
