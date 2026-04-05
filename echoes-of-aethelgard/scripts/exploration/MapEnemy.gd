## MapEnemy.gd
## Enemigo en el mapa con sprite real y grupos por capítulo.
## Usa resources/enemies/ con HeroData propios, no heroes_data del jugador.
extends Area2D

@export var speed: float            = 80.0
@export var detection_radius: float = 280.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var alert_icon: Sprite2D     = $AlertIcon

var target: Node2D       = null
var is_chasing: bool     = false
var original_position: Vector2
var enemy_group: Dictionary = {}

# ─── Grupos de encuentro organizados por capítulo ────────────────────────────
# Cada grupo: { enemies[], base_level, min_chapter, sprite_hero, name }
# sprite_hero: ID de resources/heroes/ (SpriteFrames del héroe jugador) que
#              se usa para visualmente identificar el grupo en el mapa.
const ENEMY_GROUPS := [
	# ── Capítulo 1: Enemigos débiles del bosque ───────────────────────────
	{
		"name"        : "Patrulla Goblin",
		"enemies"     : ["goblin_scout", "goblin_scout"],
		"base_level"  : 4,
		"min_chapter" : 1,
		"max_chapter" : 2,
		"sprite_hero" : "vex_nigromante",   # Sprite oscuro/pequeño
		"tint"        : Color(0.3, 0.8, 0.3, 1),   # Verde goblin
	},
	{
		"name"        : "Bandidos del Camino",
		"enemies"     : ["bandit_rogue", "bandit_rogue"],
		"base_level"  : 5,
		"min_chapter" : 1,
		"max_chapter" : 3,
		"sprite_hero" : "varra_mercenaria",
		"tint"        : Color(0.8, 0.6, 0.3, 1),   # Marrón bandido
	},
	{
		"name"        : "Guerreros Esqueleto",
		"enemies"     : ["skeleton_warrior"],
		"base_level"  : 5,
		"min_chapter" : 1,
		"max_chapter" : 3,
		"sprite_hero" : "kael_soldado",
		"tint"        : Color(0.85, 0.85, 0.85, 1), # Blanco hueso
	},

	# ── Capítulo 2-3: Enemigos medianos ───────────────────────────────────
	{
		"name"        : "Horda Orca",
		"enemies"     : ["orc_brute", "goblin_scout"],
		"base_level"  : 7,
		"min_chapter" : 2,
		"max_chapter" : 4,
		"sprite_hero" : "gorn_barbaro",
		"tint"        : Color(0.4, 0.7, 0.3, 1),   # Verde orco
	},
	{
		"name"        : "Magos Herejes",
		"enemies"     : ["dark_mage", "skeleton_warrior"],
		"base_level"  : 7,
		"min_chapter" : 2,
		"max_chapter" : 4,
		"sprite_hero" : "aldric_archimago",
		"tint"        : Color(0.5, 0.2, 0.8, 1),   # Púrpura magia oscura
	},
	{
		"name"        : "Arqueros Malditos",
		"enemies"     : ["cursed_archer", "cursed_archer"],
		"base_level"  : 8,
		"min_chapter" : 3,
		"max_chapter" : 5,
		"sprite_hero" : "theron_cazador",
		"tint"        : Color(0.6, 0.2, 0.2, 1),   # Rojo maldición
	},

	# ── Capítulo 4-5: Enemigos fuertes ────────────────────────────────────
	{
		"name"        : "Caballeros Corruptos",
		"enemies"     : ["corrupted_knight", "skeleton_warrior"],
		"base_level"  : 11,
		"min_chapter" : 4,
		"max_chapter" : 99,
		"sprite_hero" : "aethan_paladin",
		"tint"        : Color(0.3, 0.3, 0.6, 1),   # Azul oscuro corrupto
	},
	{
		"name"        : "Asesinos de Sombras",
		"enemies"     : ["shadow_assassin", "bandit_rogue"],
		"base_level"  : 11,
		"min_chapter" : 4,
		"max_chapter" : 99,
		"sprite_hero" : "vex_nigromante",
		"tint"        : Color(0.2, 0.1, 0.3, 1),   # Negro sombra
	},
	{
		"name"        : "Culto del Nigromante",
		"enemies"     : ["bone_necromancer", "skeleton_warrior", "skeleton_warrior"],
		"base_level"  : 13,
		"min_chapter" : 5,
		"max_chapter" : 99,
		"sprite_hero" : "vex_nigromante",
		"tint"        : Color(0.4, 0.1, 0.5, 1),   # Morado oscuro
	},
]

func _ready() -> void:
	original_position = global_position
	alert_icon.visible = false
	body_entered.connect(_on_body_entered)
	sprite.scale = Vector2(0.5, 0.5)

	var chapter: int = GameManager.player_data.current_chapter
	enemy_group = _pick_group_for_chapter(chapter)

	_load_sprite(enemy_group.get("sprite_hero", ""))
	# Teñir el sprite para distinguir visualmente el tipo de enemigo
	sprite.modulate = enemy_group.get("tint", Color.WHITE)

func _pick_group_for_chapter(chapter: int) -> Dictionary:
	## Filtrar grupos válidos para el capítulo actual y elegir uno al azar.
	var valid: Array = ENEMY_GROUPS.filter(func(g: Dictionary) -> bool:
		return chapter >= g["min_chapter"] and chapter <= g["max_chapter"]
	)
	if valid.is_empty():
		valid = [ENEMY_GROUPS[0]]   # Fallback al primero
	var picked: Dictionary = valid[randi() % valid.size()].duplicate()
	# Escalar el nivel: base_level + (chapter - min_chapter) * 2
	picked["level"] = picked["base_level"] + (chapter - picked["min_chapter"]) * 2
	return picked

func _load_sprite(hero_id: String) -> void:
	var path := "res://resources/heroes/%s.tres" % hero_id
	if ResourceLoader.exists(path):
		sprite.sprite_frames = load(path) as SpriteFrames
		sprite.animation     = "idle"
		sprite.play()
	else:
		_use_placeholder()

func _use_placeholder() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	var tx := PlaceholderTexture2D.new()
	tx.size = Vector2(64, 64)
	sf.add_frame("idle", tx)
	sprite.sprite_frames = sf
	sprite.play("idle")

func _process(delta: float) -> void:
	if not target:
		for hero in get_tree().get_nodes_in_group("player_hero"):
			if global_position.distance_to(hero.global_position) <= detection_radius:
				target     = hero
				is_chasing = true
				_show_alert()
				break
	else:
		var dist := global_position.distance_to(target.global_position)
		if dist > detection_radius * 1.5:
			is_chasing         = false
			target             = null
			alert_icon.visible = false
		elif is_chasing:
			var dir := (target.global_position - global_position).normalized()
			global_position += dir * speed * delta
			sprite.flip_h    = dir.x < 0

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
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished

	var battle_cfg := {
		"enemies"    : enemy_group.get("enemies", ["goblin_scout"]),
		"enemy_level": enemy_group.get("level", 5),
		"stage_name" : enemy_group.get("name", "Encuentro"),
	}
	GameManager.go_to_team_selection(battle_cfg)
