extends CharacterBody2D

# Script compartilhado por Warrior.tscn, Mage.tscn e Archer.tscn.
# Cada cena só muda o SpriteFrames (visual) e estes valores exportados.

@export var speed: float = 180.0
@export var attack_animation: String = "attack"
@export var attack_duration: float = 0.35
@export var invulnerable_time: float = 1.0
@export var projectile_scene: PackedScene
@export var projectile_delay: float = 0.15

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer

var is_attacking: bool = false
var is_invulnerable: bool = false


func _ready() -> void:
	attack_shape.disabled = true
	attack_timer.wait_time = attack_duration
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_area.area_entered.connect(_on_attack_area_entered)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_start_attack()

	if is_attacking:
		# fica parado durante a animação de ataque
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	if input_dir.length() > 0.1:
		if sprite.animation != "run":
			sprite.play("run")
		if input_dir.x != 0.0:
			sprite.flip_h = input_dir.x < 0.0
	else:
		if sprite.animation != "idle":
			sprite.play("idle")


func _start_attack() -> void:
	is_attacking = true
	sprite.play(attack_animation)
	attack_timer.start()
	if projectile_scene:
		_fire_projectile()
	else:
		attack_shape.disabled = false


func _fire_projectile() -> void:
	await get_tree().create_timer(projectile_delay).timeout
	if not is_inside_tree():
		return
	var arrow: Node2D = projectile_scene.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector2(0, -30)
	var dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	arrow.set_direction(dir)


func _on_attack_area_entered(area: Area2D) -> void:
	if is_attacking and area.has_method("take_hit"):
		area.take_hit()


func _on_attack_timer_timeout() -> void:
	is_attacking = false
	attack_shape.disabled = true
	sprite.play("idle")


func take_damage(amount: int = 1) -> void:
	if is_invulnerable:
		return
	is_invulnerable = true
	GameManager.take_damage(amount)
	if GameManager.hearts <= 0:
		# golpe fatal: a cena vai trocar pro Game Over, o nó já não
		# está mais na árvore — não faz sentido animar nem esperar.
		return
	_flash_hurt()


func _flash_hurt() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)
	await get_tree().create_timer(invulnerable_time).timeout
	is_invulnerable = false
