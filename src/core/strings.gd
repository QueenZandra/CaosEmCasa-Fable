class_name Strings
## Todos os textos do jogo em PT-BR, centralizados.
## O código do jogo é em inglês; os textos exibidos ficam aqui.

const GAME_TITLE := "Caos em Casa"
const SUBTITLE := "Sirius, Belatriz, Zoe e Minerva contra o mundo"

# ---- Menu principal ----
const MENU_LOCAL := "Jogar Local"
const MENU_ONLINE := "Jogar Online"
const MENU_QUIT := "Sair"

# ---- Lobby local ----
const PRESS_TO_JOIN := "Aperte A (ou Espaço) para entrar"
const PICK_PET := "◀ ▶  escolher pet   |   A confirmar"
const READY := "Pronto!"
const PRESS_START := "Aperte Start (ou Enter) para começar"
const SLOT_KEYBOARD := "Teclado"
const SLOT_GAMEPAD := "Controle %d"

# ---- Online ----
const ONLINE_TITLE := "Jogar Online"
const HOST_RELAY := "Criar sala (código)"
const JOIN_RELAY := "Entrar com código"
const HOST_LAN := "Criar jogo LAN"
const JOIN_LAN := "Entrar por IP"
const RELAY_URL_LABEL := "Servidor relay:"
const ROOM_CODE_LABEL := "Código da sala:"
const IP_LABEL := "IP do host:"
const BACK := "Voltar"
const CONNECTING := "Conectando..."
const CONNECTION_FAILED := "Falha na conexão"
const ROOM_CODE_IS := "Código da sala: %s"
const LAN_HOST_INFO := "Aguardando jogadores na porta %d"
const WAITING_HOST := "Aguardando o anfitrião começar..."
const START_GAME := "Começar!"
const PLAYER_N := "Jogador %d"
const DISCONNECTED := "Desconectado do jogo"

# ---- Pets ----
const PET_NAMES := {
	"sirius": "Sirius",
	"belatriz": "Belatriz",
	"zoe": "Zoe",
	"minerva": "Minerva",
}
const PET_TAGLINES := {
	"sirius": "Latido Potente — protetor e estabanado",
	"belatriz": "Modo Feroz — pequena e valente",
	"zoe": "Escalada Fantasma — bagunceira invisível",
	"minerva": "Patada Potente — rápida e implacável",
}

# ---- HUD ----
const HUD_TIME := "Tempo"
const HUD_MESS := "Bagunça"
const HUD_RAGE := "Raiva dos Donos"
const HUD_WAVE := "Onda %d/%d"
const GO := "JÁ!"
const LEVEL_CLEAR := "Fase concluída!"
const LEVEL_FAILED := "Ah não! Tentem de novo..."
const PAUSED := "Pausado"

# ---- Fases ----
const LEVEL_TITLES := {
	1: "Fase 1 — A Despedida",
	2: "Fase 2 — O Carteiro",
	3: "Fase 3 — Rebelião das Almofadas",
	4: "Fase 4 — Jardim sob Ataque",
	5: "Fase 5 — A Invasão",
	6: "Fase 6 — Os Donos Chegaram",
}
const LEVEL_GOALS := {
	1: "Os donos estão saindo! Aprendam seus poderes: sigam as tarefas.",
	2: "Não deixem o carteiro entregar as encomendas! Assustem ele.",
	3: "As almofadas fugiram! Capturem e devolvam todas ao sofá.",
	4: "Espantem os passarinhos das árvores e os bichos do portão!",
	5: "Invasores querem roubar a comida! Defendam a casa!",
	6: "Limpem TUDO e façam fofuras para acalmar os donos!",
}

# ---- Tutorial (fase 1) ----
const TUT_TASK_MOVE := "Todos: andem até o tapete da sala"
const TUT_TASK_CARRY := "Peguem um brinquedo (A) e levem até a caixa"
const TUT_TASK_ABILITY := "Usem a habilidade especial (X) uma vez cada"
const TUT_TASK_CLEAN := "Limpem a bagunça (segurem A perto dela)"
const OWNERS_LEAVING := "Tchau, filhotes! Se comportem!"

# ---- Fase 6 ----
const OWNERS_ARRIVED := "MAS O QUE ACONTECEU AQUI?!"
const RAGE_EXPLODED := "Os donos perderam a paciência..."
const HOUSE_CLEAN := "A casa está limpa! Os donos perdoaram vocês!"
const CUTE_HINT := "X perto dos donos = fofura (revezem os pets!)"

# ---- Resultados ----
const RESULTS_TITLE := "Resultado"
const SCORE := "Pontos: %d"
const MESS_MADE := "Bagunça deixada: %d"
const CONTINUE := "Continuar"
const RETRY := "Tentar de novo"
const CAMPAIGN_DONE := "Vocês salvaram o dia! Os pets são os heróis da casa!"

# ---- Ameaças (nomes para mensagens) ----
const THREAT_NAMES := {
	"mailman": "Carteiro",
	"pillow": "Almofada rebelde",
	"bird": "Passarinho",
	"gate_dog": "Cachorro no portão",
	"gate_cat": "Gato no portão",
	"rat": "Rato",
	"opossum": "Gambá",
	"armadillo": "Tatu",
}

static func pet_name(id: String) -> String:
	return PET_NAMES.get(id, id)
