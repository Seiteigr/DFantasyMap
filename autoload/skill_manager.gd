extends Node

# Autoload (singleton) — acessível em qualquer script como "SkillManager".
# Guarda quais skills estão desbloqueadas e o cooldown de cada uma. Não sabe
# nada sobre COMO uma skill funciona (isso é com scripts/skills/skill_effects.gd)
# — só controla "pode ativar agora?" (desbloqueada + cooldown zerado + mana
# suficiente) e desconta mana/inicia cooldown quando pode.

signal skill_unlocked(skill_id: String)
signal cooldown_started(skill_id: String, duration: float)

var unlocked: Dictionary = {}		# skill_id -> true
var _cooldowns: Dictionary = {}	# skill_id -> segundos restantes


func reset() -> void:
	unlocked.clear()
	_cooldowns.clear()


func _process(delta: float) -> void:
	if _cooldowns.is_empty():
		return
	for skill_id in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(_cooldowns[skill_id] - delta, 0.0)
		if _cooldowns[skill_id] <= 0.0:
			_cooldowns.erase(skill_id)


func is_unlocked(skill_id: String) -> bool:
	return unlocked.get(skill_id, false)


func unlock(skill_id: String) -> bool:
	if is_unlocked(skill_id) or PlayerStats.skill_points <= 0:
		return false
	unlocked[skill_id] = true
	PlayerStats.skill_points -= 1
	PlayerStats.stats_changed.emit()
	skill_unlocked.emit(skill_id)
	return true


func get_cooldown_remaining(skill_id: String) -> float:
	return _cooldowns.get(skill_id, 0.0)


func is_ready(skill_id: String) -> bool:
	return get_cooldown_remaining(skill_id) <= 0.0


# Confere se dá pra ativar (desbloqueada + sem cooldown + mana suficiente),
# e se der, já desconta a mana e inicia o cooldown. Quem chamou só aplica o
# efeito de verdade depois de receber `true` daqui (ver skill_effects.gd).
func try_cast(skill: Dictionary) -> bool:
	var skill_id: String = skill.get("id", "")
	if skill_id == "" or not is_unlocked(skill_id) or not is_ready(skill_id):
		return false
	if not PlayerStats.spend_mana(float(skill.get("mana_cost", 0.0))):
		return false
	var cooldown := float(skill.get("cooldown", 5.0))
	_cooldowns[skill_id] = cooldown
	cooldown_started.emit(skill_id, cooldown)
	return true
