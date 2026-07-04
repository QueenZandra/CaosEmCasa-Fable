class_name Pet
extends CharacterBody3D
## Playable pet. On the host it simulates movement, interactions and
## abilities from InputPoller frames (local devices or remote peers).
## On clients it is a "puppet": it only interpolates to networked state.

const GRAVITY := 22.0
const TURN_SPEED := 12.0
const INTERACT_RANGE := 1.7
const CARRY_HEIGHT := 1.05
const DASH_TIME := 0.22
const DASH_COOLDOWN := 2.0
const CUTE_TIME := 2.4

var pet_id := "sirius"
var def := {}
var slot := 0
var puppet := false
var level: Node = null       # LevelBase (duck-typed para evitar ciclos)

var body: PetBody
var carrying: Node3D = null

# net (puppet)
var net_pos := Vector3.ZERO
var net_roty := 0.0
var net_pose := 0

# estado (host)
var _frame := InputPoller.empty_frame()
var _prev_frame := InputPoller.empty_frame()
var _ability_cd := 0.0
var _dash_cd := 0.0
var _dash_left := 0.0
var _boost_left := 0.0
var _ferocious_left := 0.0
var _hidden := false
var _busy_left := 0.0        # tempo preso numa pose (latir, fofura, comer)
var _busy_pose := ""
var _cleaning: Node3D = null
var _knock_cd := 0.0


func setup(p_pet_id: String, p_slot: int, p_puppet: bool, p_level: Node) -> void:
	pet_id = p_pet_id
	slot = p_slot
	puppet = p_puppet
	level = p_level
	def = PetDefs.get_def(pet_id)
	name = "Pet_" + pet_id

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38 * float(def.get("scale", 1.0))
	capsule.height = 1.0
	shape.shape = capsule
	shape.position.y = 0.5
	add_child(shape)
	if puppet:
		# Réplicas só interpolam o estado da rede; não colidem localmente.
		collision_layer = 0
		collision_mask = 0

	body = PetBody.new()
	body.build(def)
	add_child(body)
	add_to_group("pets")


func apply_input(frame: Dictionary) -> void:
	_prev_frame = _frame
	_frame = frame


func is_hidden_from_threats() -> bool:
	return _hidden


func is_ferocious() -> bool:
	return _ferocious_left > 0.0


func scare_power_against(threat_kind: String) -> float:
	var power := float(def.get("scare_power", 1.0))
	if _ferocious_left > 0.0:
		power *= 2.0
		if threat_kind == "invader":
			power *= 2.5
	return power


func _physics_process(delta: float) -> void:
	if puppet:
		_puppet_update(delta)
		body.animate(delta)
		return
	_host_update(delta)
	body.animate(delta)


# ---------------------------------------------------------------- host sim

func _host_update(delta: float) -> void:
	_ability_cd = maxf(0.0, _ability_cd - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	_boost_left = maxf(0.0, _boost_left - delta)
	_knock_cd = maxf(0.0, _knock_cd - delta)
	if _ferocious_left > 0.0:
		_ferocious_left -= delta
		if _ferocious_left <= 0.0:
			body.set_pose("idle")
	if _busy_left > 0.0:
		_busy_left -= delta
		if _busy_left <= 0.0:
			_busy_pose = ""

	var mv: Vector2 = _frame.get("mv", Vector2.ZERO)
	var just := InputPoller.just_pressed_mask(_frame, _prev_frame)
	var busy := _busy_left > 0.0

	# --- limpeza (segurar interact perto de bagunça) ---
	if _cleaning != null:
		var still_valid := is_instance_valid(_cleaning) and not _cleaning.get("cleaned")
		var still_holding := InputPoller.pressed(_frame, InputPoller.BTN_INTERACT)
		var still_close := still_valid and global_position.distance_to(_cleaning.global_position) < INTERACT_RANGE + 0.3
		if still_valid and still_holding and still_close and mv.length() < 0.3:
			_cleaning.call("clean_tick", delta)
			body.set_pose("rub")
			velocity.x = 0.0
			velocity.z = 0.0
			_apply_gravity_and_move(delta)
			return
		_cleaning = null

	# --- botões ---
	if not busy:
		if just & InputPoller.BTN_INTERACT:
			_do_interact()
		if just & InputPoller.BTN_ABILITY:
			_do_ability()
		if just & InputPoller.BTN_DASH and _dash_cd <= 0.0:
			_dash_cd = DASH_COOLDOWN
			_dash_left = DASH_TIME
			AudioMan.play_sfx("sweep", -8.0)

	# --- movimento ---
	var speed := float(def.get("speed", 5.0))
	if _boost_left > 0.0:
		speed *= 1.35
	if _ferocious_left > 0.0:
		speed *= 1.2
	if _hidden:
		speed *= 0.35
	if _dash_left > 0.0:
		speed *= 2.2
	if busy:
		mv = Vector2.ZERO

	var dir := Vector3(mv.x, 0.0, mv.y)
	var target_v := dir * speed
	velocity.x = lerpf(velocity.x, target_v.x, 14.0 * delta)
	velocity.z = lerpf(velocity.z, target_v.z, 14.0 * delta)
	if dir.length() > 0.1:
		var target_rot := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, TURN_SPEED * delta)

	_apply_gravity_and_move(delta)

	# --- pose ---
	if busy:
		body.set_pose(_busy_pose)
	elif _hidden:
		body.set_pose("hide")
	elif _ferocious_left > 0.0:
		body.set_pose("ferocious")
	elif Vector2(velocity.x, velocity.z).length() > 0.6:
		body.set_pose("walk")
	else:
		body.set_pose("idle")
	body.move_ratio = Vector2(velocity.x, velocity.z).length() / maxf(speed, 0.01)

	# --- estabanados derrubam coisas correndo ---
	if def.get("clumsy", false) and _knock_cd <= 0.0:
		var fast := Vector2(velocity.x, velocity.z).length() > speed * 0.75
		if fast and level != null:
			var knocked: bool = level.call("knock_near", global_position, 0.95, pet_id)
			if knocked:
				_knock_cd = 1.2

	# --- item carregado segue o pet ---
	if carrying != null and is_instance_valid(carrying):
		carrying.global_position = global_position + Vector3(0, CARRY_HEIGHT * float(def.get("scale", 1.0)), 0)
	elif carrying != null:
		carrying = null


func _apply_gravity_and_move(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.5)
	move_and_slide()


func _do_interact() -> void:
	if _hidden:
		_unhide(true)
		return
	if carrying != null and is_instance_valid(carrying):
		level.call("pet_drop", self)
		return
	# Procura o interagível mais próximo (bagunça, comida, brinquedo, almofada).
	var target: Node3D = level.call("nearest_interactable", global_position, INTERACT_RANGE)
	if target == null:
		return
	if target.is_in_group("mess"):
		_cleaning = target
		AudioMan.play_sfx("sweep", -6.0)
	elif target.is_in_group("food"):
		_eat(target)
	elif target.is_in_group("carryable"):
		level.call("pet_pickup", self, target)


func _eat(food: Node3D) -> void:
	var lover: bool = def.get("food_lover", false)
	_boost_left = 5.0 if lover else 2.5
	_set_busy("eat", 0.8)
	AudioMan.play_sfx("pop")
	level.call("food_eaten", self, food)


func _do_ability() -> void:
	if level != null and bool(level.get("is_final_level")):
		_do_cute()
		return
	if _ability_cd > 0.0:
		return
	level.call("ability_used", self)
	match String(def.get("ability", "bark")):
		"bark":
			_ability_cd = float(def.get("ability_cooldown", 4.0))
			_set_busy("bark", 0.7)
			AudioMan.play_sfx("bark")
			level.call("scare_at", global_position, 6.5, scare_power_against(""), self)
			# Estabanado: o latido derruba coisas por perto.
			level.call("knock_near", global_position, 2.6, pet_id)
			level.call("spawn_ring_fx", global_position, 6.5, Color(1.0, 0.85, 0.3, 0.5))
		"ferocious":
			_ability_cd = float(def.get("ability_cooldown", 9.0))
			_ferocious_left = 6.0
			AudioMan.play_sfx("angry", -4.0)
			level.call("spawn_ring_fx", global_position, 2.0, Color(1.0, 0.3, 0.2, 0.5))
		"stealth":
			if _hidden:
				_unhide(true)
			else:
				_hidden = true
				AudioMan.play_sfx("pop", -10.0)
		"pounce":
			_ability_cd = float(def.get("ability_cooldown", 2.5))
			_dash_left = DASH_TIME * 1.4
			_set_busy("pounce", 0.3)
			AudioMan.play_sfx("meow", -4.0)
			var ahead := global_position + basis.z * 1.3
			level.call("scare_at", ahead, 1.8, scare_power_against("invader"), self)
			level.call("spawn_ring_fx", ahead, 1.8, Color(0.7, 0.4, 1.0, 0.5))


func _unhide(ambush: bool) -> void:
	_hidden = false
	if ambush:
		# Emboscada: susto forte em quem estava perto do esconderijo.
		level.call("scare_at", global_position, 3.2, 3.0, self)
		level.call("spawn_ring_fx", global_position, 3.2, Color(0.5, 0.9, 1.0, 0.5))
		AudioMan.play_sfx("meow")


func _do_cute() -> void:
	if _ability_cd > 0.0:
		return
	_ability_cd = 3.5
	var cute_pose := {
		"good_boy": "sit_wag",
		"belly_up": "belly_up",
		"play_ball": "play",
		"leg_rub": "rub",
	}.get(String(def.get("cute", "good_boy")), "sit_wag")
	_set_busy(cute_pose, CUTE_TIME)
	AudioMan.play_sfx("cute")
	level.call("cute_performed", self)


func _set_busy(p_pose: String, duration: float) -> void:
	_busy_pose = p_pose
	_busy_left = duration
	body.set_pose(p_pose)


# ------------------------------------------------------------- puppet mode

func _puppet_update(delta: float) -> void:
	global_position = global_position.lerp(net_pos, minf(1.0, 14.0 * delta))
	rotation.y = lerp_angle(rotation.y, net_roty, 14.0 * delta)
	body.set_pose(PetBody.pose_name(net_pose))
	body.move_ratio = 1.0 if body.pose == "walk" else 0.0


func snapshot() -> Array:
	return [
		snappedf(global_position.x, 0.01), snappedf(global_position.y, 0.01),
		snappedf(global_position.z, 0.01), snappedf(rotation.y, 0.01),
		PetBody.pose_index(body.pose),
	]


func apply_snapshot(s: Array) -> void:
	net_pos = Vector3(s[0], s[1], s[2])
	net_roty = s[3]
	net_pose = int(s[4])
