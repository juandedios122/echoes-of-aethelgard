## MapEnemy.gd
## Enemigo patrullando en el mapa de exploración.
extends Area2D

@export var enemy_group_id: String = "goblins" # ID del grupo de enemigos para cargar en batalla
@export var speed: float = 80.0
@export var detection_radius: float = 300.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var alert_icon: Sprite2D = $AlertIcon

var target: Node2D = null
var is_chasing: bool = false
var original_position: Vector2

func _ready() -> void:
	original_position = global_position
	alert_icon.visible = false
	body_entered.connect(_on_body_entered)
	
	# Setup SpriteFrames genérico por ahora
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	# Usaremos un placeholder rojo
	var tx = PlaceholderTexture2D.new()
	tx.size = Vector2(40, 40)
	sf.add_frame("idle", tx)
	sprite.sprite_frames = sf
	sprite.play("idle")
	sprite.modulate = Color(1, 0, 0, 1) # Rojo = enemigo

func _process(delta: float) -> void:
	if not target:
		var players = get_tree().get_nodes_in_group("player_hero")
		if players.size() > 0:
			var hero = players[0]
			if global_position.distance_to(hero.global_position) <= detection_radius:
				target = hero
				_show_alert()
				is_chasing = true
	else:
		if global_position.distance_to(target.global_position) > detection_radius * 1.5:
			is_chasing = false
			target = null
			alert_icon.visible = false
		elif is_chasing:
			var dir = (target.global_position - global_position).normalized()
			global_position += dir * speed * delta

func _show_alert() -> void:
	alert_icon.visible = true
	var t = create_tween()
	alert_icon.scale = Vector2.ZERO
	t.tween_property(alert_icon, "scale", Vector2(1,1), 0.2).set_trans(Tween.TRANS_BOUNCE)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_hero"):
		_initiate_battle()

func _initiate_battle() -> void:
	# Congelar Todo
	set_process(false)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_callback(func():
		var cfg = {
			"enemies": ["vex_nigromante", "vex_nigromante"], # Default genérico
			"enemy_level": GameManager.player_data.current_stage
		}
		GameManager.go_to_scene("battle_scene", cfg)
	)
