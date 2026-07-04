extends Node
## Autoload: network session manager. Owns the active Transport and moves
## Dictionaries (via var_to_bytes / bytes_to_var) between peers.
## The game is host-authoritative: the host simulates, clients send inputs
## and render replicas. Offline/local play simply has no transport.

signal connected_ok
signal connection_failed(reason: String)
signal peer_joined(id: int)
signal peer_left(id: int)
signal session_closed
signal msg_received(from_id: int, msg: Dictionary)

var transport: Transport = null
var my_id := 1               # 1 quando offline/host


func is_online() -> bool:
	return transport != null


func is_host() -> bool:
	return transport == null or transport.is_server


func host_lan(port := ENetTransport.DEFAULT_PORT) -> bool:
	var t := ENetTransport.host(port)
	if t.creation_failed():
		return false
	_adopt(t)
	my_id = 1
	connected_ok.emit.call_deferred()
	return true


func join_lan(ip: String, port := ENetTransport.DEFAULT_PORT) -> bool:
	var t := ENetTransport.join(ip, port)
	if t.creation_failed():
		return false
	_adopt(t)
	return true


func host_relay(url: String) -> void:
	_adopt(RelayTransport.host(url))


func join_relay(url: String, code: String) -> void:
	_adopt(RelayTransport.join(url, code))


func leave() -> void:
	if transport != null:
		transport.close()
		transport = null
	my_id = 1


func room_code() -> String:
	if transport is RelayTransport:
		return (transport as RelayTransport).room_code
	return ""


func peers() -> Array[int]:
	if transport == null:
		return []
	return transport.peers


func send_msg(to_id: int, msg: Dictionary, reliable := true) -> void:
	if transport == null:
		return
	transport.send(to_id, var_to_bytes(msg), reliable)


func broadcast(msg: Dictionary, reliable := true) -> void:
	send_msg(0, msg, reliable)


func _process(_delta: float) -> void:
	if transport != null:
		transport.poll()


func _adopt(t: Transport) -> void:
	leave()
	transport = t
	t.connected_ok.connect(_on_connected_ok)
	t.connection_failed.connect(_on_connection_failed)
	t.peer_connected.connect(func(id: int) -> void: peer_joined.emit(id))
	t.peer_disconnected.connect(func(id: int) -> void: peer_left.emit(id))
	t.packet_received.connect(_on_packet)
	t.closed.connect(_on_closed)


func _on_connected_ok(self_id: int) -> void:
	my_id = self_id
	connected_ok.emit()


func _on_connection_failed(reason: String) -> void:
	transport = null
	my_id = 1
	connection_failed.emit(reason)


func _on_closed() -> void:
	transport = null
	my_id = 1
	session_closed.emit()


func _on_packet(from_id: int, data: PackedByteArray) -> void:
	var msg: Variant = bytes_to_var(data)
	if typeof(msg) == TYPE_DICTIONARY:
		msg_received.emit(from_id, msg)
