class_name Invader
extends Threat
## Animal invasor (rato, gambá ou tatu): entra pelo jardim, atravessa a
## porta e tenta roubar comida da cozinha, fugindo com ela depois.

var variant := "rat"         # rat | opossum | armadillo
var carrying_food := false
var target_food_index := -1
var _entry := Vector3.ZERO
var _food_visual: Node3D


func configure(p_variant: String, entry: Vector3, food_index: int, food_pos: Vector3, house: House) -> void:
	variant = p_variant
	kind = "invader"
	_entry = entry
	target_food_index = food_index
	position = entry  # ainda fora da árvore: usar position local
	match variant:
		"rat":
			speed = 3.8
			fear_threshold = 0.9
		"opossum":
			speed = 2.7
			fear_threshold = 1.7
		"armadillo":
			speed = 2.1
			fear_threshold = 2.7
	waypoints.assign([
		house.points["door_out"],
		house.points["door_in"],
		Vector3(food_pos.x, 0, food_pos.z),
	])


func build_visual() -> void:
	match variant:
		"rat":
			var rat_body := MeshLib.sphere(visual, 0.16, Color(0.5, 0.5, 0.55), Vector3(0, 0.14, 0), 0.8)
			rat_body.scale = Vector3(1.0, 1.0, 1.5)
			MeshLib.sphere(visual, 0.1, Color(0.55, 0.55, 0.6), Vector3(0, 0.2, 0.2))
			MeshLib.cone(visual, 0.05, 0.09, Color(0.85, 0.6, 0.6), Vector3(-0.06, 0.3, 0.2))
			MeshLib.cone(visual, 0.05, 0.09, Color(0.85, 0.6, 0.6), Vector3(0.06, 0.3, 0.2))
			var tail := MeshLib.cylinder(visual, 0.02, 0.3, Color(0.8, 0.55, 0.55), Vector3(0, 0.12, -0.3))
			tail.rotation.x = 1.2
		"opossum":
			var op_body := MeshLib.sphere(visual, 0.24, Color(0.6, 0.6, 0.62), Vector3(0, 0.22, 0), 0.8)
			op_body.scale = Vector3(1.0, 1.0, 1.5)
			MeshLib.sphere(visual, 0.13, Color(0.9, 0.88, 0.85), Vector3(0, 0.3, 0.32))
			MeshLib.cone(visual, 0.05, 0.14, Color(0.85, 0.6, 0.6), Vector3(0, 0.28, 0.46))
			MeshLib.cone(visual, 0.06, 0.12, Color(0.5, 0.5, 0.52), Vector3(-0.08, 0.44, 0.28))
			MeshLib.cone(visual, 0.06, 0.12, Color(0.5, 0.5, 0.52), Vector3(0.08, 0.44, 0.28))
			var op_tail := MeshLib.cylinder(visual, 0.025, 0.34, Color(0.85, 0.7, 0.65), Vector3(0, 0.2, -0.35))
			op_tail.rotation.x = 1.1
		"armadillo":
			var shell := MeshLib.sphere(visual, 0.26, Color(0.55, 0.45, 0.35), Vector3(0, 0.24, 0), 0.75)
			shell.scale = Vector3(1.0, 1.0, 1.4)
			for i in 3:
				MeshLib.box(visual, Vector3(0.4, 0.05, 0.1), Color(0.45, 0.37, 0.28), Vector3(0, 0.36, -0.12 + 0.12 * i))
			MeshLib.sphere(visual, 0.1, Color(0.6, 0.5, 0.4), Vector3(0, 0.18, 0.36))
			MeshLib.cone(visual, 0.04, 0.12, Color(0.5, 0.42, 0.32), Vector3(0, 0.16, 0.46))
	for i in 4:
		var lx := -0.1 if i % 2 == 0 else 0.1
		var lz := 0.12 if i < 2 else -0.12
		MeshLib.cylinder(visual, 0.03, 0.14, Color(0.4, 0.38, 0.36), Vector3(lx, 0.07, lz))


func enter_act() -> void:
	state = STATE_ACT
	# Chegou na comida: tenta pegar.
	if level != null:
		var got: bool = level.call("invader_grab_food", self, target_food_index)
		if got:
			carrying_food = true
			_food_visual = Node3D.new()
			visual.add_child(_food_visual)
			MeshLib.sphere(_food_visual, 0.12, Color(0.6, 0.4, 0.2), Vector3(0, 0.45, 0.15))
			start_flee()
			speed *= 0.85  # carregando peso
		else:
			# Comida já foi: vai embora frustrado.
			start_flee()


func on_scared_off(_source: Node) -> void:
	_drop_food()
	AudioMan.play_sfx("pop", -3.0)


func receive_scare(power: float, source: Node) -> void:
	# Invasores fugindo COM comida ainda podem ser assustados para soltá-la.
	if puppet:
		return
	if state == STATE_FLEE and carrying_food:
		fear += power
		_flash()
		if fear >= fear_threshold * 1.2:
			_drop_food()
			if level != null:
				level.call("threat_scared_off", self, source)
		return
	super.receive_scare(power, source)


func _drop_food() -> void:
	if not carrying_food:
		return
	carrying_food = false
	if _food_visual != null:
		_food_visual.queue_free()
		_food_visual = null
	if level != null:
		level.call("invader_dropped_food", self, target_food_index, global_position)


func flee_waypoints() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if global_position.z < 3.0:
		# Está dentro de casa: sai pela porta primeiro.
		out.append(Vector3(0, 0, 2.0))
		out.append(Vector3(0, 0, 4.0))
	out.append(_entry)
	return out


func reached_exit_with_food() -> bool:
	return carrying_food and state == STATE_FLEE and waypoints.is_empty()
