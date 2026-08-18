extends Control

# Janela da loja do NPC mercador. Aberta por scripts/npc/merchant.gd quando
# o jogador interage (tecla "interact") perto dele. Duas listas: itens à
# venda pelo NPC (compra com gold) e os itens que o jogador carrega (vende
# por gold). Preços vêm de ItemDatabase (buy_price/sell_price).

# O que o mercador tem pra vender — fixo por enquanto, sem estoque.
const SHOP_STOCK := ["health_potion", "bone", "dragon_leather", "gem"]

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var buy_list: VBoxContainer = $Panel/VBox/HBox/BuyColumn/BuyList
@onready var sell_list: VBoxContainer = $Panel/VBox/HBox/SellColumn/SellList


func _ready() -> void:
	visible = false
	add_to_group("shop_window")
	InventoryManager.gold_changed.connect(func(_g): _refresh())
	InventoryManager.inventory_changed.connect(_refresh)


func open_shop() -> void:
	visible = true
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		visible = false


func _refresh() -> void:
	gold_label.text = "Seu gold: %d" % InventoryManager.gold
	for child in buy_list.get_children():
		child.queue_free()
	for child in sell_list.get_children():
		child.queue_free()

	for item_id in SHOP_STOCK:
		var price: int = ItemDatabase.get_item(item_id).get("buy_price", 0)
		buy_list.add_child(_build_row(
			"%s — %d gold" % [ItemDatabase.get_item_name(item_id), price],
			"Comprar",
			func(): _buy(item_id, price),
		))

	for item_id in InventoryManager.items:
		if item_id == "gold_coin":
			continue
		var amount: int = InventoryManager.items[item_id]
		var price: int = ItemDatabase.get_item(item_id).get("sell_price", 0)
		sell_list.add_child(_build_row(
			"%s x%d — %d gold" % [ItemDatabase.get_item_name(item_id), amount, price],
			"Vender",
			func(): _sell(item_id, price),
		))


func _build_row(text: String, button_text: String, action: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(action)
	row.add_child(label)
	row.add_child(button)
	return row


func _buy(item_id: String, price: int) -> void:
	if InventoryManager.spend_gold(price):
		InventoryManager.add_item(item_id, 1)


func _sell(item_id: String, price: int) -> void:
	if InventoryManager.remove_item(item_id, 1):
		InventoryManager.add_gold(price)
