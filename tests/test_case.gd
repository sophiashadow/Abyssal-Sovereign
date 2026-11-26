class_name TestCase
extends RefCounted
## Minimal assertion base. Each test_* method runs on a fresh instance.
## Failures are collected, not thrown, so one run reports every failure.

var failures: PackedStringArray = []
var checks: int = 0
var current: String = ""


func fail(msg: String) -> void:
	failures.append("%s: %s" % [current, msg])


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fail(msg)


func eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	checks += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s expected <%s> got <%s>" % [msg, str(expected), str(actual)])


func db() -> ContentDB:
	return TestHelpers.content()
