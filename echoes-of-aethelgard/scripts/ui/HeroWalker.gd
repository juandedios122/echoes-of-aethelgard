## HeroWalker.gd
## Personaje del equipo activo que camina de fondo en el hub camp.
## Nodo: Node2D con AnimatedSprite2D hijo
class_name HeroWalker
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var walk_speed : float = 60.0
var direction  : float = 1.0
var bounds_x   := Vector2(-400.0, 400.0)

func setup(hero_data: HeroData) -> void:
	var frames_path := "res://assets/sprites/heroes/%s/%s_frames.tres" % [
		hero_data.hero_name, hero_data.hero_name.to_lower()
	]
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path)
		sprite.play("walk")

func _process(delta: float) -> void:
	position.x += walk_speed * direction * delta
	sprite.flip_h = direction < 0
	
	if position.x > bounds_x.y:
		direction = -1.0
	elif position.x < bounds_x.x:
		direction  = 1.0
