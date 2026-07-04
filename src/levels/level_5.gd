class_name Level5
extends LevelBase
## Fase 5 — A Invasão. Ondas de ratos, gambás e tatus tentam roubar a
## comida e fugir com ela. Belatriz (Modo Feroz) e Minerva (Patada)
## brilham aqui. Perder 4 comidas = derrota.

const WAVES := [
	["rat", "rat", "rat"],
	["rat", "rat", "opossum", "rat"],
	["opossum", "rat", "armadillo", "rat", "opossum"],
]
const MAX_STOLEN := 4

var wave := 0
var stolen := 0
var _wave_delay := 4.0
var _spawn_queue: Array = []
var _spawn_timer := 0.0


func setup_level() -> void:
	level_number = 5
	if is_host:
		for i in house.food_spots.size():
			_spawn_food(["kibble", "bone", "fish"][i % 3], house.food_spots[i], i)


func tick_level(delta: float) -> void:
	# Spawns escalonados da onda atual.
	if not _spawn_queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 1.6
			_spawn_invader(String(_spawn_queue.pop_front()))
		return
	if alive_threats() > 0:
		return
	# Onda limpa: próxima (ou vitória).
	_wave_delay -= delta
	if _wave_delay > 0.0:
		return
	if wave >= WAVES.size():
		end_level(true)
		return
	wave += 1
	_wave_delay = 5.0
	_spawn_queue = WAVES[wave - 1].duplicate()
	_spawn_timer = 0.0
	AudioMan.play_sfx("angry", -8.0)
	banner(Strings.HUD_WAVE % [wave, WAVES.size()], 1.6)


func _spawn_invader(variant: String) -> void:
	# Escolhe uma comida-alvo ainda existente.
	var indices: Array = food_items.keys()
	if indices.is_empty():
		return
	var target: int = indices[_rng.randi() % indices.size()]
	var food: FoodItem = food_items[target]
	var entries := [
		Vector3(-13.0, 0, 7.0), Vector3(13.0, 0, 7.0),
		Vector3(0, 0, 11.0), Vector3(-13.0, 0, 9.5), Vector3(13.0, 0, 9.5),
	]
	var invader := Invader.new()
	invader.configure(
		variant, entries[_rng.randi() % entries.size()],
		target, food.position, house
	)
	spawn_threat(invader)


func food_stolen(_threat: Node) -> void:
	stolen += 1
	score -= 100
	AudioMan.play_sfx("angry", -5.0)
	banner("Comida roubada! (%d/%d)" % [stolen, MAX_STOLEN], 1.4)
	if stolen >= MAX_STOLEN:
		end_level(false)


func extra_hud() -> Dictionary:
	return {"line": "%s  |  Roubadas: %d/%d" % [Strings.HUD_WAVE % [maxi(wave, 1), WAVES.size()], stolen, MAX_STOLEN]}


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if stolen == 0:
		return 3
	return 2 if stolen <= 2 else 1
