extends RefCounted

# Aplica o efeito de cada skill descrita em SkillDatabase — traduz o campo
# "effect" (string) num pedaço de gameplay de verdade. Cada handler é
# "burro": só lê os parâmetros do dicionário da skill, não sabe nada de
# classe nem de UI. Quem chama (`player_base.gd`) já garantiu que a skill
# está desbloqueada, sem cooldown e com mana suficiente (via SkillManager).
#
# Simplificações de propósito pra manter isso do tamanho de um v1: dash não
# verifica colisão no meio do caminho (só no destino), a parede de pedra
# nasce sempre "vertical" (bloqueia quem anda na horizontal, que é o
# movimento predominante), e todo alvo de skill precisa estar no grupo
# "enemy" com um método take_hit(amount) — patrol_enemy.gd e goblin_dummy.gd
# já entram nesse grupo.

const BASE_ATTACK_DAMAGE := 1
const BASE_MELEE_RANGE := 50.0
const DASH_HIT_RADIUS := 32.0

# VFX genéricos por "sabor" de efeito — não é um por skill, é um por tipo de
# handler, senão viraria uma tabela gigante pra manter. Explosão pra golpes
# de área, raio pra procs/dashes rápidos, estrela de gelo pra buffs/auras
# (glow neutro o bastante pra servir de "efeito de status" em qualquer uma).
const BurstEffect := preload("res://scenes/effects/WarriorEffect.tscn")
const ProcEffect := preload("res://scenes/effects/RogueEffect.tscn")
const AuraEffect := preload("res://scenes/effects/MageEffect.tscn")


static func _spawn_vfx(scene: PackedScene, parent: Node, pos: Vector2, flip_h: bool = false) -> void:
	var effect: AnimatedSprite2D = scene.instantiate()
	parent.add_child(effect)
	effect.global_position = pos
	effect.flip_h = flip_h


static func apply(player: CharacterBody2D, skill: Dictionary) -> void:
	match skill.get("effect", ""):
		"melee_burst":
			_melee_burst(player, skill)
		"on_hit_proc":
			_on_hit_proc(player, skill)
		"buff":
			_buff(player, skill)
		"dash_attack":
			_dash_attack(player, skill)
		"dash_speed":
			_dash_speed(player, skill)
		"pulse_aoe":
			_pulse_aoe(player, skill)
		"multi_projectile":
			_multi_projectile(player, skill)
		"piercing_projectile":
			_piercing_projectile(player, skill)
		"ground_aoe_zone":
			_ground_aoe_zone(player, skill)
		"evasion":
			_evasion(player, skill)
		"summon_wall":
			_summon_wall(player, skill)


# Chamado por player_base.gd toda vez que um ataque NORMAL acerta alguém,
# enquanto uma skill "on_hit_proc" (Lâmina de Vento, Veneno Cortante) está
# ativa.
static func trigger_proc(player: CharacterBody2D, proc_skill: Dictionary, hit_enemy: Node) -> void:
	match proc_skill.get("proc_type", ""):
		"wind":
			var dmg := _damage(float(proc_skill.get("proc_damage_mult", 2.0)))
			var radius := BASE_MELEE_RANGE * float(proc_skill.get("proc_range_mult", 1.5))
			var angle: float = proc_skill.get("proc_angle_deg", 100.0)
			for enemy in _enemies_in_cone(player, radius, angle):
				enemy.take_hit(dmg)
				_spawn_vfx(ProcEffect, player.get_parent(), enemy.global_position, player.get_facing_dir().x < 0.0)
		"poison":
			if hit_enemy and hit_enemy.has_method("apply_poison"):
				_spawn_vfx(AuraEffect, player.get_parent(), hit_enemy.global_position)
				hit_enemy.apply_poison(
					int(proc_skill.get("poison_damage", 2)),
					float(proc_skill.get("poison_tick", 1.0)),
					float(proc_skill.get("poison_duration", 3.0)))


static func _damage(mult: float) -> int:
	return int(round(BASE_ATTACK_DAMAGE * mult * PlayerStats.damage_dealt_mult))


# --- ataques instantâneos em área ---------------------------------------


static func _melee_burst(player: CharacterBody2D, skill: Dictionary) -> void:
	var radius := BASE_MELEE_RANGE * float(skill.get("range_mult", 1.0))
	var angle: float = skill.get("angle_deg", 140.0)
	var dmg := _damage(float(skill.get("damage_mult", 1.0)))
	var flip: bool = player.get_facing_dir().x < 0.0
	_spawn_vfx(BurstEffect, player.get_parent(), player.global_position + player.get_facing_dir() * radius * 0.6 + Vector2(0, -40), flip)
	for enemy in _enemies_in_cone(player, radius, angle):
		enemy.take_hit(dmg)


static func _enemies_in_cone(player: CharacterBody2D, radius: float, angle_deg: float) -> Array:
	var result: Array = []
	var origin: Vector2 = player.global_position
	var facing: Vector2 = player.get_facing_dir()
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_hit"):
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		var dist := to_enemy.length()
		if dist > radius:
			continue
		if angle_deg < 360.0 and dist > 0.01:
			var diff := absf(rad_to_deg(facing.angle_to(to_enemy)))
			if diff > angle_deg * 0.5:
				continue
		result.append(enemy)
	return result


# --- proc temporário no ataque normal ------------------------------------


static func _on_hit_proc(player: CharacterBody2D, skill: Dictionary) -> void:
	player.set_active_proc(skill)
	await player.get_tree().create_timer(float(skill.get("duration", 10.0))).timeout
	if is_instance_valid(player):
		player.clear_active_proc(skill.get("id", ""))


# --- buff de status (cura + multiplicadores temporários) -----------------


static func _buff(player: CharacterBody2D, skill: Dictionary) -> void:
	_spawn_vfx(AuraEffect, player.get_parent(), player.global_position + Vector2(0, -40))
	PlayerStats.apply_buff(
		float(skill.get("duration", 0.0)),
		float(skill.get("speed_mult", 1.0)),
		float(skill.get("damage_dealt_mult", 1.0)),
		float(skill.get("damage_taken_mult", 1.0)),
		float(skill.get("regen_bonus", 0.0)),
		int(skill.get("hp_bonus", 0)),
		float(skill.get("heal_pct", 0.0)))


# --- deslocamento ----------------------------------------------------------


static func _dash_attack(player: CharacterBody2D, skill: Dictionary) -> void:
	var distance: float = skill.get("distance", 120.0)
	var dmg := _damage(float(skill.get("damage_mult", 1.5)))
	var start: Vector2 = player.global_position
	var end: Vector2 = start + player.get_facing_dir() * distance
	player.global_position = end
	_spawn_vfx(BurstEffect, player.get_parent(), end + Vector2(0, -40), player.get_facing_dir().x < 0.0)
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_hit"):
			continue
		if _point_segment_dist(enemy.global_position, start, end) <= DASH_HIT_RADIUS:
			enemy.take_hit(dmg)


static func _dash_speed(player: CharacterBody2D, skill: Dictionary) -> void:
	var distance: float = skill.get("distance", 100.0)
	var dir: Vector2 = player.get_facing_dir()
	if skill.get("backward", false):
		dir = -dir
	_spawn_vfx(ProcEffect, player.get_parent(), player.global_position + Vector2(0, -40), dir.x < 0.0)
	player.global_position += dir * distance
	PlayerStats.apply_buff(float(skill.get("boost_duration", 2.0)), float(skill.get("speed_boost_mult", 1.5)))


static func _point_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _evasion(player: CharacterBody2D, skill: Dictionary) -> void:
	_spawn_vfx(AuraEffect, player.get_parent(), player.global_position + Vector2(0, -40))
	player.is_invulnerable = true
	await player.get_tree().create_timer(float(skill.get("duration", 1.2))).timeout
	if is_instance_valid(player):
		player.is_invulnerable = false


# --- dano ao longo do tempo em área ----------------------------------------


static func _pulse_aoe(player: CharacterBody2D, skill: Dictionary) -> void:
	var duration: float = skill.get("duration", 6.0)
	var tick: float = skill.get("tick_interval", 1.0)
	var radius: float = skill.get("radius", 90.0)
	var dmg := _damage(float(skill.get("damage_per_tick", 3)))
	var ticks := int(duration / maxf(tick, 0.1))
	for i in ticks:
		await player.get_tree().create_timer(tick).timeout
		if not is_instance_valid(player):
			return
		_spawn_vfx(AuraEffect, player.get_parent(), player.global_position + Vector2(0, -40))
		for enemy in player.get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and enemy.has_method("take_hit"):
				if enemy.global_position.distance_to(player.global_position) <= radius:
					enemy.take_hit(dmg)


# Zona fixa no chão (não segue o jogador) — Chuva de Flechas, Nevasca.
static func _ground_aoe_zone(player: CharacterBody2D, skill: Dictionary) -> void:
	var range_dist: float = skill.get("range", 140.0)
	var radius: float = skill.get("radius", 70.0)
	var duration: float = skill.get("duration", 4.0)
	var tick: float = skill.get("tick_interval", 0.5)
	var dmg := _damage(float(skill.get("damage_per_tick", 2)))
	var center: Vector2 = player.global_position + player.get_facing_dir() * range_dist

	var zone := Node2D.new()
	zone.z_index = -1
	zone.global_position = center
	var visual := Polygon2D.new()
	visual.polygon = _circle_points(radius)
	visual.color = Color(0.6, 0.8, 1.0, 0.25)
	zone.add_child(visual)
	player.get_parent().add_child(zone)

	var ticks := int(duration / maxf(tick, 0.05))
	for i in ticks:
		await player.get_tree().create_timer(tick).timeout
		if not is_instance_valid(zone):
			return
		_spawn_vfx(BurstEffect, player.get_parent(), center)
		for enemy in player.get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy) and enemy.has_method("take_hit"):
				if enemy.global_position.distance_to(center) <= radius:
					enemy.take_hit(dmg)
	if is_instance_valid(zone):
		zone.queue_free()


static func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * float(i) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


# --- projétil (só funciona em classe com projectile_scene — hoje só o
# Arqueiro; o Feiticeiro usaria a mesma coisa quando existir) --------------


static func _multi_projectile(player: CharacterBody2D, skill: Dictionary) -> void:
	if player.projectile_scene == null:
		return
	var count: int = int(skill.get("count", 3))
	var spread: float = skill.get("spread_deg", 24.0)
	var base_dir: Vector2 = player.get_facing_dir()
	var step: float = 0.0 if count <= 1 else spread / float(count - 1)
	var start_angle := -spread * 0.5
	for i in count:
		var dir: Vector2 = base_dir.rotated(deg_to_rad(start_angle + step * i))
		_fire_projectile(player, dir, 1.0, false)


static func _piercing_projectile(player: CharacterBody2D, skill: Dictionary) -> void:
	if player.projectile_scene == null:
		return
	_fire_projectile(player, player.get_facing_dir(), float(skill.get("damage_mult", 1.8)), true)


static func _fire_projectile(player: CharacterBody2D, dir: Vector2, damage_mult: float, piercing: bool) -> void:
	var arrow: Node2D = player.projectile_scene.instantiate()
	player.get_parent().add_child(arrow)
	arrow.global_position = player.global_position + Vector2(0, -30)
	if "damage" in arrow:
		arrow.damage = _damage(damage_mult)
	if piercing and ("piercing" in arrow):
		arrow.piercing = true
	arrow.set_direction(dir)


# --- obstáculo temporário ---------------------------------------------------


static func _summon_wall(player: CharacterBody2D, skill: Dictionary) -> void:
	var distance: float = skill.get("distance", 50.0)
	var width: float = skill.get("width", 80.0)
	var duration: float = skill.get("duration", 8.0)
	var center: Vector2 = player.global_position + player.get_facing_dir() * distance

	var wall := StaticBody2D.new()
	wall.global_position = center

	var half := width * 0.5
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-8, -half), Vector2(8, -half), Vector2(8, half), Vector2(-8, half),
	])
	visual.color = Color(0.5, 0.45, 0.4, 0.95)
	wall.add_child(visual)

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16.0, width)
	shape.shape = box
	wall.add_child(shape)

	player.get_parent().add_child(wall)
	await player.get_tree().create_timer(duration).timeout
	if is_instance_valid(wall):
		wall.queue_free()
