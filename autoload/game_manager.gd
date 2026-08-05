extends Node

# Autoload (singleton) — acessível em qualquer script como "GameManager".
# Guarda qual personagem foi escolhido na tela de seleção e centraliza
# as trocas de cena do jogo.

signal hearts_changed(current: int, max_hearts: int)

enum CharacterClass { WARRIOR, MAGE, ARCHER, ROGUE }

const MAX_HEARTS := 4

var selected_character: CharacterClass = CharacterClass.WARRIOR
var hearts: int = MAX_HEARTS

const CHARACTER_SCENES := {
	CharacterClass.WARRIOR: "res://scenes/characters/Warrior.tscn",
	CharacterClass.MAGE: "res://scenes/characters/Mage.tscn",
	CharacterClass.ARCHER: "res://scenes/characters/Archer.tscn",
	CharacterClass.ROGUE: "res://scenes/characters/Rogue.tscn",
}

const CHARACTER_NAMES := {
	CharacterClass.WARRIOR: "Guerreiro",
	CharacterClass.MAGE: "Mago",
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
	reset_hearts()
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")


func reset_hearts() -> void:
	hearts = MAX_HEARTS
	hearts_changed.emit(hearts, MAX_HEARTS)


func take_damage(amount: int = 1) -> void:
	if hearts <= 0:
		return
	hearts = max(hearts - amount, 0)
	hearts_changed.emit(hearts, MAX_HEARTS)
	if hearts <= 0:
		get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")
