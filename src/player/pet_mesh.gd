class_name PetMesh
## Loft engine: gera malhas contínuas e suaves a partir de seções elípticas
## ao longo de uma espinha (Catmull-Rom), com cores por vértice.
## Port fiel do motor usado em docs/pets-preview.html — os modelos do jogo
## e do preview são os mesmos.

static var _material: StandardMaterial3D
static var _ghost: StandardMaterial3D


## Material compartilhado: albedo branco * cor de vértice.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.9
	return _material


## Material "fantasma" para a camuflagem da Zoe.
static func ghost_material() -> StandardMaterial3D:
	if _ghost == null:
		_ghost = StandardMaterial3D.new()
		_ghost.vertex_color_use_as_albedo = true
		_ghost.roughness = 0.9
		_ghost.albedo_color = Color(1, 1, 1, 0.3)
		_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _ghost


static func _cr(a: float, b: float, c: float, d: float, t: float) -> float:
	return b + 0.5 * t * (c - a + t * (2.0 * a - 5.0 * b + 4.0 * c - d + t * (3.0 * (b - c) + d - a)))


## Reamostra as seções com Catmull-Rom para curvatura suave.
## Seção: {"p": Vector3, "rx": float, "ry": float (opcional = rx)}
static func resample(sections: Array, per: int) -> Array:
	var out: Array = []
	var n := sections.size()
	for i in range(n - 1):
		var s0: Dictionary = sections[maxi(0, i - 1)]
		var s1: Dictionary = sections[i]
		var s2: Dictionary = sections[mini(n - 1, i + 1)]
		var s3: Dictionary = sections[mini(n - 1, i + 2)]
		var steps := per + 1 if i == n - 2 else per
		for k in steps:
			var t := float(k) / float(per)
			var p0: Vector3 = s0["p"]
			var p1: Vector3 = s1["p"]
			var p2: Vector3 = s2["p"]
			var p3: Vector3 = s3["p"]
			out.append({
				"p": Vector3(
					_cr(p0.x, p1.x, p2.x, p3.x, t),
					_cr(p0.y, p1.y, p2.y, p3.y, t),
					_cr(p0.z, p1.z, p2.z, p3.z, t)
				),
				"rx": maxf(0.004, _cr(_rxof(s0), _rxof(s1), _rxof(s2), _rxof(s3), t)),
				"ry": maxf(0.004, _cr(_ryof(s0), _ryof(s1), _ryof(s2), _ryof(s3), t)),
			})
	return out


static func _rxof(s: Dictionary) -> float:
	return float(s["rx"])


static func _ryof(s: Dictionary) -> float:
	return float(s.get("ry", s["rx"]))


## Constrói o tubo suave. color_fn: Callable(u: float, st: float, ct: float) -> Color
## (st/ct = seno/cosseno do ângulo da seção; u = 0..1 ao longo da espinha).
## Passe Callable() inválida para usar só base_color.
static func loft(parent: Node3D, sections: Array, segs: int, color_fn: Callable, base_color := Color.WHITE) -> MeshInstance3D:
	var s := resample(sections, 4)
	var rows: Array = []
	var verts: Array[Vector3] = []
	var colors: Array[Color] = []
	for i in s.size():
		var prev: Vector3 = s[maxi(0, i - 1)]["p"]
		var next: Vector3 = s[mini(s.size() - 1, i + 1)]["p"]
		var tangent := (next - prev).normalized()
		var up0 := Vector3(0, 0, 1) if absf(tangent.y) > 0.9 else Vector3(0, 1, 0)
		var right := up0.cross(tangent).normalized()
		var upv := tangent.cross(right).normalized()
		var u := float(i) / float(s.size() - 1)
		var row: Array[int] = []
		var center: Vector3 = s[i]["p"]
		var rx: float = s[i]["rx"]
		var ry: float = s[i]["ry"]
		for j in segs:
			var th := TAU * float(j) / float(segs)
			var ct := cos(th)
			var st := sin(th)
			verts.append(center + right * (ct * rx) + upv * (st * ry))
			colors.append(color_fn.call(u, st, ct) if color_fn.is_valid() else base_color)
			row.append(verts.size() - 1)
		rows.append(row)
	var tris: Array = []
	for i in rows.size() - 1:
		for j in segs:
			var a: int = rows[i][j]
			var b: int = rows[i + 1][j]
			var c: int = rows[i + 1][(j + 1) % segs]
			var d: int = rows[i][(j + 1) % segs]
			tris.append([a, b, d])
			tris.append([b, c, d])
	return _emit(parent, verts, colors, tris)


## Esfera suave com cor sólida (detalhes: olhos, nariz).
static func ball(parent: Node3D, r: float, pos: Vector3, color: Color, scale := Vector3.ONE, seg := 10) -> MeshInstance3D:
	var rings := maxi(6, seg - 2)
	var verts: Array[Vector3] = []
	var colors: Array[Color] = []
	var rows: Array = []
	for i in rings + 1:
		var ph := PI * float(i) / float(rings)
		var row: Array[int] = []
		for j in seg:
			var th := TAU * float(j) / float(seg)
			var p := Vector3(
				r * sin(ph) * cos(th) * scale.x,
				r * cos(ph) * scale.y,
				r * sin(ph) * sin(th) * scale.z
			)
			verts.append(p + pos)
			colors.append(color)
			row.append(verts.size() - 1)
		rows.append(row)
	var tris: Array = []
	for i in rings:
		for j in seg:
			var a: int = rows[i][j]
			var b: int = rows[i + 1][j]
			var c: int = rows[i + 1][(j + 1) % seg]
			var d: int = rows[i][(j + 1) % seg]
			if i > 0:
				tris.append([a, b, d])
			if i < rings - 1:
				tris.append([b, c, d])
	return _emit(parent, verts, colors, tris)


## Normais por FACE (flat shading facetado, estilo das folhas de design)
## + SurfaceTool -> MeshInstance3D.
static func _emit(parent: Node3D, verts: Array[Vector3], colors: Array[Color], tris: Array) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var n: Vector3 = (verts[t[1]] - verts[t[0]]).cross(verts[t[2]] - verts[t[0]])
		if n.length_squared() < 1e-12:
			n = Vector3.UP
		else:
			n = n.normalized()
		for idx in t:
			st.set_normal(n)
			st.set_color(colors[idx])
			st.add_vertex(verts[idx])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material()
	mi.set_meta("loft", true)
	parent.add_child(mi)
	return mi
