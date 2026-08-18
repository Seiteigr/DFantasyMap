# 2D Warriors — protótipo estilo Sword of Mana

Projeto Godot 4: menu inicial → seleção de personagem (Guerreiro / Clérigo /
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

| Bioma    | Marco               | Cenário                | Inimigos                          | Dificuldade |
|----------|---------------------|-------------------------|------------------------------------|-------------|
| Floresta | árvore ancestral gigante | árvores e arbustos em grupos | goblins, orcs, dragão verde | 1.0x (bioma inicial) |
| Ruínas   | templo desmoronado, com tochas | pedra cinza, colunas caídas | esqueletos, goblins, orc | 1.2x |
| Deserto  | pirâmide            | areia e pedras          | esqueletos (dormentes), orcs, dragão vermelho | 1.4x |
| Caverna  | cluster de cristais brilhantes | rocha escura + escurecimento por cima | dragões (dormentes até você chegar perto), esqueletos | 1.7x (mais puxado) |

A "Dificuldade" multiplica o dano de contato de todo inimigo daquele bioma
(campo `"difficulty"` em `biomes()`, `scripts/world/world_builder.gd`) — o
mesmo esqueleto machuca mais na Caverna do que na Floresta.

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
- **K**: abre/fecha a janela de **Status**.
- **I**: abre/fecha o **Inventário**.
- **L**: abre/fecha a janela de **Habilidades** (desbloquear skill).
- **1 / 2 / 3 / 4**: ativa a habilidade desbloqueada nesse slot (a ordem é
  sempre a mesma da janela de Habilidades).
- **E**: interage com o mercador (abre/fecha a **Loja**) quando você está
  perto dele.

## Status, inventário e loja (estilo Ragnarok Online)

O personagem tem nível, XP, HP e mana, além de **3 atributos simplificados**
(em vez dos 6 clássicos de RO) — cada ponto de nível dá 3 pontos livres pra
distribuir:

| Atributo | Efeito |
|----------|--------|
| Magia    | aumenta a mana máxima e o dano de feitiço |
| Colosso  | aumenta o HP máximo (substitui os corações fixos de antes) |
| Destreza | aumenta a velocidade de movimento |

Tudo isso mora no autoload `PlayerStats` (`autoload/player_stats.gd`) —
`GameManager` ficou só com a navegação de cena. O HUD mostra HP/mana como
barra em vez dos 4 corações antigos (`scripts/ui/hearts_hud.gd`), e a janela
de status (`scenes/ui/StatusWindow.tscn`) tem um botão "+" por atributo.

Itens e ouro (Gold Coin) moram no autoload `InventoryManager`
(`autoload/inventory_manager.gd`); a tabela de itens em si —
nome/cor/preço/stack máximo — fica centralizada em `ItemDatabase`
(`scripts/items/item_database.gd`), no mesmo espírito da tabela de biomas.
**Não existe sprite de ícone pra item no pacote de assets**, então cada item
usa uma cor + as duas primeiras letras do nome como placeholder visual, no
inventário e no chão.

Cada inimigo (menos os bonecos de treino goblin, que só desmaiam e
respawnam) solta itens e gold ao morrer, numa tabela por tipo em
`scripts/enemies/patrol_enemy.gd` (`DROP_TABLE`):

| Inimigo | Sempre dropa | Chance extra |
|---------|--------------|---------------|
| Esqueleto | 1–2 Ossos + gold | 10% de Joia |
| Dragão (verde/vermelho) | 1 Couro de Dragão + gold | 30% de Joia |
| Orc | gold | — |

Um NPC mercador (`scenes/npc/Merchant.tscn`) fica perto do início da
Floresta — chegue perto e aperte **E** pra abrir a loja
(`scenes/ui/Shop.tscn`), onde dá pra comprar Poção de Vida e vender os
itens que os monstros deixaram, por gold.

**Fora do escopo por enquanto:** sistema de craft (fica pra depois) e um
monstro morcego pras pirâmides do Deserto — falta um sprite animado, que o
pacote de assets atual não tem (ver "O que ficou fora" abaixo).

## Povoados

Cada uma das 4 ilhas tem um pequeno povoado perto do marco, ligado por
estrada como o resto do mapa: `scripts/world/villages.gd` monta casas/tendas
e uma "criatura mascote" que vagueia por perto, sempre tingida numa cor
diferente por bioma:

| Bioma | Construções | Cor da criatura |
|-------|-------------|-------------------|
| Floresta | 3 casas + poço | verde |
| Deserto | 3 tendas + poço | areia |
| Ruínas | 2 casas + baú (abandonado, sem morador) | cinza |
| Caverna | 2 barracas + casa + poço | roxo |

**Isso depende de assets de terceiros que NÃO estão no git** (ver
"Assets externos" abaixo). Sem eles, `villages.gd` desenha um placeholder
por código — casinha simples (parede + telhado) e a criatura vira uma bolha
colorida — pra ninguém abrir o projeto do zero e ver um buraco no mapa onde
devia ter povoado.

Vale registrar uma limitação honesta: só existe **uma espécie** de criatura
animada nos pacotes gratuitos que baixamos (um slime, do Characters
Animations Asset Pack) — a "variedade temática" pedida vem da cor, não de
bichos diferentes de verdade (não achamos vaca/galinha/camelo de graça em
nenhum pacote). Se algum dia entrar um pacote com bicho de fazenda de
verdade, é só estender `VILLAGE_DEFS` em `villages.gd`.

## Assets externos (não estão no repositório)

Além do pacote de unidades RTS que já vinha com o projeto, usamos 4 pacotes
gratuitos de terceiros pra montar os povoados. Todos têm licença que
**proíbe redistribuição** (mesmo as versões grátis) — como este repositório
é público e didático, os arquivos ficam só na máquina de quem desenvolve,
nunca no git (`assets_external/` e `assets/village/` estão no
`.gitignore`). Pra ter o povoado "de verdade" (em vez do placeholder por
código), baixe e credite:

| Pacote | Link | Usado pra |
|--------|------|-----------|
| Mystic Woods | https://game-endeavor.itch.io/mystic-woods | (baixado, ainda não usado no mapa) |
| Sprout Lands - UI Pack | https://cupnooble.itch.io/sprout-lands-ui-pack | (baixado, ainda não usado na UI) |
| Pixelwood Valley | https://gowldev.itch.io/pixelwood-valley | casas, tendas, poço, baú dos povoados |
| Characters Animations Asset Pack | https://oboropixel.itch.io/characters-animations-asset-pack | criatura mascote (slime) e NPC genérico animados |

Depois de baixar, extraia e copie os arquivos usados pra dentro de
`assets/village/houses/` e `assets/village/critters/` com os nomes que
`scripts/world/villages.gd` espera (`house_1.png`, `well_1.png`,
`slime_idle.png` etc. — veja `BUILDING_META` e os `load()` no script pra
lista completa).

## Plugin de desenvolvimento: Godot MCP Pro

O `addons/godot_mcp/` (plugin pago, licença proprietária) também está fora
do git pelo mesmo motivo de licença — é ferramenta de desenvolvimento, não
faz parte do jogo em si. Já vem habilitado em `project.godot`
(`[editor_plugins]`), mas falta a metade Node.js (pasta `server/`, que roda
`npm install && npm run build` e conecta via `.mcp.json`) — esse pedaço só
vem no pacote completo do itch.io, então é preciso estar logado na conta
que comprou pra baixar de novo.

## Estrutura de pastas

```
DFantasyMap/
  project.godot
  autoload/
    game_manager.gd       <- singleton: classe escolhida + troca de cena
    player_stats.gd        <- singleton: nível, XP, HP/mana, atributos, buffs
    inventory_manager.gd    <- singleton: itens carregados + gold
    skill_manager.gd          <- singleton: skill desbloqueada + cooldown
  scenes/
    ui/
      MainMenu.tscn
      CharacterSelect.tscn
      StatusWindow.tscn      <- janela de status (tecla K)
      Inventory.tscn          <- janela de inventário (tecla I)
      Shop.tscn                 <- loja do mercador (tecla E perto dele)
      SkillTree.tscn              <- árvore de skill da classe (tecla L)
    characters/
      Warrior.tscn         <- usa scripts/player_base.gd, class_id "warrior"
      Mage.tscn              (idem, é o Clérigo, class_id "cleric")
      Archer.tscn             (idem, class_id "archer")
      Rogue.tscn                (idem, class_id "rogue")
    enemies/
      GoblinDummy.tscn      <- leva hit, "desmaia", reaparece
    items/
      ItemDrop.tscn          <- item largado no chão por um inimigo morto
    npc/
      Merchant.tscn           <- NPC mercador, desenhado por código
    levels/
      Level1.tscn           <- só o esqueleto; o mapa é montado por código
  scripts/
    player_base.gd          <- script único compartilhado pelas 4 classes
    goblin_dummy.gd
    level.gd                <- monta o mundo e spawna a classe/mercador
    world/
      world_builder.gd      <- monta tudo: chão, pontes, colisão, povoação,
                                difficulty por bioma
      terrain.gd             <- a grade do terreno (ruído, estradas, costa)
      landmarks.gd            <- os 4 marcos, desenhados por código
      villages.gd               <- povoados por bioma (ver seção própria)
      minimap.gd                  <- o minimapa do HUD
      water.gdshader                <- shader da água animada
    enemies/
      patrol_enemy.gd          <- drop/XP por tipo, perseguição e respawn
    items/
      item_database.gd          <- tabela central de itens (nome/cor/preço)
      item_drop.gd                <- item no chão, coletável pelo jogador
    npc/
      merchant.gd
    skills/
      skill_database.gd          <- tabela central das 4 skills por classe
      skill_effects.gd              <- aplica cada tipo de efeito de skill
    village/
      village_critter.gd             <- bicho animado do povoado
      village_critter_placeholder.gd  <- fallback sem asset externo
    ui/
      main_menu.gd
      character_select.gd
      hearts_hud.gd            <- barra de HP/mana + nível
      status_window.gd
      inventory_window.gd
      shop_window.gd
      skill_tree_window.gd
  assets/
    tileset/, props/, icons/, units/<classe>/
    village/  <- fora do git, ver seção "Assets externos"
```

## Como as 4 classes funcionam

As quatro cenas (`Warrior.tscn`, `Mage.tscn`, `Archer.tscn`, `Rogue.tscn`)
usam o **mesmo script** (`player_base.gd`) — só muda o `SpriteFrames`
(visual) e os valores exportados (`speed`, `attack_animation`,
`attack_duration`, e agora também `class_id`, que é a chave usada pra achar
as 4 habilidades da classe em `SkillDatabase.SKILLS`). Pra criar uma classe
nova no futuro, duplique uma dessas cenas, troque as texturas do
`AnimatedSprite2D`, ajuste os valores no Inspector e dê um `class_id` novo
— não precisa mexer em código do personagem em si.

`Mage.tscn` hoje é a cena do **Clérigo** — o nome do arquivo ficou do jeito
antigo (era rotulado "Mago"), mas o texto/seleção já mostra "Clérigo" em
todo canto. Um Feiticeiro/Mago de dano de verdade é item futuro: a árvore
de skill dele já existe em `SkillDatabase.SKILLS["mage"]` (Rajada de Fogo,
Parede de Pedra, Nevasca, Recuperação Arcana), só falta sprite — o pacote
de assets atual não tem um segundo personagem arcano.

## Combate: perseguição, respawn e habilidades

- **Perseguição:** todo inimigo de `patrol_enemy.gd` (orc, esqueleto,
  dragões) larga a patrulha fixa e vai direto pro jogador assim que ele
  entra no raio `aggro_radius` (160px por padrão). Se o jogador fugir mais
  que `leash_radius` (320px) — ou sumir da árvore —, o inimigo desiste e
  volta a patrulhar a partir de onde parou.
- **Respawn:** ao morrer, o inimigo some por `respawn_time` (20s por
  padrão) e reaparece no ponto onde nasceu, com HP cheio — mesma ideia do
  boneco de treino (goblin dummy), só que sem o "desmaiado", ele já some e
  volta pronto.
- **Habilidades:** cada classe tem 4 skills (tecla **L** abre a árvore,
  teclas **1-4** ativam). Ganha 1 ponto de skill por level up — **separado**
  dos 3 pontos de atributo que já existiam —, e cada skill custa 1 ponto
  pra desbloquear (sem rank, é só "ligado" ou não) e gasta mana + tem
  cooldown pra ativar.

| Guerreiro | Clérigo | Arqueiro | Ladino |
|-----------|---------|----------|--------|
| Golpe Explosivo — 2x alcance e 2x dano num só golpe | Cura Maior — recupera boa parte do HP | Tiro Múltiplo — 3 flechas em leque | Facada Furtiva — dano bem maior que o normal |
| Lâmina de Vento — 10s: cada acerto solta um rasante extra (2x dano, mais alcance) | Luz Purificadora — dano em cone à frente | Tiro Perfurante — atravessa vários inimigos | Passo das Sombras — dash curto que atropela quem estiver no caminho |
| Corpo Fechado — cura metade do HP; 10s mais lento, 2x dano causado, menos dano recebido | Bênção de Vigor — 12s de +HP máximo e menos dano recebido | Chuva de Flechas — área que recebe flechas por um tempo | Veneno Cortante — 10s: golpes aplicam veneno (dano contínuo) |
| Investida — avança atropelando quem estiver no caminho | Aura Radiante — pulsa dano ao redor por 6s | Passo Ágil — dash pra trás + pique de velocidade | Evasão — invulnerabilidade breve |

A tabela completa (custo de mana, cooldown, parâmetro de cada efeito) está
em `scripts/skills/skill_database.gd`; quem interpreta o campo `"effect"` de
cada skill e aplica de verdade é `scripts/skills/skill_effects.gd` — um
handler genérico por tipo de efeito (`melee_burst`, `buff`, `dash_attack`,
`pulse_aoe`, `ground_aoe_zone`, `multi_projectile` etc.), não um script por
skill. Pra adicionar uma skill nova, geralmente basta uma entrada na tabela
usando um efeito que já existe.

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
  Arqueiro tem projétil de verdade (`Arrow.tscn`). O Clérigo ainda usa a
  animação "Heal" do pack como visual de "conjurar".
- Os personagens só têm sprite "de frente" (sem 4 direções reais); viram
  só com espelhamento horizontal — as skills de dash/mira usam só essa
  direção horizontal também.
- Dash de skill (Investida, Passo das Sombras, Passo Ágil) é instantâneo e
  não verifica colisão no meio do caminho, só confere quem foi atropelado
  no fim — dá pra atravessar parede/água por um instante. Aceitável pra um
  v1, mas é o primeiro lugar a olhar se isso incomodar.
- Sem objetivo, item ou saída: o jogo ainda é "explore e bata".

## Ideias pra próximo upgrade

- Feiticeiro/Mago de dano de verdade (a árvore de skill já existe, falta
  sprite — ver "Como as 4 classes funcionam").
- Rank/nível dentro de cada skill (hoje é só ligado/desligado).
- Música e som ambiente por bioma (precisa de arquivos de áudio, que o
  projeto ainda não tem).
- Iluminação dinâmica de verdade (`Light2D`), pra tochas e cristais
  brilharem contra um mundo escurecido de verdade.
- **Sistema de craft** (grade de ingredientes → item), ficou de fora de
  propósito por enquanto — o item da seção anterior já é genérico o
  suficiente pra não atrapalhar quando isso entrar.
- **Morcego nas pirâmides do Deserto e animação de verdade pros monstros**
  (idle/andar/hit em frames, não sprite único parado) — ficaram de fora
  porque o pacote de assets atual não tem sprite animado de monstro nem
  sprite de morcego. Precisa localizar/aprovar um pacote novo antes de
  implementar (nome, licença e tamanho do arquivo combinados com quem
  mantém o projeto antes de baixar qualquer coisa).
