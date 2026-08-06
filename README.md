# 2D Warriors — protótipo estilo Sword of Mana

Projeto Godot 4: menu inicial → seleção de personagem (Guerreiro / Mago /
Arqueiro / Ladino) → mapa aberto com 4 biomas ligados por pontes.

## O mapa

O mundo tem 3060 × 2260 e é dividido em quatro ilhas com costa **orgânica**
(baías e penínsulas, geradas por ruído — não retângulos), separadas por mar
e ligadas por quatro pontes de madeira (dá pra dar a volta completa):

```
   Floresta  ═══ponte═══  Deserto
      ║                      ║
    ponte        mar       ponte
      ║                      ║
   Ruínas    ═══ponte═══  Caverna
```

Cada ilha tem uma **estrada de terra** ligando o ponto de partida/pontes até
o **marco** dela — um elemento único que ajuda a lembrar onde você está:

| Bioma    | Marco               | Cenário                | Inimigos                          |
|----------|---------------------|-------------------------|------------------------------------|
| Floresta | árvore ancestral gigante | árvores e arbustos em grupos | goblins, orcs, dragão verde |
| Deserto  | pirâmide            | areia e pedras          | esqueletos (dormentes), orcs, dragão vermelho |
| Ruínas   | templo desmoronado, com tochas | pedra cinza, colunas caídas | esqueletos, goblins, orc |
| Caverna  | cluster de cristais brilhantes | rocha escura + escurecimento por cima | dragões (dormentes até você chegar perto), esqueletos |

O jogador começa na Floresta. O HUD mostra em qual bioma ele está, um
minimapa no canto mostra a forma das 4 ilhas e sua posição, e a primeira
vez que você entra em cada bioma aparece uma fala de ambientação (com uma
segunda fala, mais inquietante, se você demorar lá).

Vegetação e pedras nascem em **grupos** (3 a 6 por vez), não espalhadas
uniformemente — e por cima entram detalhes pequenos e sem colisão (flor,
cogumelo, graveto, osso, musgo, pedrinha, cristalzinho) só pra o chão não
ficar vazio. O mar tem um shader simples animado (duas camadas de ruído
deslizando em velocidades diferentes, com uma crista de espuma esparsa).

## Como abrir

1. Abra o Godot 4 (4.3+).
2. **Import** → selecione o `project.godot` desta pasta.
3. F5 pra rodar (já começa pelo `scenes/ui/MainMenu.tscn`).

## Fluxo do jogo

`MainMenu` → botão **Start Game** → `CharacterSelect` (escolhe a classe,
botão **Confirmar**) → `Level1` (o mapa), já com a classe escolhida
spawnada.

## Controles

- **Setas** ou **WASD**: andar (8 direções).
- **Espaço**: atacar (toca a animação da classe e acerta os goblins que
  estiverem na área de ataque).

## Estrutura de pastas

```
DFantasyMap/
  project.godot
  autoload/
    game_manager.gd       <- singleton: classe escolhida + troca de cena
  scenes/
    ui/
      MainMenu.tscn
      CharacterSelect.tscn
    characters/
      Warrior.tscn         <- usa scripts/player_base.gd
      Mage.tscn             (idem)
      Archer.tscn            (idem)
    enemies/
      GoblinDummy.tscn      <- leva hit, "desmaia", reaparece
    levels/
      Level1.tscn           <- só o esqueleto; o mapa é montado por código
  scripts/
    player_base.gd          <- script único compartilhado pelas 3 classes
    goblin_dummy.gd
    level.gd                <- monta o mundo e spawna a classe escolhida
    world/
      world_builder.gd      <- monta tudo: chão, pontes, colisão, povoação
      terrain.gd             <- a grade do terreno (ruído, estradas, costa)
      landmarks.gd            <- os 4 marcos, desenhados por código
      minimap.gd               <- o minimapa do HUD
      water.gdshader             <- shader da água animada
    enemies/
      patrol_enemy.gd
    ui/
      main_menu.gd
      character_select.gd
  assets/
    tileset/, props/, icons/, units/<classe>/
```

## Como as 3 classes funcionam

As três cenas (`Warrior.tscn`, `Mage.tscn`, `Archer.tscn`) usam o **mesmo
script** (`player_base.gd`) — só muda o `SpriteFrames` (visual) e os
valores exportados (`speed`, `attack_animation`, `attack_duration`). Pra
criar uma classe nova no futuro, duplique uma dessas cenas, troque as
texturas do `AnimatedSprite2D` e ajuste os valores no Inspector — não
precisa mexer em código.

## Sobre os goblin dummies

O pack de assets enviado é estilo RTS (unidades por facção) e **não tem
sprite de goblin/monstro**. Usei a unidade "Warrior" da facção preta
(`Units/Black Units/Warrior`) como bonequinho de treino — visualmente é
um soldado, não um goblin, mas cumpre o papel de "alvo pra bater".

Cada dummy:
- tem 3 HP;
- pisca vermelho e mostra "-1" flutuando a cada hit;
- ao zerar o HP, fica cinza/derrubado e some da colisão;
- depois de 3 segundos, levanta e volta ao normal (respawn automático) —
  bom pra treinar sem precisar reiniciar a cena toda hora.

## Como mexer no mapa

Todo o mapa nasce de uma tabela só: a função `biomes()` em
`scripts/world/world_builder.gd`. Cada entrada tem as cores do chão, o
marco, as falas de ambientação, quais props/detalhes espalhar e quantos
inimigos de cada tipo (e quais nascem "dormentes"):

```gdscript
{
    "id": "forest",
    "label": "Floresta",
    "ground": Color(0.24, 0.42, 0.20),
    "landmark": "giant_tree",
    "flavor_enter": "Você entrou na Floresta Ancestral.",
    "props": {"tree": 26, "bush": 15, "rock1": 4, "outcrop": 2},
    "details": {"flower": 22, "mushroom": 10, "twig": 8},
    "enemies": {"goblin": 4, "orc": 2, "dragon_green": 1},
    "dormant_enemies": [],
}
```

Mudar um número ali já muda o mapa — o formato da ilha, a estrada, a
colisão do mar e a faixa de praia saem calculados. **Não precisa abrir
nenhum `.tscn`** pra reequilibrar um bioma.

O tamanho de cada quadrante, a largura do canal de mar e a largura das
pontes são as constantes no topo do mesmo arquivo. A semente (`MAP_SEED`)
é fixa, então o mapa sai idêntico toda vez — troque o número pra gerar
outro arranjo (o ruído desenha uma ilha diferente, mas a estrada sempre
garante que o marco, o spawn e as pontes fiquem conectados).

## Detalhes técnicos que valem saber

- **Terreno = grade + ruído, não retângulos.** `scripts/world/terrain.gd`
  guarda o mundo como uma grade de células de 6px (água/terra/areia/
  estrada) desenhada com `FastNoiseLite`; um "recuo radial" garante que a
  ilha não encoste na vizinha, e um flood-fill (`_keep_main_landmass`)
  descarta qualquer pedaço de terra que o ruído tenha deixado solto, sem
  ligação com o resto da ilha.
- **Estradas "furam" a costa de propósito.** Pontos que precisam ser terra
  de qualquer jeito (o spawn, o marco, a boca de cada ponte) são forçados
  antes do flood-fill (`_force_land`); a estrada entre eles (`_carve_road`)
  também força terra ao redor, com uma curva leve no meio pra não sair
  reta. É isso que garante o "caminho natural" — e também por que ele nunca
  fica cortado pela água.
- **Vegetação em grupos:** `_scatter_clustered` sorteia um centro de grupo
  e espalha 3–6 itens ao redor dele (distribuição gaussiana), em vez de
  jogar pontos uniformemente no mapa inteiro.
- **Textura do chão é "assada" uma vez:** `Terrain.bake()` roda por toda a
  grade e gera uma única imagem (célula → pixel), com variação de tom via
  um segundo ruído e uns pontinhos (specks) aleatórios — bem mais barato
  que um `Polygon2D` por ilha.
- **Ordem de desenho (y-sort):** props, marcos, inimigos e jogador ficam
  todos no nó `Entities`, que tem `y_sort_enabled`. Quem está mais embaixo
  na tela desenha por cima, então o personagem passa *atrás* das árvores.
  Por isso a posição de cada nó é o **pé** dele, e o sprite é deslocado pra
  cima — não o contrário.
- **Colisão do mundo:** `Terrain.collision_rects()` funde blocos de 3×3
  células de água num punhado de retângulos grandes (algoritmo guloso:
  estica pra direita, depois pra baixo) — muito mais barato que uma forma
  de colisão por célula.
- **Inimigo longe não gasta frame:** cada um leva um
  `VisibleOnScreenEnabler2D`, que desliga o `_physics_process` dele até a
  câmera chegar perto.
- **Dano por encostar:** o inimigo acompanha quem está encostado pelos
  sinais `body_entered`/`body_exited` da `Area2D`, em vez de varrer as
  colisões todo frame.
- **Inimigo "dormente":** `patrol_enemy.gd` tem `dormant`/`wake_radius` —
  fica parado até o jogador (grupo `"player"`) chegar perto, aí acorda pra
  sempre. Usado nos dragões da Caverna e nos esqueletos do Deserto.

## O que ficou fora (sem assets/sistema pra isso)

Um brainstorm em cima deste mapa pediu música e som ambiente por bioma,
NPCs (mercador, ferreiro, curandeiro), pontos de interesse (baú, estátua,
fogueira) e iluminação dinâmica de verdade (luz/sombra). Nada disso entrou
porque:
- **não existe nenhum arquivo de áudio no projeto** — eu não componho
  música nem gero efeito sonoro, só código;
- **não existe sprite de NPC, baú ou estátua** no pacote de assets — os 4
  marcos (árvore, pirâmide, templo, cristais) foram desenhados por código
  com formas geométricas (`Polygon2D`/`Line2D`) por não ter arte pronta, e
  isso já é bem mais trabalhoso de ampliar do que reaproveitar textura;
- **iluminação dinâmica de verdade** (`Light2D`/`CanvasModulate` escurecendo
  o mundo pra tochas brilharem) mudaria o visual do jogo inteiro e não é
  uma decisão que dá pra tomar sozinho — o que existe hoje é uma "auréola"
  aditiva (`Landmarks._glow`) simulando brilho sem escurecer nada ao redor.

Também simplifiquei o pedido de "esqueleto enterrado que levanta" e "dragão
dormindo": mecanicamente os dois usam o mesmo `dormant` (ficam parados até
você chegar perto), mas **visualmente não mudam de pose** — não tem sprite
de "esqueleto enterrado" no pacote, só o sprite normal parado.

## Limitações conhecidas (é um protótipo)

- O Guerreiro e o Ladino batem numa área circular ao redor do corpo; só o
  Arqueiro tem projétil de verdade (`Arrow.tscn`). O Mago ainda usa a
  animação "Heal" do pack como visual de "conjurar".
- Os personagens só têm sprite "de frente" (sem 4 direções reais); viram
  só com espelhamento horizontal.
- Os inimigos (exceto os dormentes) patrulham um caminho fixo (linha,
  quadrado ou círculo) e machucam por encostar — nenhum persegue o
  jogador de verdade.
- Sem objetivo, item ou saída: o jogo ainda é "explore e bata".

## Ideias pra próximo upgrade

- Um inimigo que persegue o jogador de verdade (não só patrulha fixa).
- Bola de energia pro Mago (o Arqueiro já tem flecha).
- Música e som ambiente por bioma (precisa de arquivos de áudio, que o
  projeto ainda não tem).
- NPCs e algum objetivo — chave/baú em cada bioma, ou um chefe na Caverna
  (precisa de sprites que o asset pack não inclui).
- Iluminação dinâmica de verdade (`Light2D`), pra tochas e cristais
  brilharem contra um mundo escurecido de verdade.
