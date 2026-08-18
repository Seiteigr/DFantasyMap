extends RefCounted

# Constrói o mundo por código — v2: ilhas com costa orgânica (ruído, não
# retângulo), vegetação em grupos, estradas de terra ligando spawn → marco
# → ponte, um marco visual por bioma, água animada e uma leva de detalhes
# pequenos (flor, cogumelo, ossos, cristalzinho) só decorativos.
#
# Mapa (a "caixa" de cada bioma continua nesse arranjo, mas a ilha em si
# agora tem baías e penínsulas — isto aqui é só o quadrante onde ela nasce):
#
#     Floresta  ═══ponte═══  Deserto
#        ║                      ║
#      ponte        mar       ponte
#        ║                      ║
#     Ruínas    ═══ponte═══  Caverna
#
# Pra mexer no mapa, edite `biomes()`: cores, quais props/detalhes e quantos
# inimigos de cada tipo. O formato da costa, as estradas e a colisão saem
# calculados a partir disso — não precisa mexer em nenhum .tscn.

const Terrain := preload("res://scripts/world/terrain.gd")
const Landmarks := preload("res://scripts/world/landmarks.gd")
const Villages := preload("res://scripts/world/villages.gd")

const ISLAND_W := 1400.0
const ISLAND_H := 1000.0
const CHANNEL := 260.0		# largura do mar entre duas ilhas
const BRIDGE_W := 150.0		# largura da passagem da ponte
const CLIFF_VISUAL_H := 90.0	# altura da faixa de falésia decorativa ao sul

const WORLD_W := ISLAND_W * 2.0 + CHANNEL
const WORLD_H := ISLAND_H * 2.0 + CHANNEL

# Camadas de desenho: quem tem z_index maior desenha por cima. As
# entidades (player, props, inimigos) ficam a 0, dentro do nó com y_sort.
const Z_SEA := -40
const Z_GROUND := -25
const Z_COAST_CLIFF := -20
const Z_BRIDGE := -15
const Z_DARKNESS := 100

const BRIDGE_WOOD := Color(0.45, 0.30, 0.17)
const BRIDGE_PLANK := Color(0.31, 0.20, 0.11)
const BRIDGE_RAIL := Color(0.25, 0.16, 0.09)

const TEX_CLIFF := preload("res://assets/tileset/cliff_edge.png")

# Cada prop: onde desenhar o sprite em relação ao pé (a posição do nó é
# sempre o ponto que toca o chão, pro y-sort acertar a ordem), o raio da
# colisão e (opcional) uma escala pra variar o tamanho de uma mesma textura.
const PROP_DEFS := {
	"tree": {
		"texture": preload("res://assets/props/tree1.png"),
		"offset": Vector2(0, -95), "radius": 20.0, "scale": 1.0,
	},
	"rock1": {
		"texture": preload("res://assets/props/rock1.png"),
		"offset": Vector2(0, -16), "radius": 20.0, "scale": 1.0,
	},
	"rock2": {
		"texture": preload("res://assets/props/rock2.png"),
		"offset": Vector2(0, -16), "radius": 20.0, "scale": 1.0,
	},
	"bush": {
		"texture": preload("res://assets/props/bush1.png"),
		"offset": Vector2(0, -32), "radius": 30.0, "scale": 1.0,
	},
	# Pedregulho grande: mesma textura da rock2, só maior — dá uma segunda
	# "altura" de rocha além das pedrinhas comuns (pedido de mais níveis
	# visuais sem entrar num sistema de elevação de verdade).
	"outcrop": {
		"texture": preload("res://assets/props/rock2.png"),
		"offset": Vector2(0, -30), "radius": 34.0, "scale": 1.7,
	},
}

const ENEMY_SCENES := {
	"goblin": preload("res://scenes/enemies/GoblinDummy.tscn"),
	"orc": preload("res://scenes/enemies/Orc.tscn"),
	"skeleton": preload("res://scenes/enemies/Skeleton.tscn"),
	"dragon_red": preload("res://scenes/enemies/DragonRed.tscn"),
	"dragon_green": preload("res://scenes/enemies/DragonGreen.tscn"),
}

const ENEMY_RADIUS := 26.0
const SPACING := 26.0

# Recuo (em pixels) que um inimigo precisa pra patrulhar sem sair da ilha —
# o maior passeio é o quadrado do orc, 220 de lado.
const ENEMY_CLEARANCE := 130.0

const MAP_SEED := 20260806

const WATER_SHADER := preload("res://scripts/world/water.gdshader")


static func biomes() -> Array:
	var col2 := ISLAND_W + CHANNEL
	var row2 := ISLAND_H + CHANNEL
	return [
		{
			"id": "forest",
			"label": "Floresta",
			"quadrant": Rect2(0.0, 0.0, ISLAND_W, ISLAND_H),
			"ground": Color(0.24, 0.42, 0.20),
			"ground_dark": Color(0.17, 0.33, 0.15),
			"ground_light": Color(0.34, 0.52, 0.26),
			"speck_a": Color(0.75, 0.55, 0.85), "speck_b": Color(0.9, 0.85, 0.3),
			"shore": Color(0.80, 0.74, 0.50), "path": Color(0.42, 0.32, 0.16),
			"prop_tint": Color(1, 1, 1), "cliff_tint": Color(1, 1, 1),
			"landmark": "giant_tree",
			"flavor_enter": "Você entrou na Floresta Ancestral.",
			"flavor_later": "Os pássaros silenciam de repente...",
			"props": {"tree": 26, "bush": 15, "rock1": 4, "outcrop": 2},
			"details": {"flower": 22, "mushroom": 10, "twig": 8},
			"enemies": {"goblin": 4, "orc": 2, "dragon_green": 1},
			"dormant_enemies": [],
			"difficulty": 1.0,
		},
		{
			"id": "desert",
			"label": "Deserto",
			"quadrant": Rect2(col2, 0.0, ISLAND_W, ISLAND_H),
			"ground": Color(0.84, 0.70, 0.41),
			"ground_dark": Color(0.74, 0.58, 0.32),
			"ground_light": Color(0.92, 0.80, 0.52),
			"speck_a": Color(0.55, 0.4, 0.25), "speck_b": Color(0.95, 0.9, 0.7),
			"shore": Color(0.90, 0.82, 0.56), "path": Color(0.68, 0.54, 0.30),
			"prop_tint": Color(1.0, 0.90, 0.70), "cliff_tint": Color(0.70, 0.55, 0.30),
			"landmark": "pyramid",
			"flavor_enter": "Você entrou no Deserto.",
			"flavor_later": "A areia range sob passos que não são seus...",
			"props": {"rock1": 10, "rock2": 10, "bush": 4, "outcrop": 4},
			"details": {"bone": 10, "twig": 8, "pebble": 16},
			"enemies": {"skeleton": 4, "orc": 2, "dragon_red": 1},
			"dormant_enemies": ["skeleton"],
			"difficulty": 1.4,
		},
		{
			"id": "ruins",
			"label": "Ruínas",
			"quadrant": Rect2(0.0, row2, ISLAND_W, ISLAND_H),
			"ground": Color(0.43, 0.43, 0.39),
			"ground_dark": Color(0.34, 0.34, 0.31), "ground_light": Color(0.52, 0.52, 0.47),
			"speck_a": Color(0.3, 0.5, 0.3), "speck_b": Color(0.75, 0.72, 0.6),
			"shore": Color(0.66, 0.64, 0.56), "path": Color(0.50, 0.46, 0.38),
			"prop_tint": Color(0.84, 0.84, 0.80), "cliff_tint": Color(0.55, 0.55, 0.5),
			"landmark": "ruins",
			"flavor_enter": "Você entrou nas Ruínas.",
			"flavor_later": "Você sente uma presença estranha...",
			"props": {"rock1": 10, "rock2": 10, "bush": 5, "tree": 3, "outcrop": 5},
			"details": {"bone": 12, "pebble": 16, "moss": 10},
			"enemies": {"skeleton": 5, "goblin": 3, "orc": 1},
			"dormant_enemies": [],
			"difficulty": 1.2,
		},
		{
			"id": "cave",
			"label": "Caverna",
			"quadrant": Rect2(col2, row2, ISLAND_W, ISLAND_H),
			"ground": Color(0.19, 0.17, 0.24),
			"ground_dark": Color(0.13, 0.12, 0.18), "ground_light": Color(0.27, 0.25, 0.34),
			"speck_a": Color(0.4, 0.7, 0.9), "speck_b": Color(0.7, 0.4, 0.9),
			"shore": Color(0.28, 0.27, 0.35), "path": Color(0.24, 0.22, 0.30),
			"prop_tint": Color(0.60, 0.58, 0.72), "cliff_tint": Color(0.30, 0.28, 0.40),
			"landmark": "crystal",
			"flavor_enter": "Você entrou na Caverna.",
			"flavor_later": "Algo enorme respira na escuridão à frente...",
			"props": {"rock1": 14, "rock2": 14, "bush": 2, "outcrop": 6},
			"details": {"mushroom": 14, "pebble": 18, "crystal_shard": 10},
			"enemies": {"dragon_red": 2, "dragon_green": 2, "skeleton": 4},
			"dormant_enemies": ["dragon_red", "dragon_green"],
			"difficulty": 1.7,
		},
	]


static func bridges() -> Array:
	var col2 := ISLAND_W + CHANNEL
	var row2 := ISLAND_H + CHANNEL
	var half := BRIDGE_W * 0.5
	var north_y := ISLAND_H * 0.42
	var south_y := row2 + ISLAND_H * 0.42
	var west_x := ISLAND_W * 0.45
	var east_x := col2 + ISLAND_W * 0.45
	return [
		{"rect": Rect2(ISLAND_W, north_y - half, CHANNEL, BRIDGE_W), "horizontal": true},
		{"rect": Rect2(ISLAND_W, south_y - half, CHANNEL, BRIDGE_W), "horizontal": true},
		{"rect": Rect2(west_x - half, ISLAND_H, BRIDGE_W, CHANNEL), "horizontal": false},
		{"rect": Rect2(east_x - half, ISLAND_H, BRIDGE_W, CHANNEL), "horizontal": false},
	]


# Ponto de partida do jogador: um pouco ao sul da árvore ancestral, na
# Floresta.
static func spawn_point() -> Vector2:
	return _landmark_point(biomes()[0]["quadrant"]) + Vector2(0, 165)


static func _landmark_point(quadrant: Rect2) -> Vector2:
	return quadrant.position + Vector2(quadrant.size.x * 0.5, quadrant.size.y * 0.42)


# Povoado de cada ilha: um pouco a sudoeste do marco, longe o bastante do
# spawn/pontes pra não brigar com as outras estradas forçadas.
static func _village_point(quadrant: Rect2) -> Vector2:
	return _landmark_point(quadrant) + Vector2(-230.0, 90.0)


# --- construção principal ----------------------------------------------------


static func build(world: Node2D, entities: Node2D) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED

	var terrain := Terrain.new(Vector2(WORLD_W, WORLD_H), MAP_SEED)
	var biome_list := biomes()
	var bridge_list := bridges()
	var anchors := _build_anchors(biome_list, bridge_list)
	var roads := _build_roads(biome_list, bridge_list, anchors)

	var quadrants: Array = []
	for biome in biome_list:
		quadrants.append(biome["quadrant"])
	terrain.generate(quadrants, anchors, roads)

	_build_sea(world, terrain)
	_build_ground(world, terrain, biome_list)
	for biome_index in biome_list.size():
		_build_coast_cliffs(world, terrain, biome_list[biome_index])
	for bridge in bridge_list:
		_build_bridge(world, bridge)
	_build_collision(world, terrain, bridge_list)

	var landmark_points: Array = []
	var village_points: Array = []
	for biome_index in biome_list.size():
		var biome: Dictionary = biome_list[biome_index]
		var point: Vector2 = _landmark_point(biome["quadrant"])
		landmark_points.append(point)
		var landmark := Landmarks.build(biome["landmark"], biome["prop_tint"])
		landmark.position = point
		entities.add_child(landmark)

		var village_point: Vector2 = _village_point(biome["quadrant"])
		village_points.append(village_point)
		Villages.populate(entities, biome["id"], village_point, rng)

	for biome_index in biome_list.size():
		_populate(entities, biome_list[biome_index], terrain, landmark_points[biome_index],
			village_points[biome_index], anchors, biome_index, rng)

	_build_cave_darkness(world, terrain, biome_list)

	return {
		"terrain": terrain,
		"biomes": biome_list,
		"landmark_points": landmark_points,
		"world_size": Vector2(WORLD_W, WORLD_H),
	}


# Bioma em que um ponto do mundo está, consultando a grade real (não a
# caixa do quadrante) — assim funciona mesmo perto de uma baía ou península.
static func biome_at(build_data: Dictionary, point: Vector2) -> String:
	var terrain = build_data["terrain"]
	var g: Vector2i = terrain.to_grid(point)
	if not terrain.inside(g.x, g.y):
		return "Mar"
	var b: int = terrain.biome_of[terrain.index(g.x, g.y)]
	if b == terrain.NO_BIOME:
		return "Mar"
	return build_data["biomes"][b]["label"]


# --- pontos que o terreno é obrigado a manter como terra ---------------------


static func _build_anchors(biome_list: Array, bridge_list: Array) -> Array:
	var anchors: Array = []
	for biome_index in biome_list.size():
		var quadrant: Rect2 = biome_list[biome_index]["quadrant"]
		anchors.append({"point": _landmark_point(quadrant), "radius": 130.0, "biome": biome_index})
		anchors.append({"point": _village_point(quadrant), "radius": 140.0, "biome": biome_index})
	anchors.append({"point": spawn_point(), "radius": 100.0, "biome": 0})

	for bridge in bridge_list:
		var rect: Rect2 = bridge["rect"]
		if bridge["horizontal"]:
			var left := _biome_index_at_point(biome_list, rect.position - Vector2(40, 0))
			var right := _biome_index_at_point(biome_list, rect.end + Vector2(40, 0))
			anchors.append({"point": Vector2(rect.position.x, rect.get_center().y), "radius": 90.0, "biome": left})
			anchors.append({"point": Vector2(rect.end.x, rect.get_center().y), "radius": 90.0, "biome": right})
		else:
			var top := _biome_index_at_point(biome_list, rect.position - Vector2(0, 40))
			var bottom := _biome_index_at_point(biome_list, rect.end + Vector2(0, 40))
			anchors.append({"point": Vector2(rect.get_center().x, rect.position.y), "radius": 90.0, "biome": top})
			anchors.append({"point": Vector2(rect.get_center().x, rect.end.y), "radius": 90.0, "biome": bottom})
	return anchors


static func _biome_index_at_point(biome_list: Array, point: Vector2) -> int:
	for i in biome_list.size():
		if (biome_list[i]["quadrant"] as Rect2).has_point(point):
			return i
	return 0


# Estradas de terra: do marco de cada ilha até a boca de cada ponte dela, e
# (só na Floresta) do spawn até o marco — é o "caminho natural" pedido.
static func _build_roads(biome_list: Array, bridge_list: Array, anchors: Array) -> Array:
	var roads: Array = []
	for biome_index in biome_list.size():
		var hub: Vector2 = _landmark_point(biome_list[biome_index]["quadrant"])
		for anchor in anchors:
			if anchor["biome"] == biome_index and anchor["point"] != hub:
				roads.append({"from": hub, "to": anchor["point"]})
	return roads


# --- chão ----------------------------------------------------------------


static func _build_sea(world: Node2D, terrain: Terrain) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = MAP_SEED + 55
	noise.frequency = 0.18
	var noise_image := noise.get_image(64, 64)
	noise_image.convert(Image.FORMAT_RGBA8)
	var noise_tex := ImageTexture.create_from_image(noise_image)

	var sea := Sprite2D.new()
	sea.name = "Sea"
	sea.centered = false
	sea.region_enabled = true
	sea.region_rect = Rect2(0, 0, WORLD_W, WORLD_H)
	sea.texture = noise_tex
	sea.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sea.z_index = Z_SEA

	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("noise_tex", noise_tex)
	sea.material = material
	world.add_child(sea)


# Uma única textura "assada" cobre o mundo inteiro: bem mais barato que um
# Polygon2D por ilha e permite costa irregular sem esforço extra.
static func _build_ground(world: Node2D, terrain: Terrain, biome_list: Array) -> void:
	var ground := Sprite2D.new()
	ground.name = "Ground"
	ground.centered = false
	ground.texture = terrain.bake(biome_list)
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.scale = Vector2(Terrain.CELL, Terrain.CELL)
	ground.z_index = Z_GROUND
	world.add_child(ground)


# Faixa decorativa de falésia ao longo da costa sul de cada ilha — só onde
# a ilha realmente chega até ali (nas baías, o ruído já deixou mar, então
# naturalmente não sobra tile de falésia flutuando sobre a água).
static func _build_coast_cliffs(world: Node2D, terrain: Terrain, biome: Dictionary) -> void:
	var quadrant: Rect2 = biome["quadrant"]
	var holder := Node2D.new()
	holder.name = "CoastCliffs_" + str(biome["id"])
	holder.z_index = Z_COAST_CLIFF
	world.add_child(holder)

	var step := float(TEX_CLIFF.get_width()) * 0.6
	var y := quadrant.end.y - CLIFF_VISUAL_H
	var check_rows := int(18.0 / Terrain.CELL) + 1
	var x := quadrant.position.x
	while x < quadrant.end.x:
		var center := Vector2(x + step * 0.5, y + CLIFF_VISUAL_H * 0.5)
		var g := terrain.to_grid(center)
		if terrain.is_walkable(g.x, g.y):
			var south_g := terrain.to_grid(center + Vector2(0, check_rows * Terrain.CELL))
			if not terrain.is_walkable(south_g.x, south_g.y):
				var cliff := Sprite2D.new()
				cliff.texture = TEX_CLIFF
				cliff.centered = false
				cliff.position = Vector2(x, y)
				cliff.scale = Vector2(step / float(TEX_CLIFF.get_width()), CLIFF_VISUAL_H / float(TEX_CLIFF.get_height()))
				cliff.modulate = biome["cliff_tint"]
				holder.add_child(cliff)
		x += step


# --- pontes ----------------------------------------------------------------


static func _build_bridge(world: Node2D, bridge: Dictionary) -> void:
	var rect: Rect2 = bridge["rect"]
	var horizontal: bool = bridge["horizontal"]
	var holder := Node2D.new()
	holder.name = "Bridge"
	holder.z_index = Z_BRIDGE
	world.add_child(holder)

	_fill(holder, rect, BRIDGE_WOOD, "Deck")

	var spacing := 26.0
	if horizontal:
		var x := rect.position.x + spacing
		while x < rect.end.x:
			_fill(holder, Rect2(x, rect.position.y, 3.0, rect.size.y), BRIDGE_PLANK, "Plank")
			x += spacing
		_fill(holder, Rect2(rect.position.x, rect.position.y, rect.size.x, 9.0), BRIDGE_RAIL, "RailA")
		_fill(holder, Rect2(rect.position.x, rect.end.y - 9.0, rect.size.x, 9.0), BRIDGE_RAIL, "RailB")
	else:
		var y := rect.position.y + spacing
		while y < rect.end.y:
			_fill(holder, Rect2(rect.position.x, y, rect.size.x, 3.0), BRIDGE_PLANK, "Plank")
			y += spacing
		_fill(holder, Rect2(rect.position.x, rect.position.y, 9.0, rect.size.y), BRIDGE_RAIL, "RailA")
		_fill(holder, Rect2(rect.end.x - 9.0, rect.position.y, 9.0, rect.size.y), BRIDGE_RAIL, "RailB")


# --- colisão -----------------------------------------------------------------


static func _build_collision(world: Node2D, terrain: Terrain, bridge_list: Array) -> void:
	var body := StaticBody2D.new()
	body.name = "WorldCollision"
	world.add_child(body)

	for rect in terrain.collision_rects(bridge_list):
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)

	# Muro de segurança na borda do mundo (o ruído já devia deixar água ali,
	# isso é só um cinto de segurança contra folga de flutuante).
	var t := 80.0
	for rect in [
		Rect2(-t, -t, WORLD_W + t * 2.0, t), Rect2(-t, WORLD_H, WORLD_W + t * 2.0, t),
		Rect2(-t, 0.0, t, WORLD_H), Rect2(WORLD_W, 0.0, t, WORLD_H),
	]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)


# --- vegetação, detalhes e inimigos ------------------------------------------


static func _populate(entities: Node2D, biome: Dictionary, terrain: Terrain,
		landmark_point: Vector2, village_point: Vector2, anchors: Array, biome_index: int,
		rng: RandomNumberGenerator) -> void:
	var quadrant: Rect2 = biome["quadrant"]
	var taken := PackedVector3Array()
	taken.append(Vector3(landmark_point.x, landmark_point.y, 150.0))
	taken.append(Vector3(village_point.x, village_point.y, Villages.FOOTPRINT_RADIUS))

	# Reserva a boca de cada ponte (e o spawn) livre de prop/detalhe/inimigo —
	# sem isso, rocha/árvore podia nascer bem na entrada da passagem entre
	# biomas e entupir o único caminho de terra que liga as ilhas.
	for anchor in anchors:
		if anchor["biome"] == biome_index:
			taken.append(Vector3(anchor["point"].x, anchor["point"].y, anchor["radius"] + 40.0))

	for prop_name in biome["props"]:
		var def: Dictionary = PROP_DEFS[prop_name]
		var radius: float = def["radius"]
		var count: int = int(biome["props"][prop_name])
		_scatter_clustered(count, quadrant, terrain, radius, taken, rng, func(spot: Vector2):
			taken.append(Vector3(spot.x, spot.y, radius))
			_add_prop(entities, def, spot, biome["prop_tint"]))

	for detail_kind in biome["details"]:
		var count: int = int(biome["details"][detail_kind])
		for i in count:
			var spot := _pick_open_spot(quadrant, terrain, 2, rng)
			if spot != Vector2.INF and spot.distance_to(landmark_point) > 90.0:
				_add_detail(entities, detail_kind, biome, spot)

	# Área de sorteio dos inimigos: um pouco mais pra dentro da ilha, pra
	# eles não nascerem já quase na água — mas sem exigir uma janela gigante
	# de terra livre (a ilha inteira tem só 1400px de lado).
	var enemy_area := quadrant.grow(-ENEMY_CLEARANCE * 0.5)
	for enemy_name in biome["enemies"]:
		var scene: PackedScene = ENEMY_SCENES[enemy_name]
		var dormant: bool = (biome["dormant_enemies"] as Array).has(enemy_name)
		var count: int = int(biome["enemies"][enemy_name])
		for i in count:
			var spot := _pick_spot_in(enemy_area, terrain, 3, ENEMY_RADIUS, taken, rng)
			if spot == Vector2.INF:
				# A área "bem pra dentro" pode ter ficado apertada demais
				# numa ilha estreita; tenta de novo permitindo chegar mais
				# perto da beirada antes de desistir desse inimigo.
				spot = _pick_spot_in(quadrant.grow(-40.0), terrain, 3, ENEMY_RADIUS, taken, rng)
			if spot == Vector2.INF:
				continue
			taken.append(Vector3(spot.x, spot.y, ENEMY_RADIUS))
			_add_enemy(entities, scene, spot, dormant, float(biome.get("difficulty", 1.0)))


# Espalha `count` itens em punhados (3 a 6 por grupo) em vez de distribuí-los
# uniformemente — é o que faz uma floresta parecer floresta e não um jardim
# geométrico. A folga entre um item e outro (ou entre um item e qualquer
# outra coisa já colocada) é sempre resolvida por distância (`_too_close`),
# nunca por uma janela de "chão livre" gigante — numa ilha de 1400px de
# lado, exigir um retângulo todo livre de água já mata a busca de cara.
static func _scatter_clustered(count: int, quadrant: Rect2, terrain: Terrain, radius: float,
		taken: PackedVector3Array, rng: RandomNumberGenerator, place: Callable) -> void:
	var remaining := count
	var stall_guard := count * 6 + 20	# limite de tentativas totais, pra nunca travar
	while remaining > 0 and stall_guard > 0:
		stall_guard -= 1
		var cluster_size := mini(remaining, rng.randi_range(3, 6))
		var center := _pick_open_spot(quadrant, terrain, 2, rng)
		if center == Vector2.INF:
			remaining -= 1
			continue
		var placed_here := 0
		var item_attempts := cluster_size * 5
		while placed_here < cluster_size and item_attempts > 0:
			item_attempts -= 1
			var offset := Vector2(rng.randfn(0.0, 50.0), rng.randfn(0.0, 50.0))
			var spot: Vector2 = center + offset
			if not quadrant.grow(-6.0).has_point(spot):
				continue
			var g := terrain.to_grid(spot)
			if not terrain.is_free_land(g.x, g.y, 1):
				continue
			if _too_close(spot, radius, taken):
				continue
			place.call(spot)
			placed_here += 1
		remaining -= maxi(placed_here, 1)


static func _too_close(spot: Vector2, radius: float, taken: PackedVector3Array) -> bool:
	for other in taken:
		if spot.distance_to(Vector2(other.x, other.y)) < radius + other.z + SPACING:
			return true
	return false


# Sorteia um ponto qualquer dentro de `quadrant` que seja terra firme (não
# água, não estrada), com só uma folga mínima (`margin` células) em volta —
# usado pra achar centro de cluster e pontos de detalhe, onde não importa
# ter muito espaço, só não nascer na água.
static func _pick_open_spot(quadrant: Rect2, terrain: Terrain, margin: int,
		rng: RandomNumberGenerator) -> Vector2:
	var area := quadrant.grow(-16.0)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return Vector2.INF
	for attempt in 120:
		var spot := Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.end.y))
		var g := terrain.to_grid(spot)
		if terrain.is_free_land(g.x, g.y, margin):
			return spot
	return Vector2.INF


# Igual ao de cima, mas também respeita a distância mínima até o que já foi
# colocado (`taken`) — usado pros inimigos, que precisam de mais espaço uns
# dos outros pra patrulhar sem se atropelar.
static func _pick_spot_in(area: Rect2, terrain: Terrain, margin: int, radius: float,
		taken: PackedVector3Array, rng: RandomNumberGenerator) -> Vector2:
	var safe_area := area
	if safe_area.size.x <= 0.0 or safe_area.size.y <= 0.0:
		return Vector2.INF
	for attempt in 220:
		var spot := Vector2(
			rng.randf_range(safe_area.position.x, safe_area.end.x),
			rng.randf_range(safe_area.position.y, safe_area.end.y))
		var g := terrain.to_grid(spot)
		if not terrain.is_free_land(g.x, g.y, margin):
			continue
		if _too_close(spot, radius, taken):
			continue
		return spot
	return Vector2.INF


static func _add_prop(entities: Node2D, def: Dictionary, spot: Vector2, tint: Color) -> void:
	var prop := StaticBody2D.new()
	prop.position = spot

	var sprite := Sprite2D.new()
	sprite.texture = def["texture"]
	sprite.position = def["offset"]
	sprite.scale = Vector2.ONE * float(def["scale"])
	sprite.modulate = tint
	prop.add_child(sprite)

	var shape := CollisionShape2D.new()
	shape.shape = _circle(def["radius"])
	prop.add_child(shape)

	entities.add_child(prop)


static func _add_enemy(entities: Node2D, scene: PackedScene, spot: Vector2, dormant: bool, difficulty: float) -> void:
	var enemy := scene.instantiate()
	enemy.position = spot
	if dormant and ("dormant" in enemy):
		enemy.dormant = true
	if "damage_multiplier" in enemy:
		enemy.damage_multiplier = difficulty

	var enabler := VisibleOnScreenEnabler2D.new()
	enabler.rect = Rect2(-80, -110, 160, 150)
	enemy.add_child(enabler)

	entities.add_child(enemy)


# --- pequenos detalhes decorativos (sem colisão) -----------------------------


static func _add_detail(entities: Node2D, kind: String, biome: Dictionary, spot: Vector2) -> void:
	var node: Node2D
	match kind:
		"flower":
			node = _detail_flower()
		"mushroom":
			node = _detail_mushroom(biome["id"] == "cave")
		"twig":
			node = _detail_twig()
		"bone":
			node = _detail_bone()
		"pebble":
			node = _detail_pebble(biome["prop_tint"])
		"moss":
			node = _detail_moss()
		"crystal_shard":
			node = _detail_crystal_shard()
		_:
			return
	node.position = spot
	node.z_index = -1
	entities.add_child(node)


static func _detail_flower() -> Node2D:
	var colors := [Color(1, 0.6, 0.75), Color(1, 1, 0.6), Color(0.75, 0.6, 1)]
	var color: Color = colors[randi() % colors.size()]
	var flower := Node2D.new()

	var stem := Line2D.new()
	stem.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -9)])
	stem.width = 1.4
	stem.default_color = Color(0.3, 0.5, 0.25)
	flower.add_child(stem)

	for angle in [0.0, 90.0, 180.0, 270.0]:
		var petal := Polygon2D.new()
		petal.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -4), Vector2(2, 0), Vector2(0, 1.5)])
		petal.color = color
		petal.position = Vector2(0, -9)
		petal.rotation_degrees = angle
		flower.add_child(petal)
	return flower


static func _detail_mushroom(glowing: bool) -> Node2D:
	var mushroom := Node2D.new()
	var stem := Polygon2D.new()
	stem.polygon = PackedVector2Array([Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.2, -6), Vector2(-1.2, -6)])
	stem.color = Color(0.85, 0.8, 0.7)
	mushroom.add_child(stem)

	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		Vector2(-5, -6), Vector2(5, -6), Vector2(4, -10), Vector2(0, -12), Vector2(-4, -10),
	])
	cap.color = Color(0.35, 0.55, 0.9) if glowing else Color(0.75, 0.15, 0.15)
	mushroom.add_child(cap)

	if glowing:
		mushroom.add_child(Landmarks._glow(Vector2(0, -9), 18.0, Color(0.5, 0.7, 1.0, 0.35)))
	return mushroom


static func _detail_twig() -> Node2D:
	var twig := Line2D.new()
	var a := Vector2(-7, 0)
	var b := Vector2(7, randf_range(-2.0, 2.0))
	twig.points = PackedVector2Array([a, (a + b) * 0.5 + Vector2(0, -2), b])
	twig.width = 1.6
	twig.default_color = Color(0.35, 0.24, 0.14)
	return twig


static func _detail_bone() -> Node2D:
	var bone := Node2D.new()
	var shaft := Line2D.new()
	shaft.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0)])
	shaft.width = 2.2
	shaft.default_color = Color(0.88, 0.85, 0.75)
	bone.add_child(shaft)
	for x in [-8.0, 8.0]:
		var knob := Polygon2D.new()
		knob.polygon = _circle_points(2.6)
		knob.color = Color(0.88, 0.85, 0.75)
		knob.position = Vector2(x, 0)
		bone.add_child(knob)
	return bone


static func _detail_pebble(tint: Color) -> Node2D:
	var pebble := Polygon2D.new()
	pebble.polygon = _circle_points(randf_range(2.0, 4.0))
	pebble.color = Color(tint.r * 0.6, tint.g * 0.6, tint.b * 0.6, 1.0)
	return pebble


static func _detail_moss() -> Node2D:
	var moss := Polygon2D.new()
	moss.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(-3, -4), Vector2(5, -3), Vector2(8, 1), Vector2(2, 4), Vector2(-6, 3),
	])
	moss.color = Color(0.35, 0.5, 0.3, 0.55)
	return moss


static func _detail_crystal_shard() -> Node2D:
	var shard := Node2D.new()
	var color := Color(0.55, 0.75, 1.0, 0.85)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0, -10), Vector2(3, -3), Vector2(0, 0), Vector2(-3, -3)])
	poly.color = color
	shard.add_child(poly)
	shard.add_child(Landmarks._glow(Vector2(0, -5), 14.0, Color(color, 0.4)))
	return shard


static func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 8:
		var angle := TAU * float(i) / 8.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


# --- escuridão da caverna ------------------------------------------------


static func _build_cave_darkness(world: Node2D, terrain: Terrain, biome_list: Array) -> void:
	for biome_index in biome_list.size():
		if biome_list[biome_index]["id"] != "cave":
			continue
		var shade := Sprite2D.new()
		shade.name = "CaveDarkness"
		shade.centered = false
		shade.texture = terrain.bake_darkness(biome_index, 0.4)
		shade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shade.scale = Vector2(Terrain.CELL, Terrain.CELL)
		shade.z_index = Z_DARKNESS
		world.add_child(shade)


# --- utilitários -----------------------------------------------------------


static var _circles: Dictionary = {}


static func _circle(radius: float) -> CircleShape2D:
	if not _circles.has(radius):
		var shape := CircleShape2D.new()
		shape.radius = radius
		_circles[radius] = shape
	return _circles[radius]


static func _fill(parent: Node, rect: Rect2, color: Color, node_name: String, z: int = 0) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(rect.size.x, 0.0), rect.size, Vector2(0.0, rect.size.y),
	])
	poly.position = rect.position
	poly.color = color
	poly.z_index = z
	parent.add_child(poly)
	return poly
