class_name PetBody
extends Node3D
## Corpo procedural facetado de cada pet, seguindo as folhas de design de
## personagem fornecidas pela usuária (estilo low-poly com faces visíveis).
## As esculturas são idênticas às de docs/pets-preview.html — ajuste lá
## primeiro (com renders), depois espelhe aqui.
## API pública usada por pet.gd: build/set_pose/animate/flash/move_ratio.

const POSES := [
	"idle", "walk", "bark", "ferocious", "hide", "pounce",
	"sit_wag", "belly_up", "play", "rub", "sad", "eat",
]

const GAIT_PHASE := [0.0, PI, PI, 0.0]  # FL, FR, BL, BR — pares diagonais

var pose := "idle"
var move_ratio := 0.0

var _def := {}
var _pet_id := "sirius"
var _t := 0.0
var _core: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _leg_home: Array[Vector3] = []
var _ear_l: Node3D
var _ear_r: Node3D
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
	_ear_l = Node3D.new()
	_ear_r = Node3D.new()
	_head.add_child(_ear_l)
	_head.add_child(_ear_r)
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
	PetMesh.ball(_ball, 0.09, Vector3(0, 0.09, 0.55), Color(0.9, 0.25, 0.3), Vector3.ONE, 9)
	PetMesh.ball(_ball, 0.092, Vector3(0, 0.09, 0.55), Color(0.95, 0.9, 0.85), Vector3(1.0, 0.22, 1.0), 9)
	_ball.visible = false


## ------------------------------------------------ esculturas por pet

func _build_sirius() -> void:
	# Folha: pastor belga x vira-lata — atlético, pelo shaggy em lascas,
	# orelhas semi-eretas de ponta dobrada, focinho grisalho, cauda-sabre.
	var B := Color(0.16, 0.15, 0.16)
	var GR := Color(0.63, 0.61, 0.58)
	_head.position = Vector3(0, 0.86, 0.38)
	_tail.position = Vector3(0, 0.6, -0.36)
	var body_fn := func(u: float, st: float, _ct: float) -> Color:
		var c := B.lerp(B.lightened(0.08), _smooth(0.1, 0.7, -st) * 0.4)
		return c.lerp(B.lightened(0.12), _smooth(0.55, 0.85, u) * 0.4)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.62, -0.38), "rx": 0.05},
		{"p": Vector3(0, 0.62, -0.28), "rx": 0.16, "ry": 0.17},
		{"p": Vector3(0, 0.60, -0.05), "rx": 0.145, "ry": 0.155},
		{"p": Vector3(0, 0.60, 0.15), "rx": 0.165, "ry": 0.205},
		{"p": Vector3(0, 0.72, 0.30), "rx": 0.125, "ry": 0.125},
		{"p": Vector3(0, 0.80, 0.36), "rx": 0.045},
	], 12, body_fn)
	var head_fn := func(u: float, st: float, _ct: float) -> Color:
		var griz := _smooth(0.58, 0.78, u) * _smooth(0.0, -0.6, st) * 0.85 + _smooth(0.82, 0.97, u) * 0.5
		return B.lerp(GR, minf(1.0, griz))
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.0, -0.14), "rx": 0.05},
		{"p": Vector3(0, 0.03, -0.03), "rx": 0.135, "ry": 0.125},
		{"p": Vector3(0, 0.0, 0.06), "rx": 0.12, "ry": 0.11},
		{"p": Vector3(0, -0.05, 0.14), "rx": 0.062, "ry": 0.055},
		{"p": Vector3(0, -0.055, 0.21), "rx": 0.048, "ry": 0.042},
		{"p": Vector3(0, -0.055, 0.235), "rx": 0.016},
	], 10, head_fn)
	# Orelhas semi-eretas com ponta dobrada
	for s in [-1.0, 1.0]:
		var ear := _ear_l if s < 0 else _ear_r
		ear.position = Vector3(0.075 * s, 0.1, -0.02)
		PetMesh.loft(ear, [
			{"p": Vector3(0, 0, 0), "rx": 0.055, "ry": 0.022},
			{"p": Vector3(0.03 * s, 0.1, -0.01), "rx": 0.042, "ry": 0.017},
			{"p": Vector3(0.055 * s, 0.125, 0.0), "rx": 0.028, "ry": 0.013},
			{"p": Vector3(0.08 * s, 0.09, 0.03), "rx": 0.007},
		], 7, Callable(), B.darkened(0.06))
	_leg_set(0.13, 0.22, 0.58, 0.055, B, B.lightened(0.06), 0.4)
	# Cauda-sabre emplumada
	var tail_fn := func(u: float, _st: float, _ct: float) -> Color:
		return B.lerp(B.lightened(0.15), u * 0.7)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, -0.02, -0.06), "rx": 0.045},
		{"p": Vector3(0, -0.1, -0.2), "rx": 0.06, "ry": 0.055},
		{"p": Vector3(0, -0.12, -0.34), "rx": 0.05, "ry": 0.045},
		{"p": Vector3(0, -0.05, -0.46), "rx": 0.028},
		{"p": Vector3(0, 0.0, -0.5), "rx": 0.006},
	], 8, tail_fn)
	# LASCAS DE PELO shaggy (colar, peito, culotes, dorso, pluma da cauda)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var shades: Array[Color] = [B, B.lightened(0.09), B.lightened(0.16), B.darkened(0.08)]
	for i in 9:
		var a := -PI * 0.15 + (float(i) / 8.0) * PI * 1.3
		var base := Vector3(cos(a) * 0.15, 0.66 - 0.02 * maxf(0.0, sin(a)), 0.24 - absf(sin(a)) * 0.03)
		var dir := Vector3(cos(a) * 0.4, -0.8, 0.25 + rng.randf() * 0.15).normalized()
		_shard(_core, base, dir, 0.11 + rng.randf() * 0.03, 0.052, shades[rng.randi() % shades.size()])
	for i in 3:
		_shard(_core, Vector3(-0.05 + i * 0.05, 0.52, 0.29), Vector3(0, -1, 0.2).normalized(), 0.1, 0.045, shades[rng.randi() % shades.size()])
	for s in [-1.0, 1.0]:
		for i in 3:
			_shard(_core, Vector3(0.13 * s, 0.5 - i * 0.05, -0.24 - i * 0.02),
				Vector3(0.12 * s, -0.65, -0.7).normalized(), 0.1, 0.045, shades[rng.randi() % shades.size()])
	for i in 4:
		_shard(_core, Vector3((rng.randf() - 0.5) * 0.14, 0.75 - i * 0.015, 0.05 - i * 0.11),
			Vector3(0, -0.2, -1).normalized(), 0.09, 0.045, shades[rng.randi() % shades.size()])
	for i in 5:
		_shard(_tail, Vector3(0, -0.08 - i * 0.008, -0.14 - i * 0.07),
			Vector3(0, -0.8, -0.4).normalized(), 0.1 - i * 0.008, 0.04, shades[rng.randi() % shades.size()])
	_face(Vector3(0.058, 0.04, 0.115), 0.045, Color(0.72, 0.42, 0.12), Vector3(0, -0.052, 0.235), 0.028, Color(0.06, 0.05, 0.05))
	_make_tongue(Vector3(0, -0.1, 0.17), false)


func _build_belatriz() -> void:
	# Folha: filhote compacto creme, cabeção, orelhinhas dobradas com rosa
	# interno, sobrancelhas expressivas, rabinho curvado.
	var B := Color(0.88, 0.81, 0.66)
	var CRE := Color(0.95, 0.91, 0.8)
	_head.position = Vector3(0, 0.56, 0.26)
	_tail.position = Vector3(0, 0.35, -0.22)
	var body_fn := func(u: float, st: float, _ct: float) -> Color:
		return B.lerp(CRE, _smooth(0.0, 0.6, -st) * 0.7 + _smooth(0.6, 0.9, u) * 0.3)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.33, -0.24), "rx": 0.05},
		{"p": Vector3(0, 0.33, -0.16), "rx": 0.155, "ry": 0.15},
		{"p": Vector3(0, 0.32, 0.0), "rx": 0.165, "ry": 0.16},
		{"p": Vector3(0, 0.34, 0.12), "rx": 0.15, "ry": 0.147},
		{"p": Vector3(0, 0.42, 0.2), "rx": 0.11},
		{"p": Vector3(0, 0.46, 0.24), "rx": 0.04},
	], 12, body_fn)
	var head_fn := func(u: float, st: float, _ct: float) -> Color:
		var c := B.lerp(CRE, _smooth(0.5, 0.8, u) * 0.7)
		return c.lerp(B.lightened(0.1), _smooth(0.5, 0.2, u) * _smooth(0.3, 0.9, st) * 0.5)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.02, -0.11), "rx": 0.05},
		{"p": Vector3(0, 0.03, -0.02), "rx": 0.155, "ry": 0.145},
		{"p": Vector3(0, 0.01, 0.07), "rx": 0.145, "ry": 0.135},
		{"p": Vector3(0, -0.05, 0.13), "rx": 0.075, "ry": 0.058},
		{"p": Vector3(0, -0.055, 0.155), "rx": 0.02},
	], 10, head_fn)
	# Orelhas semi-eretas com ponta dobrada e rosinha interna
	for s in [-1.0, 1.0]:
		var ear := _ear_l if s < 0 else _ear_r
		ear.position = Vector3(0.09 * s, 0.11, -0.01)
		var ear_fn := func(u: float, _st: float, _ct: float) -> Color:
			return B.darkened(0.1).lerp(Color(0.9, 0.6, 0.62), _smooth(0.3, 0.7, u) * 0.45)
		PetMesh.loft(ear, [
			{"p": Vector3(0, 0, 0), "rx": 0.05, "ry": 0.02},
			{"p": Vector3(0.04 * s, 0.08, -0.01), "rx": 0.04, "ry": 0.016},
			{"p": Vector3(0.075 * s, 0.06, 0.03), "rx": 0.025, "ry": 0.012},
			{"p": Vector3(0.085 * s, 0.02, 0.055), "rx": 0.006},
		], 7, ear_fn)
	_leg_set(0.115, 0.15, 0.30, 0.055, B, CRE, 0.5)
	# Rabinho curto curvado para cima
	var tail_fn := func(u: float, _st: float, _ct: float) -> Color:
		return B.lerp(CRE, u * 0.6)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, -0.04), "rx": 0.035},
		{"p": Vector3(0, 0.1, -0.08), "rx": 0.045, "ry": 0.04},
		{"p": Vector3(0, 0.2, -0.04), "rx": 0.03},
		{"p": Vector3(0, 0.25, 0.02), "rx": 0.007},
	], 7, tail_fn)
	_face(Vector3(0.062, 0.03, 0.115), 0.06, Color(0.22, 0.15, 0.1), Vector3(0, -0.04, 0.16), 0.028, Color(0.06, 0.05, 0.05))
	# Sobrancelhas expressivas (pontinhos da folha de design)
	for s in [-1.0, 1.0]:
		PetMesh.ball(_head, 0.022, Vector3(0.062 * s, 0.105, 0.11), Color(0.5, 0.42, 0.3), Vector3(1.3, 0.7, 0.6), 6)
	_make_tongue(Vector3(0, -0.09, 0.13), true)


func _build_zoe() -> void:
	# Folha (novo design): gata tabby marrom com listras, peito/patas
	# brancos, olhos verdes, focinho rosa — esguia e ágil.
	var B := Color(0.63, 0.45, 0.3)
	var ST := Color(0.33, 0.23, 0.16)
	var W := Color(0.95, 0.93, 0.88)
	_head.position = Vector3(0, 0.7, 0.29)
	_tail.position = Vector3(0, 0.46, -0.26)
	var tabby := func(u: float, st: float, _ct: float) -> Color:
		var c := B
		var band := pow(absf(sin(u * 22.0)), 6.0) * _smooth(-0.25, 0.25, st)
		c = c.lerp(ST, band * 0.85)
		c = c.lerp(W, _smooth(-0.15, -0.65, st) * 0.9)
		return c.lerp(W, _smooth(0.62, 0.88, u) * _smooth(0.15, -0.4, st))
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.46, -0.3), "rx": 0.05},
		{"p": Vector3(0, 0.46, -0.22), "rx": 0.14, "ry": 0.145},
		{"p": Vector3(0, 0.45, -0.03), "rx": 0.135, "ry": 0.15},
		{"p": Vector3(0, 0.46, 0.12), "rx": 0.14, "ry": 0.15},
		{"p": Vector3(0, 0.56, 0.22), "rx": 0.09},
		{"p": Vector3(0, 0.62, 0.27), "rx": 0.04},
	], 12, tabby)
	var head_fn := func(u: float, st: float, ct: float) -> Color:
		var c := B
		var fore := pow(absf(sin((ct + 1.0) * 5.0)), 8.0) * _smooth(0.35, 0.75, st) * _smooth(0.55, 0.25, u)
		c = c.lerp(ST, fore * 0.8)
		return c.lerp(W, _smooth(0.6, 0.82, u) * _smooth(0.1, -0.5, st) * 0.95 + _smooth(0.78, 0.95, u) * 0.5)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.01, -0.1), "rx": 0.04},
		{"p": Vector3(0, 0.02, -0.02), "rx": 0.12, "ry": 0.105},
		{"p": Vector3(0, -0.01, 0.05), "rx": 0.11, "ry": 0.1},
		{"p": Vector3(0, -0.04, 0.115), "rx": 0.052, "ry": 0.042},
		{"p": Vector3(0, -0.04, 0.14), "rx": 0.016},
	], 10, head_fn)
	_cat_ears(B, 1.0, Color(0.85, 0.55, 0.5))
	_leg_set(0.105, 0.16, 0.40, 0.048, B, W, 0.9)
	# Cauda erguida com aneizinhos
	var tail_fn := func(u: float, _st: float, _ct: float) -> Color:
		return B.lerp(ST, pow(absf(sin(u * 14.0)), 6.0) * 0.85)
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, -0.04), "rx": 0.038},
		{"p": Vector3(0, 0.14, -0.1), "rx": 0.032},
		{"p": Vector3(0, 0.32, -0.08), "rx": 0.028},
		{"p": Vector3(0, 0.46, -0.01), "rx": 0.022},
		{"p": Vector3(0, 0.53, 0.04), "rx": 0.006},
	], 7, tail_fn)
	_face(Vector3(0.05, 0.025, 0.095), 0.045, Color(0.55, 0.75, 0.35), Vector3(0, -0.028, 0.145), 0.02, Color(0.85, 0.5, 0.5))


func _build_minerva() -> void:
	# Folha: gata preta sólida elegante — esguia, cauda bem erguida,
	# orelhonas, olhos amarelos, bigodes brancos.
	var B := Color(0.13, 0.13, 0.15)
	var SH := Color(0.24, 0.24, 0.29)
	_head.position = Vector3(0, 0.76, 0.32)
	_tail.position = Vector3(0, 0.5, -0.26)
	var body_fn := func(_u: float, st: float, _ct: float) -> Color:
		return B.lerp(SH, _smooth(0.2, 1.0, st) * 0.5)
	_body_mesh = PetMesh.loft(_core, [
		{"p": Vector3(0, 0.5, -0.3), "rx": 0.045},
		{"p": Vector3(0, 0.5, -0.22), "rx": 0.12, "ry": 0.13},
		{"p": Vector3(0, 0.49, -0.05), "rx": 0.105, "ry": 0.115},
		{"p": Vector3(0, 0.5, 0.12), "rx": 0.125, "ry": 0.145},
		{"p": Vector3(0, 0.6, 0.24), "rx": 0.085},
		{"p": Vector3(0, 0.66, 0.3), "rx": 0.035},
	], 12, body_fn)
	var head_fn := func(_u: float, st: float, _ct: float) -> Color:
		return B.lerp(SH, _smooth(0.2, 1.0, st) * 0.4)
	PetMesh.loft(_head, [
		{"p": Vector3(0, 0.01, -0.1), "rx": 0.04},
		{"p": Vector3(0, 0.02, -0.02), "rx": 0.115, "ry": 0.1},
		{"p": Vector3(0, -0.01, 0.05), "rx": 0.105, "ry": 0.095},
		{"p": Vector3(0, -0.035, 0.115), "rx": 0.05, "ry": 0.04},
		{"p": Vector3(0, -0.035, 0.14), "rx": 0.015},
	], 10, head_fn)
	_cat_ears(B, 1.25, B.darkened(0.25))
	_leg_set(0.10, 0.16, 0.46, 0.042, B, SH, 0.3)
	# Cauda BEM erguida, elegante
	PetMesh.loft(_tail, [
		{"p": Vector3(0, 0.0, -0.04), "rx": 0.032},
		{"p": Vector3(0, 0.16, -0.08), "rx": 0.028},
		{"p": Vector3(0, 0.36, -0.04), "rx": 0.024},
		{"p": Vector3(0, 0.52, 0.04), "rx": 0.018},
		{"p": Vector3(0, 0.58, 0.08), "rx": 0.005},
	], 7, Callable(), B)
	_face(Vector3(0.046, 0.028, 0.098), 0.042, Color(0.9, 0.75, 0.25), Vector3(0, -0.026, 0.142), 0.018, Color(0.1, 0.09, 0.09))
	# Bigodes brancos
	for s in [-1.0, 1.0]:
		for i in 2:
			var wy := -0.025 - 0.026 * i
			PetMesh.loft(_head, [
				{"p": Vector3(0.11 * s, wy, 0.1), "rx": 0.005},
				{"p": Vector3(0.26 * s, wy - 0.01 + 0.02 * i, 0.055), "rx": 0.002},
			], 6, Callable(), Color(0.93, 0.93, 0.9))


## ------------------------------------------------ peças compartilhadas

## Lasca de pelo: pétala achatada e angular (estilo shaggy da referência).
func _shard(parent: Node3D, base: Vector3, dir: Vector3, len_: float, w: float, color: Color) -> void:
	PetMesh.loft(parent, [
		{"p": base, "rx": w, "ry": w * 0.5},
		{"p": base + dir * (len_ * 0.5), "rx": w * 0.85, "ry": w * 0.4},
		{"p": base + dir * len_, "rx": 0.005},
	], 5, Callable(), color)


## Pernas retas com patinha; paw_mix controla a "meia" (0.9 = branca).
func _leg_set(x: float, z: float, hip_y: float, r: float, color: Color, paw: Color, paw_mix: float) -> void:
	var zs := [z, z, -z, -z]
	for i in 4:
		var lx := (-1.0 if i % 2 == 0 else 1.0) * x
		var lz: float = zs[i]
		var leg := _legs[i]
		leg.position = Vector3(lx, hip_y, lz)
		_leg_home.append(leg.position)
		var leg_fn := func(u: float, _st: float, _ct: float) -> Color:
			return color.lerp(paw, _smooth(0.68, 0.88, u) * paw_mix)
		PetMesh.loft(leg, [
			{"p": Vector3(0, 0.05, 0), "rx": r * 1.35},
			{"p": Vector3(0, hip_y * 0.55 - hip_y, 0), "rx": r},
			{"p": Vector3(0, 0.085 - hip_y, 0), "rx": r * 0.88},
			{"p": Vector3(0, 0.045 - hip_y, 0.02), "rx": r * 1.18, "ry": r * 0.82},
			{"p": Vector3(0, 0.008 - hip_y, 0.028), "rx": r * 0.5},
		], 8, leg_fn)


func _cat_ears(color: Color, k: float, inner: Color) -> void:
	for s in [-1.0, 1.0]:
		var ear := _ear_l if s < 0 else _ear_r
		ear.position = Vector3(0.065 * s, 0.07, -0.02)
		var ear_fn := func(u: float, _st: float, _ct: float) -> Color:
			return color.lerp(inner, (1.0 - u) * 0.3)
		PetMesh.loft(ear, [
			{"p": Vector3(0, 0, 0), "rx": 0.052 * k, "ry": 0.018},
			{"p": Vector3(0.025 * s, 0.11 * k, -0.01), "rx": 0.032 * k, "ry": 0.013},
			{"p": Vector3(0.043 * s, 0.17 * k, -0.02), "rx": 0.005},
		], 6, ear_fn)


func _face(eye_at: Vector3, eye_r: float, iris: Color, nose_at: Vector3, nose_r: float, nose_color: Color) -> void:
	for s in [-1.0, 1.0]:
		var e := Vector3(eye_at.x * s, eye_at.y, eye_at.z)
		var out := Vector3(0.28 * s, 0.12, 0.95).normalized()
		PetMesh.ball(_head, eye_r, e, Color(0.93, 0.91, 0.88), Vector3(1, 1, 0.5), 9)
		PetMesh.ball(_head, eye_r * 0.88, e + out * (eye_r * 0.22), iris, Vector3(1, 1, 0.5), 9)
		PetMesh.ball(_head, eye_r * 0.5, e + out * (eye_r * 0.45), Color(0.05, 0.05, 0.05), Vector3(1, 1, 0.5), 7)
		PetMesh.ball(_head, eye_r * 0.16, e + out * (eye_r * 0.6) + Vector3(eye_r * 0.18 * s, eye_r * 0.22, 0), Color.WHITE, Vector3.ONE, 5)
	PetMesh.ball(_head, nose_r, nose_at, nose_color, Vector3(1.3, 0.8, 0.85), 7)


func _make_tongue(at: Vector3, always: bool) -> void:
	_blep = always
	_tongue = PetMesh.loft(_head, [
		{"p": at, "rx": 0.026, "ry": 0.01},
		{"p": at + Vector3(0, -0.032, 0.018), "rx": 0.024, "ry": 0.009},
		{"p": at + Vector3(0, -0.05, 0.02), "rx": 0.011, "ry": 0.006},
	], 7, Callable(), Color(0.93, 0.5, 0.55))
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
	var wag_amp := 0.55
	var core_rot := Vector3.ZERO
	var core_pos := Vector3.ZERO
	var core_scale := Vector3.ONE
	var head_rx := 0.0
	var head_rz := 0.0
	var ear_swing := 0.0
	var leg_rot := [0.0, 0.0, 0.0, 0.0]
	var leg_lift := [0.0, 0.0, 0.0, 0.0]
	match pose:
		"walk":
			# Marcha quadrúpede: pares diagonais + squash & stretch.
			var ph := _t * 9.0
			var ratio := clampf(move_ratio, 0.25, 1.0)
			for i in 4:
				leg_rot[i] = sin(ph + GAIT_PHASE[i]) * 0.55 * ratio
				leg_lift[i] = maxf(0.0, sin(ph + GAIT_PHASE[i] + PI / 2.0)) * 0.05 * ratio
			core_pos.y = absf(sin(ph)) * 0.03 * ratio
			core_rot.z = sin(ph) * 0.03 * ratio
			var sq := 1.0 + sin(ph * 2.0 + PI / 2.0) * 0.03 * ratio
			core_scale = Vector3(1.0 / sqrt(sq), sq, 1.0 / sqrt(sq))
			head_rx = sin(ph * 2.0) * 0.05
			ear_swing = sin(ph * 2.0 - 0.9) * 0.2
			wag_speed = 7.0
		"idle":
			var breathe := 1.0 + sin(_t * 2.0) * 0.012
			core_scale = Vector3(1.0, breathe, 1.0)
			core_pos.y = sin(_t * 2.0) * 0.006
			head_rz = sin(_t * 0.6) * 0.05
			ear_swing = sin(_t * 1.3) * 0.05
			wag_speed = 2.2
			wag_amp = 0.3
		"bark":
			core_rot.x = -0.22
			head_rx = sin(_t * 20.0) * 0.18
			ear_swing = sin(_t * 20.0 - 1.0) * 0.3
			core_scale = Vector3(1.02, 0.97, 1.02)
			wag_speed = 10.0
		"ferocious":
			core_rot.x = 0.18
			core_pos.y = absf(sin(_t * 14.0)) * 0.05
			core_scale = Vector3(1.04, 1.0 + sin(_t * 14.0) * 0.03, 1.04)
			ear_swing = -0.25
			wag_speed = 14.0
		"pounce":
			core_rot.x = 0.32
			core_scale = Vector3(0.94, 0.94, 1.14)
			ear_swing = -0.3
			wag_speed = 8.0
		"hide":
			core_pos.y = -0.1
			core_rot.x = 0.08
			core_scale = Vector3(1.05, 0.84, 1.05)
			ear_swing = -0.25
		"sit_wag":
			core_rot.x = -0.45
			core_pos.y = -0.04
			ear_swing = sin(_t * 16.0) * 0.07
			head_rz = sin(_t * 3.0) * 0.06
			wag_speed = 16.0
		"belly_up":
			core_rot.z = PI
			core_pos.y = 0.86
			ear_swing = 0.18
			for i in 4:
				leg_rot[i] = sin(_t * 6.0 + i) * 0.3
		"play":
			core_rot.x = 0.26
			core_pos.y = absf(sin(_t * 8.0)) * 0.07
			core_scale = Vector3(1.0, 1.0 + sin(_t * 8.0) * 0.05, 1.0)
			ear_swing = sin(_t * 8.0) * 0.15
			_ball.position.y = absf(sin(_t * 8.0 + 1.0)) * 0.24
			wag_speed = 12.0
		"rub":
			core_rot.z = sin(_t * 5.0) * 0.32
			ear_swing = sin(_t * 5.0) * 0.12
			wag_speed = 10.0
		"sad":
			core_rot.x = 0.15
			core_pos.y = -0.05
			head_rx = 0.3
			ear_swing = -0.3
			wag_speed = 0.5
		"eat":
			core_rot.x = 0.3
			head_rx = 0.4 + sin(_t * 12.0) * 0.1
	_core.rotation = _core.rotation.lerp(core_rot, 12.0 * delta)
	_core.position = _core.position.lerp(core_pos, 12.0 * delta)
	_core.scale = _core.scale.lerp(core_scale, 12.0 * delta)
	_head.rotation.x = lerp_angle(_head.rotation.x, head_rx, 10.0 * delta)
	_head.rotation.z = lerp_angle(_head.rotation.z, head_rz, 10.0 * delta)
	# Rabo com follow-through: onda principal + camada atrasada.
	_tail.rotation.y = sin(_t * wag_speed) * wag_amp + sin(_t * wag_speed * 0.5 - 0.6) * wag_amp * 0.35
	# Orelhas com flop atrasado (fator por pet, das folhas de design).
	var ear_amp := float(_def.get("flop_k", 0.35))
	_ear_l.rotation = Vector3(ear_swing * ear_amp, 0, -absf(ear_swing) * 0.4 * ear_amp)
	_ear_r.rotation = Vector3(ear_swing * ear_amp, 0, absf(ear_swing) * 0.4 * ear_amp)
	for i in 4:
		if i < _legs.size():
			_legs[i].rotation.x = lerpf(_legs[i].rotation.x, leg_rot[i], 14.0 * delta)
			if i < _leg_home.size():
				_legs[i].position = _leg_home[i] + Vector3(0, leg_lift[i], 0)
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
