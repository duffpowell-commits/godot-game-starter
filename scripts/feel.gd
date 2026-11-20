extends Node
## Autoload "Feel": game feel in one call. Every hit gets all five: hit-stop (Character3D.hit),
## screen shake, a sound, a particle burst and a buzz. Feel.impact(world_pos, power, parent).
## power 0..1: 0.3 = a jab, 0.6 = a heavy hit, 1.0 = a finisher.

const SPARK_COLOR := Color(1.0, 0.85, 0.45)

var shakes := 0                       # counters: the autoplay bot proves each part fires
var bursts := 0
var buzzes := 0
var sounds := 0


func impact(pos: Vector3, power: float, parent: Node3D) -> void:
	var audio: Node = get_node_or_null("/root/Audio")
	if audio != null:
		audio.sfx("hit_heavy" if power >= 0.5 else "hit", randf_range(0.92, 1.08))
		sounds += 1
	for rig in get_tree().get_nodes_in_group("camera_rig"):
		rig.add_trauma(0.2 + power * 0.45)
		shakes += 1
	burst(pos, power, parent)
	buzz(int(18 + 30 * power))


func buzz(ms: int) -> void:
	var s: Node = get_node_or_null("/root/Settings")
	if s != null and s.get_value("vibration"):
		Input.vibrate_handheld(ms)
	buzzes += 1


## A one-shot spark burst (CPU particles: work on every phone and on the web).
func burst(pos: Vector3, power: float, parent: Node3D) -> CPUParticles3D:
	var low: bool = get_node_or_null("/root/Settings") != null and get_node("/root/Settings").get_value("low_graphics")
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = (6 if low else 14) + int(power * 12)
	p.lifetime = 0.35
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 2.0 + power * 2.0
	p.initial_velocity_max = 4.0 + power * 4.0
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = SPARK_COLOR
	q.material = m
	p.mesh = q
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
	bursts += 1
	return p
