extends Control

# Minimapa simples: um retrato em miniatura do terreno (gerado uma vez a
# partir da mesma grade que desenha o mapa grande) com um ponto pro
# jogador e um pontinho fixo pra cada marco de bioma.

const SIZE := Vector2(150.0, 110.0)

var _world_size: Vector2
var _player: Node2D
var _dot: ColorRect


func setup(terrain: RefCounted, world_size: Vector2, landmark_points: Array) -> void:
	_world_size = world_size
	custom_minimum_size = SIZE
	size = SIZE

	var bg := Panel.new()
	bg.size = SIZE
	bg.self_modulate = Color(0, 0, 0, 0.35)
	add_child(bg)

	var map_image := TextureRect.new()
	map_image.texture = _shrink(terrain)
	map_image.size = SIZE
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(map_image)

	for point in landmark_points:
		var mark := ColorRect.new()
		mark.size = Vector2(4, 4)
		mark.position = _to_map(point) - Vector2(2, 2)
		mark.color = Color(1.0, 0.85, 0.2, 0.9)
		add_child(mark)

	_dot = ColorRect.new()
	_dot.size = Vector2(5, 5)
	_dot.color = Color(1, 1, 1, 1)
	add_child(_dot)

	var border := Panel.new()
	border.size = SIZE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)


func follow(player: Node2D) -> void:
	_player = player


func _process(_delta: float) -> void:
	if is_instance_valid(_player) and _dot:
		_dot.position = _to_map(_player.position) - Vector2(2.5, 2.5)


func _to_map(world_point: Vector2) -> Vector2:
	return Vector2(
		world_point.x / _world_size.x * SIZE.x,
		world_point.y / _world_size.y * SIZE.y)


# Reduz a grade do terreno pra um punhado de pixels — não precisa de um
# pixel por célula, só o suficiente pra reconhecer o formato das ilhas.
func _shrink(terrain: RefCounted) -> ImageTexture:
	var w := 75
	var h := 55
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var gx := int(float(x) / w * terrain.cols)
			var gy := int(float(y) / h * terrain.rows)
			var kind: int = terrain.at(gx, gy)
			var color: Color
			match kind:
				terrain.WATER:
					color = Color(0.10, 0.22, 0.38, 0.9)
				terrain.SAND:
					color = Color(0.75, 0.68, 0.48, 1.0)
				terrain.PATH:
					color = Color(0.45, 0.32, 0.18, 1.0)
				_:
					var b: int = terrain.biome_of[terrain.index(gx, gy)]
					color = _biome_tone(b)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _biome_tone(biome_index: int) -> Color:
	match biome_index:
		0: return Color(0.30, 0.48, 0.24)
		1: return Color(0.80, 0.66, 0.38)
		2: return Color(0.46, 0.46, 0.42)
		3: return Color(0.24, 0.22, 0.32)
	return Color(0.2, 0.2, 0.2)
