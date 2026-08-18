extends Node

# Autoload (singleton) — acessível em qualquer script como "InventoryManager".
# Guarda quantidade por item (item_id -> quantidade) e o saldo de Gold Coins
# separado (é a moeda, não ocupa slot de inventário).

signal inventory_changed
signal gold_changed(amount: int)

var items: Dictionary = {}
var gold: int = 0


func reset() -> void:
	items.clear()
	gold = 0
	inventory_changed.emit()
	gold_changed.emit(gold)


func add_item(id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var max_stack: int = ItemDatabase.get_item(id).get("max_stack", 99)
	var current: int = items.get(id, 0)
	items[id] = min(current + amount, max_stack)
	inventory_changed.emit()


func has_item(id: String, amount: int = 1) -> bool:
	return items.get(id, 0) >= amount


func remove_item(id: String, amount: int = 1) -> bool:
	if not has_item(id, amount):
		return false
	items[id] -= amount
	if items[id] <= 0:
		items.erase(id)
	inventory_changed.emit()
	return true


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true
