extends Control

# Janela de status (tecla K): nível, XP, HP, mana e os 3 atributos com botão
# de "+" pra gastar pontos livres. Fica escondida por padrão e alterna com
# a ação de input "toggle_status".

@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var xp_label: Label = $Panel/VBox/XpLabel
@onready var hp_label: Label = $Panel/VBox/HpLabel
@onready var mana_label: Label = $Panel/VBox/ManaLabel
@onready var points_label: Label = $Panel/VBox/PointsLabel
@onready var skill_points_label: Label = $Panel/VBox/SkillPointsLabel
@onready var magic_label: Label = $Panel/VBox/MagicRow/MagicLabel
@onready var colosso_label: Label = $Panel/VBox/ColossoRow/ColossoLabel
@onready var dex_label: Label = $Panel/VBox/DexRow/DexLabel


func _ready() -> void:
	visible = false
	PlayerStats.stats_changed.connect(_refresh)
	PlayerStats.hp_changed.connect(func(_c, _m): _refresh())
	PlayerStats.mana_changed.connect(func(_c, _m): _refresh())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_status"):
		visible = not visible
		if visible:
			_refresh()


func _refresh() -> void:
	level_label.text = "Nível %d" % PlayerStats.level
	xp_label.text = "XP: %d / %d" % [PlayerStats.xp, PlayerStats.xp_to_next]
	hp_label.text = "HP: %d / %d" % [PlayerStats.hp, PlayerStats.max_hp()]
	mana_label.text = "Mana: %d / %d" % [PlayerStats.mana, PlayerStats.max_mana()]
	points_label.text = "Pontos livres: %d" % PlayerStats.free_points
	skill_points_label.text = "Pontos de skill: %d (tecla L)" % PlayerStats.skill_points
	magic_label.text = "Magia: %d" % PlayerStats.magic
	colosso_label.text = "Colosso: %d" % PlayerStats.colosso
	dex_label.text = "Destreza: %d" % PlayerStats.dex


func _on_magic_button_pressed() -> void:
	PlayerStats.allocate_point("magic")


func _on_colosso_button_pressed() -> void:
	PlayerStats.allocate_point("colosso")


func _on_dex_button_pressed() -> void:
	PlayerStats.allocate_point("dex")
