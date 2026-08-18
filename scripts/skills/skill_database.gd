extends Node

# Autoload (singleton) — acessível em qualquer script como "SkillDatabase".
# Tabela central das árvores de skill, uma entrada de classe -> lista de 4
# habilidades (mesmo espírito da tabela de biomas e do ItemDatabase: mudar
# um número aqui já muda o jogo, sem mexer em cena nenhuma).
#
# Cada skill tem "effect" (uma chave que scripts/skills/skill_effects.gd
# sabe interpretar) + os parâmetros que esse efeito usa. `id` é usado pelo
# SkillManager pra guardar desbloqueio/cooldown; a ordem dentro da lista da
# classe é a ordem dos slots Q/W/R/F.
#
# "mage" é a classe Feiticeiro/Mago de verdade — ainda não é jogável (sem
# sprite no pacote de assets, ver README), mas a árvore já existe pronta
# pra quando ela entrar.

const SKILLS := {
	"warrior": [
		{
			"id": "explosive_strike", "name": "Golpe Explosivo",
			"description": "Ataque único com o dobro de alcance e o dobro de dano da espadada normal.",
			"cooldown": 6.0, "mana_cost": 15.0,
			"effect": "melee_burst", "range_mult": 2.0, "damage_mult": 2.0, "angle_deg": 140.0,
		},
		{
			"id": "wind_blade", "name": "Lâmina de Vento",
			"description": "Por 10s, cada acerto de espada solta um rasante de vento com mais alcance e o dobro de dano.",
			"cooldown": 18.0, "mana_cost": 25.0,
			"effect": "on_hit_proc", "duration": 10.0, "proc_type": "wind",
			"proc_damage_mult": 2.0, "proc_range_mult": 1.8, "proc_angle_deg": 100.0,
		},
		{
			"id": "close_body", "name": "Corpo Fechado",
			"description": "Recupera metade do HP máximo; por 10s fica mais lento, causa o dobro de dano e recebe menos dano.",
			"cooldown": 30.0, "mana_cost": 30.0,
			"effect": "buff", "duration": 10.0, "heal_pct": 0.5,
			"speed_mult": 0.7, "damage_dealt_mult": 2.0, "damage_taken_mult": 0.7,
		},
		{
			"id": "charge", "name": "Investida",
			"description": "Avança rápido pra frente, atropelando quem estiver no caminho.",
			"cooldown": 10.0, "mana_cost": 15.0,
			"effect": "dash_attack", "distance": 140.0, "damage_mult": 1.5,
		},
	],
	"cleric": [
		{
			"id": "greater_heal", "name": "Cura Maior",
			"description": "Recupera uma boa parte do HP máximo.",
			"cooldown": 12.0, "mana_cost": 35.0,
			"effect": "buff", "duration": 0.0, "heal_pct": 0.45,
		},
		{
			"id": "holy_light", "name": "Luz Purificadora",
			"description": "Explosão de luz sagrada num cone à frente.",
			"cooldown": 8.0, "mana_cost": 25.0,
			"effect": "melee_burst", "range_mult": 1.8, "damage_mult": 1.6, "angle_deg": 100.0,
		},
		{
			"id": "blessing", "name": "Bênção de Vigor",
			"description": "Por 12s, aumenta o HP máximo e reduz o dano recebido.",
			"cooldown": 25.0, "mana_cost": 30.0,
			"effect": "buff", "duration": 12.0, "hp_bonus": 15, "damage_taken_mult": 0.75,
		},
		{
			"id": "radiant_aura", "name": "Aura Radiante",
			"description": "Por 6s, pulsa dano nos inimigos ao redor do clérigo.",
			"cooldown": 20.0, "mana_cost": 35.0,
			"effect": "pulse_aoe", "duration": 6.0, "tick_interval": 1.0, "radius": 90.0, "damage_per_tick": 3,
		},
	],
	"archer": [
		{
			"id": "multi_shot", "name": "Tiro Múltiplo",
			"description": "Dispara 3 flechas em leque.",
			"cooldown": 8.0, "mana_cost": 20.0,
			"effect": "multi_projectile", "count": 3, "spread_deg": 24.0,
		},
		{
			"id": "piercing_shot", "name": "Tiro Perfurante",
			"description": "Flecha forte que atravessa vários inimigos em linha.",
			"cooldown": 10.0, "mana_cost": 22.0,
			"effect": "piercing_projectile", "damage_mult": 1.8,
		},
		{
			"id": "arrow_rain", "name": "Chuva de Flechas",
			"description": "Uma área à frente recebe flechas por alguns segundos.",
			"cooldown": 16.0, "mana_cost": 30.0,
			"effect": "ground_aoe_zone", "duration": 4.0, "tick_interval": 0.5,
			"radius": 70.0, "damage_per_tick": 2, "range": 150.0,
		},
		{
			"id": "nimble_step", "name": "Passo Ágil",
			"description": "Pulo rápido pra trás com um pique de velocidade.",
			"cooldown": 9.0, "mana_cost": 15.0,
			"effect": "dash_speed", "distance": 110.0, "backward": true,
			"speed_boost_mult": 1.5, "boost_duration": 2.0,
		},
	],
	"rogue": [
		{
			"id": "backstab", "name": "Facada Furtiva",
			"description": "Golpe com dano bem maior que o normal.",
			"cooldown": 7.0, "mana_cost": 18.0,
			"effect": "melee_burst", "range_mult": 1.1, "damage_mult": 2.2, "angle_deg": 100.0,
		},
		{
			"id": "shadow_step", "name": "Passo das Sombras",
			"description": "Dash curto atravessando inimigos no caminho.",
			"cooldown": 11.0, "mana_cost": 20.0,
			"effect": "dash_attack", "distance": 150.0, "damage_mult": 1.3,
		},
		{
			"id": "venom_edge", "name": "Veneno Cortante",
			"description": "Por 10s, os golpes aplicam veneno (dano ao longo do tempo).",
			"cooldown": 18.0, "mana_cost": 25.0,
			"effect": "on_hit_proc", "duration": 10.0, "proc_type": "poison",
			"poison_damage": 2, "poison_tick": 1.0, "poison_duration": 3.0,
		},
		{
			"id": "evasion", "name": "Evasão",
			"description": "Fica invulnerável por um instante.",
			"cooldown": 14.0, "mana_cost": 20.0,
			"effect": "evasion", "duration": 1.2,
		},
	],
	# Feiticeiro/Mago de verdade — dados prontos, classe ainda não jogável.
	"mage": [
		{
			"id": "fire_bolt", "name": "Rajada de Fogo",
			"description": "Dispara uma rajada de fogo à frente.",
			"cooldown": 6.0, "mana_cost": 20.0,
			"effect": "piercing_projectile", "damage_mult": 1.4,
		},
		{
			"id": "stone_wall", "name": "Parede de Pedra",
			"description": "Ergue uma parede de pedra que bloqueia o caminho dos inimigos por um tempo.",
			"cooldown": 20.0, "mana_cost": 30.0,
			"effect": "summon_wall", "duration": 8.0, "width": 80.0, "distance": 50.0,
		},
		{
			"id": "blizzard", "name": "Nevasca",
			"description": "Área congelante que causa dano ao longo do tempo numa região grande.",
			"cooldown": 22.0, "mana_cost": 40.0,
			"effect": "ground_aoe_zone", "duration": 5.0, "tick_interval": 1.0,
			"radius": 110.0, "damage_per_tick": 4, "range": 160.0,
		},
		{
			"id": "arcane_recovery", "name": "Recuperação Arcana",
			"description": "Por alguns segundos, recupera mana bem mais rápido.",
			"cooldown": 30.0, "mana_cost": 0.0,
			"effect": "buff", "duration": 8.0, "regen_bonus": 6.0,
		},
	],
}


func get_skills(class_id: String) -> Array:
	return SKILLS.get(class_id, [])


func get_skill(class_id: String, skill_id: String) -> Dictionary:
	for skill in get_skills(class_id):
		if skill["id"] == skill_id:
			return skill
	return {}
