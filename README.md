# 🐾 Caos em Casa

Jogo 3D cooperativo (1–4 jogadores) estilo *Overcooked*, estrelado por quatro pets reais:

| Pet | Quem é | Habilidade de defesa (X) | Fofura na fase final (X) |
|---|---|---|---|
| **Sirius** 🐕 | Cão médio, peludo e preto; protetor e estabanado | **Latido Potente** — assusta ameaças em área (mas derruba coisas!) | **Bom Menino** — senta balançando o rabinho |
| **Belatriz** 🐕 | Cadela pequena e dourada, de olhos pidões | **Modo Feroz** — susto máximo contra invasores | **Barriguinha** — vira de barriga pra cima |
| **Zoe** 🐈 | Gata rajada preto/laranja, gorda e bagunceira | **Escalada Fantasma** — fica invisível e embosca | **Hora de Brincar** — brinca com a bolinha |
| **Minerva** 🐈‍⬛ | Gata preta de cara de mal, mas carinhosa | **Patada Potente** — golpe forte + avanço rápido | **Esfregadinha** — se esfrega na perna dos donos |

## A história

Os donos saem para trabalhar e os pets ficam de guarda. Durante o dia eles
defendem a casa do **carteiro**, da **rebelião das almofadas**, dos
**passarinhos** fazendo ninho, dos **bichos no portão** e da **invasão de
ratos, gambás e tatus** — bagunçando tudo no processo. Na última fase os
donos chegam **furiosos**: é preciso limpar a casa e revezar fofuras para
baixar a raiva antes que ela estoure!

## Fases

1. **A Despedida** — tutorial: aprendam os comandos enquanto os donos saem.
2. **O Carteiro** — não deixem as encomendas serem entregues.
3. **Rebelião das Almofadas** — capturem as almofadas e devolvam ao sofá.
4. **Jardim sob Ataque** — espantem passarinhos das árvores e bichos do portão.
5. **A Invasão** — protejam a comida de ratos, gambás e tatus.
6. **Os Donos Chegaram** — limpem tudo + fofuras para acalmar os donos.

A bagunça deixada nas fases 2–5 **acumula** e aumenta a dificuldade da fase 6.
Cada fase dá até ★★★.

## Como rodar

1. Instale o [Godot 4.5+](https://godotengine.org/download) (versão padrão, gratuita).
2. Abra o Godot → **Importar** → selecione o `project.godot` deste repositório.
3. Aperte **F5** (Play).

> Os gráficos são 100% procedurais (primitivas low-poly) — não há assets para
> baixar. As malhas dos pets ficam isoladas em `src/player/pet_body.gd` para
> serem substituídas futuramente por modelos baseados nas fotos reais.

## Controles

| Ação | Controle (Xbox/genérico) | Teclado (jogador 1) |
|---|---|---|
| Mover | Analógico esquerdo / D-pad | WASD ou setas |
| Interagir: pegar/soltar, **segurar para limpar** | A | Espaço |
| Habilidade especial / Fofura (fase 6) | X | E |
| Corridinha (dash) | B | Shift |
| Entrar no lobby / Começar | A / Start | Espaço / Enter |

## Jogo local (até 4 no sofá)

Menu → **Jogar Local** → cada jogador aperta **A** no seu controle (ou Espaço
no teclado) → escolhe o pet com ◀ ▶ → confirma com A → **Start** para começar.
Todos jogam na mesma tela.

## Jogo online

O online usa um **servidor relay** com código de sala (funciona sem abrir
portas no roteador). Também há modo **LAN/IP direto** sem servidor nenhum.

### 1. Subir o relay (uma vez, em qualquer máquina/serviço com Node.js)

```bash
cd relay
npm install
node server.js          # porta 9080 por padrão
```

Hospede em qualquer serviço gratuito de Node (Render, Fly.io, Railway...) ou
numa máquina com IP acessível. Anote a URL, ex.: `ws://meuservidor:9080`.

### 2. Jogar

- **Anfitrião**: Menu → Jogar Online → confira a URL do relay → **Criar sala
  (código)** → compartilhe o código de 6 letras.
- **Convidados**: Menu → Jogar Online → digitem o código → **Entrar com código**.
- Cada um escolhe seu pet, marca **Pronto**, e o anfitrião dá o **Começar!**

Na **LAN** (mesma rede): o anfitrião usa **Criar jogo LAN** e informa seu IP
local aos convidados (**Entrar por IP**), sem relay.

> Arquitetura: host-autoritativo — o anfitrião simula o jogo; os convidados
> enviam inputs e recebem snapshots a 20 Hz (`src/net/`). O relay
> (`relay/server.js`) apenas encaminha pacotes entre os jogadores da sala.

## Estrutura do código

```
src/
  autoload/    game_state, net (sessão), audio_manager (SFX procedurais)
  core/        input_poller (4 controles + teclado), meshlib, strings PT-BR
  net/         transport (base), enet_transport (LAN), relay_transport (código)
  player/      pet, pet_body (malha low-poly), pet_defs (os 4 pets)
  threats/     threat (FSM base), mailman, pillow, bird, gate_animal, invader
  world/       house (construção procedural), knockable, mess_spot, food, owners
  levels/      level_base (sim + rede) e as 6 fases
  ui/          menu, lobbies, hud, resultados
relay/         servidor de salas Node.js (ws)
```

## Testes

- Sintaxe GDScript: `pip install gdtoolkit && find . -name "*.gd" | xargs gdparse`
- Relay: `node relay/server.js &` e depois `node relay/test.js` (cria sala,
  entra com código, troca pacotes binários e valida o encerramento)
