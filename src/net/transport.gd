class_name Transport
extends RefCounted
## Abstract network transport. The game talks to peers only through this
## interface, so LAN (ENet) and internet (relay/WebSocket) are interchangeable.
## Peer ids: host is always 1; broadcast target is 0.

signal connected_ok(self_id: int)
signal connection_failed(reason: String)
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal packet_received(from_id: int, data: PackedByteArray)
signal closed

var my_id := 0
var is_server := false
var peers: Array[int] = []


func poll() -> void:
	pass


## to_id 0 = broadcast to everyone else.
func send(_to_id: int, _data: PackedByteArray, _reliable: bool) -> void:
	pass


func close() -> void:
	pass


## Extra info for the lobby UI (room code, port...).
func describe() -> String:
	return ""
