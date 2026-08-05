# 2D Warriors — protótipo estilo Sword of Mana

Projeto Godot 4: menu inicial → seleção de personagem (Guerreiro / Mago /
Arqueiro) → mapa com goblin dummies pra treinar ataque.

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
      Level1.tscn           <- mapa (era o antigo Main.tscn)
  scripts/
    player_base.gd          <- script único compartilhado pelas 3 classes
    goblin_dummy.gd
    level.gd                <- spawna a classe certa no mapa
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

## Limitações conhecidas (é um protótipo básico)

- O ataque é uma área circular ao redor do personagem, não um projétil de
  verdade — então o Arqueiro e o Mago "acertam" à distância curta, sem
  flecha/bola de fogo viajando pelo mapa ainda. Isso é o próximo passo
  natural de upgrade (instanciar uma cena de "Arrow"/"Projectile" que se
  move e detecta colisão sozinha).
- O Mago usa a animação "Heal" do pack (não tem sprite de ataque mágico
  no asset pack) só como visual de "conjurar".
- Os personagens só têm sprite "de frente" (sem 4 direções reais); viram
  só com espelhamento horizontal.
- Sem HUD de vida do jogador ainda, nem game over — os goblins têm vida,
  o jogador não.

## Ideias pra próximo upgrade

- HUD (vida do jogador, ícone da classe atual).
- Projétil de verdade pro Arqueiro (flecha) e Mago (bola de energia).
- Trocar os goblins por um inimigo que persegue o jogador (não só dummy
  parado).
- Tela de "Game Over" / "Vitória".
- Som e efeitos de partícula (o pack já tem `Particle FX/` com fogo,
  explosão, poeira — ainda não usados).
