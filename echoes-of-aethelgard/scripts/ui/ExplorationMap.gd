## ExplorationMap.gd
## Mapa de exploración simple con el héroe principal
extends Node2D

@onready var hero: CharacterBody2D = $Hero
@onready var camera: Camera2D = $Camera2D
@onready var battle_button: Button = $UI/BattleButton

const SPEED := 200.0

func _ready() -> void:
	# Configurar cámara para seguir al héroe
	camera.position = hero.position
	battle_button.pressed.connect(_on_battle_button_pressed)

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

func _on_battle_button_pressed() -> void:
	GameManager.go_to_scene("team_selection")
