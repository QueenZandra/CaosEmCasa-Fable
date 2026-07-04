class_name MeshLib
## Helpers to build the whole low-poly world out of primitive meshes,
## with a small cached material palette.

static var _materials := {}


static func material(color: Color, emissive := false) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), emissive]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.7
	if color.a < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials[key] = mat
	return mat


static func box(parent: Node, size: Vector3, color: Color, pos: Vector3, rot_y := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, color, pos, rot_y)


static func sphere(parent: Node, radius: float, color: Color, pos: Vector3, squash := 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add(parent, mesh, color, pos)


static func capsule(parent: Node, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _add(parent, mesh, color, pos)


static func cylinder(parent: Node, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _add(parent, mesh, color, pos)


static func cone(parent: Node, radius: float, height: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	return _add(parent, mesh, color, pos)


static func prism(parent: Node, size: Vector3, color: Color, pos: Vector3, rot_y := 0.0) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	return _add(parent, mesh, color, pos, rot_y)


static func _add(parent: Node, mesh: Mesh, color: Color, pos: Vector3, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color)
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi


## Static collision box (walls, furniture).
static func collider_box(parent: Node, size: Vector3, pos: Vector3, rot_y := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = pos
	body.rotation.y = rot_y
	parent.add_child(body)
	return body


## Flat circle marker on the ground (auras, targets).
static func ground_disc(parent: Node, radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04
	mesh.radial_segments = 24
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color)
	mi.position = pos + Vector3(0, 0.02, 0)
	parent.add_child(mi)
	return mi
