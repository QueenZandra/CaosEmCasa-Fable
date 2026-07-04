class_name Level2
extends LevelBase
## Fase 2 — O Carteiro. Ele volta sem parar tentando entregar encomendas;
## assustem-no antes que complete a entrega. 3 entregas = derrota.

const DURATION := 100.0
const MAX_DELIVERED := 3

var delivered := 0
var blocked := 0
var _spawn_timer := 3.0
var _from_left := true


func setup_level() -> void:
	level_number = 2
	time_left = DURATION


func tick_level(delta: float) -> void:
	if time_left <= 0.0:
		end_level(true)
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _count_mailmen() == 0:
		_spawn_timer = maxf(6.0, 13.0 - time_elapsed * 0.06)
		var mailman := Mailman.new()
		mailman.configure(_from_left, house)
		_from_left = not _from_left
		spawn_threat(mailman)


func _count_mailmen() -> int:
	var count := 0
	for id in threats:
		if threats[id] is Mailman:
			count += 1
	return count


func mail_delivered(_threat: Node) -> void:
	delivered += 1
	score -= 100
	AudioMan.play_sfx("angry", -6.0)
	banner("Encomenda entregue! (%d/%d)" % [delivered, MAX_DELIVERED], 1.5)
	if delivered >= MAX_DELIVERED:
		end_level(false)


func threat_scared_off(threat: Node, source: Node) -> void:
	super.threat_scared_off(threat, source)
	if threat is Mailman:
		blocked += 1
		score += 100


func extra_hud() -> Dictionary:
	return {"line": "Bloqueados: %d  |  Entregues: %d/%d" % [blocked, delivered, MAX_DELIVERED]}


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if delivered == 0:
		return 3
	return 2 if delivered == 1 else 1
