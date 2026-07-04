class_name Mailman
extends Threat
## O carteiro insiste em entregar encomendas na caixa de correio.
## Se completar a entrega, a fase perde pontos; assustá-lo o faz fugir.

const DELIVER_SECONDS := 5.0

var deliver_progress := 0.0
var _package: MeshInstance3D
var _from_left := true


func configure(from_left: bool, house: House) -> void:
	_from_left = from_left
	kind = "mailman"
	speed = 2.4
	fear_threshold = 1.5
	var start: Vector3 = house.points["street_left"] if from_left else house.points["street_right"]
	position = start  # ainda fora da árvore: usar position local
	waypoints = [
		Vector3(house.points["mailbox"].x, 0, 10.8),
	]


func build_visual() -> void:
	MeshLib.box(visual, Vector3(0.16, 0.6, 0.2), Color(0.25, 0.3, 0.4), Vector3(-0.11, 0.3, 0))
	MeshLib.box(visual, Vector3(0.16, 0.6, 0.2), Color(0.25, 0.3, 0.4), Vector3(0.11, 0.3, 0))
	MeshLib.box(visual, Vector3(0.48, 0.6, 0.28), Color(0.95, 0.8, 0.2), Vector3(0, 0.9, 0))
	MeshLib.sphere(visual, 0.18, Color(0.85, 0.65, 0.5), Vector3(0, 1.4, 0))
	MeshLib.cylinder(visual, 0.2, 0.08, Color(0.2, 0.25, 0.35), Vector3(0, 1.56, 0))
	MeshLib.box(visual, Vector3(0.3, 0.35, 0.15), Color(0.5, 0.35, 0.2), Vector3(0.3, 0.9, -0.15))
	_package = MeshLib.box(visual, Vector3(0.3, 0.22, 0.22), Color(0.72, 0.55, 0.35), Vector3(0, 1.05, 0.3))


func enter_act() -> void:
	state = STATE_ACT
	deliver_progress = 0.0


func act_tick(delta: float) -> void:
	deliver_progress += delta / DELIVER_SECONDS
	if _package != null:
		_package.position.y = 1.05 + deliver_progress * 0.4
	if deliver_progress >= 1.0:
		if level != null:
			level.call("mail_delivered", self)
		start_flee()


func on_scared_off(_source: Node) -> void:
	if _package != null:
		_package.visible = false
	AudioMan.play_sfx("pop")


func flee_waypoints() -> Array[Vector3]:
	var exit_x := -13.0 if _from_left else 13.0
	return [Vector3(exit_x, 0, 11.5)]
