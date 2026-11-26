extends SceneTree
## Headless test runner:  godot --headless --path . --script res://tests/run_tests.gd
## Optional filter:       ... -- --only=test_dungeon
## Exit code 0 only if every test ran and passed.


func _init() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			if only == "" or f.get_basename() == only:
				files.append(f)
	files.sort()
	var total := 0
	var failed := 0
	var checks := 0
	var started := Time.get_ticks_msec()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null:
			print("FAIL %s: could not load" % f)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var mname := String(method["name"])
			if not mname.begins_with("test_"):
				continue
			total += 1
			var tc: TestCase = script.new()
			tc.current = "%s::%s" % [f.get_basename(), mname]
			var t0 := Time.get_ticks_msec()
			tc.call(mname)
			checks += tc.checks
			if tc.failures.is_empty():
				print("PASS %s (%d checks, %d ms)" % [tc.current, tc.checks, Time.get_ticks_msec() - t0])
			else:
				failed += 1
				print("FAIL %s" % tc.current)
				for msg in tc.failures:
					print("     - " + msg)
	print("")
	print("RESULT: %d tests, %d passed, %d failed, %d checks, %.1fs" % [total, total - failed, failed, checks, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if failed > 0 or total == 0 else 0)
