class_name Level1
extends LevelBase
## Fase 1 — A Despedida (tutorial). Os donos saem para trabalhar e os
## pets aprendem os comandos em quatro tarefinhas.

var owners: Owners
var task_index := 0
var _abilities_used := {}
var _toys_delivered := 0
var _owners_left := false


func setup_level() -> void:
	level_number = 1
	owners = Owners.new()
	owners.position = house.points["door_out"]
	add_child(owners)
	if is_host:
		spawn_carryable("ball", house.sofa_pos + Vector3(1.2, 0, 1.6))
		spawn_carryable("toy_bone", house.sofa_pos + Vector3(-1.6, 0, 1.4))


func tick_level(_delta: float) -> void:
	if not _owners_left and time_elapsed > 2.0:
		_owners_left = true
		send_generic("owners_leave")
		banner(Strings.OWNERS_LEAVING, 2.0)
	match task_index:
		0:
			var all_on_rug := true
			for slot in pets:
				var pet: Pet = pets[slot]
				var rug: Vector3 = house.points["rug"]
				if Vector2(pet.global_position.x - rug.x, pet.global_position.z - rug.z).length() > 2.6:
					all_on_rug = false
					break
			if all_on_rug and running:
				_advance_task()
		1:
			if _toys_delivered >= 1:
				_advance_task()
		2:
			if _abilities_used.size() >= pets.size():
				_advance_task()
		3:
			if mess_count() == 0 and time_elapsed > 4.0:
				score += 200
				end_level(true)


func _advance_task() -> void:
	task_index += 1
	score += 100
	AudioMan.play_sfx("ding")
	if task_index == 3 and is_host:
		# Garante que existe bagunça para limpar.
		if mess_count() == 0:
			add_mess("dirt", house.points["rug"])


func on_generic_event(kind: String) -> void:
	if kind == "owners_leave":
		owners.walk_out([
			house.points["gate_in"], house.points["gate_out"],
			house.points["street_right"],
		])


func item_dropped(item: Node3D, pos: Vector3) -> void:
	var box: Vector3 = house.points["toy_box"]
	if Vector2(pos.x - box.x, pos.z - box.z).length() < 1.7:
		_toys_delivered += 1
		if item is Carryable:
			carryables.erase((item as Carryable).net_id)
		item.queue_free()
		AudioMan.play_sfx("cute")


func ability_used(pet: Node) -> void:
	if task_index >= 2:
		_abilities_used[(pet as Pet).slot] = true


func objective_text() -> String:
	match task_index:
		0: return Strings.TUT_TASK_MOVE
		1: return Strings.TUT_TASK_CARRY
		2: return Strings.TUT_TASK_ABILITY
		_: return Strings.TUT_TASK_CLEAN


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if time_elapsed < 75.0:
		return 3
	return 2 if time_elapsed < 120.0 else 1
