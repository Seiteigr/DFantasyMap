extends Node

# Autoload (singleton) — acessível em qualquer script como "PlayerStats".
# Nível, XP e os 3 atributos simplificados estilo Ragnarok Online:
#   Magia    -> mana máxima e dano de feitiço
#   Colosso  -> HP máximo e dano físico
#   Destreza -> velocidade de movimento e esquiva
# HP/mana continuam sendo "quanto falta pra morrer/ficar sem mana", só que
# agora o teto deles é calculado a partir do atributo em vez de fixo.
#
# Cada level up também dá 1 ponto de HABILIDADE (skill_points), separado dos
# 3 pontos de atributo — gasto na árvore de skills (SkillManager), não aqui.
#
# Buffs de skill (Corpo Fechado, Bênção de Vigor, Recuperação Arcana etc.)
# moram aqui como multiplicadores temporários com um único timer — é um v1
# simples que não empilha buff em cima de buff (o mais novo substitui o
# anterior), suficiente pra uma habilidade ativa por vez.

signal stats_changed
signal level_up(new_level: int)
signal hp_changed(current: int, max_hp: int)
signal mana_changed(current: float, max_mana: int)
signal buff_changed(time_left: float)

const BASE_HP := 20
const BASE_MANA := 10
const HP_PER_COLOSSO := 10
const MANA_PER_MAGIA := 8
const XP_PER_LEVEL := 20
const ATTRIBUTE_POINTS_PER_LEVEL := 3
const SKILL_POINTS_PER_LEVEL := 1
const BASE_MANA_REGEN := 2.0	# mana por segundo, sempre ativo

var level: int = 1
var xp: int = 0
var xp_to_next: int = XP_PER_LEVEL
var free_points: int = 0
var skill_points: int = 0

var magic: int = 1
var colosso: int = 1
var dex: int = 1

var hp: int
var mana: float

# Multiplicadores temporários (skills como Corpo Fechado/Bênção de Vigor
# mexem aqui). Voltam ao normal sozinhos quando `_buff_time_left` zera.
var speed_mult: float = 1.0
var damage_dealt_mult: float = 1.0
var damage_taken_mult: float = 1.0
var mana_regen_bonus: float = 0.0
var bonus_hp: int = 0

var _buff_time_left: float = 0.0


func _ready() -> void:
	reset_stats()


func _process(delta: float) -> void:
	if mana < max_mana():
		mana = minf(mana + (BASE_MANA_REGEN + mana_regen_bonus) * delta, max_mana())
		mana_changed.emit(mana, max_mana())

	if _buff_time_left > 0.0:
		_buff_time_left -= delta
		buff_changed.emit(maxf(_buff_time_left, 0.0))
		if _buff_time_left <= 0.0:
			_clear_buff()


func reset_stats() -> void:
	level = 1
	xp = 0
	xp_to_next = XP_PER_LEVEL
	free_points = 0
	skill_points = 0
	magic = 1
	colosso = 1
	dex = 1
	_clear_buff()
	hp = max_hp()
	mana = max_mana()
	stats_changed.emit()
	hp_changed.emit(hp, max_hp())
	mana_changed.emit(mana, max_mana())


func max_hp() -> int:
	return BASE_HP + colosso * HP_PER_COLOSSO + bonus_hp


func max_mana() -> int:
	return BASE_MANA + magic * MANA_PER_MAGIA


# Bônus simples de velocidade: cada ponto de Destreza soma um pouco ao
# speed base da classe (lido por player_base.gd).
func move_speed_bonus() -> float:
	return dex * 4.0


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		free_points += ATTRIBUTE_POINTS_PER_LEVEL
		skill_points += SKILL_POINTS_PER_LEVEL
		xp_to_next = level * XP_PER_LEVEL
		level_up.emit(level)
	stats_changed.emit()


func allocate_point(stat_name: String) -> bool:
	if free_points <= 0:
		return false
	match stat_name:
		"magic":
			magic += 1
			mana = max_mana()
		"colosso":
			colosso += 1
			hp = max_hp()
		"dex":
			dex += 1
		_:
			return false
	free_points -= 1
	stats_changed.emit()
	hp_changed.emit(hp, max_hp())
	mana_changed.emit(mana, max_mana())
	return true


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	var effective := int(round(amount * damage_taken_mult))
	hp = max(hp - effective, 0)
	hp_changed.emit(hp, max_hp())
	if hp <= 0:
		GameManager.game_over()


func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(hp + amount, max_hp())
	hp_changed.emit(hp, max_hp())


func spend_mana(amount: float) -> bool:
	if mana < amount:
		return false
	mana -= amount
	mana_changed.emit(mana, max_mana())
	return true


# Aplica um "estado" temporário — qualquer parâmetro omitido mantém o valor
# neutro (sem efeito). Um buff novo sempre substitui o anterior (sem
# empilhar), o que é suficiente enquanto só existe uma habilidade ativa por
# vez em cada classe.
func apply_buff(duration: float, speed: float = 1.0, dmg_dealt: float = 1.0,
		dmg_taken: float = 1.0, regen_bonus: float = 0.0, hp_bonus: int = 0, heal_pct: float = 0.0) -> void:
	if heal_pct > 0.0:
		heal(int(round(max_hp() * heal_pct)))
	if duration <= 0.0:
		return
	speed_mult = speed
	damage_dealt_mult = dmg_dealt
	damage_taken_mult = dmg_taken
	mana_regen_bonus = regen_bonus
	bonus_hp = hp_bonus
	if hp_bonus > 0:
		hp = mini(hp + hp_bonus, max_hp())
	_buff_time_left = duration
	stats_changed.emit()
	hp_changed.emit(hp, max_hp())
	buff_changed.emit(_buff_time_left)


func _clear_buff() -> void:
	speed_mult = 1.0
	damage_dealt_mult = 1.0
	damage_taken_mult = 1.0
	mana_regen_bonus = 0.0
	bonus_hp = 0
	_buff_time_left = 0.0
	hp = mini(hp, max_hp())
	stats_changed.emit()
	buff_changed.emit(0.0)
