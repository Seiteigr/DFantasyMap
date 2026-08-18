extends Node

# Autoload (singleton) — acessível em qualquer script como "GameManager".
# Guarda qual personagem foi escolhido na tela de seleção e centraliza
# as trocas de cena do jogo. HP/mana/atributos moraram pro PlayerStats,
# itens e gold pro InventoryManager — aqui fica só navegação de cena.

# CLERIC reaproveita a cena/sprite que antes era rotulada "Mago" — a
# animação "Heal" do pack sempre coube muito mais como clérigo do que como
# mago de dano. Um Feiticeiro/Mago de verdade (elemental) é item futuro,
# precisa de sprite novo que o pacote atual não tem.
enum CharacterClass { WARRIOR, CLERIC, ARCHER, ROGUE }

var selected_character: CharacterClass = CharacterClass.WARRIOR

const CHARACTER_SCENES := {
	CharacterClass.WARRIOR: "res://scenes/characters/Warrior.tscn",
	CharacterClass.CLERIC: "res://scenes/characters/Mage.tscn",
	CharacterClass.ARCHER: "res://scenes/characters/Archer.tscn",
	CharacterClass.ROGUE: "res://scenes/characters/Rogue.tscn",
}

const CHARACTER_NAMES := {
	CharacterClass.WARRIOR: "Guerreiro",
	CharacterClass.CLERIC: "Clérigo",
	CharacterClass.ARCHER: "Arqueiro",
	CharacterClass.ROGUE: "Ladino",
}


func get_selected_scene_path() -> String:
	return CHARACTER_SCENES[selected_character]


func select_character(character_class: CharacterClass) -> void:
	selected_character = character_class


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func go_to_character_select() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/CharacterSelect.tscn")


func start_game() -> void:
	PlayerStats.reset_stats()
	InventoryManager.reset()
	SkillManager.reset()
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")


func game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")
