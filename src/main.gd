extends Node
## Orquestrador do jogo: menus -> lobby (local/online) -> fases -> resultados.
## No online, o host decide as transições e avisa os clientes ({"c":"load"}).

const LEVEL_CLASSES := [Level1, Level2, Level3, Level4, Level5, Level6]

var current_screen: Node = null
var current_level: LevelBase = null
var hud: Hud = null


func _ready() -> void:
	Net.msg_received.connect(_on_net_msg)
	Net.session_closed.connect(_on_session_closed)
	show_menu()


func _clear() -> void:
	if current_screen != null:
		current_screen.queue_free()
		current_screen = null
	if current_level != null:
		current_level.queue_free()
		current_level = null
	if hud != null:
		hud.queue_free()
		hud = null


## ---------------- telas ----------------

func show_menu() -> void:
	_clear()
	Net.leave()
	GameState.reset_session()
	var menu := MainMenu.new()
	menu.local_pressed.connect(show_local_lobby)
	menu.online_pressed.connect(show_online_menu)
	add_child(menu)
	current_screen = menu


func show_local_lobby() -> void:
	_clear()
	var lobby := LocalLobby.new()
	lobby.start_requested.connect(_start_local)
	lobby.back_requested.connect(show_menu)
	add_child(lobby)
	current_screen = lobby


func show_online_menu() -> void:
	_clear()
	var menu := OnlineMenu.new()
	menu.connected_as_host.connect(show_online_lobby)
	menu.connected_as_client.connect(show_online_lobby)
	menu.back_requested.connect(show_menu)
	add_child(menu)
	current_screen = menu


func show_online_lobby() -> void:
	_clear()
	var lobby := OnlineLobby.new()
	lobby.start_game.connect(_start_online)
	lobby.left_lobby.connect(show_menu)
	add_child(lobby)
	current_screen = lobby


## ---------------- início de sessão ----------------

func _start_local(players: Array) -> void:
	GameState.reset_session()
	GameState.online = false
	GameState.is_host = true
	for p in players:
		GameState.add_player(int(p.slot), String(p.pet), int(p.device), 0)
	GameState.reset_campaign()
	load_level(1)


func _start_online(players: Array) -> void:
	GameState.reset_session()
	GameState.online = true
	GameState.is_host = Net.is_host()
	var joypads := Input.get_connected_joypads()
	var my_device: int = joypads[0] if not joypads.is_empty() else -1
	for p in players:
		var peer := int(p.peer)
		var device := my_device if peer == Net.my_id else -1
		GameState.add_player(int(p.slot), String(p.pet), device, peer)
	GameState.reset_campaign()
	load_level(1)


## ---------------- fases ----------------

func load_level(number: int) -> void:
	_clear()
	GameState.level_index = number
	hud = Hud.new()
	add_child(hud)
	var level: LevelBase = LEVEL_CLASSES[number - 1].new()
	level.level_number = number
	level.hud = hud
	level.finished.connect(_on_level_finished)
	add_child(level)
	current_level = level


func _on_level_finished(result: Dictionary) -> void:
	GameState.record_result(result)
	# Pequena pausa dramática antes do resultado.
	var timer := get_tree().create_timer(1.4)
	timer.timeout.connect(_show_results.bind(result))


func _show_results(result: Dictionary) -> void:
	if current_level == null:
		return
	_clear()
	var results := Results.new()
	results.result = result
	results.campaign_complete = bool(result.get("won", false)) and int(result.get("level", 1)) >= GameState.LEVEL_COUNT
	results.continue_pressed.connect(_continue_from_results.bind(result))
	add_child(results)
	current_screen = results


func _continue_from_results(result: Dictionary) -> void:
	var lvl := int(result.get("level", 1))
	var won := bool(result.get("won", false))
	var next := lvl + 1 if won else lvl
	if won and lvl >= GameState.LEVEL_COUNT:
		if GameState.online:
			Net.broadcast({"c": "menu"})
		show_menu()
		return
	if GameState.online:
		Net.broadcast({"c": "load", "level": next})
	load_level(next)


## ---------------- rede (cliente segue o host) ----------------

func _on_net_msg(_from_id: int, msg: Dictionary) -> void:
	if Net.is_host():
		return
	match String(msg.get("c", "")):
		"load":
			load_level(int(msg.get("level", 1)))
		"menu":
			show_menu()


func _on_session_closed() -> void:
	# Conexão caiu no meio do jogo/lobby: volta ao menu.
	if GameState.online or current_screen is OnlineLobby:
		show_menu()


func _input(event: InputEvent) -> void:
	# ESC durante uma fase local volta ao menu.
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		if current_level != null and not GameState.online:
			show_menu()
