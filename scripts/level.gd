extends Node2D

# Preso ao nó raiz do mapa. Ao entrar na cena, instancia a classe
# escolhida na tela de seleção de personagem (GameManager) e posiciona
# a câmera com os limites do mapa.

const WORLD_LEFT := 0
const WORLD_TOP := 0
const WORLD_RIGHT := 1520
const WORLD_BOTTOM := 1200

@onready var player_spawn: Marker2D = $PlayerSpawn


func _ready() -> void:
	var scene_path: String = GameManager.get_selected_scene_path()
	var player_scene: PackedScene = load(scene_path)
	var player: CharacterBody2D = player_scene.instantiate()
	player.position = player_spawn.position
	add_child(player)

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera:
		camera.limit_left = WORLD_LEFT
		camera.limit_top = WORLD_TOP
		camera.limit_right = WORLD_RIGHT
		camera.limit_bottom = WORLD_BOTTOM
		camera.make_current()
