extends Node
## Autoload "Autoplay": a bot that plays the whole flow with real taps and saves screenshots.
## Off unless the game is started with `-- --autoplay`. Run it (needs a screen, so xvfb):
##   tools/autoplay.sh            -> docs/renders/flow_*.png, prints one PASS line per check
## It ends with "AUTOPLAY PASS" or "AUTOPLAY FAIL <step>"; CI fails without the PASS or on any FAIL line.
## Uses its own settings/save folder (XDG_DATA_HOME in the script), never the player's.
##
## When the game grows, extend `_run()`: drive the real game the way a player would, and add a
## PASS line for each thing that must keep working.

var shots := ""
var failed := false


func _ready() -> void:
	if not "--autoplay" in OS.get_cmdline_user_args():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.trim_prefix("--shots=")
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
	get_tree().create_timer(240.0).timeout.connect(func(): _fail("timeout"))
	_run.call_deferred()


# ---------------------------------------------------------------- the run

func _run() -> void:
	await _wait_scene("Intro")
	await _frames(10)
	_shot("intro")
	await _click("SKIP")
	await _wait_scene("Title")
	await _frames(10)
	_shot("title")
	_check(_find("CONTINUE") == null, "TITLE PASS (no save yet)")
	await _click("NEW GAME")
	await _wait_scene("Game")
	var game := get_tree().current_scene

	# Play: tap the green orbs for a few seconds.
	var t := 0.0
	var start_score: int = game.score
	while t < 5.0:
		for o in game.orbs:
			if not o.bad and o.pos.y > 150:
				await _tap_at(game.field.get_global_transform() * o.pos)
				break
		await _frames(3)
		t += 3.0 / 60.0
	_shot("game")
	_check(game.score > start_score, "PLAY PASS (score %d)" % game.score)

	# Checkpoint: next level autosaves.
	game.debug_skip_level()
	await _frames(2)
	var saved: Dictionary = get_node("/root/Save").read()
	_check(int(saved.get("level", 0)) == 2, "AUTOSAVE PASS (level 2 saved)")

	# Phone interruption: the app loses focus -> pause + save.
	get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _frames(10)
	_check(game.paused and _find("RESUME") != null, "INTERRUPT PASS (paused on focus loss)")
	_shot("pause")

	# Settings from the pause menu: bigger text, colorblind, left-handed.
	await _click("SETTINGS")
	await _frames(10)
	_shot("settings")
	await _click("TEXT SIZE")
	await _frames(5)
	await _click("COLORBLIND")
	await _click("LEFT-HANDED")
	await _frames(10)
	_shot("settings_changed")
	var s: Node = get_node("/root/Settings")
	_check(s.get_value("colorblind") and s.get_value("left_handed") and int(s.get_value("text_size")) == 2,
		"SETTINGS PASS (saved)")
	await _click("DONE")
	await _frames(5)

	# Quit to title, CONTINUE, back where we were.
	await _click("QUIT TO TITLE")
	await _wait_scene("Title")
	await _frames(10)
	_shot("title_continue")
	await _click("CONTINUE")
	await _wait_scene("Game")
	game = get_tree().current_scene
	_check(game.level == 2, "RESUME PASS (continued at level %d)" % game.level)
	await _frames(10)
	_shot("game_lefthanded")

	# Android back = pause, back again = resume.
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(5)
	_check(game.paused, "BACK PASS (back button pauses)")
	await _click("RESUME")
	await _frames(5)

	# Stop tapping and let the orbs fall: GAME OVER.
	Engine.time_scale = 4.0
	var waited := 0
	while not game.over and waited < 60 * 60:
		await _frames(1)
		waited += 1
	Engine.time_scale = 1.0
	await _frames(10)
	_shot("gameover")
	_check(game.over and _find("TRY AGAIN") != null and not get_node("/root/Save").exists(),
		"GAMEOVER PASS (game over screen, save cleared)")
	await _click("TITLE")
	await _wait_scene("Title")
	await _frames(5)
	_check(_find("CONTINUE") == null, "FLOW PASS (back at title, no stale CONTINUE)")

	# Bug report sheet carries the build line.
	await _click("REPORT A BUG")
	await _frames(10)
	_shot("bug_report")
	var txt: String = preload("res://scripts/bug_report.gd").report_text("test", get_tree())
	_check("build:" in txt and "device:" in txt, "BUGREPORT PASS")
	await _click("CLOSE")

	# Debug menu (dev builds): 5 taps on the version number.
	for i in 5:
		await _click_node(get_tree().current_scene.find_child("Version", true, false))
	await _frames(10)
	_check(_find("GOD MODE") != null, "DEBUG PASS (dev menu opens)")
	_shot("debug_menu")

	# 3D character standard (docs/MOVEMENT_3D.md): real skeleton, 360° movement, actions, ink look.
	await _click("3D CHARACTER TEST")
	await _wait_scene("CharacterTest")
	await _frames(20)
	var ct: Node = get_tree().current_scene
	var hero: Node = ct.hero
	var skel: Skeleton3D = hero.model.find_children("*", "Skeleton3D", true, false)[0]
	var foot := skel.find_bone("foot_l")
	var top_speed := 0.0
	var foot_travel := 0.0
	var last_foot := skel.get_bone_global_pose(foot).origin
	var ang := 0.0
	while ang < TAU * 1.15:           # steer the stick once round the full circle
		ct.bot_stick = Vector2(cos(ang), sin(ang))
		await get_tree().physics_frame
		ang += 0.06
		top_speed = maxf(top_speed, hero.speed())
		var f := skel.get_bone_global_pose(foot).origin
		foot_travel += f.distance_to(last_foot)
		last_foot = f
		if absf(ang - PI) < 0.03:
			_shot("char_run")
	ct.bot_stick = Vector2.ZERO
	_check(hero.turned > 5.6 and top_speed > 4.0,
		"MOVE360 PASS (turned %.1f rad, top speed %.1f m/s)" % [hero.turned, top_speed])
	_check(foot_travel > 2.0, "LIMBS PASS (left foot moved %.1f m against the hips: real animation)" % foot_travel)
	await _frames(40)
	# Walk up to the dummy and punch it with a real tap on PUNCH.
	ct.bot_stick = Vector2.ZERO
	hero.global_position = ct.dummy.global_position + Vector3(0, 0, 1.0)
	hero.heading = PI
	hero.model.rotation.y = PI
	await _frames(5)
	await _click("PUNCH")
	await _frames(4)
	_check(hero.is_acting("punch") and ct.dummy.is_acting("hit"), "ACTION PASS (punch lands, dummy reacts)")
	_shot("char_punch")
	await _frames(60)
	await _click("DODGE")
	await _frames(4)
	_check(hero.is_acting("dodge"), "DODGE PASS")
	await _frames(60)
	ct.dummy.die()
	await _frames(70)
	_check(ct.dummy.dead, "DEATH PASS")
	_shot("char_death")
	var inked := true
	for m in hero.model.find_children("*", "MeshInstance3D", true, false):
		for i in (m as MeshInstance3D).mesh.get_surface_count():
			var mat := (m as MeshInstance3D).get_surface_override_material(i) as ShaderMaterial
			inked = inked and mat != null and mat.next_pass != null
	_check(inked, "INK PASS (toon + outline on every surface)")

	if not failed:
		print("AUTOPLAY PASS")
	get_tree().quit(1 if failed else 0)


# ---------------------------------------------------------------- helpers

func _check(ok: bool, line: String) -> void:
	if ok:
		print(line)
	else:
		failed = true
		print("FAIL: " + line)


func _fail(step: String) -> void:
	print("AUTOPLAY FAIL " + step)
	get_tree().quit(1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait_scene(node_name: String) -> void:
	for i in 600:
		var s := get_tree().current_scene
		if s != null and s.name == node_name:
			await _frames(2)
			return
		await _frames(1)
	_fail("scene " + node_name)


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join("flow_%s.png" % name))


## The visible, enabled button whose text starts with `prefix` (topmost sheet wins).
func _find(prefix: String) -> Button:
	var found: Button = null
	for b in get_tree().root.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and not b.disabled and b.text.begins_with(prefix) and not b.is_queued_for_deletion():
			found = b
	return found


func _click(prefix: String) -> void:
	var b := _find(prefix)
	if b == null:
		_fail("no button " + prefix)
		return
	await _click_node(b)


func _click_node(c: Control) -> void:
	if c == null:
		_fail("no node")
		return
	var sc := c.get_parent()
	while sc != null and not sc is ScrollContainer:
		sc = sc.get_parent()
	if sc != null:
		(sc as ScrollContainer).ensure_control_visible(c)
		await _frames(3)
	await _tap_at(c.get_global_rect().get_center())


## A real tap at a canvas point: converted to window pixels and sent through Input.
func _tap_at(p: Vector2) -> void:
	var w := get_viewport().get_final_transform() * p
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = w
		e.global_position = w
		Input.parse_input_event(e)
		await _frames(2)
