class_name GateAnimal
extends Threat
## Cachorro ou gato de rua que fica provocando no portão. Enquanto
## provoca, os pets ficam doidos e coisas caem dentro de casa.

const PROVOKE_INTERVAL := 5.0

var variant := "gate_dog"    # gate_dog | gate_cat
var _provoke_timer := 2.0
var _from_left := true


func configure(p_variant: String, from_left: bool, house: House) -> void:
	variant = p_variant
	kind = variant
	_from_left = from_left
	speed = 3.0 if variant == "gate_dog" else 3.6
	fear_threshold = 2.0 if variant == "gate_dog" else 1.2
	var start: Vector3 = house.points["street_left"] if from_left else house.points["street_right"]
	position = start  # ainda fora da árvore: usar position local
	var rng := RandomNumberGenerator.new()
	rng.seed = int(start.x * 100) + Time.get_ticks_msec() % 1000
	var spot_x := rng.randf_range(-4.0, 4.0)
	waypoints = [Vector3(spot_x, 0, 10.9)]


func build_visual() -> void:
	var is_dog := variant == "gate_dog"
	var col := Color(0.55, 0.42, 0.3) if is_dog else Color(0.75, 0.75, 0.78)
	var animal_body := MeshLib.sphere(visual, 0.26, col, Vector3(0, 0.32, 0), 0.8)
	animal_body.scale = Vector3(1.0, 1.0, 1.4)
	MeshLib.sphere(visual, 0.18, col, Vector3(0, 0.5, 0.32))
	if is_dog:
		MeshLib.box(visual, Vector3(0.12, 0.1, 0.14), col.lightened(0.2), Vector3(0, 0.44, 0.48))
		MeshLib.cone(visual, 0.07, 0.14, col.darkened(0.1), Vector3(-0.1, 0.66, 0.3))
		MeshLib.cone(visual, 0.07, 0.14, col.darkened(0.1), Vector3(0.1, 0.66, 0.3))
	else:
		MeshLib.cone(visual, 0.06, 0.12, col, Vector3(-0.09, 0.64, 0.3))
		MeshLib.cone(visual, 0.06, 0.12, col, Vector3(0.09, 0.64, 0.3))
	for i in 4:
		var lx := -0.12 if i % 2 == 0 else 0.12
		var lz := 0.15 if i < 2 else -0.15
		MeshLib.cylinder(visual, 0.04, 0.24, col.darkened(0.2), Vector3(lx, 0.12, lz))
	MeshLib.cylinder(visual, 0.03, 0.3, col, Vector3(0, 0.45, -0.4)).rotation.x = 0.9


func enter_act() -> void:
	state = STATE_ACT
	_provoke_timer = PROVOKE_INTERVAL * 0.5


func act_tick(delta: float) -> void:
	_provoke_timer -= delta
	if _provoke_timer <= 0.0:
		_provoke_timer = PROVOKE_INTERVAL
		AudioMan.play_sfx("bark" if variant == "gate_dog" else "meow", -6.0)
		if level != null:
			level.call("gate_provocation", self)


func on_scared_off(_source: Node) -> void:
	AudioMan.play_sfx("pop")


func flee_waypoints() -> Array[Vector3]:
	var exit_x := -13.0 if _from_left else 13.0
	return [Vector3(exit_x, 0, 11.5)]


func animate(_delta: float) -> void:
	super.animate(_delta)
	if anim_state == STATE_ACT:
		visual.position.y = absf(sin(_t * 10.0)) * 0.15
