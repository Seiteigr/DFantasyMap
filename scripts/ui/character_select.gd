extends Control

@onready var warrior_card: PanelContainer = $VBoxContainer/CardsContainer/WarriorCard
@onready var mage_card: PanelContainer = $VBoxContainer/CardsContainer/MageCard
@onready var archer_card: PanelContainer = $VBoxContainer/CardsContainer/ArcherCard
@onready var rogue_card: PanelContainer = $VBoxContainer/CardsContainer/RogueCard
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

var _cards_by_class: Dictionary


func _ready() -> void:
	_cards_by_class = {
		GameManager.CharacterClass.WARRIOR: warrior_card,
		GameManager.CharacterClass.CLERIC: mage_card,
		GameManager.CharacterClass.ARCHER: archer_card,
		GameManager.CharacterClass.ROGUE: rogue_card,
	}
	_select(GameManager.selected_character)


func _on_warrior_button_pressed() -> void:
	_select(GameManager.CharacterClass.WARRIOR)


func _on_mage_button_pressed() -> void:
	_select(GameManager.CharacterClass.CLERIC)


func _on_archer_button_pressed() -> void:
	_select(GameManager.CharacterClass.ARCHER)


func _on_rogue_button_pressed() -> void:
	_select(GameManager.CharacterClass.ROGUE)


func _on_confirm_button_pressed() -> void:
	GameManager.start_game()


func _on_back_button_pressed() -> void:
	GameManager.go_to_main_menu()


func _select(character_class: GameManager.CharacterClass) -> void:
	GameManager.select_character(character_class)

	for c in _cards_by_class.keys():
		var card: PanelContainer = _cards_by_class[c]
		card.modulate = Color(1, 1, 1) if c == character_class else Color(0.5, 0.5, 0.5)

	match character_class:
		GameManager.CharacterClass.WARRIOR:
			description_label.text = "Guerreiro: armadura pesada e espada em punho — resiste na linha de frente e aguenta qualquer combate corpo a corpo."
		GameManager.CharacterClass.CLERIC:
			description_label.text = "Clérigo: cura, benções e magia de apoio — mantém o grupo de pé enquanto ataca de perto."
		GameManager.CharacterClass.ARCHER:
			description_label.text = "Arqueiro: mira infalível com o arco — golpeia de longe sem deixar o inimigo chegar perto."
		GameManager.CharacterClass.ROGUE:
			description_label.text = "Ladino: adagas rápidas nas mãos — golpes curtos e ágeis, o mais veloz de todos."
