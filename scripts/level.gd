extends Node2D

# Preso ao nó raiz do mapa. Manda o WorldBuilder montar o mundo (4 biomas
# orgânicos, mar, estradas, marcos e povoação), spawna a classe escolhida,
# acerta os limites da câmera e cuida da UI que reage à exploração (nome do
# bioma, minimapa, falas de ambientação).

const WorldBuilder := preload("res://scripts/world/world_builder.gd")
const Minimap := preload("res://scripts/world/minimap.gd")
const MerchantScene := preload("res://scenes/npc/Merchant.tscn")

const FLAVOR_LATER_DELAY := 5.0

@onready var entities: Node2D = $Entities
@onready var biome_label: Label = $HUD/BiomeLabel
@onready var flavor_label: Label = $HUD/FlavorLabel
@onready var minimap: Control = $HUD/Minimap

var _player: CharacterBody2D
var _world: Dictionary
var _current_biome_id: String = ""
var _shown_enter: Dictionary = {}
var _shown_later: Dictionary = {}
var _time_in_biome: float = 0.0


func _ready() -> void:
	_world = WorldBuilder.build(self, entities)
	_spawn_player()
	_spawn_merchant()
	minimap.setup(_world["terrain"], _world["world_size"], _world["landmark_points"])
	minimap.follow(_player)
	_update_biome()


func _spawn_player() -> void:
	var player_scene: PackedScene = load(GameManager.get_selected_scene_path())
	_player = player_scene.instantiate()
	_player.position = WorldBuilder.spawn_point()
	# Entra no mesmo nó dos props e inimigos: é o nó com y_sort ligado, então
	# quem está mais embaixo na tela desenha por cima (o jogador passa atrás
	# das árvores em vez de flutuar sobre elas).
	entities.add_child(_player)

	var camera: Camera2D = _player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(_world["world_size"].x)
		camera.limit_bottom = int(_world["world_size"].y)
		camera.make_current()


func _spawn_merchant() -> void:
	# Fica pertinho do spawn, na Floresta — fácil de achar sem precisar
	# explorar, e não atrapalha os inimigos que nascem mais longe.
	var merchant: Area2D = MerchantScene.instantiate()
	merchant.position = WorldBuilder.spawn_point() + Vector2(60, 20)
	entities.add_child(merchant)


func _process(delta: float) -> void:
	_update_biome()
	if _current_biome_id != "":
		_time_in_biome += delta
		_maybe_show_later_flavor()


func _update_biome() -> void:
	if not is_instance_valid(_player):
		return
	var label := WorldBuilder.biome_at(_world, _player.position)
	if label == biome_label.text:
		return
	biome_label.text = label

	var biome_id := _biome_id_for_label(label)
	if biome_id != _current_biome_id:
		_current_biome_id = biome_id
		_time_in_biome = 0.0
		_maybe_show_enter_flavor(biome_id)


func _biome_id_for_label(label: String) -> String:
	for biome in _world["biomes"]:
		if biome["label"] == label:
			return biome["id"]
	return ""


func _maybe_show_enter_flavor(biome_id: String) -> void:
	if biome_id == "" or _shown_enter.has(biome_id):
		return
	_shown_enter[biome_id] = true
	for biome in _world["biomes"]:
		if biome["id"] == biome_id:
			_show_flavor(biome["flavor_enter"])
			return


func _maybe_show_later_flavor() -> void:
	if _current_biome_id == "" or _shown_later.has(_current_biome_id):
		return
	if _time_in_biome < FLAVOR_LATER_DELAY:
		return
	_shown_later[_current_biome_id] = true
	for biome in _world["biomes"]:
		if biome["id"] == _current_biome_id:
			_show_flavor(biome["flavor_later"])
			return


func _show_flavor(text: String) -> void:
	flavor_label.text = text
	flavor_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.6)
	tween.tween_property(flavor_label, "modulate:a", 0.0, 1.2)
