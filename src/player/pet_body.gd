class_name PetBody
extends Node3D
## Procedural low-poly body for a pet, built from primitives.
## Placeholder proporcional/colorido de cada pet real; as malhas ficam
## isoladas aqui para serem trocadas por modelos das fotos no futuro.

const POSES := [
	"idle", "walk", "bark", "ferocious", "hide", "pounce",
	"sit_wag", "belly_up", "play", "rub", "sad", "eat",
]

var pose := "idle"
var move_ratio := 0.0

var _def := {}
var _t := 0.0
var _core: Node3D          # inclina/rota para poses
var _body: MeshInstance3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _ball: MeshInstance3D  # bolinha da Zoe (pose "play")
var _base_scale := 1.0


static func pose_index(p: String) -> int:
	var i := POSES.find(p)
	return maxi(i, 0)


static func pose_name(i: int) -> String:
	if i >= 0 and i < POSES.size():
		return POSES[i]
	return "idle"


func build(def: Dictionary) -> void:
	_def = def
	_base_scale = float(def.get("scale", 1.0))
	scale = Vector3.ONE * _base_scale
	_core = Node3D.new()
	add_child(_core)

	var chubby := float(def.get("chubby", 1.0))
	var body_col: Color = def.get("body_color", Color.GRAY)
	var belly_col: Color = def.get("belly_color", Color.LIGHT_GRAY)
	var is_cat: bool = def.get("kind", "dog") == "cat"

	# Corpo
	_body = MeshLib.sphere(_core, 0.34 * chubby, body_col, Vector3(0, 0.42, 0), 0.85)
	_body.scale = Vector3(1.0, 1.0, 1.35)
	MeshLib.sphere(_core, 0.22 * chubby, belly_col, Vector3(0, 0.32, 0.12), 0.8)

	# Cabeça
	_head = Node3D.new()
	_head.position = Vector3(0, 0.62, 0.42)
	_core.add_child(_head)
	MeshLib.sphere(_head, 0.24, body_col, Vector3.ZERO)
	# Focinho
	if is_cat:
		MeshLib.sphere(_head, 0.08, belly_col, Vector3(0, -0.05, 0.2))
	else:
		var muzzle := MeshLib.box(_head, Vector3(0.16, 0.12, 0.18), belly_col, Vector3(0, -0.06, 0.22))
		muzzle.scale = Vector3.ONE
	MeshLib.sphere(_head, 0.035, Color(0.05, 0.04, 0.04), Vector3(0, -0.03, 0.3))  # nariz
	# Olhos (grandes e pidões para a Belatriz)
	var eye_r := 0.05 if String(_def.get("ear", "")) != "dog_up" else 0.07
	MeshLib.sphere(_head, eye_r, Color(0.08, 0.07, 0.06), Vector3(-0.1, 0.08, 0.18))
	MeshLib.sphere(_head, eye_r, Color(0.08, 0.07, 0.06), Vector3(0.1, 0.08, 0.18))
	# Orelhas
	match String(def.get("ear", "cat")):
		"cat":
			MeshLib.cone(_head, 0.09, 0.16, body_col, Vector3(-0.13, 0.22, 0.0))
			MeshLib.cone(_head, 0.09, 0.16, body_col, Vector3(0.13, 0.22, 0.0))
		"dog_up":
			MeshLib.cone(_head, 0.1, 0.22, body_col, Vector3(-0.13, 0.24, -0.02))
			MeshLib.cone(_head, 0.1, 0.22, body_col, Vector3(0.13, 0.24, -0.02))
		"dog_floppy":
			var e1 := MeshLib.box(_head, Vector3(0.08, 0.26, 0.14), body_col, Vector3(-0.22, 0.05, 0.0))
			e1.rotation.z = 0.5
			var e2 := MeshLib.box(_head, Vector3(0.08, 0.26, 0.14), body_col, Vector3(0.22, 0.05, 0.0))
			e2.rotation.z = -0.5

	# Listras da Zoe (rajada preto/laranja)
	if def.get("ability", "") == "stealth":
		for i in 4:
			var stripe := MeshLib.box(
				_core, Vector3(0.5, 0.06, 0.09), belly_col,
				Vector3(0, 0.52 + 0.04 * (i % 2), -0.18 + 0.13 * i)
			)
			stripe.rotation.z = 0.15 * (1 if i % 2 == 0 else -1)

	# Pernas
	for i in 4:
		var leg := Node3D.new()
		var lx := -0.16 if i % 2 == 0 else 0.16
		var lz := 0.2 if i < 2 else -0.2
		leg.position = Vector3(lx, 0.18, lz)
		_core.add_child(leg)
		MeshLib.cylinder(leg, 0.05, 0.28, body_col.darkened(0.15), Vector3(0, -0.08, 0))
		_legs.append(leg)

	# Rabo
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.52, -0.42)
	_core.add_child(_tail)
	if def.get("tail", "thin") == "fluffy":
		MeshLib.sphere(_tail, 0.1, body_col, Vector3(0, 0.08, -0.08))
		MeshLib.sphere(_tail, 0.08, body_col.lightened(0.15), Vector3(0, 0.18, -0.14))
	else:
		var seg := MeshLib.cylinder(_tail, 0.035, 0.34, body_col, Vector3(0, 0.14, -0.06))
		seg.rotation.x = 0.5

	# Bolinha (aparece só na pose "play")
	_ball = MeshLib.sphere(self, 0.09, Color(0.9, 0.25, 0.3), Vector3(0, 0.09, 0.55))
	_ball.visible = false


func set_pose(p: String) -> void:
	if pose == p:
		return
	pose = p
	_ball.visible = p == "play"
	_apply_transparency(0.25 if p == "hide" else 1.0)


func animate(delta: float) -> void:
	_t += delta
	var wag_speed := 3.0
	var core_rot := Vector3.ZERO
	var core_pos := Vector3.ZERO
	match pose:
		"walk":
			var swing := sin(_t * 10.0) * 0.6 * clampf(move_ratio, 0.2, 1.0)
			for i in _legs.size():
				_legs[i].rotation.x = swing * (1.0 if i % 2 == 0 else -1.0)
			core_pos.y = absf(sin(_t * 10.0)) * 0.04
			wag_speed = 6.0
		"idle":
			for leg in _legs:
				leg.rotation.x = lerpf(leg.rotation.x, 0.0, 10.0 * delta)
			core_pos.y = sin(_t * 2.0) * 0.015
		"bark":
			core_rot.x = -0.25
			_head.rotation.x = sin(_t * 20.0) * 0.2
			wag_speed = 10.0
		"ferocious":
			core_rot.x = 0.2
			core_pos.y = absf(sin(_t * 14.0)) * 0.05
			wag_speed = 14.0
		"pounce":
			core_rot.x = 0.35
		"hide":
			core_pos.y = -0.12
			core_rot.x = 0.1
		"sit_wag":
			core_rot.x = -0.5
			core_pos.y = -0.06
			wag_speed = 16.0
		"belly_up":
			core_rot.z = PI
			core_pos.y = 0.25
			for i in _legs.size():
				_legs[i].rotation.x = sin(_t * 6.0 + i) * 0.3
		"play":
			core_rot.x = 0.3
			core_pos.y = absf(sin(_t * 8.0)) * 0.08
			_ball.position.y = 0.09 + absf(sin(_t * 8.0 + 1.0)) * 0.25
			wag_speed = 12.0
		"rub":
			core_rot.z = sin(_t * 5.0) * 0.35
			wag_speed = 10.0
		"sad":
			core_rot.x = 0.15
			core_pos.y = -0.05
			_head.rotation.x = 0.3
			wag_speed = 0.5
		"eat":
			core_rot.x = 0.3
			_head.rotation.x = 0.4 + sin(_t * 12.0) * 0.1
	_core.rotation = _core.rotation.lerp(core_rot, 12.0 * delta)
	_core.position = _core.position.lerp(core_pos, 12.0 * delta)
	if pose != "belly_up" and pose != "play":
		_ball.visible = false
	_tail.rotation.y = sin(_t * wag_speed) * 0.6


func flash(color: Color) -> void:
	var mesh_material := MeshLib.material(color)
	var old := _body.material_override
	_body.material_override = mesh_material
	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_body):
			_body.material_override = old
	)


func _apply_transparency(alpha: float) -> void:
	var nodes: Array[Node] = [_core]
	while not nodes.is_empty():
		var n: Node = nodes.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var mat := mi.material_override as StandardMaterial3D
			if mat != null:
				var col := mat.albedo_color
				col.a = alpha
				mi.material_override = MeshLib.material(col)
		nodes.append_array(n.get_children())
