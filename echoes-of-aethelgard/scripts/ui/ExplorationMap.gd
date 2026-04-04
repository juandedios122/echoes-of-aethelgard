## ExplorationMap.gd
## Mapa de exploración — teclado (PC) + joystick virtual (Android).
## El VirtualJoystick se crea por código, NO hace falta añadirlo en la escena.
extends Node2D

@onready var hero: CharacterBody2D     = $Hero
@onready var camera: Camera2D          = $Camera2D
@onready var enemies_container: Node2D = $Enemies
@onready var ui_layer: CanvasLayer     = $UI

const SPEED := 220.0
const MapEnemyScene: PackedScene = preload("res://scenes/exploration/MapEnemy.tscn")

# Sin tipo explícito: evita el error de asignación antes de que el script
# se aplique al nodo (Godot asigna el script DESPUÉS de add_child).
var virtual_joystick: Node = null

# ─── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	if camera and hero:
		camera.position = hero.position

	_generate_base_floor()
	_create_virtual_joystick()
	_spawn_map_enemies()

	AudioManager.play_music("exploration_theme", 1.5)

## Crea el joystick virtual por código para evitar problemas de UID en la escena.
func _create_virtual_joystick() -> void:
	var joystick_script: Script = load("res://scripts/ui/VirtualJoystick.gd")
	if joystick_script == null:
		push_warning("[ExplorationMap] VirtualJoystick.gd no encontrado — solo teclado.")
		return

	# Crear el nodo, añadirlo al árbol PRIMERO, luego asignar el script.
	# Así Godot puede inicializar correctamente el tipo.
	var node := Control.new()
	node.name = "VirtualJoystick"
	ui_layer.add_child(node)
	node.set_script(joystick_script)
	virtual_joystick = node

func _generate_base_floor() -> void:
	var tile_map: TileMap = get_node_or_null("TileMap")
	if not tile_map:
		return
	if tile_map.get_used_rect().get_area() > 0:
		return
	var r := 6
	for x in range(-r, r):
		for y in range(-r, r):
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func _spawn_map_enemies() -> void:
	if not ResourceLoader.exists("res://scenes/exploration/MapEnemy.tscn"):
		return
	var positions := [
		Vector2(400, 100),
		Vector2(-350, 200),
		Vector2(600, -300),
		Vector2(-500, -150),
		Vector2(200, 400),
	]
	for pos in positions:
		var enemy: Node2D = MapEnemyScene.instantiate()
		enemies_container.add_child(enemy)
		enemy.position = pos

# ─── Movimiento ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	# Teclado / gamepad
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	# Joystick virtual (tiene prioridad si hay input táctil)
	if virtual_joystick != null and virtual_joystick.has_method("get_direction"):
		var joy_dir: Vector2 = virtual_joystick.get_direction()
		if joy_dir.length() > 0.1:
			direction = joy_dir

	if direction.length() > 1.0:
		direction = direction.normalized()

	hero.velocity = direction * SPEED
	hero.move_and_slide()

	_update_hero_animation(direction)
	camera.position = camera.position.lerp(hero.position, 6.0 * delta)

func _update_hero_animation(direction: Vector2) -> void:
	var sprite: AnimatedSprite2D = hero.get_node_or_null("AnimatedSprite2D")
	if not sprite or not sprite.sprite_frames:
		return

	if direction.length() > 0.05:
		if sprite.animation != "walk" and sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		if direction.x != 0:
			sprite.flip_h = direction.x < 0
	else:
		if sprite.animation != "idle" and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

# ─── Pausa ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var pause_menu := get_node_or_null("PauseMenu")
		if pause_menu and pause_menu.has_method("toggle"):
			pause_menu.toggle()
