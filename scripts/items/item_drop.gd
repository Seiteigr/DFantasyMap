extends Area2D

# Item largado no chão por um monstro morto. Sem sprite de item pronto no
# pacote de assets, então desenha um losango colorido com as duas primeiras
# letras do nome — mesmo espírito de placeholder usado pelos marcos dos
# biomas (landmarks.gd) antes de ter arte de verdade.

const SIZE := 14.0
const BOB_HEIGHT := 4.0
const BOB_DURATION := 0.8

@export var item_id: String = "gold_coin"
@export var amount: int = 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_y: float = 0.0
var _picked_up: bool = false


func _ready() -> void:
	add_to_group("item_drop")
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	_bob()


func _bob() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", _base_y - BOB_HEIGHT, BOB_DURATION * 0.5)
	tween.tween_property(self, "position:y", _base_y, BOB_DURATION * 0.5)


func _draw() -> void:
	var color: Color = ItemDatabase.get_color(item_id)
	var points := PackedVector2Array([
		Vector2(0, -SIZE), Vector2(SIZE, 0), Vector2(0, SIZE), Vector2(-SIZE, 0),
	])
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0, 0, 0, 0.6), 2.0)

	var label_text: String = ItemDatabase.get_item_name(item_id).substr(0, 2).to_upper()
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-SIZE, 4), label_text, HORIZONTAL_ALIGNMENT_CENTER, SIZE * 2, 12, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if _picked_up or not body.is_in_group("player"):
		return
	_picked_up = true
	if item_id == "gold_coin":
		InventoryManager.add_gold(amount)
	else:
		InventoryManager.add_item(item_id, amount)
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
