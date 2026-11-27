extends TestCase
## M7.7 configurable shortcuts and assist preferences (GameSettings).


func test_default_shortcuts_are_unique_and_never_steal_movement() -> void:
	var s := GameSettings.new()
	var seen := {}
	for a in GameSettings.SHORTCUT_ORDER:
		var kc := s.key_for(a)
		ok(kc != KEY_NONE, "%s has a default" % a)
		ok(not GameSettings.RESERVED_KEYS.has(kc), "%s default is not a movement or menu key" % a)
		ok(not seen.has(kc), "%s default does not collide" % a)
		seen[kc] = true
		eq(s.action_for(kc), a, "%s maps back from its key" % a)


func test_rebind_refuses_reserved_and_taken_keys() -> void:
	var s := GameSettings.new()
	ok(s.rebind("pickup", KEY_H) != "", "movement key refused")
	ok(s.rebind("pickup", KEY_ESCAPE) != "", "Esc refused")
	ok(s.rebind("pickup", KEY_3) != "", "talent number refused")
	ok(s.rebind("pickup", s.key_for("inventory")) != "", "another command's key refused")
	eq(s.key_for("pickup"), KEY_G, "refusals change nothing")
	eq(s.rebind("pickup", KEY_V), "", "a free key is accepted")
	eq(s.key_for("pickup"), KEY_V, "now bound")
	eq(s.action_for(KEY_G), "", "the old key is free")
	eq(s.rebind("inventory", KEY_G), "", "and can be reused")
	s.reset_shortcuts()
	eq(s.key_for("pickup"), KEY_G, "reset restores defaults")
	ok(s.rebind("nonsense", KEY_V) != "", "unknown command refused")


func test_log_filter_presets_and_view_options_are_in_range() -> void:
	var s := GameSettings.new()
	eq(s.log_kinds().size(), 0, "default shows every message")
	s.log_filter_index = 2
	eq(s.log_filter_name(), "Dangers", "named preset")
	s.log_filter_index = 99
	ok(s.log_filter_name() != "", "out-of-range index is clamped, not a crash")
	ok(s.inv_sort_index < Assist.SORTS.size() and s.inv_filter_index < Assist.FILTERS.size(), "pack options index valid lists")
	ok(s.warn_descent and s.confirm_destructive, "advisories and confirmations default on")
