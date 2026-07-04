class_name LevelBase
extends Node3D
## Base of every phase: builds the world, spawns pets, routes input
## (local devices + remote peers), simulates on the host and replicates
## to clients via events (reliable) + snapshots (20 Hz, unreliable).

signal finished(result: Dictionary)

const SNAPSHOT_EVERY := 3      # a cada N physics frames (60/3 = 20 Hz)
const INPUT_EVERY := 2         # cliente envia input a 30 Hz
const HUD_EVERY := 12          # estado de HUD a 5 Hz

var level_number := 1
var is_final_level := false
var is_host := true
var online := false

var house: House
var hud: Node = null           # HUD (CanvasLayer), setado pelo Main

var pets := {}                 # slot -> Pet
var threats := {}              # net_id -> Threat
var mess_spots := {}           # net_id -> MessSpot
var carryables := {}           # net_id -> Carryable
var food_items := {}           # index -> FoodItem

var time_left := 0.0
var time_elapsed := 0.0
var score := 0
var mess_made := 0
var running := false
var ended := false

var _next_id := 1
var _frame_count := 0
var _remote_frames := {}       # peer_id -> input frame
var _countdown := 3.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	is_host = Net.is_host()
	online = Net.is_online() and GameState.online
	_rng.seed = 1000 + level_number
	_build_environment()
	house = House.new()
	add_child(house)
	_spawn_pets()
	if online:
		Net.msg_received.connect(_on_net_msg)
	setup_level()
	_update_hud(true)
	AudioMan.play_sfx("ding")


func _exit_tree() -> void:
	if online and Net.msg_received.is_connected(_on_net_msg):
		Net.msg_received.disconnect(_on_net_msg)


## ------------------------------------------------ pontos de extensão

func setup_level() -> void:
	pass


func tick_level(_delta: float) -> void:
	pass


func objective_text() -> String:
	return Strings.LEVEL_GOALS.get(level_number, "")


func compute_stars(won: bool) -> int:
	return 2 if won else 0


func extra_hud() -> Dictionary:
	return {}


## Clientes: estado extra vindo do host (progresso de ninhos, raiva...).
func on_remote_hud(_state: Dictionary) -> void:
	pass


## Eventos de jogo sem estado (cutscenes, gatilhos): rodam em todo mundo.
func on_generic_event(_kind: String) -> void:
	pass


## Banner replicado: aparece no host e nos clientes.
func banner(text: String, seconds := 1.5) -> void:
	if hud != null:
		hud.call("show_banner", text, seconds)
	if online and is_host:
		Net.broadcast({"e": "ban", "t": text, "d": seconds})


func send_generic(kind: String) -> void:
	on_generic_event(kind)
	if online and is_host:
		Net.broadcast({"e": "gen", "k": kind})


## Hooks chamados pelas ameaças (defaults inofensivos).
func mail_delivered(_threat: Node) -> void: pass
func nest_tick(_tree: int, _amount: float, _bird: Node) -> void: pass
func gate_provocation(_threat: Node) -> void: pass
func pillow_feathers(pos: Vector3) -> void: add_mess("feathers", pos)
func pillow_captured(_pillow: Node) -> void: pass
func threat_scared_off(_threat: Node, _source: Node) -> void: score += 50
func ability_used(_pet: Node) -> void: pass
func cute_performed(_pet: Node) -> void: pass


func invader_grab_food(_invader: Node, food_index: int) -> bool:
	if food_items.has(food_index):
		_remove_food(food_index)
		return true
	return false


func invader_dropped_food(_invader: Node, food_index: int, pos: Vector3) -> void:
	_spawn_food("kibble", Vector3(pos.x, 0, pos.z), food_index)


func threat_gone(threat: Threat) -> void:
	if threat is Invader and (threat as Invader).reached_exit_with_food():
		food_stolen(threat)
	_despawn_threat(threat.net_id)


func food_stolen(_threat: Node) -> void:
	pass


func food_eaten(pet: Pet, food: Node3D) -> void:
	for idx in food_items:
		if food_items[idx] == food:
			_remove_food(idx)
			var lover: bool = pet.def.get("food_lover", false)
			score += 10 if lover else 5
			return


## ------------------------------------------------ construção

func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 28, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.75, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.8, 0.9)
	env.ambient_light_energy = 0.8
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 19.0, 15.5)
	cam.fov = 55.0
	add_child(cam)
	cam.look_at(Vector3(0, 0, 0.8), Vector3.UP)
	cam.current = true


func _spawn_pets() -> void:
	var spawns: Array = house.points.get("pet_spawns", [Vector3.ZERO]) if house != null else [Vector3.ZERO]
	# house ainda não está em _ready quando chamado? garantimos ordem no _ready.
	for p in GameState.players:
		var pet := Pet.new()
		var is_puppet: bool = online and not is_host
		pet.setup(p.pet, p.slot, is_puppet, self)
		add_child(pet)
		pet.global_position = spawns[p.slot % spawns.size()]
		pets[p.slot] = pet


## ------------------------------------------------ loop principal

func _physics_process(delta: float) -> void:
	if ended:
		return
	_frame_count += 1
	if _countdown > 0.0:
		var before := int(ceil(_countdown))
		_countdown -= delta
		if _countdown <= 0.0:
			running = true
			if hud != null:
				hud.call("show_banner", Strings.GO, 0.8)
		elif int(ceil(_countdown)) != before and hud != null:
			hud.call("show_banner", str(int(ceil(_countdown))), 0.9)
		return

	_route_input()

	if is_host:
		time_elapsed += delta
		if time_left > 0.0:
			time_left = maxf(0.0, time_left - delta)
		tick_level(delta)
		if online:
			if _frame_count % SNAPSHOT_EVERY == 0:
				_send_snapshot()
			if _frame_count % HUD_EVERY == 0:
				_send_hud_state()
	# Clientes recebem o estado autoritativo pelo evento "hud" (5 Hz);
	# atualizar localmente aqui faria o timer piscar com valores velhos.
	if _frame_count % 6 == 0 and (is_host or not online):
		_update_hud(false)


func _route_input() -> void:
	if is_host:
		for p in GameState.players:
			var pet: Pet = pets.get(p.slot)
			if pet == null:
				continue
			var frame: Dictionary
			if not online or p.peer == Net.my_id:
				frame = InputPoller.sample(p.device)
			else:
				frame = _remote_frames.get(p.peer, InputPoller.empty_frame())
			pet.apply_input(frame)
	else:
		# Cliente: envia o input dos jogadores locais ao host.
		if _frame_count % INPUT_EVERY == 0:
			for p in GameState.local_players():
				var frame := InputPoller.sample(p.device)
				Net.send_msg(1, {"i": frame}, true)


## ------------------------------------------------ interações dos pets

func nearest_interactable(pos: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for node in get_tree().get_nodes_in_group("interactable"):
		var n3 := node as Node3D
		if n3 == null or not is_instance_valid(n3):
			continue
		if n3 is MessSpot and (n3 as MessSpot).cleaned:
			continue
		if n3 is Carryable and (n3 as Carryable).carried_by != null:
			continue
		var d := Vector2(pos.x - n3.global_position.x, pos.z - n3.global_position.z).length()
		if d < best_d:
			best_d = d
			best = n3
	return best


func pet_pickup(pet: Pet, target: Node3D) -> void:
	if target is Pillow:
		(target as Pillow).picked_up()
		pet.carrying = target
	elif target is Carryable:
		(target as Carryable).carried_by = pet
		pet.carrying = target
	AudioMan.play_sfx("pop", -8.0)


func pet_drop(pet: Pet) -> void:
	var item := pet.carrying
	pet.carrying = null
	if item == null or not is_instance_valid(item):
		return
	var drop_pos := pet.global_position + pet.basis.z * 0.7
	drop_pos.y = 0.0
	if item is Pillow:
		var near_sofa := Vector2(
			drop_pos.x - house.sofa_pos.x, drop_pos.z - house.sofa_pos.z
		).length() < 2.3
		item.global_position = drop_pos
		(item as Pillow).dropped(near_sofa)
	elif item is Carryable:
		(item as Carryable).carried_by = null
		item.global_position = drop_pos
		item_dropped(item, drop_pos)


func item_dropped(_item: Node3D, _pos: Vector3) -> void:
	pass


## ------------------------------------------------ susto / bagunça / comida

func scare_at(pos: Vector3, radius: float, power: float, source: Node) -> void:
	if not is_host:
		return
	for node in get_tree().get_nodes_in_group("threats"):
		var threat := node as Threat
		if threat == null or not is_instance_valid(threat):
			continue
		var d := Vector2(pos.x - threat.global_position.x, pos.z - threat.global_position.z).length()
		if d <= radius:
			threat.receive_scare(power, source)


## Derruba o primeiro objeto em pé no raio. Retorna true se derrubou.
func knock_near(pos: Vector3, radius: float, _who: String) -> bool:
	if not is_host:
		return false
	for k in house.knockables:
		if k.knocked:
			continue
		var d := Vector2(pos.x - k.global_position.x, pos.z - k.global_position.z).length()
		if d <= radius:
			knock_object(k.net_id)
			return true
	return false


func knock_object(knockable_id: int) -> void:
	if knockable_id < 0 or knockable_id >= house.knockables.size():
		return
	var k := house.knockables[knockable_id]
	if k.knocked:
		return
	k.topple()
	var mess_kind := "shards" if k.kind in ["vase", "cup", "bottle"] else "generic"
	add_mess(mess_kind, k.global_position)
	if online and is_host:
		Net.broadcast({"e": "knock", "id": knockable_id})


func knock_random_object() -> void:
	var standing: Array[int] = []
	for k in house.knockables:
		if not k.knocked:
			standing.append(k.net_id)
	if standing.is_empty():
		return
	knock_object(standing[_rng.randi() % standing.size()])


func add_mess(kind: String, pos: Vector3) -> MessSpot:
	var id := _next_id
	_next_id += 1
	var spot := MessSpot.create(kind, Vector3(pos.x, 0, pos.z))
	spot.net_id = id
	add_child(spot)
	mess_spots[id] = spot
	mess_made += 1
	if online and is_host:
		Net.broadcast({"e": "mess+", "id": id, "k": kind, "p": [pos.x, pos.z]})
	return spot


func mess_cleaned(spot: MessSpot) -> void:
	if not is_host:
		return
	mess_spots.erase(spot.net_id)
	score += 25
	if online:
		Net.broadcast({"e": "mess-", "id": spot.net_id})
	spot.queue_free()


func mess_count() -> int:
	var count := 0
	for id in mess_spots:
		var spot: MessSpot = mess_spots[id]
		if is_instance_valid(spot) and not spot.cleaned:
			count += 1
	return count


func _spawn_food(kind: String, pos: Vector3, index := -1) -> void:
	var idx := index
	if idx < 0:
		idx = _next_id
		_next_id += 1
	var food := FoodItem.create(kind, pos)
	food.net_id = idx
	add_child(food)
	food_items[idx] = food
	if online and is_host:
		Net.broadcast({"e": "food+", "id": idx, "k": kind, "p": [pos.x, pos.y, pos.z]})


func _remove_food(index: int) -> void:
	if not food_items.has(index):
		return
	var food: FoodItem = food_items[index]
	food_items.erase(index)
	if is_instance_valid(food):
		food.queue_free()
	if online and is_host:
		Net.broadcast({"e": "food-", "id": index})


func spawn_carryable(kind: String, pos: Vector3) -> Carryable:
	var id := _next_id
	_next_id += 1
	var c := Carryable.create(kind, pos)
	c.net_id = id
	add_child(c)
	carryables[id] = c
	if online and is_host:
		Net.broadcast({"e": "carry+", "id": id, "k": kind, "p": [pos.x, pos.z]})
	return c


func remove_carryable(item: Carryable) -> void:
	carryables.erase(item.net_id)
	if online and is_host:
		Net.broadcast({"e": "carry-", "id": item.net_id})
	item.queue_free()


## ------------------------------------------------ ameaças (host)

func spawn_threat(threat: Threat) -> void:
	var id := _next_id
	_next_id += 1
	threat.net_id = id
	threat.setup(self, false)
	add_child(threat)
	threats[id] = threat
	if online and is_host:
		Net.broadcast({
			"e": "threat+", "id": id, "cls": _threat_class(threat),
			"var": threat.get("variant") if threat.get("variant") != null else "",
			"tree": threat.get("tree_index") if threat is Bird else 0,
			"ci": threat.get("color_index") if threat is Pillow else 0,
			"p": [threat.global_position.x, threat.global_position.y, threat.global_position.z],
		})


func _despawn_threat(id: int) -> void:
	if not threats.has(id):
		return
	var threat: Threat = threats[id]
	threats.erase(id)
	if is_instance_valid(threat):
		threat.queue_free()
	if online and is_host:
		Net.broadcast({"e": "threat-", "id": id})


func _threat_class(threat: Threat) -> String:
	if threat is Mailman:
		return "mailman"
	if threat is Pillow:
		return "pillow"
	if threat is Bird:
		return "bird"
	if threat is GateAnimal:
		return "gate"
	if threat is Invader:
		return "invader"
	return "threat"


func alive_threats() -> int:
	return threats.size()


## ------------------------------------------------ efeitos

func spawn_ring_fx(pos: Vector3, radius: float, color: Color) -> void:
	_ring_fx_local(pos, radius, color)
	if online and is_host:
		Net.broadcast({
			"e": "fx", "p": [pos.x, pos.z], "r": radius,
			"c": [color.r, color.g, color.b, color.a],
		})


func _ring_fx_local(pos: Vector3, radius: float, color: Color) -> void:
	var ring := MeshLib.ground_disc(self, 0.4, color, Vector3(pos.x, 0.05, pos.z))
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(radius / 0.4, 1.0, radius / 0.4), 0.35)
	tween.parallel().tween_property(ring, "transparency", 1.0, 0.4)
	tween.tween_callback(ring.queue_free)


## ------------------------------------------------ fim de fase

func end_level(won: bool) -> void:
	if ended:
		return
	ended = true
	running = false
	var result := {
		"level": level_number,
		"won": won,
		"score": score,
		"stars": compute_stars(won) if won else 0,
		"mess_left": mess_count(),
		"time": time_elapsed,
	}
	AudioMan.play_sfx("ding" if won else "angry")
	if online and is_host:
		Net.broadcast({"e": "end", "r": result})
	finished.emit(result)


## ------------------------------------------------ HUD

func _update_hud(force: bool) -> void:
	if hud == null:
		return
	var state := {
		"time": time_left if time_left > 0.0 else time_elapsed,
		"objective": objective_text(),
		"mess": mess_count(),
		"title": Strings.LEVEL_TITLES.get(level_number, ""),
	}
	state.merge(extra_hud(), true)
	hud.call("update_state", state, force)


func _send_hud_state() -> void:
	var state := {
		"time": time_left if time_left > 0.0 else time_elapsed,
		"mess": mess_count(),
	}
	state.merge(extra_hud(), true)
	Net.broadcast({"e": "hud", "s": state}, false)


## ------------------------------------------------ rede

func _send_snapshot() -> void:
	var pets_snap := {}
	for slot in pets:
		pets_snap[slot] = pets[slot].snapshot()
	var threats_snap := {}
	for id in threats:
		if is_instance_valid(threats[id]):
			threats_snap[id] = threats[id].snapshot()
	var carry_snap := {}
	for id in carryables:
		var c: Carryable = carryables[id]
		if is_instance_valid(c):
			carry_snap[id] = [
				snappedf(c.global_position.x, 0.01),
				snappedf(c.global_position.y, 0.01),
				snappedf(c.global_position.z, 0.01),
			]
	Net.broadcast({"s": {"p": pets_snap, "t": threats_snap, "c": carry_snap}}, false)


func _on_net_msg(from_id: int, msg: Dictionary) -> void:
	if is_host:
		if msg.has("i") and typeof(msg["i"]) == TYPE_DICTIONARY:
			_remote_frames[from_id] = msg["i"]
		return
	if from_id != 1:
		return
	# Eventos primeiro: a mensagem de HUD carrega "e" E "s" ao mesmo tempo.
	if msg.has("e"):
		_apply_event(msg)
	elif msg.has("s"):
		_apply_snapshot(msg["s"])


func _apply_snapshot(snap: Dictionary) -> void:
	var pets_snap: Dictionary = snap.get("p", {})
	for slot in pets_snap:
		var pet: Pet = pets.get(int(slot))
		if pet != null:
			pet.apply_snapshot(pets_snap[slot])
	var threats_snap: Dictionary = snap.get("t", {})
	for id in threats_snap:
		var threat: Threat = threats.get(int(id))
		if threat != null and is_instance_valid(threat):
			threat.apply_snapshot(threats_snap[id])
	var carry_snap: Dictionary = snap.get("c", {})
	for id in carry_snap:
		var c: Carryable = carryables.get(int(id))
		if c != null and is_instance_valid(c):
			var arr: Array = carry_snap[id]
			c.global_position = Vector3(arr[0], arr[1], arr[2])


func _apply_event(msg: Dictionary) -> void:
	match String(msg.get("e", "")):
		"knock":
			var id := int(msg.get("id", -1))
			if id >= 0 and id < house.knockables.size():
				house.knockables[id].topple()
		"mess+":
			var p: Array = msg.get("p", [0, 0])
			var spot := MessSpot.create(String(msg.get("k", "generic")), Vector3(p[0], 0, p[1]))
			spot.net_id = int(msg.get("id", 0))
			add_child(spot)
			mess_spots[spot.net_id] = spot
		"mess-":
			var id := int(msg.get("id", 0))
			if mess_spots.has(id):
				var spot: MessSpot = mess_spots[id]
				mess_spots.erase(id)
				if is_instance_valid(spot):
					spot.queue_free()
		"food+":
			var p: Array = msg.get("p", [0, 0, 0])
			var idx := int(msg.get("id", 0))
			var food := FoodItem.create(String(msg.get("k", "kibble")), Vector3(p[0], p[1], p[2]))
			food.net_id = idx
			add_child(food)
			food_items[idx] = food
		"food-":
			var idx := int(msg.get("id", 0))
			if food_items.has(idx):
				var food: FoodItem = food_items[idx]
				food_items.erase(idx)
				if is_instance_valid(food):
					food.queue_free()
		"carry+":
			var p: Array = msg.get("p", [0, 0])
			var c := Carryable.create(String(msg.get("k", "ball")), Vector3(p[0], 0, p[1]))
			c.net_id = int(msg.get("id", 0))
			add_child(c)
			carryables[c.net_id] = c
		"carry-":
			var id := int(msg.get("id", 0))
			if carryables.has(id):
				var c: Carryable = carryables[id]
				carryables.erase(id)
				if is_instance_valid(c):
					c.queue_free()
		"threat+":
			_spawn_threat_replica(msg)
		"threat-":
			var id := int(msg.get("id", 0))
			if threats.has(id):
				var threat: Threat = threats[id]
				threats.erase(id)
				if is_instance_valid(threat):
					threat.queue_free()
		"fx":
			var p: Array = msg.get("p", [0, 0])
			var c: Array = msg.get("c", [1, 1, 1, 0.5])
			_ring_fx_local(
				Vector3(p[0], 0, p[1]), float(msg.get("r", 2.0)),
				Color(c[0], c[1], c[2], c[3])
			)
		"hud":
			var state: Dictionary = msg.get("s", {})
			state["objective"] = objective_text()
			state["title"] = Strings.LEVEL_TITLES.get(level_number, "")
			on_remote_hud(state)
			if hud != null:
				hud.call("update_state", state, false)
		"ban":
			if hud != null:
				hud.call("show_banner", String(msg.get("t", "")), float(msg.get("d", 1.5)))
		"gen":
			on_generic_event(String(msg.get("k", "")))
		"end":
			ended = true
			finished.emit(msg.get("r", {}))


func _spawn_threat_replica(msg: Dictionary) -> void:
	var threat: Threat
	match String(msg.get("cls", "threat")):
		"mailman":
			threat = Mailman.new()
			threat.kind = "mailman"
		"pillow":
			var pillow := Pillow.new()
			pillow.color_index = int(msg.get("ci", 0))
			pillow.kind = "pillow"
			threat = pillow
		"bird":
			var bird := Bird.new()
			bird.tree_index = int(msg.get("tree", 0))
			bird.kind = "bird"
			bird.flying = true
			threat = bird
		"gate":
			var ga := GateAnimal.new()
			ga.variant = String(msg.get("var", "gate_dog"))
			ga.kind = ga.variant
			threat = ga
		"invader":
			var inv := Invader.new()
			inv.variant = String(msg.get("var", "rat"))
			inv.kind = "invader"
			threat = inv
		_:
			threat = Threat.new()
	threat.net_id = int(msg.get("id", 0))
	threat.setup(self, true)
	add_child(threat)
	var p: Array = msg.get("p", [0, 0, 0])
	threat.global_position = Vector3(p[0], p[1], p[2])
	threat.net_pos = threat.global_position
	threats[threat.net_id] = threat
