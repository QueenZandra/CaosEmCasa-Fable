class_name Pillow
extends Threat
## Almofada rebelde: pula pela sala espalhando penas. Um susto a deixa
## tonta (dá para pegar, A); leve-a de volta ao sofá para capturá-la.

const STATE_CARRIED := 4
const CATCH_WINDOW := 6.0

var color_index := 0
var catchable := false
var _catch_left := 0.0
var _feather_timer := 3.0
var _wander_rng := RandomNumberGenerator.new()

const COLORS := [
	Color(0.9, 0.5, 0.4), Color(0.5, 0.7, 0.45),
	Color(0.55, 0.55, 0.85), Color(0.92, 0.8, 0.4),
]


func configure(index: int, seed_value: int) -> void:
	kind = "pillow"
	color_index = index % COLORS.size()
	speed = 3.0
	fear_threshold = 0.8
	_wander_rng.seed = seed_value


func build_visual() -> void:
	var col: Color = COLORS[color_index]
	var cushion := MeshLib.box(visual, Vector3(0.55, 0.2, 0.55), col, Vector3(0, 0.18, 0))
	cushion.rotation.y = 0.4
	MeshLib.sphere(visual, 0.05, Color(0.15, 0.12, 0.1), Vector3(-0.12, 0.28, 0.2))
	MeshLib.sphere(visual, 0.05, Color(0.15, 0.12, 0.1), Vector3(0.12, 0.28, 0.2))


func _physics_process(delta: float) -> void:
	if not puppet and state == STATE_CARRIED:
		anim_state = STATE_CARRIED
		return
	if not puppet:
		if catchable:
			_catch_left -= delta
			if _catch_left <= 0.0:
				_set_catchable(false)
				fear = 0.0
				state = STATE_APPROACH
		if state == STATE_APPROACH and waypoints.is_empty():
			_pick_wander_target()
		if state == STATE_APPROACH and not catchable:
			_feather_timer -= delta
			if _feather_timer <= 0.0:
				_feather_timer = _wander_rng.randf_range(4.0, 7.0)
				if level != null:
					level.call("pillow_feathers", global_position)
	super._physics_process(delta)


func _pick_wander_target() -> void:
	# Perambula pela sala de estar.
	waypoints = [Vector3(
		_wander_rng.randf_range(-11.0, -1.5), 0.0,
		_wander_rng.randf_range(-7.5, 1.5)
	)]


func enter_act() -> void:
	# Almofadas não têm ACT: continuam vagando.
	state = STATE_APPROACH


func receive_scare(power: float, source: Node) -> void:
	if puppet or state == STATE_CARRIED or catchable:
		return
	fear += power
	_flash()
	if fear >= fear_threshold:
		stun_left = CATCH_WINDOW
		state = STATE_STUNNED
		_set_catchable(true)
		_catch_left = CATCH_WINDOW
		AudioMan.play_sfx("pop", -4.0)
		if level != null:
			level.call("threat_scared_off", self, source)


func _set_catchable(value: bool) -> void:
	catchable = value
	if value:
		add_to_group("carryable")
		add_to_group("interactable")
	else:
		remove_from_group("carryable")
		remove_from_group("interactable")


func picked_up() -> void:
	state = STATE_CARRIED
	_set_catchable(false)
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0


func dropped(near_sofa: bool) -> void:
	if near_sofa:
		if level != null:
			level.call("pillow_captured", self)
		return
	# Caiu longe do sofá: fica tonta um tempo e volta a fugir.
	collision_layer = 1
	collision_mask = 1
	state = STATE_STUNNED
	stun_left = CATCH_WINDOW * 0.6
	_set_catchable(true)
	_catch_left = CATCH_WINDOW * 0.6
	fear = 0.0


func animate(_delta: float) -> void:
	if anim_state == STATE_CARRIED:
		visual.rotation.z = sin(_t * 4.0) * 0.1
		return
	if anim_state == STATE_STUNNED:
		visual.rotation.z = sin(_t * 20.0) * 0.25
		return
	# Pulinhos
	visual.position.y = absf(sin(_t * 7.0)) * 0.22
	visual.rotation.y = sin(_t * 3.5) * 0.4
