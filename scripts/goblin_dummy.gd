extends Area2D

# Boneco de treino: apanha do jogador, mostra o dano e "desmaia".
# Depois de alguns segundos, levanta de novo (respawn automático).

@export var max_hp: int = 4
@export var respawn_time: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var respawn_timer: Timer = $RespawnTimer
@onready var hit_label: Label = $HitLabel

var hp: int
var knocked_out: bool = false
var _label_base_y: float


func _ready() -> void:
	hp = max_hp
	hit_label.visible = false
	_label_base_y = hit_label.position.y
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)


func take_hit() -> void:
	if knocked_out:
		return
	hp -= 1
	_flash_red()
	_show_hit_label()
	if hp <= 0:
		_knock_out()


func _flash_red() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	if not knocked_out:
		sprite.modulate = Color(1, 1, 1)


func _show_hit_label() -> void:
	hit_label.text = "-1"
	hit_label.position.y = _label_base_y
	hit_label.modulate.a = 1.0
	hit_label.visible = true
	var tween := create_tween()
	tween.tween_property(hit_label, "position:y", _label_base_y - 24, 0.5)
	tween.parallel().tween_property(hit_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): hit_label.visible = false)


func _knock_out() -> void:
	knocked_out = true
	collision_shape.set_deferred("disabled", true)
	sprite.modulate = Color(0.5, 0.5, 0.5)
	sprite.rotation_degrees = 90
	respawn_timer.start()


func _on_respawn() -> void:
	hp = max_hp
	knocked_out = false
	collision_shape.set_deferred("disabled", false)
	sprite.modulate = Color(1, 1, 1)
	sprite.rotation_degrees = 0
