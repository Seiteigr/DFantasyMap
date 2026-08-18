extends Node2D

# Bichinho decorativo do povoado: sem vida, sem dano, só vagueia num raio
# curto perto de onde nasceu. Usa a sprite sheet solta do pacote (idle/walk
# num PNG só, 96x96 por frame) — sem SpriteFrames pronto no asset, então
# fatiamos aqui mesmo em AtlasTexture.

const FRAME_SIZE := 96
const IDLE_FRAMES := 6
const WALK_FRAMES := 8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var idle_sheet: Texture2D
var walk_sheet: Texture2D
var wander_radius: float = 30.0
var speed: float = 18.0

var _origin: Vector2
var _target: Vector2
var _wait_time: float = 0.0


func setup(idle: Texture2D, walk: Texture2D, tint: Color, radius: float) -> void:
	idle_sheet = idle
	walk_sheet = walk
	wander_radius = radius
	modulate = tint


func _ready() -> void:
	_origin = position
	_target = position
	sprite.sprite_frames = _build_frames()
	sprite.play("idle")


func _process(delta: float) -> void:
	if _wait_time > 0.0:
		_wait_time -= delta
		return

	var to_target: Vector2 = _target - position
	if to_target.length() < 3.0:
		sprite.play("idle")
		_wait_time = randf_range(1.5, 3.0)
		var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		_target = _origin + offset
		return

	var dir := to_target.normalized()
	position += dir * speed * delta
	sprite.flip_h = dir.x < 0.0
	if sprite.animation != "walk":
		sprite.play("walk")


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", idle_sheet, IDLE_FRAMES)
	_add_animation(frames, "walk", walk_sheet, WALK_FRAMES)
	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 7.0)
	frames.set_animation_loop(anim_name, true)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas)
