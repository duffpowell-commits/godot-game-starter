extends SceneTree
## Rule tests, headless: godot --headless --path . --script tests/run_tests.gd
## Last line is "ALL PASS (N)" or "FAILED k of N". Add a test_* function for every rule.
## A new test only counts once you've seen it fail (break the code, watch it go red, restore).

const Config = preload("res://scripts/config.gd")
const UI = preload("res://scripts/ui.gd")
const Updater = preload("res://scripts/updater.gd")
const BugReport = preload("res://scripts/bug_report.gd")

var n := 0
var bad := 0


func _initialize() -> void:
	await process_frame   # autoloads are ready after the first frame
	for m in get_method_list():
		if m.name.begins_with("test_"):
			n += 1
			var before := bad
			await call(m.name)
			print(("ok   " if bad == before else "FAIL ") + m.name)
	print("ALL PASS (%d)" % n if bad == 0 else "FAILED %d of %d" % [bad, n])
	quit(1 if bad > 0 else 0)


func check(ok: bool, what: String) -> void:
	if not ok:
		bad += 1
		print("  failed: " + what)


func test_save_roundtrip() -> void:
	var save: Node = root.get_node("Save")
	save.path = "user://test_run.json"
	save.clear()
	check(not save.exists(), "no save at start")
	check(save.write({"level": 3, "score": 27, "lives": 1}), "write ok")
	var d: Dictionary = save.read()
	check(int(d.get("level")) == 3 and int(d.get("score")) == 27, "same values back")
	check(int(d.get("_version")) == save.VERSION, "version stamped")
	save.clear()
	check(not save.exists(), "cleared")
	save.path = "user://run.json"


func test_corrupt_save_is_ignored() -> void:
	var save: Node = root.get_node("Save")
	save.path = "user://test_bad.json"
	var f := FileAccess.open(save.path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	check(save.read().is_empty(), "garbage save reads as empty, no crash")
	save.clear()
	save.path = "user://run.json"


func test_settings_defaults_and_persist() -> void:
	var s: Node = root.get_node("Settings")
	s.reset_for_tests()
	for k in ["music", "sfx", "vibration", "gamma", "text_size", "invert_y", "sensitivity",
			"low_graphics", "left_handed", "subtitles", "high_contrast", "colorblind"]:
		check(s.DEFAULTS.has(k), "setting exists: " + k)
	s.set_value("music", 0.25)
	s.values["music"] = 0.9
	s.load_settings()
	check(absf(float(s.get_value("music")) - 0.25) < 0.001, "music volume saved to disk")
	var bus := AudioServer.get_bus_index("Music")
	check(bus > 0, "Music bus exists at boot")
	check(AudioServer.get_bus_index("SFX") > 0, "SFX bus exists at boot")
	check(absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.25)) < 0.1, "music slider moves the bus")
	s.reset_for_tests()
	s.save_settings()


func test_text_scale_steps() -> void:
	var s: Node = root.get_node("Settings")
	s.values["text_size"] = 3
	check(UI.font_size(20) > 20, "large text is larger")
	s.values["text_size"] = 1
	check(UI.font_size(20) == 20, "normal is unchanged")


func test_colorblind_swaps_key_colors() -> void:
	var s: Node = root.get_node("Settings")
	s.values["colorblind"] = false
	var a := UI.key("good")
	s.values["colorblind"] = true
	check(UI.key("good") != a, "colorblind palette differs")
	s.values["colorblind"] = false


func test_touch_targets() -> void:
	check(UI.MIN_TOUCH >= 62, "min touch >= 48dp (~62 base units)")
	var b := UI.button("X")
	check(b.custom_minimum_size.y >= UI.MIN_TOUCH, "buttons use the minimum")
	b.free()


func test_updater_compare() -> void:
	check(Updater.is_newer(5, 4), "newer build offered")
	check(not Updater.is_newer(4, 4), "same build not offered")
	check(not Updater.is_newer(9, 0), "editor build (0) never offered")


func test_config_paths() -> void:
	check(Config.apk_name().ends_with(".apk"), "apk name")
	check(Config.release_url().begins_with("https://github.com/") and Config.release_url().ends_with("/releases/download/dev/"), "release url")


func test_bug_report_text() -> void:
	var t := BugReport.report_text("it broke", self)
	check(t.begins_with("it broke"), "note first")
	check("build:" in t and "device:" in t, "build + device added")
	check(BugReport.issue_url(t).contains("/issues/new?"), "issue link")


# ---------------------------------------------------------------- house standards (GROK_STANDARDS.md)

## 11. Every game action works on keyboard AND gamepad, and remaps survive a restart.
func test_controls_keyboard_and_pad() -> void:
	var c: Node = root.get_node("Controls")
	for a in c.ACTIONS:
		var has_key := false
		var has_pad := false
		for e in InputMap.action_get_events(a):
			has_key = has_key or e is InputEventKey
			has_pad = has_pad or c.is_pad(e)
		check(has_key and has_pad, a + " has a key and a pad input")
	var k := InputEventKey.new()
	k.physical_keycode = KEY_G
	c.rebind("attack", k)
	var fresh: Node = load("res://scripts/controls.gd").new()
	fresh._load()
	check(fresh._custom.has("attack") and (fresh._custom.attack.key as InputEventKey).physical_keycode == KEY_G, "remap saved and loaded")
	fresh.free()
	c.reset()
	check(not InputMap.action_has_event("attack", k), "reset restores defaults")


## 9 + 12. Stats stay on the phone unless the player opts in AND an endpoint is set; a run that
## didn't close cleanly is spotted next launch.
func test_telemetry_offline_and_crash_flag() -> void:
	var t: Node = root.get_node("Telemetry")
	check(not t.allowed(), "nothing is sent by default")
	var before: int = t.events().size()
	t.event("unit_test", {"x": 1})
	check(t.events().size() == before + 1, "event kept locally")
	var f := FileAccess.open(t.RUN_FLAG, FileAccess.WRITE)
	f.store_string("Game v0.1.0")
	f = null
	var fresh: Node = load("res://scripts/telemetry.gd").new()
	root.add_child(fresh)
	check(fresh.crashed_last_run, "unclean exit detected")
	fresh.clean_exit()
	check(not FileAccess.file_exists(t.RUN_FLAG), "clean exit clears the flag")
	fresh.queue_free()
	var http := 0
	for n in root.find_children("*", "HTTPRequest", true, false):
		if t.is_ancestor_of(n):
			http += 1
	check(http == 0, "no network request without consent")


## 8. Portable assets: every model is glTF on the standard humanoid skeleton and listed in SOURCES.
func test_models_portable() -> void:
	var sources := FileAccess.get_file_as_string("res://assets/models/SOURCES.md")
	var d := DirAccess.open("res://assets/models")
	var count := 0
	for f in d.get_files():
		if f.ends_with(".import") or f.ends_with(".md"):
			continue
		count += 1
		check(f.ends_with(".glb") or f.ends_with(".gltf"), f + " is glTF")
		check(f in sources, f + " listed in SOURCES.md")
		var scene: Node = (load("res://assets/models/" + f) as PackedScene).instantiate()
		var sk := scene.find_children("*", "Skeleton3D", true, false)
		check(sk.size() == 1, f + " has one skeleton")
		if sk.size() == 1:
			for b in ["pelvis", "spine_01", "Head", "thigh_l", "calf_l", "foot_l", "upperarm_r", "hand_r"]:
				check((sk[0] as Skeleton3D).find_bone(b) >= 0, f + " has bone " + b)
		scene.free()
	check(count > 0, "models found")


## 7. Coach hints are short (no text walls).
func test_coach_hints_short() -> void:
	var re := RegEx.create_from_string('Coach\\.teach\\([^,]+,\\s*"[^"]+",\\s*"([^"]+)"')
	for f in ["res://scripts/character_test.gd", "res://scripts/game.gd"]:
		if not FileAccess.file_exists(f):
			continue
		for m in re.search_all(FileAccess.get_file_as_string(f)):
			check(m.get_string(1).split(" ", false).size() <= 4, "hint '%s' is 4 words or fewer" % m.get_string(1))
