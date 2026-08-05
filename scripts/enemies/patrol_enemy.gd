extends Area2D

# Inimigo que patrulha um caminho fixo (linha, quadrado ou círculo) e tira
# 1 vida por contato. Não ataca nem persegue o jogador, mas apanha do
# ataque do jogador como o boneco de treino e morre de vez em 4 tapas.

enum PatrolPattern { LINE, SQUARE, CIRCLE }

@export var pattern: PatrolPattern = PatrolPattern.LINE
@export var speed: float = 60.0
@export var contact_damage: int = 1
@export var max_hp: int = 4

@export_group("Line")
@export var line_length: float = 160.0
@export var line_horizontal: bool = true

@export_group("Square")
@export var square_size: float = 200.0

@export_group("Circle")
@export var circle_radius: float = 90.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var hp: int
var is_dead: bool = false
var _origin: Vector2
var _t: float = 0.0
var _square_corners: Array[Vector2] = []
var _square_index: int = 0
var _prev_position: Vector2


func _ready() -> void:
	hp = max_hp
	_origin = position
	match pattern:
		PatrolPattern.SQUARE:
			var h := square_size * 0.5
			_square_corners = [
				_origin + Vector2(-h, -h),
				_origin + Vector2(h, -h),
				_origin + Vector2(h, h),
				_origin + Vector2(-h, h),
			]
			position = _square_corners[0]
		PatrolPattern.CIRCLE:
			position = _origin + Vector2(circle_radius, 0)
	_prev_position = position


func _physics_process(delta: float) -> void:
	match pattern:
		PatrolPattern.LINE:
			_move_line(delta)
		PatrolPattern.SQUARE:
			_move_square(delta)
		PatrolPattern.CIRCLE:
			_move_circle(delta)

	var move_delta: Vector2 = position - _prev_position
	if absf(move_delta.x) > 0.05:
		sprite.flip_h = move_delta.x < 0.0
	_prev_position = position

	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)


func take_hit() -> void:
	if is_dead:
		return
	hp -= 1
	_flash_red()
	if hp <= 0:
		_die()


func _flash_red() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	if not is_dead:
		sprite.modulate = Color(1, 1, 1)


func _die() -> void:
	is_dead = true
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 0.4)
	tween.tween_callback(queue_free)


func _move_line(delta: float) -> void:
	var half := line_length * 0.5
	_t += delta * (speed / maxf(half, 1.0))
	var offset := sin(_t) * half
	position = _origin + (Vector2.RIGHT * offset if line_horizontal else Vector2.DOWN * offset)


func _move_square(delta: float) -> void:
	var target: Vector2 = _square_corners[_square_index]
	var to_target: Vector2 = target - position
	var dist := to_target.length()
	var step := speed * delta
	if step >= dist:
		position = target
		_square_index = (_square_index + 1) % _square_corners.size()
	else:
		position += to_target.normalized() * step


func _move_circle(delta: float) -> void:
	_t += delta * (speed / maxf(circle_radius, 1.0))
	position = _origin + Vector2(cos(_t), sin(_t)) * circle_radius
