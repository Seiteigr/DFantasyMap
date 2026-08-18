extends AnimatedSprite2D

# Efeito visual de golpe/magia: toca a animação "play" uma vez e se desfaz
# sozinho. Instanciado por player_base.gd (_spawn_attack_effect) e por
# arrow.gd (impacto da flecha) — mesmo script pros dois casos.


func _ready() -> void:
	play("play")
	animation_finished.connect(queue_free)
