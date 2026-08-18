# Prompt — Inventário, Status (estilo Ragnarok Online) e Drops

Quero adicionar ao DFantasyMap (projeto Godot 4) um sistema de **status** e
**inventário** com a vibe de Ragnarok Online, **drop de itens por monstro**,
um **NPC comprador/vendedor**, e um **monstro novo (morcego)** nas pirâmides
do Deserto. Sistema de craft fica pra depois — não faz parte deste prompt.

Siga os padrões já usados no projeto: comentários em português explicando o
"porquê" (não o "o quê"), scripts compartilhados entre cenas parecidas
(como `scripts/player_base.gd`), autoloads novos no mesmo espírito de
`autoload/game_manager.gd`, e uma tabela central fácil de balancear (mesmo
espírito da tabela de biomas em `world_builder.gd`).

## 0. Pré-requisito: assets pendentes

O pacote de assets atual **não tem** sprite de morcego nem frames de
animação pros monstros existentes (`skeleton.png`, `orc.png`,
`dragon_green.png`, `dragon_red.png` são imagens únicas e estáticas,
usadas em `Sprite2D`, não `AnimatedSprite2D`). Pra ter animação de verdade
e o morcego, será preciso localizar e aprovar um pacote de assets novo
(nome, fonte, licença e tamanho do arquivo antes de qualquer download) —
isso é um passo separado, feito com o usuário antes de mexer no código
desses dois itens. Até lá, esses dois pontos ficam bloqueados; o resto do
prompt (status, inventário, drop, NPC) não depende disso e pode ser feito
com os assets atuais.

## 1. Sistema de Status (simplificado, estilo RO)

Em vez dos 6 atributos clássicos de Ragnarok (STR/AGI/VIT/INT/DEX/LUK),
usar **3 atributos simplificados**:

- **Magia**: aumenta mana máxima, poder dos feitiços (dano do Mago) e
  quantas vezes as magias podem ser usadas antes de precisar recarregar.
- **Colosso**: aumenta força (dano físico), resistência (reduz dano
  recebido), armadura e HP máximo.
- **Destreza**: aumenta velocidade de movimento, chance de esquiva, e dá
  um "ar mais ladino" ao personagem (ex: bônus de dano crítico ou chance
  de ataque duplo pro Ladino).

Sistema de nível: personagem ganha XP ao matar monstro (em
`patrol_enemy.gd`, no `_die()`), sobe de nível numa tabela de XP simples,
e ganha pontos pra distribuir entre os 3 atributos ao subir de nível.

Criar `autoload/player_stats.gd` (singleton `PlayerStats`), guardando:
nível, XP atual/necessário, pontos livres, valor de cada um dos 3
atributos, HP atual/máximo (substituindo os 4 "corações" fixos por HP
numérico calculado a partir de Colosso), mana atual/máxima (calculada a
partir de Magia). Sinais: `stats_changed`, `level_up`, `hp_changed`.

UI: `scenes/ui/StatusWindow.tscn` — mostra nível, XP (barra), HP, mana, os
3 atributos com um botão "+" ao lado de cada um enquanto houver pontos
livres. Abre com uma tecla (ex. `Alt+S`, no espírito de atalhos do RO).

Ajustar `player_base.gd` e `patrol_enemy.gd`/inimigos pra ler dano e
velocidade de `PlayerStats` em vez de valores fixos, e trocar
`hearts_hud.gd` por uma barra de HP (pode manter o arquivo e só mudar a
lógica interna, já que ele já escuta um sinal de mudança de vida).

## 2. Sistema de Inventário (estilo RO)

Criar `autoload/inventory_manager.gd` (singleton `InventoryManager`):
dicionário `item_id -> quantidade`, sinal `inventory_changed`. Métodos:
`add_item(id, amount)`, `remove_item(id, amount)`, `has_item(id, amount)`,
`get_gold()`, `add_gold(amount)`, `spend_gold(amount)`.

Item = `Resource` customizado (`scripts/items/item_data.gd`): id, nome,
ícone, tipo (material/moeda/consumível), stack máximo, descrição curta,
preço de compra/venda (pro NPC da seção 4).

UI: `scenes/ui/Inventory.tscn` — grade de slots (ícone + número no canto,
visual de janela estilo RO), abre/fecha com uma tecla (ex. `Alt+I`).
Mostrar o saldo de Gold Coins com destaque.

Itens iniciais:
- **Gold Coin** — moeda do jogo, stack alto (999+).
- **Osso** — drop de esqueleto.
- **Couro de Dragão** — drop de dragão verde/vermelho.
- **Joia** — drop raro, qualquer inimigo.
- **Asa de Morcego** — drop do morcego (fica reservado no código até o
  monstro existir de verdade — ver seção 0 e 5).

## 3. Drop de monstros

Em `patrol_enemy.gd`, no `_die()`, adicionar uma tabela de drop por tipo
de inimigo (goblin, orc, skeleton, dragon_green, dragon_red — e bat depois
que existir), com chance individual por item. Exemplo de regra: esqueleto
sempre dropa 1–2 ossos e tem chance baixa de joia; dragão sempre dropa
couro de dragão e tem chance média de joia; todo inimigo solta algumas
gold coins ao morrer, dragão solta mais que goblin.

Os itens dropados aparecem no mundo (ícone pequeno no chão, dentro do nó
`Entities` pra respeitar o y-sort) e são coletados ao encostar no jogador
(`Area2D`, mesmo padrão da área de dano de contato, mas chamando
`InventoryManager.add_item()`/`add_gold()` em vez de tirar vida).

## 4. NPC comprador/vendedor

Criar `scenes/npc/Merchant.tscn` + `scripts/npc/merchant.gd`: NPC parado
num ponto fixo do mapa (ex. perto do spawn na Floresta, ou um por bioma —
decidir na implementação). `Area2D` de interação: quando o jogador chega
perto e aperta uma tecla (ex. `E` ou `Enter`), abre a loja.

UI: `scenes/ui/Shop.tscn` — duas listas: itens à venda pelo NPC (preço em
gold coin, desconta de `InventoryManager` ao comprar) e itens que o
jogador pode vender (soma gold ao vender, usando o preço de venda definido
em `item_data.gd`). Fecha com Esc ou clicando fora.

## 5. Monstro novo: Morcego (bloqueado por assets — ver seção 0)

Bioma Deserto, perto da pirâmide (marco do bioma). Padrão de voo errático
dentro de um raio (pode reaproveitar/estender o enum `PatrolPattern` de
`patrol_enemy.gd` com um novo padrão, ex. `ERRATIC`, em vez de linha/
quadrado/círculo previsíveis). Entra na tabela `enemies` do bioma Deserto
em `world_builder.gd`, do mesmo jeito que os outros. Drop: Asa de Morcego
+ chance pequena de gold coin.

## 6. Requisitos gerais

- Código legível e simples — material didático pra alunos, prefira
  clareza a abstração esperta.
- Não quebrar o fluxo atual (`MainMenu` → `CharacterSelect` → `Level1`).
- Atualizar `README.md` com as novas seções (status, inventário, drop,
  NPC), no mesmo estilo das seções existentes (tabelas, trechos de
  código).
- Craft fica fora deste prompt — não implementar agora, só deixar a
  estrutura de itens (`item_data.gd`) genérica o suficiente pra não
  atrapalhar quando formos adicionar depois.
