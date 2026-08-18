extends Node2D

# Fallback sem asset externo: uma bolha colorida que vagueia devagar — usado
# quando assets/village/ não existe na máquina de quem abriu o projeto
# (os pacotes de terceiros não vão pro git, ver README pra baixar de novo).

var tint: Color = Color.WHITE
var wander_radius: float = 30.0
var speed: float = 16.0

var _origin: Vector2
var _target: Vector2
var _wait_time: float = 0.0


func setup(critter_tint: Color, radius: float) -> void:
	tint = critter_tint
	wander_radius = radius


func _ready() -> void:
	_origin = position
	_target = position
	queue_redraw()


func _process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		return

	var to_target: Vector2 = _target - position
	if to_target.length() < 3.0:
		_wait_time = randf_range(1.5, 3.0)
		var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		_target = _origin + offset
		return

	position += to_target.normalized() * speed * delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, tint)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color(0, 0, 0, 0.5), 1.5)
