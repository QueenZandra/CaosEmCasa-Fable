class_name Knockable
extends Node3D
## Decorative object that can be knocked over (vaso, livros, luminária...).
## When knocked it topples with a tween and reports to the level, which
## spawns a MessSpot. Host-authoritative; puppets topple via event.

var kind := "vase"
var knocked := false
var net_id := 0

var _visual: Node3D


static func create(p_kind: String, pos: Vector3) -> Knockable:
	var k := Knockable.new()
	k.kind = p_kind
	k.position = pos
	return k


func _ready() -> void:
	add_to_group("knockable")
	_visual = Node3D.new()
	add_child(_visual)
	match kind:
		"vase":
			MeshLib.cylinder(_visual, 0.16, 0.34, Color(0.85, 0.4, 0.3), Vector3(0, 0.17, 0))
			MeshLib.sphere(_visual, 0.16, Color(0.3, 0.65, 0.3), Vector3(0, 0.42, 0), 0.7)
		"books":
			MeshLib.box(_visual, Vector3(0.3, 0.08, 0.22), Color(0.75, 0.3, 0.3), Vector3(0, 0.04, 0))
			MeshLib.box(_visual, Vector3(0.28, 0.08, 0.2), Color(0.3, 0.45, 0.75), Vector3(0.02, 0.12, 0), 0.3)
			MeshLib.box(_visual, Vector3(0.26, 0.08, 0.2), Color(0.9, 0.75, 0.3), Vector3(-0.02, 0.2, 0), -0.2)
		"lamp":
			MeshLib.cylinder(_visual, 0.05, 0.9, Color(0.4, 0.35, 0.3), Vector3(0, 0.45, 0))
			MeshLib.cone(_visual, 0.22, 0.26, Color(0.95, 0.9, 0.7), Vector3(0, 1.0, 0))
		"cup":
			MeshLib.cylinder(_visual, 0.08, 0.14, Color(0.9, 0.9, 0.95), Vector3(0, 0.07, 0))
		"frame":
			MeshLib.box(_visual, Vector3(0.3, 0.4, 0.04), Color(0.55, 0.4, 0.25), Vector3(0, 0.2, 0))
		"bottle":
			MeshLib.cylinder(_visual, 0.06, 0.3, Color(0.35, 0.6, 0.4), Vector3(0, 0.15, 0))


## Chamado pelo host (lógica) e pelos puppets (evento de rede).
func topple() -> void:
	if knocked:
		return
	knocked = true
	AudioMan.play_sfx("thud", -6.0)
	var tween := create_tween()
	tween.tween_property(_visual, "rotation:z", PI * 0.55, 0.3) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_visual, "position:y", 0.05, 0.3)


func restore() -> void:
	knocked = false
	var tween := create_tween()
	tween.tween_property(_visual, "rotation:z", 0.0, 0.25)
	tween.parallel().tween_property(_visual, "position:y", 0.0, 0.25)
