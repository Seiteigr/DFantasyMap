extends Control

# Janela de inventário (tecla I): grade de slots gerada por código a partir
# de InventoryManager.items — sem sprite de ícone pronto, cada slot mostra
# uma cor + as duas primeiras letras do item (mesmo placeholder usado pelo
# item no chão, ver scripts/items/item_drop.gd).

const SLOT_SIZE := Vector2(56, 56)

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var grid: GridContainer = $Panel/VBox/Grid


func _ready() -> void:
	visible = false
	InventoryManager.inventory_changed.connect(_refresh)
	InventoryManager.gold_changed.connect(func(_g): _refresh())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh()


func _refresh() -> void:
	gold_label.text = "Gold: %d" % InventoryManager.gold
	for child in grid.get_children():
		child.queue_free()
	for item_id in InventoryManager.items:
		grid.add_child(_build_slot(item_id, InventoryManager.items[item_id]))


func _build_slot(item_id: String, amount: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.theme_type_variation = &"CardPanel"

	var color_rect := ColorRect.new()
	color_rect.color = ItemDatabase.get_color(item_id)
	color_rect.custom_minimum_size = SLOT_SIZE

	var label := Label.new()
	label.text = "%s\n x%d" % [ItemDatabase.get_item_name(item_id).substr(0, 2).to_upper(), amount]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	color_rect.add_child(label)
	panel.add_child(color_rect)
	panel.tooltip_text = ItemDatabase.get_item_name(item_id)
	return panel
