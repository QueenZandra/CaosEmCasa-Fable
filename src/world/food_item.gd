class_name FoodItem
extends Node3D
## A snack/food bowl item. Pets can eat it (energy boost). Invaders try to
## steal it and run away. Host-authoritative; replicated via events.

var net_id := 0
var kind := "kibble"       # kibble, bone, fish
var taken := false


static func create(p_kind: String, pos: Vector3) -> FoodItem:
	var f := FoodItem.new()
	f.kind = p_kind
	f.position = pos
	return f


func _ready() -> void:
	add_to_group("food")
	add_to_group("interactable")
	match kind:
		"kibble":
			MeshLib.cylinder(self, 0.22, 0.1, Color(0.85, 0.3, 0.35), Vector3(0, 0.05, 0))
			MeshLib.sphere(self, 0.12, Color(0.6, 0.4, 0.2), Vector3(0, 0.14, 0), 0.6)
		"bone":
			MeshLib.capsule(self, 0.05, 0.3, Color(0.95, 0.93, 0.85), Vector3(0, 0.08, 0))
			MeshLib.sphere(self, 0.07, Color(0.95, 0.93, 0.85), Vector3(-0.15, 0.08, 0))
			MeshLib.sphere(self, 0.07, Color(0.95, 0.93, 0.85), Vector3(0.15, 0.08, 0))
		"fish":
			var fish_body := MeshLib.sphere(self, 0.12, Color(0.55, 0.7, 0.85), Vector3(0, 0.08, 0), 0.6)
			fish_body.scale = Vector3(1.6, 0.6, 0.8)
			MeshLib.prism(self, Vector3(0.12, 0.12, 0.04), Color(0.5, 0.65, 0.8), Vector3(-0.2, 0.08, 0))
