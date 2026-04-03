## ExplorationMap.gd
## Mapa de exploración simple con el héroe principal
extends Node2D

@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Camera2D

const SPEED := 200.0

func _ready() -> void:
	# Configurar cámara para seguir al héroe
	if camera and hero:
		camera.position = hero.position
	
	_generate_base_floor()
	
	# Reproducir música de exploración
	AudioManager.play_music("exploration_theme", 1.5)

func _generate_base_floor() -> void:
	var tile_map: TileMap = get_node_or_null("TileMap")
	if not tile_map:
		return
		
	# Si el mapa ya tiene tiles dibujados desde el editor, no lo sobrescribimos
	if tile_map.get_used_rect().get_area() > 0:
		return
		
	# Llenar un área equivalente a un escenario grande pero usando los tiles de 1024x1024
	var r = 4
	for x in range(-r, r):
		for y in range(-r, r):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		hero.velocity = direction * SPEED
	else:
		hero.velocity = Vector2.ZERO
	
	hero.move_and_slide()
	
	# Actualizar sprite del héroe
	_update_hero_animation(direction)
	
	# Cámara sigue al héroe suavemente
	camera.position = camera.position.lerp(hero.position, 5.0 * delta)

func _update_hero_animation(direction: Vector2) -> void:
	var sprite: AnimatedSprite2D = hero.get_node_or_null("AnimatedSprite2D")
	if not sprite or not sprite.sprite_frames:
		return
	
	if direction.length() > 0:
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		sprite.flip_h = direction.x < 0
	else:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
