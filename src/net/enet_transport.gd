class_name ENetTransport
extends Transport
## LAN/direct-IP transport built on ENetMultiplayerPeer, polled manually
## (we do not use Godot's high-level multiplayer; the game has its own
## host-authoritative protocol on top of Transport).

const DEFAULT_PORT := 9077

var _peer: ENetMultiplayerPeer
var _was_connected := false
var _failed := false


static func host(port := DEFAULT_PORT, max_players := 8) -> ENetTransport:
	var t := ENetTransport.new()
	t._peer = ENetMultiplayerPeer.new()
	var err := t._peer.create_server(port, max_players)
	if err != OK:
		t._failed = true
		return t
	t.is_server = true
	t.my_id = 1
	t._was_connected = true
	t._peer.peer_connected.connect(t._on_peer_connected)
	t._peer.peer_disconnected.connect(t._on_peer_disconnected)
	return t


static func join(ip: String, port := DEFAULT_PORT) -> ENetTransport:
	var t := ENetTransport.new()
	t._peer = ENetMultiplayerPeer.new()
	var err := t._peer.create_client(ip, port)
	if err != OK:
		t._failed = true
		return t
	t.is_server = false
	t._peer.peer_connected.connect(t._on_peer_connected)
	t._peer.peer_disconnected.connect(t._on_peer_disconnected)
	return t


func creation_failed() -> bool:
	return _failed


func poll() -> void:
	if _peer == null:
		return
	_peer.poll()
	var status := _peer.get_connection_status()
	if not is_server:
		if not _was_connected:
			if status == MultiplayerPeer.CONNECTION_CONNECTED:
				_was_connected = true
				my_id = _peer.get_unique_id()
				connected_ok.emit(my_id)
			elif status == MultiplayerPeer.CONNECTION_DISCONNECTED:
				connection_failed.emit("enet_connect_failed")
				_peer = null
				return
		elif status == MultiplayerPeer.CONNECTION_DISCONNECTED:
			closed.emit()
			_peer = null
			return
	while _peer != null and _peer.get_available_packet_count() > 0:
		var from_id := _peer.get_packet_peer()
		var data := _peer.get_packet()
		packet_received.emit(from_id, data)


func send(to_id: int, data: PackedByteArray, reliable: bool) -> void:
	if _peer == null:
		return
	if _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if to_id == 0 and peers.is_empty():
		return
	_peer.transfer_mode = (
		MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable
		else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	)
	_peer.set_target_peer(to_id)
	_peer.put_packet(data)


func close() -> void:
	if _peer != null:
		_peer.close()
		_peer = null


func describe() -> String:
	return "LAN porta %d" % DEFAULT_PORT


func _on_peer_connected(id: int) -> void:
	if not peers.has(id):
		peers.append(id)
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	peers.erase(id)
	peer_disconnected.emit(id)
