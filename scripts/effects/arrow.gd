extends Area2D

# Flecha do arqueiro: voa reto na direção do tiro e acerta o primeiro
# inimigo que tocar (mesma convenção do AttackArea: chama take_hit()).

@export var speed: float = 420.0
@export var lifetime: float = 1.2
@export var damage: int = 1

var _direction: Vector2 = Vector2.RIGHT

@onready var lifetime_timer: Timer = $LifetimeTimer


func _ready() -> void:
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()
	area_entered.connect(_on_area_entered)
	rotation = _direction.angle()


func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	position += _direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		area.take_hit()
		queue_free()
