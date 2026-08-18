extends Control

# HUD de status: barra de HP (vermelha), barra de mana (azul) e nível.
# Substituiu os 4 corações fixos — agora HP/mana têm teto variável, calculado
# pelo PlayerStats a partir dos atributos (Colosso e Magia).

const BAR_WIDTH := 180.0
const BAR_HEIGHT := 14.0
const BAR_GAP := 4.0
const HP_COLOR := Color(0.851, 0.157, 0.157, 1)
const MANA_COLOR := Color(0.2, 0.45, 0.9, 1)
const EMPTY_COLOR := Color(0.16, 0.13, 0.1, 1)
const OUTLINE_COLOR := Color(0.1, 0.08, 0.04, 1)

var _hp: int
var _hp_max: int
var _mana: int
var _mana_max: int
var _level: int


func _ready() -> void:
	_hp = PlayerStats.hp
	_hp_max = PlayerStats.max_hp()
	_mana = PlayerStats.mana
	_mana_max = PlayerStats.max_mana()
	_level = PlayerStats.level
	PlayerStats.hp_changed.connect(_on_hp_changed)
	PlayerStats.mana_changed.connect(_on_mana_changed)
	PlayerStats.stats_changed.connect(_on_stats_changed)
	custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT * 2 + BAR_GAP)
	queue_redraw()


func _on_hp_changed(current: int, max_hp: int) -> void:
	_hp = current
	_hp_max = max_hp
	queue_redraw()


func _on_mana_changed(current: int, max_mana: int) -> void:
	_mana = current
	_mana_max = max_mana
	queue_redraw()


func _on_stats_changed() -> void:
	_level = PlayerStats.level
	queue_redraw()


func _draw() -> void:
	_draw_bar(0.0, _hp, _hp_max, HP_COLOR)
	_draw_bar(BAR_HEIGHT + BAR_GAP, _mana, _mana_max, MANA_COLOR)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(BAR_WIDTH + 8, BAR_HEIGHT), "Lv. %d" % _level, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _draw_bar(y: float, current: int, max_value: int, color: Color) -> void:
	var rect := Rect2(0, y, BAR_WIDTH, BAR_HEIGHT)
	draw_rect(rect, EMPTY_COLOR)
	var ratio: float = 0.0 if max_value <= 0 else float(current) / float(max_value)
	draw_rect(Rect2(0, y, BAR_WIDTH * ratio, BAR_HEIGHT), color)
	draw_rect(rect, OUTLINE_COLOR, false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(4, y + BAR_HEIGHT - 3), "%d/%d" % [current, max_value], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
