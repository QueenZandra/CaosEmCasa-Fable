class_name Threat
extends CharacterBody3D
## Base class for every threat. Simple FSM:
##   APPROACH (follow waypoints) -> ACT (do mischief) -> FLEE (leave)
## Getting scared enough (fear >= threshold) forces FLEE; smaller scares
## stun briefly. Host simulates; puppets interpolate networked state.

const STATE_APPROACH := 0
const STATE_ACT := 1
const STATE_FLEE := 2
const STATE_STUNNED := 3

const GRAVITY := 22.0

var kind := "rat"
var net_id := 0
var puppet := false
var level: Node = null

var fear := 0.0
var fear_threshold := 1.0
var speed := 2.5
var flying := false
var state := STATE_APPROACH
var waypoints: Array[Vector3] = []
var stun_left := 0.0
var anim_state := STATE_APPROACH

var visual: Node3D
var _t := 0.0

# net (puppet)
var net_pos := Vector3.ZERO
var net_roty := 0.0


func setup(p_level: Node, p_puppet: bool) -> void:
	level = p_level
	puppet = p_puppet
	add_to_group("threats")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 0.8
	shape.shape = capsule
	shape.position.y = 0.4
	add_child(shape)
	if puppet:
		# Puppets não colidem com nada; só seguem a rede.
		collision_layer = 0
		collision_mask = 0
	visual = Node3D.new()
	add_child(visual)
	build_visual()


## --------- pontos de extensão (subclasses) ---------

func build_visual() -> void:
	MeshLib.sphere(visual, 0.25, Color.GRAY, Vector3(0, 0.25, 0))


func enter_act() -> void:
	state = STATE_ACT


func act_tick(_delta: float) -> void:
	pass


func on_scared_off(_source: Node) -> void:
	pass


func flee_waypoints() -> Array[Vector3]:
	return []


## --------- API chamada pelo level/pets (host) ---------

func receive_scare(power: float, source: Node) -> void:
	if puppet or state == STATE_FLEE:
		return
	fear += power
	if visual != null:
		_flash()
	if fear >= fear_threshold:
		on_scared_off(source)
		start_flee()
		if level != null:
			level.call("threat_scared_off", self, source)
	else:
		stun_left = maxf(stun_left, 0.9)
		if state != STATE_ACT:
			state = STATE_STUNNED


func start_flee() -> void:
	state = STATE_FLEE
	waypoints = flee_waypoints()
	speed *= 1.5


## --------- simulação ---------

func _physics_process(delta: float) -> void:
	_t += delta
	if puppet:
		global_position = global_position.lerp(net_pos, minf(1.0, 12.0 * delta))
		rotation.y = lerp_angle(rotation.y, net_roty, 12.0 * delta)
		animate(delta)
		return
	match state:
		STATE_STUNNED:
			stun_left -= delta
			velocity.x = 0.0
			velocity.z = 0.0
			if stun_left <= 0.0:
				state = STATE_APPROACH
		STATE_APPROACH:
			if _follow_waypoints(delta):
				enter_act()
		STATE_ACT:
			act_tick(delta)
		STATE_FLEE:
			if _follow_waypoints(delta):
				if level != null:
					level.call("threat_gone", self)
				return
	if not flying:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
	anim_state = state
	animate(delta)


## Retorna true quando o caminho terminou.
func _follow_waypoints(delta: float) -> bool:
	if waypoints.is_empty():
		return true
	var target := waypoints[0]
	var flat := Vector3(target.x, global_position.y, target.z)
	if flying:
		flat = target
	if global_position.distance_to(flat) < 0.35:
		waypoints.pop_front()
		return waypoints.is_empty()
	var dir := (flat - global_position).normalized()
	if flying:
		global_position += dir * speed * delta
		velocity = Vector3.ZERO
	else:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10.0 * delta)
	return false


## Balanço básico; subclasses podem sobrescrever.
func animate(_delta: float) -> void:
	if visual == null:
		return
	match anim_state:
		STATE_APPROACH, STATE_FLEE:
			visual.position.y = absf(sin(_t * 9.0)) * 0.08
		STATE_ACT:
			visual.rotation.z = sin(_t * 6.0) * 0.08
		STATE_STUNNED:
			visual.rotation.z = sin(_t * 30.0) * 0.15


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE * 1.25, 0.06)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.12)


## --------- rede ---------

func snapshot() -> Array:
	return [
		snappedf(global_position.x, 0.01), snappedf(global_position.y, 0.01),
		snappedf(global_position.z, 0.01), snappedf(rotation.y, 0.01),
		anim_state,
	]


func apply_snapshot(s: Array) -> void:
	net_pos = Vector3(s[0], s[1], s[2])
	net_roty = s[3]
	anim_state = int(s[4])
