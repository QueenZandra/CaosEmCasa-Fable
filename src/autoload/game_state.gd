extends Node
## Autoload: session/campaign state shared by menus, levels and netcode.

const LEVEL_COUNT := 6

## Players in the session. Each entry:
## {slot:int 0..3, pet:String, device:int (-1 kb, >=0 joypad; only meaningful
##  on the machine that owns it), peer:int (0 = local/offline, else transport id)}
var players: Array[Dictionary] = []

var online := false
var is_host := true          # offline/local sempre é host
var level_index := 1
var carry_mess := 0          # bagunça acumulada das fases 2..5 (entra na fase 6)
var stars := {}              # level -> int 0..3
var last_result := {}        # resultado da última fase (para a tela de resultados)


func reset_campaign() -> void:
	level_index = 1
	carry_mess = 0
	stars = {}
	last_result = {}


func reset_session() -> void:
	players.clear()
	online = false
	is_host = true
	reset_campaign()


func add_player(slot: int, pet: String, device: int, peer: int) -> void:
	players.append({"slot": slot, "pet": pet, "device": device, "peer": peer})


func player_by_slot(slot: int) -> Dictionary:
	for p in players:
		if p.slot == slot:
			return p
	return {}


func player_by_peer(peer: int) -> Dictionary:
	for p in players:
		if p.peer == peer:
			return p
	return {}


func local_players() -> Array[Dictionary]:
	# Players controlled on this machine. Offline: all. Online: peer == Net.my_id.
	var out: Array[Dictionary] = []
	for p in players:
		if not online or p.peer == Net.my_id:
			out.append(p)
	return out


func used_pets() -> Array[String]:
	var out: Array[String] = []
	for p in players:
		out.append(p.pet)
	return out


func free_pet(preferred: String = "") -> String:
	if preferred != "" and not used_pets().has(preferred):
		return preferred
	for pet_id in PetDefs.ORDER:
		if not used_pets().has(pet_id):
			return pet_id
	return "sirius"


func record_result(result: Dictionary) -> void:
	last_result = result
	var lvl := int(result.get("level", level_index))
	if result.get("won", false):
		var star_count := int(result.get("stars", 1))
		if star_count > int(stars.get(lvl, 0)):
			stars[lvl] = star_count
		if lvl >= 2 and lvl <= 5:
			carry_mess += int(result.get("mess_left", 0))
