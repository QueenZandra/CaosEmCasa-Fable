class_name Level6
extends LevelBase
## Fase 6 — Os Donos Chegaram. A raiva sobe com a bagunça visível.
## Limpem tudo (segurar A) enquanto revezam fofuras (X perto dos donos):
## Sirius senta obediente, Belatriz vira a barriguinha, Zoe traz a
## bolinha e Minerva se esfrega na perna. Raiva 100 = derrota.

const CUTE_RADIUS := 3.6
const CUTE_BASE_RELIEF := 13.0
const CUTE_RECOVERY_TIME := 28.0

var rage := 20.0
var owners: Owners
var _cute_factor := {}       # slot -> multiplicador (efeito decrescente)
var _shown_hint := false


func setup_level() -> void:
	level_number = 6
	is_final_level = true
	owners = Owners.new()
	owners.position = house.points["door_in"]
	owners.rotation.y = PI    # olhando para dentro de casa
	add_child(owners)
	owners.set_angry(true)
	MeshLib.ground_disc(self, CUTE_RADIUS, Color(1.0, 0.6, 0.7, 0.12), house.points["door_in"])

	# Estrago pré-existente: metade dos objetos caídos (determinístico,
	# roda igual em host e clientes — sem eventos).
	var pre_rng := RandomNumberGenerator.new()
	pre_rng.seed = 60_606
	for k in house.knockables:
		if pre_rng.randf() < 0.5:
			k.topple()

	# Bagunça inicial: 6 + o que ficou das fases anteriores (só o host
	# cria; os clientes recebem por evento).
	if is_host:
		var total := mini(6 + GameState.carry_mess, 14)
		var kinds := ["dirt", "feathers", "shards", "food", "generic"]
		for i in total:
			var pos := Vector3(pre_rng.randf_range(-11.0, 11.0), 0, pre_rng.randf_range(-8.0, 2.0))
			add_mess(kinds[i % kinds.size()], pos)
	for slot in pets:
		_cute_factor[slot] = 1.0


func tick_level(delta: float) -> void:
	if not _shown_hint and time_elapsed > 1.0:
		_shown_hint = true
		banner(Strings.OWNERS_ARRIVED, 2.2)
		banner(Strings.CUTE_HINT, 3.0)
	# Fatores de fofura se recuperam com o tempo.
	for slot in _cute_factor:
		_cute_factor[slot] = minf(1.0, _cute_factor[slot] + delta / CUTE_RECOVERY_TIME)
	# A raiva sobe com a bagunça visível.
	var visible_mess := mess_count()
	rage += (0.45 + 0.22 * visible_mess) * delta
	rage = clampf(rage, 0.0, 100.0)
	if rage >= 100.0:
		banner(Strings.RAGE_EXPLODED, 2.0)
		end_level(false)
		return
	if visible_mess == 0 and time_elapsed > 3.0:
		score += int(300.0 - rage)
		banner(Strings.HOUSE_CLEAN, 2.0)
		end_level(true)


func cute_performed(pet: Node) -> void:
	var p := pet as Pet
	var owner_pos: Vector3 = house.points["door_in"]
	var dist := Vector2(
		p.global_position.x - owner_pos.x, p.global_position.z - owner_pos.z
	).length()
	if dist > CUTE_RADIUS:
		return
	var factor: float = _cute_factor.get(p.slot, 1.0)
	rage = maxf(0.0, rage - CUTE_BASE_RELIEF * factor)
	score += int(30.0 * factor)
	_cute_factor[p.slot] = factor * 0.45
	spawn_ring_fx(p.global_position, 2.2, Color(1.0, 0.5, 0.7, 0.6))
	AudioMan.play_sfx("cute")


func objective_text() -> String:
	return Strings.LEVEL_GOALS[6]


func on_remote_hud(state: Dictionary) -> void:
	rage = float(state.get("rage", rage))
	owners.set_angry(rage > 1.0)


func extra_hud() -> Dictionary:
	return {"rage": rage}


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if rage < 35.0:
		return 3
	return 2 if rage < 70.0 else 1
