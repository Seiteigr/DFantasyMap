extends Control

# Janela de árvore de skill (tecla L): mostra as 4 habilidades da classe do
# jogador atual (SkillDatabase.get_skills(class_id)), com botão de
# desbloquear (gasta 1 skill point) e a tecla de ativação (1/2/3/4). Gerada
# por código — igual ao inventário, o número de skills por classe é sempre
# 4 mas não vale a pena descrever cada linha na cena.

@onready var points_label: Label = $Panel/VBox/PointsLabel
@onready var list: VBoxContainer = $Panel/VBox/List


func _ready() -> void:
	visible = false
	PlayerStats.stats_changed.connect(_refresh)
	SkillManager.skill_unlocked.connect(func(_id): _refresh())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_skill_tree"):
		visible = not visible
		if visible:
			_refresh()


func _refresh() -> void:
	points_label.text = "Pontos de skill: %d" % PlayerStats.skill_points
	for child in list.get_children():
		child.queue_free()

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var skills: Array = SkillDatabase.get_skills(player.class_id)
	for i in skills.size():
		list.add_child(_build_row(skills[i], i))


func _build_row(skill: Dictionary, slot: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var title := Label.new()
	title.text = "[%d] %s" % [slot + 1, skill.get("name", "")]
	title.add_theme_color_override("font_color", Color(1, 0.851, 0.302, 1))
	info.add_child(title)

	var desc := Label.new()
	desc.text = String(skill.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(260, 0)
	info.add_child(desc)

	var cost := Label.new()
	cost.text = "Custo: %s mana — cooldown %ss" % [str(skill.get("mana_cost", 0)), str(skill.get("cooldown", 0))]
	cost.add_theme_font_size_override("font_size", 12)
	info.add_child(cost)

	var skill_id: String = skill.get("id", "")
	if SkillManager.is_unlocked(skill_id):
		var unlocked_label := Label.new()
		unlocked_label.text = "Desbloqueada"
		unlocked_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		hbox.add_child(unlocked_label)
	else:
		var button := Button.new()
		button.text = "Desbloquear"
		button.disabled = PlayerStats.skill_points <= 0
		button.pressed.connect(func(): _on_unlock_pressed(skill_id))
		hbox.add_child(button)

	return panel


func _on_unlock_pressed(skill_id: String) -> void:
	SkillManager.unlock(skill_id)
