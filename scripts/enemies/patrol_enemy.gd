extends Area2D

# Inimigo que patrulha um caminho fixo (linha, quadrado ou círculo), mas
# passa a perseguir o jogador direto quando ele chega perto (aggro_radius) e
# desiste (volta a patrulhar) se o jogador fugir longe demais (leash_radius).
# Morre em `max_hp` tapas, larga item conforme DROP_TABLE e depois de um
# tempo (`respawn_time`) volta a nascer no mesmo lugar — igual ao boneco de
# treino (goblin_dummy.gd), só que sem o "desmaiado", já reaparece pronto.

enum PatrolPattern { LINE, SQUARE, CIRCLE }
enum State { PATROL, CHASE }

# Nome usado pra achar a tabela de drop/XP em DROP_TABLE — não precisa bater
# com o nome do nó, só com uma chave lá embaixo.
@export var enemy_type: String = "orc"
@export var pattern: PatrolPattern = PatrolPattern.LINE
@export var speed: float = 60.0
@export var contact_damage: int = 1
@export var max_hp: int = 4

# Multiplicador de dano aplicado pelo WorldBuilder de acordo com a
# dificuldade do bioma (biomes()["difficulty"] em world_builder.gd) — o
# mesmo esqueleto machuca mais na Caverna do que na Floresta.
@export var damage_multiplier: float = 1.0

@export_group("Perseguição")
@export var aggro_radius: float = 160.0
@export var leash_radius: float = 320.0
@export var chase_speed: float = 75.0

@export_group("Respawn")
@export var respawn_time: float = 20.0

@export_group("Line")
@export var line_length: float = 160.0
@export var line_horizontal: bool = true

@export_group("Square")
@export var square_size: float = 200.0

@export_group("Circle")
@export var circle_radius: float = 90.0

# Inimigo "dormindo": fica parado (mas ainda machuca por contato) até o
# jogador chegar perto — aí acorda de vez e passa a reagir normalmente
# (patrulha e depois perseguição, como qualquer outro). Usado pelo
# WorldBuilder pra fazer os dragões da caverna e os esqueletos do deserto
# darem a sensação de emboscada, sem precisar de sprite novo.
@export_group("Dormant")
@export var dormant: bool = false
@export var wake_radius: float = 190.0

# Drop e XP por tipo de inimigo. Cada entrada de "drops" tem uma chance
# (0.0-1.0) e uma quantidade [min, max]. Gold Coin sempre entra em algum
# valor pra todo mundo dar uma recompensa mínima.
const DROP_TABLE := {
	"orc": {"xp": 8, "gold": [1, 3], "drops": {}},
	"skeleton": {"xp": 6, "gold": [1, 2], "drops": {"bone": {"chance": 1.0, "amount": [1, 2]}, "gem": {"chance": 0.1, "amount": [1, 1]}}},
	"dragon_green": {"xp": 20, "gold": [3, 6], "drops": {"dragon_leather": {"chance": 1.0, "amount": [1, 1]}, "gem": {"chance": 0.3, "amount": [1, 1]}}},
	"dragon_red": {"xp": 20, "gold": [3, 6], "drops": {"dragon_leather": {"chance": 1.0, "amount": [1, 1]}, "gem": {"chance": 0.3, "amount": [1, 1]}}},
	"bat": {"xp": 4, "gold": [0, 1], "drops": {"bat_wing": {"chance": 0.8, "amount": [1, 1]}}},
}

const ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var hp: int
var is_dead: bool = false
var _state: State = State.PATROL
var _origin: Vector2
var _t: float = 0.0
var _square_corners: Array[Vector2] = []
var _square_index: int = 0
var _prev_position: Vector2
var _awake: bool = true
# Quem está encostado agora. Mantido pelos sinais da Area2D em vez de
# varrer as colisões a cada frame (o mapa tem inimigo demais pra isso).
var _touching: Array[Node2D] = []


func _ready() -> void:
	hp = max_hp
	_origin = position
	_awake = not dormant
	add_to_group("enemy")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.play("idle")
	_reset_pattern_position()
	_prev_position = position


func _reset_pattern_position() -> void:
	match pattern:
		PatrolPattern.SQUARE:
			var h := square_size * 0.5
			_square_corners = [
				_origin + Vector2(-h, -h),
				_origin + Vector2(h, -h),
				_origin + Vector2(h, h),
				_origin + Vector2(-h, h),
			]
			_square_index = 0
			position = _square_corners[0]
		PatrolPattern.CIRCLE:
			_t = 0.0
			position = _origin + Vector2(circle_radius, 0)
		PatrolPattern.LINE:
			_t = 0.0
			position = _origin


func _physics_process(delta: float) -> void:
	if not _awake:
		_check_wake()
		return

	var player: Node2D = get_tree().get_first_node_in_group("player")

	if _state == State.CHASE:
		_update_chase(delta, player)
	else:
		_check_aggro(player)
		if _state == State.PATROL:
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
	_update_animation(move_delta.length() > 0.05)
	_prev_position = position

	# Enquanto o jogador continuar encostado, segue tomando dano — quem
	# controla o ritmo é a invulnerabilidade dele.
	var effective_damage := int(round(contact_damage * damage_multiplier))
	for body in _touching:
		if is_instance_valid(body):
			body.take_damage(effective_damage)


# Troca idle/walk conforme o inimigo está de fato andando — cobre patrulha,
# perseguição e até a leve oscilação do padrão LINE perto das pontas.
func _update_animation(moving: bool) -> void:
	var anim := "walk" if moving else "idle"
	if sprite.animation != anim:
		sprite.play(anim)


# Distância até o grupo "player" pra decidir se começa a perseguir — só
# dispara a partir do estado PATROL, pra não ficar entrando/saindo de CHASE
# toda hora perto da borda do raio (a saída de CHASE é controlada só pelo
# leash_radius em _update_chase).
func _check_aggro(player: Node2D) -> void:
	if player and global_position.distance_to(player.global_position) <= aggro_radius:
		_state = State.CHASE


# Persegue em linha reta na direção do jogador. Desiste (volta pro estado
# PATROL a partir da posição atual, sem teleportar de volta pra origem) se
# o jogador sumir, ficar longe demais, ou se a perseguição levar o inimigo
# longe demais do ponto onde ele nasceu.
func _update_chase(delta: float, player: Node2D) -> void:
	if player == null or not is_instance_valid(player):
		_state = State.PATROL
		return

	var dist_to_player := global_position.distance_to(player.global_position)
	var dist_from_origin := _origin.distance_to(global_position)
	if dist_to_player > leash_radius or dist_from_origin > leash_radius:
		_state = State.PATROL
		return

	var dir: Vector2 = (player.global_position - global_position).normalized()
	position += dir * chase_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not _touching.has(body):
		_touching.append(body)


func _on_body_exited(body: Node2D) -> void:
	_touching.erase(body)


# Só checa distância contra o grupo "player" (mais barato que ficar
# escaneando toda a árvore) e desperta pra sempre assim que ele chega perto.
func _check_wake() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= wake_radius:
		_awake = true


func take_hit(amount: int = 1) -> void:
	if is_dead:
		return
	hp -= amount
	_flash_red()
	if hp <= 0:
		_die()


# Veneno de skill (Veneno Cortante): dano repetido, independente do
# `take_hit` normal — cada instância de veneno é uma corrotina própria, então
# dois acertos envenenados seguidos só somam dano, sem se cancelar.
func apply_poison(damage: int, tick: float, duration: float) -> void:
	var ticks := int(duration / maxf(tick, 0.1))
	for i in ticks:
		await get_tree().create_timer(tick).timeout
		if is_dead or not is_inside_tree():
			return
		take_hit(damage)


func _flash_red() -> void:
	sprite.modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	if not is_dead:
		sprite.modulate = Color(1, 1, 1)


func _die() -> void:
	is_dead = true
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	_touching.clear()
	_drop_loot()
	# O inimigo pode morrer bem na hora de sair da tela; sem isso o
	# VisibleOnScreenEnabler2D congelaria o tween/timer e ele nunca sumiria
	# nem voltaria a nascer.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 0.0), 0.4)
	tween.tween_callback(_begin_respawn_wait)


func _begin_respawn_wait() -> void:
	visible = false
	await get_tree().create_timer(respawn_time).timeout
	_respawn()


func _respawn() -> void:
	is_dead = false
	hp = max_hp
	_state = State.PATROL
	_awake = not dormant
	position = _origin
	_reset_pattern_position()
	_prev_position = position
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.play("idle")
	visible = true
	collision_shape.set_deferred("disabled", false)
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)


func _drop_loot() -> void:
	var table: Dictionary = DROP_TABLE.get(enemy_type, {})
	if table.is_empty():
		return

	PlayerStats.add_xp(int(table.get("xp", 0)))

	var gold_range: Array = table.get("gold", [0, 0])
	var gold_amount: int = randi_range(gold_range[0], gold_range[1])
	if gold_amount > 0:
		_spawn_drop("gold_coin", gold_amount)

	var drops: Dictionary = table.get("drops", {})
	for item_id in drops:
		var entry: Dictionary = drops[item_id]
		if randf() <= float(entry.get("chance", 0.0)):
			var amount_range: Array = entry.get("amount", [1, 1])
			_spawn_drop(item_id, randi_range(amount_range[0], amount_range[1]))


func _spawn_drop(item_id: String, amount: int) -> void:
	var drop: Area2D = ItemDropScene.instantiate()
	drop.item_id = item_id
	drop.amount = amount
	get_parent().add_child(drop)
	drop.global_position = global_position


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
