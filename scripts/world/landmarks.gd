extends RefCounted

# Um marco visual por bioma, pra dar identidade e um "landmark" pra
# lembrar onde é onde (pedido nº 4 e nº 16 do brainstorm).
#
# Não veio nenhum sprite de pirâmide/templo/cristal no pacote de assets, e
# eu não desenho imagem — então cada marco aqui é montado com formas
# geométricas (Polygon2D/Line2D) tingidas na cor do bioma, ou reaproveitando
# um asset existente em escala maior (a árvore gigante usa tree1.png). É
# estilizado, não pixel art "de verdade", mas cumpre o papel de "algo
# memorável e diferente do resto do cenário".
#
# Cada função devolve um StaticBody2D com origem no PÉ do marco (mesma
# convenção dos props em world_builder.gd), pronto pra entrar no nó
# y-sorted de entidades.

const TEX_TREE := preload("res://assets/props/tree1.png")

# Textura branca 1x1 usada como base de qualquer "brilho": um Sprite2D com
# essa textura, escalado grande e com um shader/gradiente de alpha, vira
# uma auréola de luz suave (usado em tochas e cristais).
static var _glow_cache: Dictionary = {}


static func build(kind: String, tint: Color) -> Node2D:
	match kind:
		"giant_tree":
			return _giant_tree(tint)
		"pyramid":
			return _pyramid(tint)
		"ruins":
			return _ruined_temple(tint)
		"crystal":
			return _crystal_cluster(tint)
	return Node2D.new()


# --- Floresta: árvore ancestral ---------------------------------------------


static func _giant_tree(tint: Color) -> Node2D:
	var root := StaticBody2D.new()
	root.name = "GiantTree"

	var sprite := Sprite2D.new()
	sprite.texture = TEX_TREE
	sprite.scale = Vector2(3.0, 3.2)
	sprite.position = Vector2(0, -95.0 * 3.2 * 0.5 - 40.0)
	sprite.modulate = Color(tint.r * 0.85, tint.g * 0.95, tint.b * 0.85)
	root.add_child(sprite)

	# Pontinhos de luz em volta da copa: sugerem magia sem precisar de
	# partícula animada.
	for offset in [Vector2(-70, -260), Vector2(60, -300), Vector2(10, -230)]:
		root.add_child(_glow(offset, 26.0, Color(0.85, 1.0, 0.6, 0.5)))

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 46.0
	shape.shape = circle
	shape.position = Vector2(0, -10)
	root.add_child(shape)
	return root


# --- Deserto: pirâmide -------------------------------------------------------


static func _pyramid(tint: Color) -> Node2D:
	var root := StaticBody2D.new()
	root.name = "Pyramid"

	var half_w := 170.0
	var height := 230.0
	var apex := Vector2(0, -height)
	var base_l := Vector2(-half_w, 0)
	var base_r := Vector2(half_w, 0)

	var stone := Color(tint.r * 0.75, tint.g * 0.62, tint.b * 0.40)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([apex, base_r, base_l])
	body.color = stone
	root.add_child(body)

	# Faixas horizontais: dão a leitura de "degraus" sem modelar cada um.
	var step_color := stone.darkened(0.25)
	for t: float in [0.25, 0.45, 0.62, 0.78]:
		var y: float = lerp(base_l.y, apex.y, t)
		var w: float = lerp(half_w, 0.0, t)
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(-w, y), Vector2(w, y)])
		line.width = 3.0
		line.default_color = step_color
		root.add_child(line)

	# Entrada escura na base.
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0), Vector2(14, -46), Vector2(-14, -46),
	])
	door.color = Color(0.08, 0.06, 0.04, 0.9)
	root.add_child(door)

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(half_w * 1.5, 90.0)
	shape.shape = box
	shape.position = Vector2(0, -45)
	root.add_child(shape)
	return root


# --- Ruínas: templo desmoronado ---------------------------------------------


static func _ruined_temple(tint: Color) -> Node2D:
	var root := StaticBody2D.new()
	root.name = "RuinedTemple"
	var stone := Color(tint.r * 0.9, tint.g * 0.9, tint.b * 0.86)

	# Piso do templo: uma laje irregular por baixo de tudo.
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(-140, -20), Vector2(-90, -55), Vector2(90, -50), Vector2(150, -10),
		Vector2(120, 40), Vector2(-30, 55), Vector2(-130, 30),
	])
	floor_poly.color = stone.darkened(0.35)
	floor_poly.z_index = -1
	root.add_child(floor_poly)

	# Colunas de pé, num anel solto — o jogador passa entre elas.
	var standing := [
		Vector2(-100, -10), Vector2(-40, -40), Vector2(50, -35), Vector2(110, 0),
	]
	for pos in standing:
		root.add_child(_pillar(pos, 120.0 + randf_seed(pos) * 30.0, stone, false))
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 13.0
		shape.shape = circle
		shape.position = pos
		root.add_child(shape)

	# Colunas caídas: só decoração, sem colisão.
	root.add_child(_pillar(Vector2(-10, 20), 100.0, stone, true))
	root.add_child(_pillar(Vector2(70, 30), 90.0, stone, true))

	# Tochas junto da "entrada" (lado sul, onde o piso é mais aberto).
	root.add_child(_torch(Vector2(-70, 30)))
	root.add_child(_torch(Vector2(60, 35)))
	return root


static func _pillar(base: Vector2, height: float, stone: Color, fallen: bool) -> Node2D:
	var pillar := Node2D.new()
	pillar.position = base

	var body := Polygon2D.new()
	var w := 13.0
	body.polygon = PackedVector2Array([
		Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.8, -height), Vector2(-w * 0.8, -height),
	])
	body.color = stone
	pillar.add_child(body)

	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-w * 1.3, -height), Vector2(w * 1.3, -height),
		Vector2(w * 1.1, -height - 12), Vector2(-w * 1.1, -height - 12),
	])
	top.color = stone.darkened(0.15)
	pillar.add_child(top)

	if fallen:
		pillar.rotation_degrees = 88.0
		pillar.modulate.a = 0.9
	return pillar


# Um número pseudo-aleatório estável a partir de uma posição, só pra variar
# a altura das colunas sem precisar carregar um RNG até aqui.
static func randf_seed(v: Vector2) -> float:
	var h := int(v.x * 928371 + v.y * 128371)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFF) / 65535.0


# --- Caverna: cristais gigantes ----------------------------------------------


static func _crystal_cluster(tint: Color) -> Node2D:
	var root := StaticBody2D.new()
	root.name = "CrystalCluster"

	var specs := [
		{"pos": Vector2(0, 0), "w": 34.0, "h": 150.0, "color": Color(0.55, 0.75, 1.0, 0.85)},
		{"pos": Vector2(-45, 10), "w": 22.0, "h": 95.0, "color": Color(0.65, 0.55, 1.0, 0.85)},
		{"pos": Vector2(48, 14), "w": 24.0, "h": 105.0, "color": Color(0.5, 0.85, 0.95, 0.85)},
		{"pos": Vector2(-20, 20), "w": 16.0, "h": 65.0, "color": Color(0.6, 0.65, 1.0, 0.8)},
		{"pos": Vector2(28, 22), "w": 16.0, "h": 60.0, "color": Color(0.55, 0.8, 1.0, 0.8)},
	]

	for spec in specs:
		var pos: Vector2 = spec["pos"]
		var color: Color = spec["color"]
		root.add_child(_glow(pos - Vector2(0, spec["h"] * 0.3), spec["h"] * 0.9, Color(color, 0.35)))

	for spec in specs:
		var crystal := Polygon2D.new()
		var w: float = spec["w"]
		var h: float = spec["h"]
		crystal.polygon = PackedVector2Array([
			Vector2(0, -h), Vector2(w * 0.6, -h * 0.55), Vector2(w * 0.55, -h * 0.05),
			Vector2(0, 0), Vector2(-w * 0.55, -h * 0.05), Vector2(-w * 0.6, -h * 0.55),
		])
		crystal.position = spec["pos"]
		crystal.color = spec["color"]
		root.add_child(crystal)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 60.0
	shape.shape = circle
	shape.position = Vector2(5, 5)
	root.add_child(shape)
	return root


# --- utilitário de brilho ----------------------------------------------------


# Uma auréola aditiva: um círculo com alpha caindo do centro pra fora,
# desenhado com blend ADD. Usado nas tochas e nos cristais.
static func _glow(pos: Vector2, radius: float, color: Color) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.texture = _glow_texture(radius)
	glow.position = pos
	glow.modulate = color
	glow.material = _add_material()
	glow.z_index = 5
	return glow


static func _torch(pos: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.position = pos

	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(3, -34), Vector2(-3, -34),
	])
	post.color = Color(0.28, 0.18, 0.10)
	holder.add_child(post)

	var flame := Polygon2D.new()
	flame.polygon = PackedVector2Array([
		Vector2(0, -34), Vector2(7, -46), Vector2(0, -60), Vector2(-7, -46),
	])
	flame.color = Color(1.0, 0.65, 0.15)
	holder.add_child(flame)

	holder.add_child(_glow(Vector2(0, -46), 60.0, Color(1.0, 0.7, 0.3, 0.45)))
	return holder


static var _add_shader_material: ShaderMaterial


static func _add_material() -> ShaderMaterial:
	if _add_shader_material == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
render_mode blend_add;

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
"""
		_add_shader_material = ShaderMaterial.new()
		_add_shader_material.shader = shader
	return _add_shader_material


static func _glow_texture(radius: float) -> ImageTexture:
	var key := int(radius)
	if _glow_cache.has(key):
		return _glow_cache[key]

	var size := key * 2
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for y in size:
		for x in size:
			var dist := Vector2(x, y).distance_to(center) / radius
			var a := clampf(1.0 - dist, 0.0, 1.0)
			a *= a
			image.set_pixel(x, y, Color(1, 1, 1, a))

	var tex := ImageTexture.create_from_image(image)
	_glow_cache[key] = tex
	return tex
