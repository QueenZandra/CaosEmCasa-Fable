class_name OnlineLobby
extends Control
## Sala de espera online. O host mantém a lista (peer, pet, pronto) e
## replica para todos; cada jogador escolhe seu pet e marca "Pronto".

signal start_game(players: Array)
signal left_lobby

var lobby_players: Array = []    # [{peer:int, pet:String, ready:bool}]

var _code_label: Label
var _players_box: VBoxContainer
var _pet_label: Label
var _tagline: Label
var _ready_btn: Button
var _start_btn: Button
var _my_ready := false


func _ready() -> void:
	var root := UiUtil.screen_root()
	add_child(root)
	var box := UiUtil.center_box(root)
	UiUtil.title_label(box, Strings.ONLINE_TITLE, 36)
	_code_label = UiUtil.label(box, "", 30, UiUtil.ACCENT)
	_players_box = VBoxContainer.new()
	_players_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_players_box.add_theme_constant_override("separation", 6)
	box.add_child(_players_box)

	UiUtil.label(box, "", 8)
	var pick_row := HBoxContainer.new()
	pick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pick_row.add_theme_constant_override("separation", 12)
	box.add_child(pick_row)
	UiUtil.button(pick_row, "◀", func() -> void: _cycle(-1), 24).custom_minimum_size = Vector2(60, 48)
	var pet_box := VBoxContainer.new()
	pick_row.add_child(pet_box)
	_pet_label = UiUtil.label(pet_box, "", 30, UiUtil.ACCENT)
	_tagline = UiUtil.label(pet_box, "", 14, Color(0.85, 0.85, 0.9))
	_pet_label.custom_minimum_size = Vector2(320, 0)
	UiUtil.button(pick_row, "▶", func() -> void: _cycle(1), 24).custom_minimum_size = Vector2(60, 48)

	_ready_btn = UiUtil.button(box, Strings.READY, _toggle_ready)
	_start_btn = UiUtil.button(box, Strings.START_GAME, _host_start)
	_start_btn.visible = Net.is_host()
	_start_btn.disabled = true
	UiUtil.button(box, Strings.BACK, _leave, 20).custom_minimum_size = Vector2(200, 40)

	Net.msg_received.connect(_on_msg)
	Net.peer_joined.connect(_on_peer_joined)
	Net.peer_left.connect(_on_peer_left)
	Net.session_closed.connect(_on_session_closed)

	var code := Net.room_code()
	if code != "":
		_code_label.text = Strings.ROOM_CODE_IS % code
	else:
		_code_label.text = Strings.LAN_HOST_INFO % ENetTransport.DEFAULT_PORT if Net.is_host() else "LAN"

	if Net.is_host():
		lobby_players = [{"peer": 1, "pet": "sirius", "ready": false}]
		_refresh()
	else:
		Net.send_msg(1, {"c": "hello"})


func _exit_tree() -> void:
	for sig_pair in [
		[Net.msg_received, _on_msg], [Net.peer_joined, _on_peer_joined],
		[Net.peer_left, _on_peer_left], [Net.session_closed, _on_session_closed],
	]:
		var sig: Signal = sig_pair[0]
		var cb: Callable = sig_pair[1]
		if sig.is_connected(cb):
			sig.disconnect(cb)


func _me() -> Dictionary:
	for p in lobby_players:
		if p.peer == Net.my_id:
			return p
	return {}


func _taken_pets(except_peer: int) -> Array:
	var out := []
	for p in lobby_players:
		if p.peer != except_peer:
			out.append(p.pet)
	return out


## ---------------- ações locais ----------------

func _cycle(direction: int) -> void:
	var me := _me()
	if me.is_empty() or _my_ready:
		return
	var pet: String = me.pet
	for i in PetDefs.ORDER.size():
		pet = PetDefs.next_pet(pet, direction)
		if not _taken_pets(Net.my_id).has(pet):
			break
	if Net.is_host():
		me.pet = pet
		_broadcast_lobby()
		_refresh()
	else:
		Net.send_msg(1, {"c": "pick", "pet": pet})


func _toggle_ready() -> void:
	_my_ready = not _my_ready
	if Net.is_host():
		var me := _me()
		if not me.is_empty():
			me.ready = _my_ready
		_broadcast_lobby()
		_refresh()
	else:
		Net.send_msg(1, {"c": "ready", "v": _my_ready})


func _host_start() -> void:
	if not Net.is_host():
		return
	var players := []
	var slot := 0
	for p in lobby_players:
		if not p.ready:
			return
		players.append({"slot": slot, "pet": p.pet, "peer": p.peer, "device": -1})
		slot += 1
	if players.is_empty():
		return
	Net.broadcast({"c": "start", "players": players})
	start_game.emit(players)


func _leave() -> void:
	Net.leave()
	left_lobby.emit()


## ---------------- rede ----------------

func _on_peer_joined(_id: int) -> void:
	pass  # aguarda o "hello" do peer


func _on_peer_left(id: int) -> void:
	if not Net.is_host():
		return
	for i in range(lobby_players.size() - 1, -1, -1):
		if lobby_players[i].peer == id:
			lobby_players.remove_at(i)
	_broadcast_lobby()
	_refresh()


func _on_session_closed() -> void:
	left_lobby.emit()


func _on_msg(from_id: int, msg: Dictionary) -> void:
	var kind := String(msg.get("c", ""))
	if Net.is_host():
		match kind:
			"hello":
				var taken := _taken_pets(-1)
				var pet := "sirius"
				for pid in PetDefs.ORDER:
					if not taken.has(pid):
						pet = pid
						break
				lobby_players.append({"peer": from_id, "pet": pet, "ready": false})
				_broadcast_lobby()
				_refresh()
			"pick":
				var pet := String(msg.get("pet", ""))
				if PetDefs.ORDER.has(pet) and not _taken_pets(from_id).has(pet):
					for p in lobby_players:
						if p.peer == from_id and not p.ready:
							p.pet = pet
				_broadcast_lobby()
				_refresh()
			"ready":
				for p in lobby_players:
					if p.peer == from_id:
						p.ready = bool(msg.get("v", false))
				_broadcast_lobby()
				_refresh()
	else:
		match kind:
			"lobby":
				lobby_players = msg.get("players", [])
				_refresh()
			"start":
				start_game.emit(msg.get("players", []))


func _broadcast_lobby() -> void:
	Net.broadcast({"c": "lobby", "players": lobby_players})


## ---------------- render ----------------

func _refresh() -> void:
	for child in _players_box.get_children():
		child.queue_free()
	var index := 1
	var all_ready := not lobby_players.is_empty()
	for p in lobby_players:
		var who := Strings.PLAYER_N % index
		if p.peer == Net.my_id:
			who += " (você)"
		var status: String = Strings.READY if p.ready else "..."
		UiUtil.label(
			_players_box,
			"%s — %s  [%s]" % [who, Strings.pet_name(p.pet), status],
			20,
			Color(0.7, 1.0, 0.7) if p.ready else Color.WHITE
		)
		if not p.ready:
			all_ready = false
		index += 1
	var me := _me()
	if not me.is_empty():
		_pet_label.text = Strings.pet_name(me.pet)
		_tagline.text = Strings.PET_TAGLINES.get(me.pet, "")
	_ready_btn.text = Strings.READY if not _my_ready else "Esperar"
	if Net.is_host():
		_start_btn.disabled = not all_ready
	elif _my_ready:
		_code_label.text = Strings.WAITING_HOST
