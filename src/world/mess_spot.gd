class_name MessSpot
extends Node3D
## A cleanable mess (broken vase, feathers, dirt...). Pets clean it by
## holding the interact button next to it. Host simulates progress and
## replicates via events; puppets show progress from the network.

const CLEAN_SECONDS := 1.6

var net_id := 0
var kind := "generic"
var cleaned := false
var progress := 0.0

var _bits: Node3D
var _ring: MeshInstance3D


static func create(p_kind: String, pos: Vector3) -> MessSpot:
	var m := MessSpot.new()
	m.kind = p_kind
	m.position = pos
	return m


func _ready() -> void:
	add_to_group("mess")
	add_to_group("interactable")
	_bits = Node3D.new()
	add_child(_bits)
	var palette := {
		"generic": [Color(0.5, 0.42, 0.35), Color(0.42, 0.35, 0.3)],
		"feathers": [Color(0.95, 0.95, 0.9), Color(0.85, 0.85, 0.95)],
		"shards": [Color(0.85, 0.4, 0.3), Color(0.7, 0.32, 0.25)],
		"dirt": [Color(0.4, 0.3, 0.2), Color(0.3, 0.22, 0.15)],
		"food": [Color(0.8, 0.6, 0.3), Color(0.7, 0.45, 0.2)],
	}
	var colors: Array = palette.get(kind, palette["generic"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(position) & 0x7FFFFFFF
	for i in 6:
		var ang := rng.randf() * TAU
		var dist := rng.randf() * 0.45
		var piece := MeshLib.box(
			_bits,
			Vector3(0.12, 0.03, 0.1) * rng.randf_range(0.7, 1.4),
			colors[i % colors.size()],
			Vector3(cos(ang) * dist, 0.02, sin(ang) * dist),
			rng.randf() * TAU
		)
		piece.rotation.z = rng.randf_range(-0.15, 0.15)
	_ring = MeshLib.ground_disc(self, 0.55, Color(1.0, 1.0, 1.0, 0.12), Vector3.ZERO)


func clean_tick(delta: float) -> void:
	if cleaned:
		return
	set_progress(progress + delta / CLEAN_SECONDS)


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	_bits.scale = Vector3.ONE * maxf(0.05, 1.0 - progress)
	_ring.material_override = MeshLib.material(Color(0.4, 1.0, 0.5, 0.1 + progress * 0.35))
	if progress >= 1.0 and not cleaned:
		cleaned = true
		AudioMan.play_sfx("ding")
		if get_parent() != null and get_parent().has_method("mess_cleaned"):
			get_parent().call("mess_cleaned", self)
