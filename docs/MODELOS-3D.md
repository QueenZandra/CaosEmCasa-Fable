# 🎨 Modelos 3D dos pets — guia de geração e importação

O jogo carrega automaticamente modelos profissionais em `.glb` — basta
colocar os arquivos na pasta certa. Enquanto um pet não tiver `.glb`, ele usa
o modelo procedural embutido como reserva.

## Passo 1 — Gerar os modelos a partir das suas folhas de design

Suas folhas de design (vista frontal + lateral + traseira de cada pet) são o
insumo **perfeito** para ferramentas de IA imagem→3D:

| Ferramenta | Site | Plano gratuito |
|---|---|---|
| **Meshy** | meshy.ai | ~200 créditos/mês (dá para os 4 pets) |
| **Tripo3D** | tripo3d.ai | créditos gratuitos ao criar conta |

Para cada pet:

1. Crie uma tarefa **Image to 3D**.
2. Envie a folha de design do pet. Se a ferramenta aceitar múltiplas imagens
   (Meshy aceita), **recorte e envie as 3 vistas separadas** (frontal,
   lateral, traseira) — o resultado fica muito mais fiel.
3. Escolha estilo **low-poly / stylized** se houver a opção.
4. Se a ferramenta oferecer **rigging/animação** (Meshy tem "Animate", com
   ciclos de andar/correr/idle para quadrúpedes), aplique — o jogo usa essas
   animações automaticamente. Sem rigging também funciona (o jogo anima o
   modelo inteiro proceduralmente).
5. Exporte/baixe como **GLB**.

## Passo 2 — Colocar no jogo

Renomeie os arquivos e coloque em `assets/pets/`:

```
assets/pets/sirius.glb
assets/pets/belatriz.glb
assets/pets/zoe.glb
assets/pets/minerva.glb
```

Abra o projeto no Godot (ele importa os .glb sozinho) e aperte F5. Pronto.

## O que o jogo faz sozinho

- **Escala e chão**: o modelo é redimensionado para a altura padrão do pet e
  alinhado com as patas no chão (não precisa ajustar nada no export).
- **Orientação**: modelos glTF costumam olhar para −Z; o jogo vira 180° por
  padrão. Se algum pet andar de costas, adicione `"model_yaw": 0.0` no bloco
  dele em `src/player/pet_defs.gd`.
- **Animações**: se o `.glb` tiver animações, o jogo mapeia por nome
  (walk/run → andar, idle → parado, sit → sentar, attack → habilidades,
  roll/lie → barriguinha...). O que não tiver animação própria usa as poses
  procedurais (inclinar, achatar, girar) aplicadas ao modelo inteiro.
- **Camuflagem da Zoe**: o efeito fantasma funciona em qualquer modelo.

## Dicas

- Gere **um pet por vez** e teste no jogo antes do próximo.
- Se o modelo vier com base/pedestal, use a opção de remover fundo/base da
  ferramenta (ou peça "no base" no prompt).
- Guarde também o arquivo fonte da ferramenta (permite re-exportar).
- Commit dos `.glb` no repositório: pode, são pequenos (1–10 MB).

## Se quiser ainda mais controle depois

Os `.glb` abrem no **Blender** — dá para retocar cores, suavizar partes ou
ajustar proporções e re-exportar com o mesmo nome, sem mexer em código.
