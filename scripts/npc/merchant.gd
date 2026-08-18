extends Area2D

# NPC mercador: fica parado, e quando o jogador chega perto e aperta a
# tecla de interação, abre a loja (scripts/ui/shop_window.gd, achada pelo
# grupo "shop_window" — mesmo padrão usado pra achar o jogador pelo grupo
# "player"). Sem sprite de NPC no pacote de assets, então desenha um
# bonequinho simples por código (cabeça + túnica), no espírito dos marcos
# desenhados em landmarks.gd.

const BODY_COLOR := Color(0.35, 0.22, 0.1)
const HEAD_COLOR := Color(0.85, 0.7, 0.55)
const PROMPT_COLOR := Color(1, 0.851, 0.302)

var _player_near: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _draw() -> void:
	draw_rect(Rect2(-12, -34, 24, 34), BODY_COLOR)
	draw_circle(Vector2(0, -42), 10.0, HEAD_COLOR)
	if _player_near:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-40, -60), "[E] Loja", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, PROMPT_COLOR)


func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact"):
		var shop := get_tree().get_first_node_in_group("shop_window")
		if shop:
			shop.open_shop()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		queue_redraw()
