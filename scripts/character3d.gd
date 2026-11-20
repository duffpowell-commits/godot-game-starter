extends CharacterBody3D
## A real-time 3D character with full range of movement (the house standard, docs/MOVEMENT_3D.md).
## Model + the shared animation library (Quaternius UAL1, CC0, one humanoid skeleton), toon/ink
## look, AnimationTree: idle -> walk -> jog -> sprint blended by speed, one-shots for actions.
##
##   var c := Character3D.new(); c.model_path = "res://assets/models/<id>.glb"; add_child(c)
##   c.move_input = Vector2(x, y)    # stick, any direction (360°); length = how fast
##   c.act("punch")                  # punch, cross, dodge, hit; c.die() / c.revive()
## The model must use the shared skeleton (UAL / UE5-mannequin bone names) and carry the clips,
## or be retargeted to it in Godot's import dock (docs/MOVEMENT_3D.md, "New character").

const MODEL_DEFAULT := "res://assets/models/ual1_standard.glb"
const TOON = preload("res://shaders/toon.gdshader")
const OUTLINE = preload("res://shaders/outline.gdshader")

## Locomotion clips by speed (m/s) for the BlendSpace1D. Same names in every UAL model.
const LOCO := [["Idle", 0.0], ["Walk", 1.6], ["Jog_Fwd", 3.6], ["Sprint", 6.0]]
## One-shot actions: name -> clip.
const ACTIONS := {"punch": "Punch_Jab", "cross": "Punch_Cross", "dodge": "Roll", "hit": "Hit_Chest"}
const DEATH := "Death01"

@export var model_path := MODEL_DEFAULT
@export var max_speed := 6.0
@export var accel := 18.0
@export var turn_speed := 12.0           # radians/s the body turns toward its heading
@export var tint := Color(1, 1, 1)       # multiplies the model colours (recolour one model per character)
@export var rim := 0.0                   # rim light strength (hero glow); 0 = none
@export var outline_px := 3.0

var move_input := Vector2.ZERO           # x = right, y = forward-on-screen is NEGATIVE (like a stick)
var dead := false
var model: Node3D
var anim: AnimationPlayer
var tree: AnimationTree
var heading := 0.0                       # where the body faces (radians, Y axis)
var turned := 0.0                        # total turning done (tests read this)
var _actions_seen := {}


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	model = (load(model_path) as PackedScene).instantiate()
	add_child(model)
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	apply_toon(model, tint, rim, outline_px)
	_build_tree()


## Swap every material on a model for toon + outline, keeping its colours/textures.
static func apply_toon(root: Node, tint_c: Color = Color.WHITE, rim_s: float = 0.0, outline: float = 3.0) -> void:
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			var t := ShaderMaterial.new()
			t.shader = TOON
			if src is BaseMaterial3D:
				t.set_shader_parameter("albedo", (src as BaseMaterial3D).albedo_color * tint_c)
				if (src as BaseMaterial3D).albedo_texture != null:
					t.set_shader_parameter("albedo_tex", (src as BaseMaterial3D).albedo_texture)
			else:
				t.set_shader_parameter("albedo", tint_c)
			t.set_shader_parameter("rim_strength", rim_s)
			if outline > 0.0:
				var o := ShaderMaterial.new()
				o.shader = OUTLINE
				o.set_shader_parameter("width_px", outline)
				t.next_pass = o
			mi.set_surface_override_material(i, t)


func _build_tree() -> void:
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(anim)
	var bt := AnimationNodeBlendTree.new()
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = max_speed
	for l in LOCO:
		var a := AnimationNodeAnimation.new()
		a.animation = l[0]
		loco.add_blend_point(a, l[1])
	bt.add_node("loco", loco, Vector2(0, 0))
	var prev := "loco"
	var x := 200
	for act_name in ACTIONS:
		var a := AnimationNodeAnimation.new()
		a.animation = ACTIONS[act_name]
		var shot := AnimationNodeOneShot.new()
		shot.fadein_time = 0.08
		shot.fadeout_time = 0.15
		bt.add_node("clip_" + act_name, a, Vector2(x, 200))
		bt.add_node("shot_" + act_name, shot, Vector2(x, 0))
		bt.connect_node("shot_" + act_name, 0, prev)
		bt.connect_node("shot_" + act_name, 1, "clip_" + act_name)
		prev = "shot_" + act_name
		x += 200
	var death := AnimationNodeAnimation.new()
	death.animation = DEATH
	death.play_mode = AnimationNodeAnimation.PLAY_MODE_FORWARD
	var alive := AnimationNodeTransition.new()
	alive.add_input("alive")
	alive.add_input("dead")
	alive.xfade_time = 0.15
	bt.add_node("death", death, Vector2(x, 200))
	bt.add_node("state", alive, Vector2(x + 200, 0))
	bt.connect_node("state", 0, prev)
	bt.connect_node("state", 1, "death")
	bt.connect_node("output", 0, "state")
	tree.tree_root = bt
	tree.active = true
	tree.set("parameters/state/transition_request", "alive")   # a Transition starts with no state


func _physics_process(dt: float) -> void:
	var want := Vector3.ZERO
	if not dead and not is_acting("dodge"):
		var v := move_input.limit_length(1.0)
		want = Vector3(v.x, 0, v.y) * max_speed
	if is_acting("dodge"):
		want = Vector3(sin(heading), 0, cos(heading)) * 4.5   # a roll carries you forward
	var flat := Vector3(velocity.x, 0, velocity.z).move_toward(want, accel * dt)
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * dt
	move_and_slide()
	if flat.length() > 0.3 and not dead:
		var target := atan2(flat.x, flat.z)
		var diff := wrapf(target - heading, -PI, PI)
		var stepped := clampf(diff, -turn_speed * dt, turn_speed * dt)
		heading += stepped
		turned += absf(stepped)
		model.rotation.y = heading
	tree.set("parameters/loco/blend_position", 0.0 if dead else Vector2(velocity.x, velocity.z).length())


func speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func act(what: String) -> void:
	if dead or not ACTIONS.has(what):
		return
	tree.set("parameters/shot_%s/request" % what, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_actions_seen[what] = true


func is_acting(what: String) -> bool:
	return bool(tree.get("parameters/shot_%s/active" % what)) if tree != null else false


func die() -> void:
	dead = true
	tree.set("parameters/state/transition_request", "dead")


func revive() -> void:
	dead = false
	tree.set("parameters/state/transition_request", "alive")
