extends Node

# Autoload (singleton) — acessível em qualquer script como "ItemDatabase".
# Tabela central de itens, no mesmo espírito da tabela de biomas em
# world_builder.gd: mudar uma entrada aqui já muda o item em todo o jogo,
# sem precisar mexer em cena nenhuma.
#
# Sem sprite de ícone pronto pra cada item (o pacote de assets não tem),
# então cada item usa uma cor + as duas primeiras letras do nome como
# placeholder visual (ver scripts/ui/item_slot.gd e scripts/items/item_drop.gd).

const ITEMS := {
	"gold_coin": {
		"name": "Gold Coin",
		"color": Color(0.96, 0.78, 0.15),
		"max_stack": 999,
		"sell_price": 0,
		"buy_price": 0,
	},
	"bone": {
		"name": "Osso",
		"color": Color(0.9, 0.88, 0.8),
		"max_stack": 99,
		"sell_price": 2,
		"buy_price": 4,
	},
	"dragon_leather": {
		"name": "Couro de Dragão",
		"color": Color(0.2, 0.55, 0.25),
		"max_stack": 99,
		"sell_price": 15,
		"buy_price": 30,
	},
	"gem": {
		"name": "Joia",
		"color": Color(0.55, 0.25, 0.85),
		"max_stack": 99,
		"sell_price": 25,
		"buy_price": 50,
	},
	# Reservado pro morcego (bloqueado até ter sprite/asset aprovado) —
	# já dá pra dropar/vender mesmo sem o monstro existir de verdade.
	"bat_wing": {
		"name": "Asa de Morcego",
		"color": Color(0.35, 0.2, 0.4),
		"max_stack": 99,
		"sell_price": 5,
		"buy_price": 10,
	},
	# Item vendido pelo NPC pra dar uso ao gold sem precisar de craft ainda.
	"health_potion": {
		"name": "Poção de Vida",
		"color": Color(0.85, 0.2, 0.2),
		"max_stack": 20,
		"sell_price": 3,
		"buy_price": 10,
	},
}


func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


func get_item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


func get_color(id: String) -> Color:
	return ITEMS.get(id, {}).get("color", Color.WHITE)
