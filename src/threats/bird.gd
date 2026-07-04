class_name Bird
extends Threat
## Passarinho: voa até uma árvore e vai construindo um ninho.
## Se o ninho completar, ponto ruim; sustos o espantam.

const NEST_SECONDS := 9.0

var tree_index := 0
var _perch := Vector3.ZERO
var _wing_l: MeshInstance3D
var _wing_r: MeshInstance3D


func configure(p_tree_index: int, house: House, entry_x: float) -> void:
	kind = "bird"
	flying = true
	speed = 3.4
	fear_threshold = 0.6
	tree_index = p_tree_index
	var tree: Vector3 = house.tree_positions[tree_index]
	_perch = tree + Vector3(0.2, 2.9, 0.4)
	position = Vector3(entry_x, 4.5, 12.5)  # ainda fora da árvore
	waypoints = [
		Vector3(entry_x * 0.5, 3.8, 9.0),
		_perch,
	]


func build_visual() -> void:
	var palette := [Color(0.85, 0.45, 0.3), Color(0.4, 0.6, 0.85), Color(0.9, 0.75, 0.3)]
	var col: Color = palette[tree_index % palette.size()]
	var bird_body := MeshLib.sphere(visual, 0.14, col, Vector3(0, 0.1, 0), 0.85)
	bird_body.scale = Vector3(1.0, 1.0, 1.3)
	MeshLib.sphere(visual, 0.09, col.lightened(0.2), Vector3(0, 0.22, 0.1))
	MeshLib.cone(visual, 0.03, 0.08, Color(0.95, 0.7, 0.2), Vector3(0, 0.22, 0.2)).rotation.x = PI / 2
	_wing_l = MeshLib.box(visual, Vector3(0.16, 0.02, 0.1), col.darkened(0.15), Vector3(-0.13, 0.12, 0))
	_wing_r = MeshLib.box(visual, Vector3(0.16, 0.02, 0.1), col.darkened(0.15), Vector3(0.13, 0.12, 0))


func enter_act() -> void:
	state = STATE_ACT
	global_position = _perch


func act_tick(delta: float) -> void:
	if level != null:
		level.call("nest_tick", tree_index, delta / NEST_SECONDS, self)


func on_scared_off(_source: Node) -> void:
	AudioMan.play_sfx("chirp")


func flee_waypoints() -> Array[Vector3]:
	var dir_x := 12.0 if global_position.x >= 0 else -12.0
	return [
		global_position + Vector3(0, 2.0, 0),
		Vector3(dir_x, 6.0, 13.0),
	]


func animate(_delta: float) -> void:
	var flap := 0.9 if anim_state != STATE_ACT else 0.15
	_wing_l.rotation.z = sin(_t * 18.0) * flap
	_wing_r.rotation.z = -sin(_t * 18.0) * flap
	if anim_state == STATE_ACT:
		visual.position.y = sin(_t * 5.0) * 0.03
