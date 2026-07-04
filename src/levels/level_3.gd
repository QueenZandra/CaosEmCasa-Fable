class_name Level3
extends LevelBase
## Fase 3 — Rebelião das Almofadas. Cinco almofadas fugiram do sofá.
## Assuste (fica tonta), pegue (A) e devolva ao sofá antes do tempo acabar.

const DURATION := 150.0
const PILLOW_COUNT := 5

var captured := 0


func setup_level() -> void:
	level_number = 3
	time_left = DURATION
	if is_host:
		for i in PILLOW_COUNT:
			var pillow := Pillow.new()
			pillow.configure(i, 7000 + i)
			pillow.position = house.sofa_pos + Vector3(
				-2.0 + i * 1.0, 0.2, 1.2 + (i % 2) * 0.8
			)
			spawn_threat(pillow)


func tick_level(_delta: float) -> void:
	if time_left <= 0.0:
		end_level(captured >= PILLOW_COUNT)


func pillow_captured(pillow: Node) -> void:
	captured += 1
	score += 150
	AudioMan.play_sfx("cute")
	# Se algum pet ainda a segura, solta a referência.
	for slot in pets:
		if pets[slot].carrying == pillow:
			pets[slot].carrying = null
	_despawn_threat((pillow as Pillow).net_id)
	banner("Almofada capturada! (%d/%d)" % [captured, PILLOW_COUNT], 1.2)
	if captured >= PILLOW_COUNT:
		end_level(true)


func extra_hud() -> Dictionary:
	return {"line": "Almofadas no sofá: %d/%d" % [captured, PILLOW_COUNT]}


func compute_stars(won: bool) -> int:
	if not won:
		return 0
	if time_left >= 60.0 and mess_count() <= 4:
		return 3
	return 2 if time_left >= 20.0 else 1
