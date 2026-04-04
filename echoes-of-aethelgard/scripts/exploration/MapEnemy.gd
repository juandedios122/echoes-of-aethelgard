## MapEnemy.gd
## Enemigo en el mapa con sprite real y grupo aleatorio de rivales.
extends Area2D

@export var speed: float          = 80.0
@export var detection_radius: float = 280.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var alert_icon: Sprite2D     = $AlertIcon

var target: Node2D      = null
var is_chasing: bool    = false
var original_position: Vector2
var enemy_group: Dictionary = {}   # { name, enemies, level }

# ─── Grupos de enemigos disponibles ──────────────────────────────────────────
# Cada grupo define qué héroes aparecen como rivales en la batalla y a qué nivel.
# Todos usan heroes_data existentes como plantilla de enemigo.
const ENEMY_GROUPS := [
	{ "name": "Bandidos",          "enemies": ["varra_mercenaria", "kael_soldado"],    "level": 3,  "sprite_hero": "varra_mercenaria" },
	{ "name": "Culto de Sombras",  "enemies": ["vex_nigromante"],                     "level": 5,  "sprite_hero": "vex_nigromante"   },
	{ "name": "Cazadores",         "enemies": ["theron_cazador", "lyra_arquera"],      "level": 4,  "sprite_hero": "theron_cazador"   },
	{ "name": "Bárbaros",          "enemies": ["gorn_barbaro", "kael_soldado"],        "level": 4,  "sprite_hero": "gorn_barbaro"     },
	{ "name": "Guardianes Caídos", "enemies": ["seraphel_jueza", "kael_soldado"],      "level": 6,  "sprite_hero": "seraphel_jueza"   },
	{ "name": "Magos Renegados",   "enemies": ["aldric_archimago", "vex_nigromante"],  "level": 6,  "sprite_hero": "aldric_archimago" },
]

func _ready() -> void:
	original_position = global_position
	alert_icon.visible = false
	body_entered.connect(_on_body_entered)

	# Escalar al tamaño correcto para el mundo (los sprites de héroe son grandes)
	sprite.scale = Vector2(0.5, 0.5)

	# Elegir un grupo aleatorio
	enemy_group = ENEMY_GROUPS[randi() % ENEMY_GROUPS.size()]

	# Escalar el nivel según el capítulo actual del jugador
	var chapter := GameManager.player_data.current_chapter
	enemy_group = enemy_group.duplicate()
	enemy_group["level"] = enemy_group["level"] + (chapter - 1) * 2

	_load_sprite(enemy_group["sprite_hero"])

func _load_sprite(hero_id: String) -> void:
	## Cargar los SpriteFrames del héroe desde resources/heroes/
	var frames_path := "res://resources/heroes/%s.tres" % hero_id
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path) as SpriteFrames
		sprite.animation     = "idle"
		sprite.play()
	else:
		# Fallback: cuadrado rojo si no existe el recurso
		push_warning("[MapEnemy] SpriteFrames no encontrado: %s" % frames_path)
		_use_placeholder()

func _use_placeholder() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	var tx := PlaceholderTexture2D.new()
	tx.size = Vector2(40, 40)
	sf.add_frame("idle", tx)
	sprite.sprite_frames = sf
	sprite.play("idle")
	sprite.modulate = Color(1, 0.2, 0.2, 1)

func _process(delta: float) -> void:
	if not target:
		# Detectar héroe del jugador
		for hero in get_tree().get_nodes_in_group("player_hero"):
			if global_position.distance_to(hero.global_position) <= detection_radius:
				target      = hero
				is_chasing  = true
				_show_alert()
				break
	else:
		var dist := global_position.distance_to(target.global_position)
		if dist > detection_radius * 1.5:
			# El jugador escapó
			is_chasing         = false
			target             = null
			alert_icon.visible = false
		elif is_chasing:
			# Perseguir
			var dir := (target.global_position - global_position).normalized()
			global_position   += dir * speed * delta
			sprite.flip_h      = dir.x < 0

func _show_alert() -> void:
	alert_icon.visible = true
	var t := create_tween()
	alert_icon.scale = Vector2.ZERO
	t.tween_property(alert_icon, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BOUNCE)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_hero"):
		_initiate_battle()

func _initiate_battle() -> void:
	set_process(false)

	# Animación de "enganche"
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	await tween.finished

	# Pasar la config al GameManager y abrir selección de equipo
	var battle_cfg := {
		"enemies"    : enemy_group["enemies"],
		"enemy_level": enemy_group["level"],
		"stage_name" : enemy_group["name"],
	}
	GameManager.go_to_team_selection(battle_cfg)
