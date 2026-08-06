extends RefCounted

# Terreno do mundo: decide o que é terra, areia, caminho e mar, e "assa"
# tudo numa textura só.
#
# A ideia central: em vez de guardar milhares de nós de chão, o mundo vira
# uma grade de células pequenas (CELL px cada). A grade responde três
# perguntas — o que tem aqui? de que bioma é? dá pra andar? — e a partir
# dela sai (1) uma imagem do mundo inteiro, (2) os retângulos de colisão e
# (3) os pontos onde espalhar árvore e inimigo.
#
# O formato das ilhas vem de ruído (FastNoiseLite), então a costa fica
# irregular, com baías e penínsulas, em vez de um retângulo perfeito.

const CELL := 6.0			# lado de cada célula da grade, em pixels
const COLLISION_CELL := 3	# a colisão usa blocos de 3x3 células (18px)

# O que tem em cada célula.
const WATER := 0
const LAND := 1
const SAND := 2
const PATH := 3

const NO_BIOME := 255

# Acima disso a célula vira terra. Mexer aqui engorda ou afina as ilhas.
const LAND_THRESHOLD := 0.12

# Raios (em células) usados ao abrir caminho: a terra é forçada num raio
# maior que a trilha, pra estrada não virar uma ponte de terra fininha.
const PATH_RADIUS := 3
const PATH_LAND_RADIUS := 8

var cols: int
var rows: int
var cells: PackedByteArray		# WATER / LAND / SAND / PATH
var biome_of: PackedByteArray	# índice do bioma, ou NO_BIOME

var _shape := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _world_size: Vector2


func _init(world_size: Vector2, map_seed: int) -> void:
	_world_size = world_size
	cols = int(ceil(world_size.x / CELL))
	rows = int(ceil(world_size.y / CELL))
	cells = PackedByteArray()
	cells.resize(cols * rows)
	biome_of = PackedByteArray()
	biome_of.resize(cols * rows)
	biome_of.fill(NO_BIOME)

	_rng.seed = map_seed

	# Ruído grande: desenha o contorno da ilha.
	_shape.seed = map_seed
	_shape.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shape.frequency = 0.0030
	_shape.fractal_octaves = 4

	# Ruído pequeno: manchas de grama clara/escura e terra batida.
	_detail.seed = map_seed + 977
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail.frequency = 0.012
	_detail.fractal_octaves = 2


# --- consultas -------------------------------------------------------------


func index(gx: int, gy: int) -> int:
	return gy * cols + gx


func inside(gx: int, gy: int) -> bool:
	return gx >= 0 and gy >= 0 and gx < cols and gy < rows


func to_grid(point: Vector2) -> Vector2i:
	return Vector2i(int(point.x / CELL), int(point.y / CELL))


func to_world(gx: int, gy: int) -> Vector2:
	return Vector2(gx * CELL + CELL * 0.5, gy * CELL + CELL * 0.5)


func at(gx: int, gy: int) -> int:
	if not inside(gx, gy):
		return WATER
	return cells[index(gx, gy)]


func is_walkable(gx: int, gy: int) -> bool:
	return at(gx, gy) != WATER


func is_walkable_point(point: Vector2) -> bool:
	var g := to_grid(point)
	return is_walkable(g.x, g.y)


# Terra firme com folga em volta: usado pra não plantar árvore na beirada
# nem em cima da estrada.
func is_free_land(gx: int, gy: int, margin: int) -> bool:
	for dy in range(-margin, margin + 1):
		for dx in range(-margin, margin + 1):
			var kind := at(gx + dx, gy + dy)
			if kind == WATER or kind == PATH:
				return false
	return true


# --- geração ---------------------------------------------------------------


# `islands` é uma lista de Rect2 (o quadrante de cada bioma), na mesma ordem
# da tabela de biomas. `anchors` são pontos que precisam ser terra de
# qualquer jeito (boca de ponte, spawn, marco).
func generate(islands: Array, anchors: Array, roads: Array) -> void:
	for i in islands.size():
		_carve_island(islands[i], i)
	for anchor in anchors:
		_force_land(anchor["point"], anchor["radius"])
	for road in roads:
		_carve_road(road["from"], road["to"])
	for i in islands.size():
		_keep_main_landmass(islands[i], anchors, i)
	_mark_beaches()


# Desenha uma ilha dentro do quadrante: o ruído dá o miolo e um decaimento
# radial garante que ela não encoste na borda (senão colaria na vizinha).
func _carve_island(island: Rect2, biome_index: int) -> void:
	var center := island.get_center()
	var half := island.size * 0.5
	var from := to_grid(island.position)
	var to := to_grid(island.end)

	for gy in range(maxi(from.y, 0), mini(to.y, rows)):
		for gx in range(maxi(from.x, 0), mini(to.x, cols)):
			var point := to_world(gx, gy)
			var n := (_shape.get_noise_2dv(point) + 1.0) * 0.5
			var d := Vector2(
				(point.x - center.x) / half.x,
				(point.y - center.y) / half.y).length()
			var falloff := smoothstep(0.35, 1.05, d)
			if n - falloff > LAND_THRESHOLD:
				var i := index(gx, gy)
				cells[i] = LAND
				biome_of[i] = biome_index


func _force_land(point: Vector2, radius: float) -> void:
	var center := to_grid(point)
	var r := int(ceil(radius / CELL))
	var biome := _nearest_biome(center, r)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var gx := center.x + dx
			var gy := center.y + dy
			if not inside(gx, gy):
				continue
			var i := index(gx, gy)
			if cells[i] == WATER:
				cells[i] = LAND
			if biome_of[i] == NO_BIOME:
				biome_of[i] = biome


# Abre uma estrada de terra batida entre dois pontos, forçando terra por
# baixo. É isso que garante que marco, spawn e ponte fiquem ligados.
func _carve_road(from: Vector2, to: Vector2) -> void:
	var steps := int(from.distance_to(to) / (CELL * 0.5)) + 1
	# Um desvio suave no meio do caminho, pra estrada não sair reta.
	var mid := (from + to) * 0.5
	var side := (to - from).orthogonal().normalized()
	mid += side * _rng.randf_range(-90.0, 90.0)

	var previous := from
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var point := from.bezier_interpolate(mid, mid, to, t)
		_stamp_road(point)
		previous = point


func _stamp_road(point: Vector2) -> void:
	var center := to_grid(point)
	var biome := _nearest_biome(center, PATH_LAND_RADIUS)
	for dy in range(-PATH_LAND_RADIUS, PATH_LAND_RADIUS + 1):
		for dx in range(-PATH_LAND_RADIUS, PATH_LAND_RADIUS + 1):
			var gx := center.x + dx
			var gy := center.y + dy
			if not inside(gx, gy):
				continue
			var dist_sq := dx * dx + dy * dy
			var i := index(gx, gy)
			if dist_sq <= PATH_LAND_RADIUS * PATH_LAND_RADIUS:
				if cells[i] == WATER:
					cells[i] = LAND
				if biome_of[i] == NO_BIOME:
					biome_of[i] = biome
			if dist_sq <= PATH_RADIUS * PATH_RADIUS:
				cells[i] = PATH


func _nearest_biome(center: Vector2i, radius: int) -> int:
	for r in range(0, radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var gx := center.x + dx
				var gy := center.y + dy
				if inside(gx, gy) and biome_of[index(gx, gy)] != NO_BIOME:
					return biome_of[index(gx, gy)]
	return NO_BIOME


# Ilhota solta é bonita mas o jogador não alcança: fica só o pedaço de terra
# ligado aos pontos importantes daquele bioma.
func _keep_main_landmass(island: Rect2, anchors: Array, biome_index: int) -> void:
	var start := Vector2i(-1, -1)
	for anchor in anchors:
		if anchor["biome"] == biome_index:
			var g := to_grid(anchor["point"])
			if is_walkable(g.x, g.y):
				start = g
				break
	if start.x < 0:
		return

	var reached := {}
	var queue: Array[Vector2i] = [start]
	reached[start] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + step
			if not inside(nxt.x, nxt.y) or reached.has(nxt):
				continue
			if cells[index(nxt.x, nxt.y)] == WATER:
				continue
			reached[nxt] = true
			queue.append(nxt)

	var from := to_grid(island.position)
	var to := to_grid(island.end)
	for gy in range(maxi(from.y, 0), mini(to.y, rows)):
		for gx in range(maxi(from.x, 0), mini(to.x, cols)):
			var g := Vector2i(gx, gy)
			if cells[index(gx, gy)] != WATER and not reached.has(g):
				cells[index(gx, gy)] = WATER
				biome_of[index(gx, gy)] = NO_BIOME


# Toda terra encostada no mar vira praia.
func _mark_beaches() -> void:
	var beach := PackedInt32Array()
	for gy in rows:
		for gx in cols:
			var i := index(gx, gy)
			if cells[i] != LAND:
				continue
			if at(gx - 1, gy) == WATER or at(gx + 1, gy) == WATER \
					or at(gx, gy - 1) == WATER or at(gx, gy + 1) == WATER \
					or at(gx - 2, gy) == WATER or at(gx + 2, gy) == WATER \
					or at(gx, gy - 2) == WATER or at(gx, gy + 2) == WATER:
				beach.append(i)
	for i in beach:
		cells[i] = SAND


# --- textura assada --------------------------------------------------------


# Uma imagem do mundo inteiro: cada célula vira um pixel, e o Sprite2D que
# usa essa textura é escalado por CELL. Água fica transparente, pro mar
# animado aparecer por baixo.
func bake(biomes: Array) -> ImageTexture:
	var data := PackedByteArray()
	data.resize(cols * rows * 4)

	for gy in rows:
		for gx in cols:
			var i := index(gx, gy)
			var color := _color_of(gx, gy, biomes)
			var o := i * 4
			data[o] = int(color.r * 255.0)
			data[o + 1] = int(color.g * 255.0)
			data[o + 2] = int(color.b * 255.0)
			data[o + 3] = int(color.a * 255.0)

	var image := Image.create_from_data(cols, rows, false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(image)


# Máscara de escurecimento pra um bioma só: alpha só nas células de terra
# dele, zero em todo o resto (inclusive no mar) — sobreposta com um Sprite2D
# do mesmo jeito que o chão, ela acompanha o contorno real da ilha em vez
# de ser um retângulo por cima da água.
func bake_darkness(biome_index: int, alpha: float) -> ImageTexture:
	var data := PackedByteArray()
	data.resize(cols * rows * 4)
	for gy in rows:
		for gx in cols:
			var i := index(gx, gy)
			var a := 0.0
			if cells[i] != WATER and biome_of[i] == biome_index:
				a = alpha
			var o := i * 4
			data[o] = 6
			data[o + 1] = 5
			data[o + 2] = 20
			data[o + 3] = int(a * 255.0)
	var image := Image.create_from_data(cols, rows, false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(image)


func _color_of(gx: int, gy: int, biomes: Array) -> Color:
	var i := index(gx, gy)
	var kind := cells[i]
	if kind == WATER:
		return Color(0, 0, 0, 0)

	var b := biome_of[i]
	if b == NO_BIOME:
		return Color(0, 0, 0, 0)
	var biome: Dictionary = biomes[b]

	if kind == SAND:
		return biome["shore"]
	if kind == PATH:
		return biome["path"]

	# Terra: mancha entre três tons conforme o ruído pequeno, mais uns
	# pontinhos soltos (florzinha, pedrinha) pra não ficar chapado.
	var n := _detail.get_noise_2d(gx * CELL, gy * CELL)
	var ground: Color = biome["ground"]
	if n < -0.25:
		ground = ground.lerp(biome["ground_dark"], minf(1.0, (-n - 0.25) * 3.0))
	elif n > 0.25:
		ground = ground.lerp(biome["ground_light"], minf(1.0, (n - 0.25) * 3.0))

	var speck := _hash01(gx, gy)
	if speck > 0.995:
		return biome["speck_a"]
	if speck > 0.988:
		return biome["speck_b"]
	return ground


# Ruído barato e estável por célula (mesma célula, mesmo valor sempre).
func _hash01(gx: int, gy: int) -> float:
	var h := gx * 374761393 + gy * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFF) / 65535.0


# --- colisão ---------------------------------------------------------------


# Junta as células de água em poucos retângulos grandes (algoritmo guloso:
# estica pra direita, depois pra baixo enquanto a faixa inteira for água).
# Sem isso seriam milhares de formas de colisão.
func collision_rects(bridges: Array) -> Array:
	var bw := int(ceil(float(cols) / float(COLLISION_CELL)))
	var bh := int(ceil(float(rows) / float(COLLISION_CELL)))
	var block := PackedByteArray()
	block.resize(bw * bh)

	for by in bh:
		for bx in bw:
			block[by * bw + bx] = 1 if _block_is_water(bx, by, bridges) else 0

	var used := PackedByteArray()
	used.resize(bw * bh)
	var size := CELL * float(COLLISION_CELL)
	var rects: Array = []

	for by in bh:
		for bx in bw:
			var i := by * bw + bx
			if block[i] == 0 or used[i] == 1:
				continue
			var width := 1
			while bx + width < bw and block[i + width] == 1 and used[i + width] == 0:
				width += 1
			var height := 1
			while by + height < bh and _row_free(block, used, bw, bx, by + height, width):
				height += 1
			for y in range(by, by + height):
				for x in range(bx, bx + width):
					used[y * bw + x] = 1
			rects.append(Rect2(bx * size, by * size, width * size, height * size))
	return rects


func _block_is_water(bx: int, by: int, bridges: Array) -> bool:
	var water := 0
	var total := 0
	for dy in COLLISION_CELL:
		for dx in COLLISION_CELL:
			var gx := bx * COLLISION_CELL + dx
			var gy := by * COLLISION_CELL + dy
			if not inside(gx, gy):
				continue
			total += 1
			if cells[index(gx, gy)] == WATER:
				water += 1
	if total == 0:
		return false
	# Bloqueia só se o bloco for majoritariamente água — assim o jogador
	# consegue chegar até a beirada da praia.
	if water * 2 <= total:
		return false
	# Ponte por cima da água continua sendo chão.
	var size := CELL * float(COLLISION_CELL)
	var here := Rect2(bx * size, by * size, size, size)
	for bridge in bridges:
		if here.intersects((bridge["rect"] as Rect2).grow(-2.0)):
			return false
	return true


func _row_free(block: PackedByteArray, used: PackedByteArray, bw: int,
		bx: int, by: int, width: int) -> bool:
	for x in range(bx, bx + width):
		var i := by * bw + x
		if block[i] == 0 or used[i] == 1:
			return false
	return true
