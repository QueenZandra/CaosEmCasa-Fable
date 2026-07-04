class_name Carryable
extends Node3D
## Small item pets can pick up and carry (toys, tutorial items).

var net_id := 0
var kind := "ball"
var carried_by: Node3D = null


static func create(p_kind: String, pos: Vector3) -> Carryable:
	var c := Carryable.new()
	c.kind = p_kind
	c.position = pos
	return c


func _ready() -> void:
	add_to_group("carryable")
	add_to_group("interactable")
	match kind:
		"ball":
			MeshLib.sphere(self, 0.14, Color(0.9, 0.25, 0.3), Vector3(0, 0.14, 0))
			MeshLib.box(self, Vector3(0.3, 0.03, 0.06), Color(0.95, 0.9, 0.85), Vector3(0, 0.14, 0))
		"toy_bone":
			MeshLib.capsule(self, 0.06, 0.34, Color(0.7, 0.85, 0.9), Vector3(0, 0.09, 0))
			MeshLib.sphere(self, 0.08, Color(0.7, 0.85, 0.9), Vector3(-0.17, 0.09, 0))
			MeshLib.sphere(self, 0.08, Color(0.7, 0.85, 0.9), Vector3(0.17, 0.09, 0))
		"mouse_toy":
			var toy_body := MeshLib.sphere(self, 0.1, Color(0.6, 0.6, 0.65), Vector3(0, 0.08, 0), 0.7)
			toy_body.scale = Vector3(1.4, 0.8, 1.0)
			MeshLib.cone(self, 0.03, 0.2, Color(0.85, 0.5, 0.55), Vector3(-0.16, 0.08, 0))
