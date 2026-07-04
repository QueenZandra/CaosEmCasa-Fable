class_name RelayTransport
extends Transport
## Internet transport through the room-code relay server (relay/server.js).
## Control messages are JSON text frames; game packets are binary frames
## prefixed with a 4-byte little-endian peer id (target when sending,
## source when receiving). WebSocket/TCP is always reliable+ordered.

const DEFAULT_URL := "ws://127.0.0.1:9080"

var room_code := ""
var _ws := WebSocketPeer.new()
var _mode := ""              # "create" ou "join"
var _join_code := ""
var _opened := false
var _registered := false


static func host(url: String) -> RelayTransport:
	var t := RelayTransport.new()
	t._mode = "create"
	t._start(url)
	return t


static func join(url: String, code: String) -> RelayTransport:
	var t := RelayTransport.new()
	t._mode = "join"
	t._join_code = code.strip_edges().to_upper()
	t._start(url)
	return t


func _start(url: String) -> void:
	var err := _ws.connect_to_url(url)
	if err != OK:
		_opened = true  # força o caminho de falha no primeiro poll
		_registered = true
		connection_failed.emit.call_deferred("ws_connect_error")


func poll() -> void:
	_ws.poll()
	var state := _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not _opened:
		_opened = true
		if _mode == "create":
			_ws.send_text(JSON.stringify({"t": "create"}))
		else:
			_ws.send_text(JSON.stringify({"t": "join", "code": _join_code}))
	if state == WebSocketPeer.STATE_CLOSED:
		if not _registered:
			_registered = true
			connection_failed.emit("ws_closed")
		else:
			closed.emit()
		return
	while _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()
		if _ws.was_string_packet():
			_handle_control(pkt.get_string_from_utf8())
		else:
			if pkt.size() > 4:
				var from_id := pkt.decode_s32(0)
				packet_received.emit(from_id, pkt.slice(4))


func _handle_control(text: String) -> void:
	var msg: Variant = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	match String(msg.get("t", "")):
		"created":
			_registered = true
			my_id = int(msg.get("id", 1))
			is_server = true
			room_code = String(msg.get("code", ""))
			connected_ok.emit(my_id)
		"joined":
			_registered = true
			my_id = int(msg.get("id", 0))
			is_server = false
			room_code = _join_code
			for p in msg.get("peers", []):
				var pid := int(p)
				if not peers.has(pid):
					peers.append(pid)
			connected_ok.emit(my_id)
		"peer_joined":
			var id := int(msg.get("id", 0))
			if not peers.has(id):
				peers.append(id)
			peer_connected.emit(id)
		"peer_left":
			var id := int(msg.get("id", 0))
			peers.erase(id)
			peer_disconnected.emit(id)
		"error":
			_registered = true
			connection_failed.emit(String(msg.get("msg", "relay_error")))


func send(to_id: int, data: PackedByteArray, _reliable: bool) -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var pkt := PackedByteArray()
	pkt.resize(4)
	pkt.encode_s32(0, to_id)
	pkt.append_array(data)
	_ws.send(pkt)


func close() -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.close()


func describe() -> String:
	return room_code
