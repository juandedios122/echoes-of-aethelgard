## HubCamp.gd
## El campamento medieval — pantalla principal entre batallas.
## Los walkers se crean en código para evitar el bug de autoplay del .tscn
class_name HubCamp
extends Node2D

@onready var gold_label: Label    = $HUD/GoldLabel
@onready var amber_label: Label   = $HUD/AmberLabel
@onready var hero_walkers: Node2D = $HeroWalkers

func _ready() -> void:
	_refresh_hud()
	_connect_signals()
	# Diferir los walkers al siguiente frame para evitar conflictos de _ready()
	call_deferred("_spawn_walkers")
	AudioManager.play_music("menu_theme", 1.5)

func _connect_signals() -> void:
	SignalBus.currency_changed.connect(_on_currency_changed)
	SignalBus.stamina_changed.connect(_on_stamina_changed)

func _refresh_hud() -> void:
	var pd := GameManager.player_data
	gold_label.text  = "⚙ %d" % pd.gold
	amber_label.text = "🔶 %d" % pd.amber_shards
	var stamina_lbl := get_node_or_null("HUD/StaminaLabel") as Label
	if stamina_lbl:
		stamina_lbl.text = "⚡ %d / %d" % [pd.stamina, pd.max_stamina]

func _spawn_walkers() -> void:
	## Crea los walkers completamente en código para evitar el bug de autoplay
	## que ocurre cuando el AnimatedSprite2D entra al árbol con sprite_frames null.
	var team := GameManager.player_data.active_team
	var start_x := -300.0

	for i in team.size():
		var hero_id: String = team[i]

		# Cargar los SpriteFrames del héroe (resources/heroes/{hero_id}.tres)
		var frames_path := "res://resources/heroes/%s.tres" % hero_id
		if not ResourceLoader.exists(frames_path):
			continue
		var frames := load(frames_path)
		if not frames is SpriteFrames:
			continue

		# Crear el walker Node2D en código
		var walker := _create_walker_node(frames as SpriteFrames)
		hero_walkers.add_child(walker)
		walker.position = Vector2(start_x + i * 200.0, 0.0)
		walker.set_meta("direction", 1.0)

## Crea un Node2D con AnimatedSprite2D ya configurado correctamente.
## Al crear el sprite ANTES de add_child, el autoplay no interfiere.
func _create_walker_node(frames: SpriteFrames) -> Node2D:
	var walker := Node2D.new()

	# Crear el AnimatedSprite2D y configurarlo ANTES de añadirlo al árbol
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames   # ← Asignar frames ANTES de entrar al árbol
	sprite.scale         = Vector2(1.5, 1.5)

	# Elegir animación segura
	if frames.has_animation("idle"):
		sprite.animation = "idle"
		sprite.autoplay  = "idle"
	elif frames.get_animation_names().size() > 0:
		var first: String = frames.get_animation_names()[0]
		sprite.animation = first
		sprite.autoplay  = first

	walker.add_child(sprite)
	walker.set_script(_WalkerBehavior)
	return walker

## Script inline para el comportamiento del walker (evita cargar HeroWalker.tscn)
const _WalkerBehavior = preload("res://scripts/ui/HeroWalker.gd")

# ─── Botones de Navegación ────────────────────────────────────────────────────
func _on_battle_pressed() -> void:
	GameManager.go_to_scene("exploration_map")

func _on_gacha_pressed() -> void:
	GameManager.go_to_scene("gacha_screen")

func _on_roster_pressed() -> void:
	GameManager.go_to_scene("hero_roster")

func _on_settings_pressed() -> void:
	pass

# ─── Actualización de HUD ─────────────────────────────────────────────────────
func _on_currency_changed(_type: String, _amount: int) -> void:
	_refresh_hud()

func _on_stamina_changed(_current: int, _max: int) -> void:
	var stamina_lbl := get_node_or_null("HUD/StaminaLabel") as Label
	if stamina_lbl:
		stamina_lbl.text = "⚡ %d / %d" % [_current, _max]
