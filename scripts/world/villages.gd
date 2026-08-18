extends RefCounted

# Um povoado por bioma, perto do marco — casas/tendas do Pixelwood Valley e
# uma criatura mascote (o slime do Characters Animations Asset Pack, tingido
# por bioma) vagueando ao redor.
#
# IMPORTANTE: esses dois pacotes são de terceiros com licença "não
# redistribuir" e por isso NÃO estão no git (ver .gitignore e README) — só
# existem na máquina de quem baixou. Por isso nada aqui usa `preload()`
# (que quebraria o projeto pra quem clonou sem os assets); tudo é `load()`
# condicional, e se a pasta assets/village/ não existir, cada povoado nasce
# com casinhas e bichinhos desenhados por código (mesmo espírito dos marcos
# em landmarks.gd), sem ficar um buraco vazio no mapa.
#
# Também: só existe UMA espécie de bicho no pacote free (o slime) — a
# variedade "temática" entre biomas vem da cor, não de animais diferentes de
# verdade (não achamos vaca/galinha/camelo de graça em nenhum pacote
# baixado). Ver "O que ficou fora" no README.

const ASSET_DIR := "res://assets/village/"
const CRITTER_SCENE_SCRIPT := "res://scripts/village/village_critter.gd"
const CRITTER_PLACEHOLDER_SCRIPT := "res://scripts/village/village_critter_placeholder.gd"

const BUILDING_META := {
	"house_1": {"path": "houses/house_1.png", "radius": 40.0},
	"house_2": {"path": "houses/house_2.png", "radius": 40.0},
	"house_3": {"path": "houses/house_3.png", "radius": 40.0},
	"house_5": {"path": "houses/house_5.png", "radius": 40.0},
	"house_7": {"path": "houses/house_7.png", "radius": 40.0},
	"house_8": {"path": "houses/house_8.png", "radius": 40.0},
	"shop_1": {"path": "houses/shop_1.png", "radius": 26.0},
	"shop_2": {"path": "houses/shop_2.png", "radius": 26.0},
	"tent_1": {"path": "houses/tent_1.png", "radius": 34.0},
	"tent_2": {"path": "houses/tent_2.png", "radius": 34.0},
	"tent_3": {"path": "houses/tent_3.png", "radius": 34.0},
	"well_1": {"path": "houses/well_1.png", "radius": 26.0},
	"chest_1": {"path": "houses/chest_1.png", "radius": 14.0},
}

const VILLAGE_DEFS := {
	"forest": {
		"buildings": ["house_1", "house_2", "house_3", "well_1"],
		"critter_tint": Color(0.55, 0.95, 0.55),
		"villagers": 2, "critters": 2,
	},
	"desert": {
		"buildings": ["tent_1", "tent_2", "tent_3", "well_1"],
		"critter_tint": Color(0.95, 0.8, 0.4),
		"villagers": 1, "critters": 2,
	},
	"ruins": {
		"buildings": ["house_7", "house_8", "chest_1"],
		"critter_tint": Color(0.6, 0.6, 0.68),
		"villagers": 0, "critters": 2,
	},
	"cave": {
		"buildings": ["shop_1", "shop_2", "house_5", "well_1"],
		"critter_tint": Color(0.7, 0.45, 0.9),
		"villagers": 1, "critters": 2,
	},
}

const BUILDING_OFFSETS := [
	Vector2(-70, -30), Vector2(65, -45), Vector2(-40, 55), Vector2(80, 40),
	Vector2(10, -80), Vector2(-90, 20),
]

# Raio total que o povoado ocupa — usado por world_builder.gd pra afastar
# árvores/inimigos de cima das casas.
const FOOTPRINT_RADIUS := 190.0

static var _has_assets_cache: int = -1  # -1 = ainda não checou, 0/1 = resultado em cache


static func has_assets() -> bool:
	if _has_assets_cache == -1:
		_has_assets_cache = 1 if ResourceLoader.exists(ASSET_DIR + "houses/house_1.png") else 0
	return _has_assets_cache == 1


static func populate(entities: Node2D, biome_id: String, center: Vector2, rng: RandomNumberGenerator) -> void:
	if not VILLAGE_DEFS.has(biome_id):
		return
	var village: Dictionary = VILLAGE_DEFS[biome_id]

	if has_assets():
		_populate_real(entities, village, center)
	else:
		_populate_placeholder(entities, village, center)


# --- versão real (assets/village/ baixado) -----------------------------------


static func _populate_real(entities: Node2D, village: Dictionary, center: Vector2) -> void:
	var buildings: Array = village["buildings"]
	for i in buildings.size():
		var meta: Dictionary = BUILDING_META[buildings[i]]
		var spot: Vector2 = center + BUILDING_OFFSETS[i % BUILDING_OFFSETS.size()]
		_add_real_building(entities, ASSET_DIR + meta["path"], spot, meta["radius"])

	var tint: Color = village["critter_tint"]
	var idle_tex := load("res://assets/village/critters/slime_idle.png")
	var walk_tex := load("res://assets/village/critters/slime_walk.png")
	for i in int(village["critters"]):
		_add_real_critter(entities, idle_tex, walk_tex, tint, center)

	var villager_idle := load("res://assets/village/critters/villager_idle.png")
	var villager_walk := load("res://assets/village/critters/villager_walk.png")
	for i in int(village["villagers"]):
		_add_real_critter(entities, villager_idle, villager_walk, Color(1, 1, 1), center)


static func _add_real_building(entities: Node2D, path: String, spot: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = spot

	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.position = Vector2(0, -sprite.texture.get_height() * 0.5) if sprite.texture else Vector2.ZERO
	body.add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	body.add_child(shape)

	entities.add_child(body)


static func _add_real_critter(entities: Node2D, idle_tex: Texture2D, walk_tex: Texture2D, tint: Color, center: Vector2) -> void:
	var critter := Node2D.new()
	critter.set_script(load(CRITTER_SCENE_SCRIPT))

	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	critter.add_child(sprite)

	critter.position = center + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
	critter.setup(idle_tex, walk_tex, tint, 35.0)
	entities.add_child(critter)


# --- placeholder (sem asset externo) ------------------------------------------


static func _populate_placeholder(entities: Node2D, village: Dictionary, center: Vector2) -> void:
	var buildings: Array = village["buildings"]
	var tint: Color = village["critter_tint"]
	for i in buildings.size():
		var spot: Vector2 = center + BUILDING_OFFSETS[i % BUILDING_OFFSETS.size()]
		_add_placeholder_building(entities, spot, tint)

	var critter_count: int = int(village["critters"]) + int(village["villagers"])
	for i in critter_count:
		_add_placeholder_critter(entities, tint, center)


static func _add_placeholder_building(entities: Node2D, spot: Vector2, tint: Color) -> void:
	var body := StaticBody2D.new()
	body.position = spot

	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(24, 0), Vector2(24, -34), Vector2(-24, -34)])
	wall.color = Color(tint.r * 0.55 + 0.2, tint.g * 0.5 + 0.18, tint.b * 0.45 + 0.15)
	body.add_child(wall)

	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-30, -34), Vector2(30, -34), Vector2(0, -60)])
	roof.color = tint.darkened(0.2)
	body.add_child(roof)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	shape.position = Vector2(0, -12)
	body.add_child(shape)

	entities.add_child(body)


static func _add_placeholder_critter(entities: Node2D, tint: Color, center: Vector2) -> void:
	var critter := Node2D.new()
	critter.set_script(load(CRITTER_PLACEHOLDER_SCRIPT))
	critter.position = center + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
	critter.setup(tint, 35.0)
	entities.add_child(critter)
