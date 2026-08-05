extends Control

# Desenha os corações de vida (estilo pixelado) e escuta o GameManager
# para atualizar sempre que o jogador leva dano.

var HEART_POINTS := PackedVector2Array([
	Vector2(0.0, 0.3), Vector2(0.15, 0.05), Vector2(0.35, 0.0), Vector2(0.5, 0.12),
	Vector2(0.65, 0.0), Vector2(0.85, 0.05), Vector2(1.0, 0.3), Vector2(0.85, 0.55),
	Vector2(0.5, 1.0), Vector2(0.15, 0.55),
])

const HEART_SIZE := 26.0
const HEART_GAP := 8.0
const FILL_COLOR := Color(0.851, 0.157, 0.157, 1)
const EMPTY_COLOR := Color(0.16, 0.13, 0.1, 1)
const OUTLINE_COLOR := Color(0.1, 0.08, 0.04, 1)

var _max_hearts: int = GameManager.MAX_HEARTS
var _hearts: int = GameManager.MAX_HEARTS


func _ready() -> void:
	_max_hearts = GameManager.MAX_HEARTS
	_hearts = GameManager.hearts
	GameManager.hearts_changed.connect(_on_hearts_changed)
	custom_minimum_size = Vector2(_max_hearts * (HEART_SIZE + HEART_GAP), HEART_SIZE)
	queue_redraw()


func _on_hearts_changed(current: int, max_hearts: int) -> void:
	_hearts = current
	_max_hearts = max_hearts
	queue_redraw()


func _draw() -> void:
	for i in range(_max_hearts):
		var offset := Vector2(i * (HEART_SIZE + HEART_GAP), 0.0)
		var points := PackedVector2Array()
		for p in HEART_POINTS:
			points.append(offset + p * HEART_SIZE)
		var color := FILL_COLOR if i < _hearts else EMPTY_COLOR
		draw_colored_polygon(points, color)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, OUTLINE_COLOR, 3.0, false)
