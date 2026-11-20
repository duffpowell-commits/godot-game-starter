extends Node3D
## 3D CHARACTER TEST (dev menu): the full-movement standard working end to end.
## Hero = UAL mannequin with the orange rim; dummy = same model and skeleton, recoloured.
## Left half: floating stick (any direction, push further = faster). Right side: PUNCH / DODGE.
## Keyboard: WASD/arrows, J punch, K dodge. Camera: fixed high three-quarter (50° down), follows
## with look-ahead, never rotates. Copy this setup into a game's real scene.

const UI = preload("res://scripts/ui.gd")
const Character3D = preload("res://scripts/character3d.gd")
const TOON = preload("res://shaders/toon.gdshader")
const OUTLINE = preload("res://shaders/outline.gdshader")

const CAM_PITCH := deg_to_rad(50.0)
const CAM_DIST := 7.5
const LOOK_AHEAD := 0.35

var hero: CharacterBody3D
var dummy: CharacterBody3D
var cam: Camera3D
var sun: DirectionalLight3D
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var stick_down := false
var bot_stick := Vector2.INF     # the autoplay bot steers through this when set
var stick_area: Control
var ui: CanvasLayer


func _ready() -> void:
	var settings: Node = get_node("/root/Settings")
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("1b1f2a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("5b6175")
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-35), 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = not settings.get_value("low_graphics")
	add_child(sun)
	_floor()
	for p in [Vector3(3, 0, -2), Vector3(-3.5, 0, 1.5), Vector3(1.5, 0, 4)]:
		_crate(p)
	hero = Character3D.new()
	hero.rim = 1.4
	add_child(hero)
	dummy = Character3D.new()
	dummy.tint = Color(0.75, 0.35, 0.35)
	dummy.position = Vector3(0, 0, -2.5)
	add_child(dummy)
	cam = Camera3D.new()
	cam.fov = 45
	add_child(cam)
	_place_camera(1.0)
	_build_ui()


func _floor() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	mi.mesh = plane
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", Color("3a4256"))
	mi.material_override = m
	body.add_child(mi)
	add_child(body)
	# Grid lines so movement reads on a flat floor.
	for i in range(-10, 11, 2):
		for horiz in [true, false]:
			var line := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(40, 0.01, 0.04) if horiz else Vector3(0.04, 0.01, 40)
			line.mesh = bm
			line.position = Vector3(0 if horiz else i, 0.005, i if horiz else 0)
			var lm := StandardMaterial3D.new()
			lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lm.albedo_color = Color("2a3040")
			line.material_override = lm
			add_child(line)


func _crate(p: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p + Vector3(0, 0.5, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	mi.mesh = bm
	var src := StandardMaterial3D.new()
	src.albedo_color = Color("8a6a45")
	bm.material = src
	body.add_child(mi)
	add_child(body)
	Character3D.apply_toon(body)


func _place_camera(k: float) -> void:
	var v := hero.velocity
	var target := hero.global_position + Vector3(v.x, 0, v.z) * LOOK_AHEAD + Vector3(0, 1.0, 0)
	var want := target + Vector3(0, sin(CAM_PITCH), cos(CAM_PITCH)) * CAM_DIST
	cam.global_position = cam.global_position.lerp(want, k)
	cam.rotation = Vector3(-CAM_PITCH, 0, 0)


func _process(dt: float) -> void:
	var v := Vector2.ZERO
	if bot_stick != Vector2.INF:
		v = bot_stick
	elif stick_down:
		v = stick_vec
	else:
		v = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		for k in [[KEY_A, Vector2.LEFT], [KEY_D, Vector2.RIGHT], [KEY_W, Vector2.UP], [KEY_S, Vector2.DOWN]]:
			if Input.is_physical_key_pressed(k[0]):
				v += k[1]
	hero.move_input = v.limit_length(1.0)
	_place_camera(clampf(dt * 6.0, 0.0, 1.0))
	# The dummy reacts when a punch lands near it.
	if (hero.is_acting("punch") or hero.is_acting("cross")) and not dummy.dead \
			and hero.global_position.distance_to(dummy.global_position) < 1.4 and not dummy.is_acting("hit"):
		dummy.act("hit")
		UI.buzz(25)
	stick_area.queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_J: hero.act("punch")
			KEY_K: hero.act("dodge")


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	ui.add_child(root)
	var left: bool = get_node("/root/Settings").get_value("left_handed")
	stick_area = Control.new()
	stick_area.anchor_left = 0.5 if left else 0.0
	stick_area.anchor_right = 1.0 if left else 0.5
	stick_area.anchor_bottom = 1.0
	stick_area.offset_top = 120
	stick_area.gui_input.connect(_stick_input)
	stick_area.draw.connect(_draw_stick)
	root.add_child(stick_area)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.GAP)
	col.anchor_left = 0.0 if left else 1.0
	col.anchor_right = col.anchor_left
	col.anchor_top = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 24 if left else -24 - 180
	col.offset_right = col.offset_left + 180
	col.offset_top = -40 - 2 * 96 - UI.GAP
	col.offset_bottom = -40
	col.add_child(UI.button("PUNCH", func(): hero.act("punch"), 96))
	col.add_child(UI.button("DODGE", func(): hero.act("dodge"), 96))
	root.add_child(col)
	var back := UI.button("BACK", func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	back.anchor_left = 0.0
	back.offset_left = 24
	back.offset_right = 24 + 150
	back.offset_top = 30
	back.offset_bottom = 30 + UI.MIN_TOUCH
	root.add_child(back)
	var hint := UI.label("Drag on the %s half to move" % ("right" if left else "left"), 18, UI.DIM)
	hint.anchor_right = 1.0
	hint.offset_top = 110
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint)


func _stick_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		stick_down = e.pressed
		stick_origin = e.position
		stick_vec = Vector2.ZERO
	elif e is InputEventMouseMotion and stick_down:
		stick_vec = ((e.position - stick_origin) / 90.0).limit_length(1.0)


func _draw_stick() -> void:
	if not stick_down:
		return
	stick_area.draw_circle(stick_origin, 90, Color(1, 1, 1, 0.08))
	stick_area.draw_arc(stick_origin, 90, 0, TAU, 48, Color(1, 1, 1, 0.3), 3.0)
	stick_area.draw_circle(stick_origin + stick_vec * 90, 36, Color(UI.ACCENT, 0.7))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file.call_deferred("res://scenes/title.tscn")


func bug_state() -> String:
	return "3d test: hero %s speed %.1f dead %s" % [hero.global_position, hero.speed(), hero.dead]
