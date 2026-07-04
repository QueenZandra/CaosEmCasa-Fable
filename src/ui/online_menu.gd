class_name OnlineMenu
extends Control
## Menu online: criar/entrar em sala via relay (código) ou LAN (IP).

signal connected_as_host
signal connected_as_client
signal back_requested

var _relay_url: LineEdit
var _code: LineEdit
var _ip: LineEdit
var _status: Label
var _busy := false


func _ready() -> void:
	var root := UiUtil.screen_root()
	add_child(root)
	var box := UiUtil.center_box(root)
	UiUtil.title_label(box, Strings.ONLINE_TITLE, 40)

	UiUtil.label(box, Strings.RELAY_URL_LABEL, 18, Color(0.8, 0.8, 0.9))
	_relay_url = UiUtil.line_edit(box, "ws://servidor:9080", RelayTransport.DEFAULT_URL)
	UiUtil.button(box, Strings.HOST_RELAY, _host_relay)
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 10)
	box.add_child(join_row)
	_code = UiUtil.line_edit(join_row, Strings.ROOM_CODE_LABEL)
	_code.custom_minimum_size = Vector2(180, 44)
	UiUtil.button(join_row, Strings.JOIN_RELAY, _join_relay, 20).custom_minimum_size = Vector2(220, 44)

	UiUtil.label(box, "", 8)
	UiUtil.button(box, Strings.HOST_LAN, _host_lan)
	var lan_row := HBoxContainer.new()
	lan_row.add_theme_constant_override("separation", 10)
	box.add_child(lan_row)
	_ip = UiUtil.line_edit(lan_row, Strings.IP_LABEL, "127.0.0.1")
	_ip.custom_minimum_size = Vector2(180, 44)
	UiUtil.button(lan_row, Strings.JOIN_LAN, _join_lan, 20).custom_minimum_size = Vector2(220, 44)

	_status = UiUtil.label(box, "", 20, Color(1.0, 0.7, 0.6))
	UiUtil.button(box, Strings.BACK, func() -> void:
		Net.leave()
		back_requested.emit()
	, 20).custom_minimum_size = Vector2(200, 40)

	Net.connected_ok.connect(_on_connected)
	Net.connection_failed.connect(_on_failed)


func _exit_tree() -> void:
	if Net.connected_ok.is_connected(_on_connected):
		Net.connected_ok.disconnect(_on_connected)
	if Net.connection_failed.is_connected(_on_failed):
		Net.connection_failed.disconnect(_on_failed)


func _host_relay() -> void:
	if _busy:
		return
	_busy = true
	_status.text = Strings.CONNECTING
	Net.host_relay(_relay_url.text.strip_edges())


func _join_relay() -> void:
	if _busy or _code.text.strip_edges().is_empty():
		return
	_busy = true
	_status.text = Strings.CONNECTING
	Net.join_relay(_relay_url.text.strip_edges(), _code.text)


func _host_lan() -> void:
	if _busy:
		return
	_status.text = Strings.CONNECTING
	if Net.host_lan():
		_busy = true
	else:
		_status.text = Strings.CONNECTION_FAILED


func _join_lan() -> void:
	if _busy:
		return
	_status.text = Strings.CONNECTING
	if Net.join_lan(_ip.text.strip_edges()):
		_busy = true
	else:
		_status.text = Strings.CONNECTION_FAILED


func _on_connected() -> void:
	_busy = false
	if Net.is_host():
		connected_as_host.emit()
	else:
		connected_as_client.emit()


func _on_failed(reason: String) -> void:
	_busy = false
	_status.text = "%s (%s)" % [Strings.CONNECTION_FAILED, reason]
