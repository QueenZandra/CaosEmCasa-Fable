class_name House
extends Node3D
## Builds the whole low-poly house deterministically: floors, walls,
## garden, gate, furniture, knockable objects and food spots.
## Determinism matters: host and clients build the exact same arrays, so
## network events can reference objects by index.

const WALL_H := 2.2
const LOW_WALL_H := 1.0
const WALL_T := 0.3

# Cores
const COL_FLOOR := Color(0.87, 0.78, 0.65)
const COL_KITCHEN_FLOOR := Color(0.75, 0.82, 0.8)
const COL_WALL := Color(0.93, 0.88, 0.78)
const COL_GRASS := Color(0.45, 0.68, 0.35)
const COL_PATH := Color(0.75, 0.72, 0.65)
const COL_FENCE := Color(0.8, 0.75, 0.68)
const COL_SOFA := Color(0.35, 0.5, 0.65)
const COL_WOOD := Color(0.55, 0.4, 0.25)
const COL_SIDEWALK := Color(0.6, 0.6, 0.62)

var points := {}                      # pontos nomeados usados pelas fases
var knockables: Array[Knockable] = [] # índice = id de rede
var food_spots: Array[Vector3] = []
var sofa_pos := Vector3(-8.0, 0.0, 1.0)
var tree_positions: Array[Vector3] = [Vector3(-8, 0, 6.5), Vector3(8, 0, 6.5)]


func _ready() -> void:
	_build_ground()
	_build_walls()
	_build_garden()
	_build_living_room()
	_build_kitchen()
	_collect_points()


func _build_ground() -> void:
	# Piso interno (sala + cozinha)
	MeshLib.box(self, Vector3(24, 0.2, 12), COL_FLOOR, Vector3(0, -0.1, -3))
	# Sobrepõe piso da cozinha (lado leste)
	MeshLib.box(self, Vector3(12, 0.22, 12), COL_KITCHEN_FLOOR, Vector3(6, -0.09, -3))
	# Tapete da sala
	MeshLib.box(self, Vector3(4.5, 0.26, 3.2), Color(0.7, 0.35, 0.35), Vector3(-6, -0.06, -2))
	# Grama do jardim
	MeshLib.box(self, Vector3(28, 0.2, 7), COL_GRASS, Vector3(0, -0.1, 6.5))
	# Caminho da porta ao portão
	MeshLib.box(self, Vector3(2.0, 0.24, 7), COL_PATH, Vector3(0, -0.08, 6.5))
	# Calçada externa
	MeshLib.box(self, Vector3(28, 0.2, 3), COL_SIDEWALK, Vector3(0, -0.1, 11.5))
	# Colisor do chão inteiro
	MeshLib.collider_box(self, Vector3(40, 0.2, 40), Vector3(0, -0.1, 2))


func _wall(size: Vector3, pos: Vector3, color := COL_WALL) -> void:
	MeshLib.box(self, size, color, pos)
	MeshLib.collider_box(self, size, pos)


func _build_walls() -> void:
	# Parede de trás (norte, z=-9)
	_wall(Vector3(24 + WALL_T, WALL_H, WALL_T), Vector3(0, WALL_H / 2, -9))
	# Laterais
	_wall(Vector3(WALL_T, WALL_H, 12), Vector3(-12, WALL_H / 2, -3))
	_wall(Vector3(WALL_T, WALL_H, 12), Vector3(12, WALL_H / 2, -3))
	# Frente (z=3), baixa para a câmera ver dentro; vão da porta em x -1..1
	_wall(Vector3(11, LOW_WALL_H, WALL_T), Vector3(-6.5, LOW_WALL_H / 2, 3))
	_wall(Vector3(11, LOW_WALL_H, WALL_T), Vector3(6.5, LOW_WALL_H / 2, 3))
	# Parede interna (x=0) com vão em z -4..-2
	_wall(Vector3(WALL_T, WALL_H, 5), Vector3(0, WALL_H / 2, -6.5))
	_wall(Vector3(WALL_T, WALL_H, 5), Vector3(0, WALL_H / 2, 0.5))
	# Limites do lote (invisíveis)
	MeshLib.collider_box(self, Vector3(0.4, 3, 26), Vector3(-14.2, 1.5, 2))
	MeshLib.collider_box(self, Vector3(0.4, 3, 26), Vector3(14.2, 1.5, 2))
	MeshLib.collider_box(self, Vector3(30, 3, 0.4), Vector3(0, 1.5, 13.2))
	MeshLib.collider_box(self, Vector3(30, 3, 0.4), Vector3(0, 1.5, -9.4))


func _build_garden() -> void:
	# Cerca (z=10) com vão do portão em x -1.5..1.5
	_wall(Vector3(11.5, LOW_WALL_H, 0.2), Vector3(-7.25, LOW_WALL_H / 2, 10), COL_FENCE)
	_wall(Vector3(11.5, LOW_WALL_H, 0.2), Vector3(7.25, LOW_WALL_H / 2, 10), COL_FENCE)
	# Postes do portão
	MeshLib.box(self, Vector3(0.25, 1.4, 0.25), COL_WOOD, Vector3(-1.5, 0.7, 10))
	MeshLib.box(self, Vector3(0.25, 1.4, 0.25), COL_WOOD, Vector3(1.5, 0.7, 10))
	# Portão (visual, sempre fechado para os pets — bloqueia)
	MeshLib.box(self, Vector3(2.8, 0.9, 0.1), Color(0.5, 0.55, 0.6), Vector3(0, 0.55, 10))
	MeshLib.collider_box(self, Vector3(3.0, 1.2, 0.2), Vector3(0, 0.6, 10))
	# Cercas laterais do jardim
	_wall(Vector3(0.2, LOW_WALL_H, 7), Vector3(-14, LOW_WALL_H / 2, 6.5), COL_FENCE)
	_wall(Vector3(0.2, LOW_WALL_H, 7), Vector3(14, LOW_WALL_H / 2, 6.5), COL_FENCE)
	# Caixa de correio
	MeshLib.box(self, Vector3(0.18, 1.0, 0.18), COL_WOOD, Vector3(2.6, 0.5, 9.6))
	MeshLib.box(self, Vector3(0.45, 0.3, 0.3), Color(0.85, 0.25, 0.25), Vector3(2.6, 1.1, 9.6))
	# Árvores
	for tp in tree_positions:
		MeshLib.cylinder(self, 0.28, 1.8, Color(0.45, 0.32, 0.2), tp + Vector3(0, 0.9, 0))
		MeshLib.sphere(self, 1.3, Color(0.3, 0.55, 0.28), tp + Vector3(0, 2.4, 0))
		MeshLib.sphere(self, 0.9, Color(0.35, 0.6, 0.3), tp + Vector3(0.6, 1.9, 0.3))
		MeshLib.collider_box(self, Vector3(0.6, 2, 0.6), tp + Vector3(0, 1, 0))
	# Flores
	for i in 6:
		var fx := -12.0 + i * 4.6
		if absf(fx) < 2.0:
			continue
		MeshLib.sphere(self, 0.12, [Color(0.95, 0.5, 0.6), Color(0.95, 0.85, 0.4), Color(0.7, 0.5, 0.9)][i % 3], Vector3(fx, 0.12, 4.2))


func _build_living_room() -> void:
	# Sofá (destino das almofadas na fase 3)
	MeshLib.box(self, Vector3(3.6, 0.7, 1.4), COL_SOFA, sofa_pos + Vector3(0, 0.35, 0))
	MeshLib.box(self, Vector3(3.6, 0.8, 0.4), COL_SOFA.darkened(0.15), sofa_pos + Vector3(0, 0.75, 0.55))
	MeshLib.collider_box(self, Vector3(3.6, 1.2, 1.5), sofa_pos + Vector3(0, 0.6, 0.1))
	# Rack e TV
	MeshLib.box(self, Vector3(2.6, 0.5, 0.7), COL_WOOD, Vector3(-8, 0.25, -8.4))
	MeshLib.box(self, Vector3(2.2, 1.2, 0.12), Color(0.12, 0.12, 0.14), Vector3(-8, 1.2, -8.4))
	MeshLib.collider_box(self, Vector3(2.6, 1.6, 0.7), Vector3(-8, 0.8, -8.4))
	# Estante na parede oeste
	MeshLib.box(self, Vector3(0.5, 1.8, 2.6), COL_WOOD, Vector3(-11.5, 0.9, -3))
	MeshLib.collider_box(self, Vector3(0.5, 1.8, 2.6), Vector3(-11.5, 0.9, -3))
	# Mesinha lateral
	MeshLib.box(self, Vector3(0.8, 0.55, 0.8), COL_WOOD, Vector3(-5.5, 0.27, 1.8))
	MeshLib.collider_box(self, Vector3(0.8, 0.55, 0.8), Vector3(-5.5, 0.27, 1.8))
	# Caixa de brinquedos (tutorial)
	MeshLib.box(self, Vector3(1.0, 0.5, 0.7), Color(0.4, 0.6, 0.85), Vector3(-2.5, 0.25, -7.5))
	MeshLib.collider_box(self, Vector3(1.0, 0.5, 0.7), Vector3(-2.5, 0.25, -7.5))

	# Objetos deruráveis da sala
	_knock("vase", Vector3(-5.5, 0.55, 1.8))       # na mesinha
	_knock("books", Vector3(-11.1, 1.85, -3.4))    # na estante
	_knock("frame", Vector3(-11.1, 1.85, -2.4))
	_knock("lamp", Vector3(-3.2, 0.0, 1.6))
	_knock("vase", Vector3(-10.5, 0.0, -7.8))
	_knock("books", Vector3(-6.6, 0.0, -8.3))


func _build_kitchen() -> void:
	# Bancada ao longo da parede de trás
	MeshLib.box(self, Vector3(8, 0.9, 1.0), Color(0.65, 0.68, 0.72), Vector3(7, 0.45, -8.3))
	MeshLib.collider_box(self, Vector3(8, 0.9, 1.0), Vector3(7, 0.45, -8.3))
	# Geladeira
	MeshLib.box(self, Vector3(1.2, 2.0, 1.0), Color(0.85, 0.87, 0.9), Vector3(11.2, 1.0, -8.2))
	MeshLib.collider_box(self, Vector3(1.2, 2.0, 1.0), Vector3(11.2, 1.0, -8.2))
	# Mesa da cozinha
	MeshLib.cylinder(self, 1.1, 0.12, COL_WOOD, Vector3(6, 0.72, -2))
	MeshLib.cylinder(self, 0.12, 0.7, COL_WOOD.darkened(0.2), Vector3(6, 0.35, -2))
	MeshLib.collider_box(self, Vector3(2.0, 0.9, 2.0), Vector3(6, 0.45, -2))
	# Potes de comida dos pets (área de comida)
	MeshLib.cylinder(self, 0.3, 0.12, Color(0.8, 0.3, 0.3), Vector3(2.2, 0.06, 1.6))
	MeshLib.cylinder(self, 0.3, 0.12, Color(0.3, 0.5, 0.8), Vector3(3.2, 0.06, 1.6))

	# Objetos deruráveis da cozinha
	_knock("cup", Vector3(4.5, 0.9, -8.2))
	_knock("cup", Vector3(6.0, 0.9, -8.2))
	_knock("bottle", Vector3(8.5, 0.9, -8.2))
	_knock("cup", Vector3(5.6, 0.78, -1.6))
	_knock("bottle", Vector3(6.5, 0.78, -2.2))
	_knock("vase", Vector3(11.0, 0.0, -5.0))

	# Pontos de comida (índices determinísticos)
	food_spots = [
		Vector3(2.2, 0.12, 1.6),
		Vector3(3.2, 0.12, 1.6),
		Vector3(9.5, 0.9, -8.2),
		Vector3(6.0, 0.78, -2.4),
		Vector3(2.8, 0.0, -0.5),
	]


func _knock(kind: String, pos: Vector3) -> void:
	var k := Knockable.create(kind, pos)
	k.net_id = knockables.size()
	knockables.append(k)
	add_child(k)


func _collect_points() -> void:
	points = {
		"door_in": Vector3(0, 0, 2.0),
		"door_out": Vector3(0, 0, 4.0),
		"gate_in": Vector3(0, 0, 9.0),
		"gate_out": Vector3(0, 0, 11.0),
		"mailbox": Vector3(2.6, 0, 9.2),
		"sofa": sofa_pos + Vector3(0, 0.9, 0),
		"rug": Vector3(-6, 0, -2),
		"toy_box": Vector3(-2.5, 0.6, -7.5),
		"street_left": Vector3(-13, 0, 11.5),
		"street_right": Vector3(13, 0, 11.5),
		"kitchen_food": Vector3(2.7, 0, 1.2),
		"trees": tree_positions,
		"pet_spawns": [
			Vector3(-7, 0.2, -2), Vector3(-5, 0.2, -2),
			Vector3(-7, 0.2, -0.5), Vector3(-5, 0.2, -0.5),
		],
	}
