## HeroWalker.gd
## Comportamiento de caminata para los walkers del HubCamp.
## Este script se aplica a nodos creados en código por HubCamp._create_walker_node()
## Los SpriteFrames ya están asignados ANTES de que este script se ejecute.
extends Node2D

var walk_speed: float  = 55.0
var direction: float   = 1.0
var bounds_x := Vector2(-500.0, 500.0)

func _ready() -> void:
	# El sprite ya tiene frames asignados por HubCamp antes de add_child.
	# Solo iniciamos la animación de caminata si existe.
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _process(delta: float) -> void:
	position.x += walk_speed * direction * delta

	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = direction < 0

	if position.x > bounds_x.y:
		direction = -1.0
	elif position.x < bounds_x.x:
		direction = 1.0

## Llamado desde HubCamp si se quiere usar la API de setup() tradicional.
## En este flujo no es necesario, pero se mantiene por compatibilidad.
func setup(_hero_data: Object) -> void:
	pass
