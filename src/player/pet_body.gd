class_name PetBody
extends Node3D
## Corpo procedural suave de cada pet: malhas contínuas geradas por loft
## (PetMesh), com cores por vértice. As esculturas são idênticas às do
## preview em docs/pets-preview.html — ajuste lá primeiro, depois aqui.
## API pública usada por pet.gd: build/set_pose/animate/flash/move_ratio.

const POSES := [
	"idle", "walk", "bark", "ferocious", "hide", "pounce",
	"sit_wag", "belly_up", "play", "rub", "sad", "eat",
]

var pose := "idle"
var move_ratio := 0.0

var _def := {}
var _pet_id := "sirius"
var _t := 0.0
var _core: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _ball: Node3D
var _tongue: MeshInstance3D = null
var _blep := false
var _body_mesh: MeshInstance3D
var _ghosted := false


static func pose_index(p: String) -> int:
	return maxi(POSES.find(p), 0)


static func pose_name(i: int) -> String:
	if i >= 0 and i < POSES.size():
		return POSES[i]
	return "idle"


static func _smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func build(def: Dictionary) -> void:
	_def = def
	_pet_id = String(def.get("id", "sirius"))
	scale = Vector3.ONE * float(def.get("scale", 1.0))
	_core = Node3D.new()
	add_child(_core)
	_head = Node3D.new()
	_tail = Node3D.new()
	_core.add_child(_head)
	_core.add_child(_tail)
	for i in 4:
		var leg := Node3D.new()
		_core.add_child(leg)
		_legs.append(leg)
	match _pet_id:
		"sirius":
			_build_sirius()
		"belatriz":
			_build_belatriz()
		"zoe":
			_build_zoe()
		_:
			_build_minerva()
	# Bolinha da pose "play" (fora do _core, como no jogo original)
	_ball = Node3D.new()
	add_child(_ball)
	PetMesh.ball(_ball, 0.09, Vector3(0, 0.09, 0.55), Color(0.9, 0.25, 0.3))
	PetMesh.ball(_ball, 0.093, Vector3(0, 0.09, 0.55), Color(0.95, 0.9, 0.85), Vector3(1.0, 0.22, 1.0))
	_ball.visible = false


## ------------------------------------------------ esculturas por pet

func _build_sirius() -> void:
	var B := Color(0.18, 0.17, 0.18)
	var BE := Color(0.28, 0.26, 0.27)
	var GR := Color(0.66, 0.64, 0.6)
	_head.position = Vector3(0, 0.72, 0.42)
	_tail.position = Vector3(0, 0.5, -0.34)
	var body_fn := func(u: float, st: float, _ct: float) -> Color:
		var c := B
		var belly_t := _smooth(0.05, 0.6, -st) * _smooth(0.05, 0.25, u) * (1.0 - _smooth(0.72, 0.95, u))
		c = c.lerp(BE, belly_t * 0.85)
		return c.lerp(B.lightened(0.16), _smooth(0.62, 0.85, u) * 0.35)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.54, -0.46), "rx": 0.05},
		{"p": Vector3(0, 0.52, -0.34), "rx": 0.20, "ry": 0.19},
		{"p": Vector3(0, 0.48, -0.08), "rx": 0.235, "ry": 0.225},
		{"p": Vector3(0, 0.50, 0.14), "rx": 0.215, "ry": 0.21},
		{"p": Vector3(0, 0.58, 0.30), "rx": 0.15, "ry": 0.15},
		{"p": Vector3(0, 0.64, 0.38), "rx": 0.05},
	], 16, body_fn)
	var head_fn := func(u: float, st: float, _ct: float) -> Color:
		var griz := _smooth(0.62, 0.8, u) * _smooth(-0.1, -0.7, st) * 0.9 + _smooth(0.86, 0.98, u) * 0.35
		return B.lerp(GR, minf(1.0, griz))
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.02, -0.14), "rx": 0.05},
		{"p": Vector3(0, 0.02, -0.05), "rx": 0.155, "ry": 0.147},
		{"p": Vector3(0, 0.01, 0.05), "rx": 0.145, "ry": 0.137},
		{"p": Vector3(0, -0.035, 0.15), "rx": 0.075, "ry": 0.066},
		{"p": Vector3(0, -0.05, 0.27), "rx": 0.05, "ry": 0.046},
		{"p": Vector3(0, -0.05, 0.32), "rx": 0.018},
	], 14, head_fn)
	for s in [-1.0, 1.0]:
		var ear_fn := func(u: float, _st: float, _ct: float) -> Color:
			return B.lightened(0.14).lerp(B.darkened(0.05), u)
		PetMesh.loft(_head, [
			{"p": Vector3(0.09 * s, 0.16, -0.01), "rx": 0.025},
			{"p": Vector3(0.18 * s, 0.12, 0.0), "rx": 0.07, "ry": 0.024},
			{"p": Vector3(0.26 * s, 0.0, 0.01), "rx": 0.07, "ry": 0.026},
			{"p": Vector3(0.29 * s, -0.1, 0.02), "rx": 0.04, "ry": 0.018},
			{"p": Vector3(0.3 * s, -0.15, 0.02), "rx": 0.009},
		], 10, ear_fn)
	_leg_set([0.15, 0.20], 0.5, 0.07, B.darkened(0.1), B.lightened(0.05))
	var plume_fn := func(u: float, _st: float, _ct: float) -> Color:
		return B.lerp(B.lightened(0.22), u)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, -0.06), "rx": 0.045},
		{"p": Vector3(0, 0.16, -0.16), "rx": 0.09, "ry": 0.085},
		{"p": Vector3(0, 0.36, -0.13), "rx": 0.115, "ry": 0.105},
		{"p": Vector3(0, 0.49, 0.02), "rx": 0.09, "ry": 0.085},
		{"p": Vector3(0, 0.53, 0.16), "rx": 0.045},
		{"p": Vector3(0, 0.52, 0.22), "rx": 0.008},
	], 12, plume_fn)
	_face(Vector3(0.062, 0.045, 0.125), 0.05, Color(0.5, 0.32, 0.17), Vector3(0, -0.04, 0.325), 0.032)
	_make_tongue(Vector3(0, -0.1, 0.26), false)


func _build_belatriz() -> void:
	var B := Color(0.85, 0.7, 0.48)
	var BE := Color(0.94, 0.88, 0.73)
	var CRE := Color(0.93, 0.87, 0.7)
	_head.position = Vector3(0, 0.53, 0.3)
	_tail.position = Vector3(0, 0.36, -0.34)
	var body_fn := func(u: float, st: float, _ct: float) -> Color:
		var c := B.lerp(BE, _smooth(0.0, 0.55, -st) * 0.9)
		return c.lerp(CRE, _smooth(0.6, 0.9, u) * 0.55)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.34, -0.30), "rx": 0.05},
		{"p": Vector3(0, 0.33, -0.20), "rx": 0.185, "ry": 0.175},
		{"p": Vector3(0, 0.31, 0.0), "rx": 0.21, "ry": 0.20},
		{"p": Vector3(0, 0.33, 0.14), "rx": 0.18, "ry": 0.175},
		{"p": Vector3(0, 0.40, 0.23), "rx": 0.125, "ry": 0.12},
		{"p": Vector3(0, 0.45, 0.28), "rx": 0.045},
	], 16, body_fn)
	var head_fn := func(u: float, st: float, _ct: float) -> Color:
		var beard := _smooth(0.5, 0.75, u) * (_smooth(-0.05, -0.6, st) * 0.9 + 0.25)
		var c := B.lerp(CRE, minf(1.0, beard))
		return c.lerp(B.lightened(0.12), _smooth(0.7, 0.4, u) * _smooth(0.4, 0.9, st) * 0.5)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.01, -0.13), "rx": 0.05},
		{"p": Vector3(0, 0.01, -0.04), "rx": 0.17, "ry": 0.16},
		{"p": Vector3(0, 0.0, 0.06), "rx": 0.16, "ry": 0.15},
		{"p": Vector3(0, -0.035, 0.13), "rx": 0.105, "ry": 0.09},
		{"p": Vector3(0, -0.04, 0.18), "rx": 0.06, "ry": 0.05},
		{"p": Vector3(0, -0.04, 0.2), "rx": 0.015},
	], 14, head_fn)
	for s in [-1.0, 1.0]:
		var ear_fn := func(u: float, _st: float, _ct: float) -> Color:
			return B.darkened(0.12).lerp(CRE, u * 0.4)
		PetMesh.loft(_head, [
			{"p": Vector3(0.08 * s, 0.15, -0.01), "rx": 0.022},
			{"p": Vector3(0.17 * s, 0.1, 0.0), "rx": 0.06, "ry": 0.022},
			{"p": Vector3(0.23 * s, -0.02, 0.01), "rx": 0.06, "ry": 0.024},
			{"p": Vector3(0.24 * s, -0.11, 0.02), "rx": 0.03, "ry": 0.014},
			{"p": Vector3(0.24 * s, -0.14, 0.02), "rx": 0.008},
		], 10, ear_fn)
	_leg_set([0.12, 0.14], 0.28, 0.058, B.darkened(0.08), CRE)
	var tail_fn := func(u: float, _st: float, _ct: float) -> Color:
		return B.lerp(CRE, u * 0.7)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, 0.08), "rx": 0.04},
		{"p": Vector3(0, 0.12, -0.02), "rx": 0.085, "ry": 0.08},
		{"p": Vector3(0, 0.24, 0.01), "rx": 0.06, "ry": 0.055},
		{"p": Vector3(0, 0.3, 0.07), "rx": 0.01},
	], 10, tail_fn)
	_face(Vector3(0.062, 0.035, 0.12), 0.062, Color(0.3, 0.19, 0.11), Vector3(0, -0.025, 0.205), 0.03)
	_make_tongue(Vector3(0, -0.075, 0.17), true)


func _build_zoe() -> void:
	var B := Color(0.17, 0.13, 0.11)
	var ORA := Color(0.78, 0.45, 0.16)
	var CRE := Color(0.85, 0.68, 0.42)
	_head.position = Vector3(0, 0.55, 0.34)
	_tail.position = Vector3(0, 0.34, -0.28)
	# manchas escaminha semeadas no espaço (u, ângulo) — determinístico
	# (semente fixa: igual em host e clientes)
	var spots: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 20_250_705
	for i in 13:
		spots.append({
			"u": rng.randf(), "th": rng.randf() * TAU,
			"r": 0.12 + rng.randf() * 0.16,
			"c": CRE if i % 2 == 1 else ORA,
		})
	var mottle := func(u: float, st: float, ct: float) -> Color:
		var c := B
		var th := atan2(st, ct)
		for sp in spots:
			var dth: float = absf(th - sp["th"])
			dth = minf(dth, TAU - dth)
			var d: float = Vector2((u - sp["u"]) * 1.6, dth / PI).length()
			c = c.lerp(sp["c"], _smooth(sp["r"], sp["r"] * 0.45, d) * 0.9)
		return c
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.36, -0.36), "rx": 0.06},
		{"p": Vector3(0, 0.34, -0.24), "rx": 0.235, "ry": 0.215},
		{"p": Vector3(0, 0.33, 0.0), "rx": 0.275, "ry": 0.255},
		{"p": Vector3(0, 0.35, 0.16), "rx": 0.215, "ry": 0.205},
		{"p": Vector3(0, 0.42, 0.26), "rx": 0.125, "ry": 0.12},
		{"p": Vector3(0, 0.46, 0.31), "rx": 0.05},
	], 18, mottle)
	var head_fn := func(u: float, st: float, ct: float) -> Color:
		var c: Color = mottle.call(u * 0.6 + 0.2, st, ct)
		return c.lerp(CRE, _smooth(0.62, 0.85, u) * 0.85)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.01, -0.12), "rx": 0.045},
		{"p": Vector3(0, 0.01, -0.04), "rx": 0.15, "ry": 0.14},
		{"p": Vector3(0, 0.0, 0.05), "rx": 0.14, "ry": 0.13},
		{"p": Vector3(0, -0.025, 0.12), "rx": 0.075, "ry": 0.062},
		{"p": Vector3(0, -0.025, 0.155), "rx": 0.02},
	], 14, head_fn)
	_cat_ears(B, 1.0, ORA)
	_leg_set([0.13, 0.16], 0.3, 0.062, B.darkened(0.05), ORA)
	var tail_fn := func(u: float, _st: float, _ct: float) -> Color:
		if u > 0.82:
			return Color(0.88, 0.85, 0.78)
		return B.lerp(ORA, 0.55 if sin(u * 18.0) > 0.4 else 0.0)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, 0.0), "rx": 0.045},
		{"p": Vector3(0, 0.1, -0.1), "rx": 0.038},
		{"p": Vector3(0, 0.24, -0.18), "rx": 0.033},
		{"p": Vector3(0, 0.42, -0.21), "rx": 0.028},
		{"p": Vector3(0, 0.56, -0.16), "rx": 0.022},
		{"p": Vector3(0, 0.63, -0.12), "rx": 0.006},
	], 9, tail_fn)
	_face(Vector3(0.055, 0.03, 0.105), 0.05, Color(0.93, 0.68, 0.18), Vector3(0, -0.02, 0.16), 0.026)


func _build_minerva() -> void:
	var B := Color(0.11, 0.11, 0.13)
	var SH := Color(0.26, 0.26, 0.31)
	_head.position = Vector3(0, 0.66, 0.34)
	_tail.position = Vector3(0, 0.44, -0.34)
	var body_fn := func(_u: float, st: float, _ct: float) -> Color:
		return B.lerp(SH, _smooth(0.3, 1.0, st) * 0.5)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.44, -0.36), "rx": 0.05},
		{"p": Vector3(0, 0.42, -0.26), "rx": 0.165, "ry": 0.155},
		{"p": Vector3(0, 0.41, 0.0), "rx": 0.185, "ry": 0.175},
		{"p": Vector3(0, 0.43, 0.15), "rx": 0.155, "ry": 0.15},
		{"p": Vector3(0, 0.52, 0.26), "rx": 0.105, "ry": 0.1},
		{"p": Vector3(0, 0.57, 0.31), "rx": 0.045},
	], 16, body_fn)
	var head_fn := func(_u: float, st: float, _ct: float) -> Color:
		return B.lerp(SH, _smooth(0.3, 1.0, st) * 0.4)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.01, -0.12), "rx": 0.045},
		{"p": Vector3(0, 0.01, -0.04), "rx": 0.14, "ry": 0.135},
		{"p": Vector3(0, 0.0, 0.05), "rx": 0.13, "ry": 0.12},
		{"p": Vector3(0, -0.025, 0.12), "rx": 0.07, "ry": 0.058},
		{"p": Vector3(0, -0.025, 0.15), "rx": 0.018},
	], 14, head_fn)
	_cat_ears(B, 1.3, B.darkened(0.2))
	_leg_set([0.12, 0.15], 0.38, 0.05, B, SH)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, 0.0), "rx": 0.038},
		{"p": Vector3(0, 0.22, -0.12), "rx": 0.03},
		{"p": Vector3(0, 0.46, -0.12), "rx": 0.025},
		{"p": Vector3(0, 0.61, -0.02), "rx": 0.018},
		{"p": Vector3(0, 0.66, 0.04), "rx": 0.005},
	], 9, Callable(), B)
	_face(Vector3(0.046, 0.032, 0.108), 0.044, Color(0.8, 0.8, 0.32), Vector3(0, -0.018, 0.155), 0.026)
	# bigodes brancos + presinhas
	for s in [-1.0, 1.0]:
		for i in 2:
			var wy := -0.03 - 0.03 * i
			PetMesh.loft(_head, [
				{"p": Vector3(0.1 * s, wy, 0.11), "rx": 0.006},
				{"p": Vector3(0.24 * s, wy - 0.015 + 0.02 * i, 0.07), "rx": 0.002},
			], 6, Callable(), Color(0.93, 0.93, 0.9))
		PetMesh.loft(_head, [
			{"p": Vector3(0.028 * s, -0.075, 0.135), "rx": 0.011},
			{"p": Vector3(0.028 * s, -0.11, 0.14), "rx": 0.003},
		], 6, Callable(), Color(0.95, 0.94, 0.9))


## ------------------------------------------------ peças compartilhadas

func _leg_set(xz: Array, hip_y: float, r: float, color: Color, paw_tone: Color) -> void:
	for i in 4:
		var lx: float = (-1.0 if i % 2 == 0 else 1.0) * xz[0]
		var lz: float = (1.0 if i < 2 else -1.0) * xz[1]
		var leg := _legs[i]
		leg.position = Vector3(lx, hip_y, lz)
		var leg_fn := func(u: float, _st: float, _ct: float) -> Color:
			return color.lerp(paw_tone, _smooth(0.75, 0.95, u) * 0.4)
		PetMesh.loft(leg, [
			{"p": Vector3(0, 0.06, 0), "rx": r * 1.25},
			{"p": Vector3(0, -(hip_y - 0.1) * 0.5, 0), "rx": r},
			{"p": Vector3(0, 0.09 - hip_y, 0), "rx": r * 0.92},
			{"p": Vector3(0, 0.045 - hip_y, 0.025), "rx": r * 1.15, "ry": r * 0.8},
			{"p": Vector3(0, 0.01 - hip_y, 0.03), "rx": r * 0.5},
		], 10, leg_fn)


func _cat_ears(color: Color, k: float, inner: Color) -> void:
	for s in [-1.0, 1.0]:
		var ear_fn := func(u: float, _st: float, _ct: float) -> Color:
			return color.lerp(inner, (1.0 - u) * 0.25)
		PetMesh.loft(_head, [
			{"p": Vector3(0.075 * s, 0.1, -0.01), "rx": 0.055 * k, "ry": 0.02},
			{"p": Vector3(0.1 * s, 0.17 * k, -0.015), "rx": 0.035 * k, "ry": 0.015},
			{"p": Vector3(0.115 * s, 0.23 * k, -0.02), "rx": 0.006},
		], 8, ear_fn)


func _face(eye_at: Vector3, eye_r: float, iris: Color, nose_at: Vector3, nose_r: float) -> void:
	for s in [-1.0, 1.0]:
		var e := Vector3(eye_at.x * s, eye_at.y, eye_at.z)
		var out := Vector3(0.3 * s, 0.12, 0.95).normalized()
		PetMesh.ball(_head, eye_r, e, Color(0.93, 0.91, 0.88), Vector3(1, 1, 0.5))
		PetMesh.ball(_head, eye_r * 0.88, e + out * (eye_r * 0.22), iris, Vector3(1, 1, 0.5))
		PetMesh.ball(_head, eye_r * 0.5, e + out * (eye_r * 0.45), Color(0.05, 0.05, 0.05), Vector3(1, 1, 0.5), 8)
		PetMesh.ball(_head, eye_r * 0.16, e + out * (eye_r * 0.6) + Vector3(eye_r * 0.18 * s, eye_r * 0.22, 0), Color.WHITE, Vector3.ONE, 6)
	PetMesh.ball(_head, nose_r, nose_at, Color(0.06, 0.05, 0.05), Vector3(1.3, 0.85, 0.9), 8)


func _make_tongue(at: Vector3, always: bool) -> void:
	_blep = always
	_tongue = PetMesh.loft(_head, [
		{"p": at, "rx": 0.028, "ry": 0.01},
		{"p": at + Vector3(0, -0.035, 0.02), "rx": 0.026, "ry": 0.009},
		{"p": at + Vector3(0, -0.055, 0.022), "rx": 0.012, "ry": 0.006},
	], 8, Callable(), Color(0.93, 0.5, 0.55))
	_tongue.visible = always


## ------------------------------------------------ poses e animação

func set_pose(p: String) -> void:
	if pose == p:
		return
	pose = p
	_ball.visible = p == "play"
	_set_ghost(p == "hide")


func animate(delta: float) -> void:
	_t += delta
	var wag_speed := 3.0
	var core_rot := Vector3.ZERO
	var core_pos := Vector3.ZERO
	match pose:
		"walk":
			var swing := sin(_t * 10.0) * 0.55 * clampf(move_ratio, 0.2, 1.0)
			for i in _legs.size():
				_legs[i].rotation.x = swing * (1.0 if i % 2 == 0 else -1.0)
			core_pos.y = absf(sin(_t * 10.0)) * 0.04
			wag_speed = 6.0
		"idle":
			for leg in _legs:
				leg.rotation.x = lerpf(leg.rotation.x, 0.0, 10.0 * delta)
			core_pos.y = sin(_t * 2.0) * 0.013
		"bark":
			core_rot.x = -0.22
			_head.rotation.x = sin(_t * 20.0) * 0.18
			wag_speed = 10.0
		"ferocious":
			core_rot.x = 0.18
			core_pos.y = absf(sin(_t * 14.0)) * 0.05
			wag_speed = 14.0
		"pounce":
			core_rot.x = 0.32
			wag_speed = 8.0
		"hide":
			core_pos.y = -0.1
			core_rot.x = 0.08
		"sit_wag":
			core_rot.x = -0.45
			core_pos.y = -0.04
			wag_speed = 16.0
		"belly_up":
			# Gira em torno da origem no chão; o offset alto recoloca o
			# corpo em cima do piso (corrige o antigo afundamento).
			core_rot.z = PI
			core_pos.y = 0.86
			for i in _legs.size():
				_legs[i].rotation.x = sin(_t * 6.0 + i) * 0.3
		"play":
			core_rot.x = 0.26
			core_pos.y = absf(sin(_t * 8.0)) * 0.07
			_ball.position.y = absf(sin(_t * 8.0 + 1.0)) * 0.24
			wag_speed = 12.0
		"rub":
			core_rot.z = sin(_t * 5.0) * 0.32
			wag_speed = 10.0
		"sad":
			core_rot.x = 0.15
			core_pos.y = -0.05
			_head.rotation.x = 0.3
			wag_speed = 0.5
		"eat":
			core_rot.x = 0.3
			_head.rotation.x = 0.4 + sin(_t * 12.0) * 0.1
	if pose != "bark" and pose != "sad" and pose != "eat":
		_head.rotation.x = lerp_angle(_head.rotation.x, 0.0, 10.0 * delta)
	_core.rotation = _core.rotation.lerp(core_rot, 12.0 * delta)
	_core.position = _core.position.lerp(core_pos, 12.0 * delta)
	_tail.rotation.y = sin(_t * wag_speed) * 0.55
	if _tongue != null:
		_tongue.visible = _blep or (bool(_def.get("tongue", false)) and pose in ["walk", "sit_wag", "play"])


func flash(color: Color) -> void:
	if _body_mesh == null:
		return
	var old := _body_mesh.material_override
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	_body_mesh.material_override = mat
	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_body_mesh):
			_body_mesh.material_override = old
	)


func _set_ghost(on: bool) -> void:
	if _ghosted == on:
		return
	_ghosted = on
	var target := PetMesh.ghost_material() if on else PetMesh.material()
	var stack: Array[Node] = [_core]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.has_meta("loft"):
			(n as MeshInstance3D).material_override = target
		stack.append_array(n.get_children())
