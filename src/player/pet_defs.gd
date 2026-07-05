class_name PetDefs
## Definitions of the four playable pets, based on the real-life pets.

const ORDER := ["sirius", "belatriz", "zoe", "minerva"]

const DEFS := {
	"sirius": {
		"id": "sirius",
		# Cão porte médio, peludo, preto. Protetor, latido potente, estabanado.
		# Visual baseado nas fotos reais: esguio, pernas longas, juba fofa,
		# rabo de pluma enrolado sobre as costas, focinho grisalho, olhos
		# castanhos e a língua de fora quando está feliz.
		"kind": "dog",
		"scale": 1.12,
		"flop_k": 0.35,
		"chubby": 0.85,
		"leggy": 1.18,
		"snout": 1.25,
		"body_color": Color(0.13, 0.12, 0.13),
		"belly_color": Color(0.2, 0.19, 0.2),
		"muzzle_color": Color(0.62, 0.6, 0.57),
		"eye_color": Color(0.45, 0.28, 0.15),
		"ruff": true,
		"leg_feathers": true,
		"tongue": true,
		"ear": "dog_floppy",
		"tail": "plume_up",
		"speed": 5.2,
		"ability": "bark",         # AoE scare, knocks nearby objects over (clumsy!)
		"cute": "good_boy",        # senta e balança o rabinho
		"clumsy": true,            # derruba objetos ao correr perto
		"food_lover": true,        # rouba comida (boost maior)
		"scare_power": 2.0,
		"ability_cooldown": 4.0,
	},
	"belatriz": {
		"id": "belatriz",
		# Cadela pequena, dourada, olhos pidões. Feroz contra invasores.
		# Visual baseado nas fotos reais: pelo creme/damasco ondulado e
		# bagunçadinho, focinho curto com barbinha creme, orelhas caídas
		# com franja, olhões escuros de pidona e a linguinha de fora (blep).
		"kind": "dog",
		"scale": 0.78,
		"flop_k": 0.6,
		"chubby": 1.05,
		"leggy": 0.85,
		"snout": 0.7,
		"body_color": Color(0.88, 0.81, 0.66),
		"belly_color": Color(0.93, 0.87, 0.72),
		"muzzle_color": Color(0.92, 0.86, 0.7),
		"eye_color": Color(0.32, 0.2, 0.12),
		"eye_size": 1.45,
		"ruff": true,
		"ruff_color": Color(0.93, 0.87, 0.72),
		"head_tuft": true,
		"beard": true,
		"leg_feathers": true,
		"blep": true,
		"ear": "dog_floppy",
		"tail": "fluffy",
		"speed": 5.6,
		"ability": "ferocious",    # buff: susto máximo contra invasores
		"cute": "belly_up",        # barriguinha pra cima
		"clumsy": false,
		"food_lover": false,       # pidona
		"scare_power": 1.2,
		"ability_cooldown": 9.0,
	},
	"zoe": {
		"id": "zoe",
		# Gata bagunceira que sobe em tudo e é medrosa. Visual do novo
		# design (folha de referência): tabby marrom com listras, peito e
		# patas brancos, olhos verdes e focinho rosa.
		"kind": "cat",
		"scale": 1.0,
		"flop_k": 0.35,
		"chubby": 1.3,
		"body_color": Color(0.63, 0.45, 0.3),
		"belly_color": Color(0.95, 0.93, 0.88),
		"muzzle_color": Color(0.85, 0.68, 0.45),
		"eye_color": Color(0.55, 0.75, 0.35),
		"eye_size": 1.15,
		"mottled": true,
		"tail_tip_color": Color(0.88, 0.85, 0.78),
		"ear": "cat",
		"tail": "thin",
		"speed": 4.8,
		"ability": "stealth",      # fica invisível parada; emboscada ao sair
		"cute": "play_ball",       # brinca com a bolinha perto dos donos
		"clumsy": true,
		"food_lover": true,
		"scare_power": 1.0,
		"ability_cooldown": 6.0,
	},
	"minerva": {
		"id": "minerva",
		# Gata preta, cara de mal mas carinhosa. Rápida, patada potente.
		# Visual das fotos reais: pantera em miniatura — preta lustrosa,
		# esguia, olhões amarelo-esverdeados, orelhonas pontudas, bigodes
		# brancos destacados e presinhas de deboche à mostra.
		"kind": "cat",
		"scale": 1.02,
		"flop_k": 0.35,
		"chubby": 0.9,
		"body_color": Color(0.08, 0.08, 0.09),
		"belly_color": Color(0.13, 0.13, 0.15),
		"muzzle_color": Color(0.12, 0.12, 0.13),
		"eye_color": Color(0.78, 0.78, 0.3),
		"eye_size": 1.2,
		"ear_size": 1.25,
		"whiskers": true,
		"fangs": true,
		"ear": "cat",
		"tail": "thin",
		"speed": 6.4,
		"ability": "pounce",       # patada forte + avanço rápido
		"cute": "leg_rub",         # se esfrega na perna dos donos
		"clumsy": false,
		"food_lover": false,
		"scare_power": 1.6,
		"ability_cooldown": 2.5,
	},
}


static func get_def(pet_id: String) -> Dictionary:
	return DEFS.get(pet_id, DEFS["sirius"])


static func next_pet(current: String, direction: int) -> String:
	var idx := ORDER.find(current)
	idx = wrapi(idx + direction, 0, ORDER.size())
	return ORDER[idx]
