## HeroWalker.gd
## Personaje del equipo activo caminando de fondo en el HubCamp.
class_name HeroWalker
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var walk_speed: float = 60.0
var direction: float  = 1.0
var bounds_x := Vector2(-400.0, 400.0)

func setup(hero_data: HeroData) -> void:
	# Cargar SpriteFrames desde resources/heroes/{hero_id}.tres
	var frames_path := "res://resources/heroes/%s.tres" % hero_data.hero_id
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path) as SpriteFrames
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
	else:
		push_warning("[HeroWalker] SpriteFrames no encontrado: %s" % frames_path)

func _process(delta: float) -> void:
	position.x    += walk_speed * direction * delta
	sprite.flip_h   = direction < 0

	if position.x > bounds_x.y:
		direction = -1.0
	elif position.x < bounds_x.x:
		direction = 1.0
