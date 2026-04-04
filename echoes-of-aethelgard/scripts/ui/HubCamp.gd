## HubCamp.gd
## El campamento medieval — pantalla principal entre batallas.
## Árbol de nodos:
##   HubCamp (Node2D)
##   ├── ParallaxBackground / Castle / BackgroundTexture
##   ├── HeroWalkers (Node2D)
##   ├── HUD (CanvasLayer)
##   │   ├── GoldLabel (Label)
##   │   ├── AmberLabel (Label)
##   │   └── StaminaLabel (Label)
##   └── NavigationMenu (CanvasLayer)
##       └── VBoxContainer
##           ├── BattleButton (Button)
##           ├── GachaButton (Button)
##           ├── HeroRosterButton (Button)
##           └── SettingsButton (Button)
class_name HubCamp
extends Node2D

@onready var gold_label: Label    = $HUD/GoldLabel
@onready var amber_label: Label   = $HUD/AmberLabel
@onready var hero_walkers: Node2D = $HeroWalkers

const WalkerScene: PackedScene = preload("res://scenes/exploration/HeroWalker.tscn")

func _ready() -> void:
	_refresh_hud()
	_spawn_walkers()
	_connect_signals()
	AudioManager.play_music("menu_theme", 1.5)

func _connect_signals() -> void:
	SignalBus.currency_changed.connect(_on_currency_changed)
	SignalBus.stamina_changed.connect(_on_stamina_changed)

func _refresh_hud() -> void:
	var pd := GameManager.player_data
	gold_label.text  = "⚙ %d" % pd.gold
	amber_label.text = "🔶 %d" % pd.amber_shards

	# Mostrar stamina si el nodo existe
	var stamina_lbl := get_node_or_null("HUD/StaminaLabel") as Label
	if stamina_lbl:
		stamina_lbl.text = "⚡ %d / %d" % [pd.stamina, pd.max_stamina]

func _spawn_walkers() -> void:
	## BUG FIX: Cargar HeroData desde resources/heroes_data/ (no resources/heroes/)
	## resources/heroes/      → SpriteFrames (.tres con animaciones)
	## resources/heroes_data/ → HeroData     (.tres con stats, habilidades, etc.)
	var team := GameManager.player_data.active_team
	var start_x := -300.0
	for i in team.size():
		var hero_id: String = team[i]
		var path := "res://resources/heroes_data/%s.tres" % hero_id
		if not ResourceLoader.exists(path):
			push_warning("[HubCamp] HeroData no encontrado: %s" % path)
			continue
		var hero_data := load(path) as HeroData
		if hero_data == null:
			continue
		var walker: Node2D = WalkerScene.instantiate()
		hero_walkers.add_child(walker)
		walker.position = Vector2(start_x + i * 120.0, 50.0)
		if walker.has_method("setup"):
			walker.setup(hero_data)

# ─── Botones de Navegación ────────────────────────────────────────────────────
func _on_battle_pressed() -> void:
	GameManager.go_to_scene("exploration_map")

func _on_gacha_pressed() -> void:
	GameManager.go_to_scene("gacha_screen")

func _on_roster_pressed() -> void:
	GameManager.go_to_scene("hero_roster")

func _on_settings_pressed() -> void:
	pass  # TODO: Abrir panel de configuración (SettingsPanel.gd ya existe)

# ─── Actualización de HUD ─────────────────────────────────────────────────────
func _on_currency_changed(_type: String, _amount: int) -> void:
	_refresh_hud()

func _on_stamina_changed(_current: int, _max: int) -> void:
	var stamina_lbl := get_node_or_null("HUD/StaminaLabel") as Label
	if stamina_lbl:
		stamina_lbl.text = "⚡ %d / %d" % [_current, _max]
