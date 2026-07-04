class_name Level4
extends LevelBase
## Fase 4 — Jardim sob Ataque. Passarinhos fazem ninho nas árvores
## enquanto bichos de rua provocam no portão (e a bagunça acontece
## dentro de casa). 2 ninhos completos = derrota.

const DURATION := 130.0
const MAX_NESTS := 2

var nest_progress := [0.0, 0.0]
var nests_built := 0
var provocations := 0
var _bird_timer := 4.0
var _gate_timer := 10.0
var _nest_visuals: Array = [null, null]


func setup_level() -> void:
	level_number = 4
	time_left = DURATION
	for i in 2:
		var nest := MeshLib.sphere(self, 0.45, Color(0.5, 0.38, 0.22), house.tree_positions[i] + Vector3(0.2, 2.75, 0.4), 0.55)
		nest.scale = Vector3.ONE * 0.05
		_nest_visuals[i] = nest


func tick_level(delta: float) -> void:
	if time_left <= 0.0:
		end_level(true)
		return
	_bird_timer -= delta
	if _bird_timer <= 0.0 and _count_of(Bird) < 3:
		_bird_timer = maxf(5.0, 10.0 - time_elapsed * 0.05)
		var tree := _pick_tree()
		if tree >= 0:
			var bird := Bird.new()
			bird.configure(tree, house, _rng.randf_range(-10.0, 10.0))
			spawn_threat(bird)
	_gate_timer -= delta
	if _gate_timer <= 0.0 and _count_of(GateAnimal) < 2:
		_gate_timer = _rng.randf_range(12.0, 18.0)
		var animal := GateAnimal.new()
		animal.configure(
			"gate_dog" if _rng.randf() < 0.5 else "gate_cat",
			_rng.randf() < 0.5, house
		)
		spawn_threat(animal)
	_update_nest_visuals()


func _count_of(cls: Variant) -> int:
	var count := 0
	for id in threats:
		if is_instance_of(threats[id], cls):
			count += 1
	return count


func _pick_tree() -> int:
	# Prefere árvore sem ninho completo e com menos progresso.
	var best := -1
	var best_progress := 2.0
	for i in 2:
		if nest_progress[i] >= 1.0:
			continue
		if nest_progress[i] < best_progress:
			best_progress = nest_progress[i]
			best = i
	return best


func nest_tick(tree: int, amount: float, bird: Node) -> void:
	if nest_progress[tree] >= 1.0:
		(bird as Bird).start_flee()
		return
	nest_progress[tree] += amount
	if nest_progress[tree] >= 1.0:
		nest_progress[tree] = 1.0
		nests_built += 1
		score -= 150
		(bird as Bird).start_flee()
		AudioMan.play_sfx("angry", -6.0)
		banner("Ninho completo! (%d/%d)" % [nests_built, MAX_NESTS], 1.5)
		if nests_built >= MAX_NESTS:
			end_level(false)


func gate_provocation(_threat: Node) -> void:
	provocations += 1
	score -= 20
	knock_random_object()


func _update_nest_visuals() -> void:
	for i in 2:
		var nest: MeshInstance3D = _nest_visuals[i]
		if nest != null:
			nest.scale = Vector3.ONE * maxf(0.05, nest_progress[i])


func on_remote_hud(state: Dictionary) -> void:
	var nests: Array = state.get("nests", [])
	if nests.size() == 2:
		nest_progress[0] = float(nests[0])
		nest_progress[1] = float(nests[1])
		_update_nest_visuals()


func extra_hud() -> Dictionary:
	return {
		"line": "Ninhos: %d/%d  |  Provocações: %d" % [nests_built, MAX_NESTS, provocations],
		"nests": nest_progress,
	}


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if nests_built == 0 and provocations <= 4:
		return 3
	return 2 if nests_built == 0 else 1
