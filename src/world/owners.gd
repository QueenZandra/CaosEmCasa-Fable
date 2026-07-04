class_name Owners
extends Node3D
## The two owners (Dono e Dona), built from blocks. Level 1: they wave
## goodbye and walk out the gate. Level 6: they stand at the door fuming;
## their mood drives the rage meter (owned by the level, not here).

var angry := false

var _owner_a: Node3D
var _owner_b: Node3D
var _t := 0.0
var _walking := false
var _walk_path: Array[Vector3] = []
var _walk_speed := 2.2
var _steam: Array[MeshInstance3D] = []


func _ready() -> void:
	_owner_a = _build_person(Color(0.3, 0.45, 0.7), Color(0.25, 0.25, 0.3), 1.0)
	_owner_a.position = Vector3(-0.6, 0, 0)
	add_child(_owner_a)
	_owner_b = _build_person(Color(0.8, 0.45, 0.55), Color(0.9, 0.85, 0.4), 0.94)
	_owner_b.position = Vector3(0.6, 0, 0)
	add_child(_owner_b)
	for i in 3:
		var puff := MeshLib.sphere(self, 0.08 + 0.03 * i, Color(0.9, 0.9, 0.9, 0.7), Vector3(-0.6, 2.0 + 0.25 * i, 0))
		puff.visible = false
		_steam.append(puff)


func _build_person(shirt: Color, hair: Color, height: float) -> Node3D:
	var person := Node3D.new()
	MeshLib.box(person, Vector3(0.16, 0.7, 0.2), Color(0.3, 0.32, 0.4), Vector3(-0.12, 0.35, 0))
	MeshLib.box(person, Vector3(0.16, 0.7, 0.2), Color(0.3, 0.32, 0.4), Vector3(0.12, 0.35, 0))
	MeshLib.box(person, Vector3(0.5, 0.65, 0.3), shirt, Vector3(0, 1.0 * height, 0))
	MeshLib.sphere(person, 0.2, Color(0.9, 0.72, 0.6), Vector3(0, 1.55 * height, 0))
	MeshLib.sphere(person, 0.21, hair, Vector3(0, 1.62 * height, -0.04), 0.7)
	return person


func set_angry(value: bool) -> void:
	angry = value
	for puff in _steam:
		puff.visible = value


## Fase 1: caminham por um caminho e somem no fim.
func walk_out(path: Array) -> void:
	_walk_path.assign(path)
	_walking = true


func _process(delta: float) -> void:
	_t += delta
	# Balanço/aceno
	var bob := sin(_t * (10.0 if angry else 3.0)) * (0.06 if angry else 0.03)
	_owner_a.position.y = bob
	_owner_b.position.y = -bob
	if angry:
		_owner_a.rotation.z = sin(_t * 12.0) * 0.06
		_owner_b.rotation.z = -sin(_t * 12.0) * 0.06
		for i in _steam.size():
			var puff := _steam[i]
			puff.position.y = 2.0 + 0.25 * i + fmod(_t * 0.8 + i * 0.3, 0.5)
	if _walking and not _walk_path.is_empty():
		var target := _walk_path[0]
		var flat_target := Vector3(target.x, position.y, target.z)
		var dist := position.distance_to(flat_target)
		if dist < 0.15:
			_walk_path.pop_front()
			if _walk_path.is_empty():
				_walking = false
				visible = false
			return
		var dir := (flat_target - position).normalized()
		position += dir * _walk_speed * delta
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
