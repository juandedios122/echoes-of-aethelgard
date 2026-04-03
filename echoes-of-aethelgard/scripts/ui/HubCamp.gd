## HubCamp.gd
## El campamento medieval — pantalla principal entre batallas.
## Árbol de nodos sugerido:
##   HubCamp (Node2D)
##   ├── ParallaxBackground
##   │   ├── Sky (ParallaxLayer)
##   │   ├── Mountains (ParallaxLayer)
##   │   └── Camp (ParallaxLayer)
##   ├── HeroWalkers (Node2D)         ← personajes caminando de fondo
##   ├── HUD (CanvasLayer)
##   │   ├── GoldLabel (Label)
##   │   ├── AmberLabel (Label)
##   │   └── PlayerNameLabel (Label)
##   ├── NavigationMenu (CanvasLayer)
##   │   ├── BattleButton (Button)
##   │   ├── GachaButton (Button)
##   │   ├── HeroRosterButton (Button)
##   │   └── SettingsButton (Button)
##   └── FireParticles (GPUParticles2D)
class_name HubCamp
extends Node2D

@onready var gold_label: Label   = $HUD/GoldLabel
@onready var amber_label: Label  = $HUD/AmberLabel
@onready var hero_walkers: Node2D = $HeroWalkers

const WalkerScene: PackedScene = preload("res://scenes/exploration/HeroWalker.tscn")

func _ready() -> void:
	_refresh_hud()
	_spawn_walkers()
	GameManager.currency_changed.connect(_on_currency_changed)

func _refresh_hud() -> void:
	var pd := GameManager.player_data
	gold_label.text  = "⚙ %d" % pd.gold
	amber_label.text = "🔶 %d" % pd.amber_shards

func _spawn_walkers() -> void:
	## Mostrar héroes del equipo activo caminando por el campamento
	var team := GameManager.player_data.active_team
	var start_x := -300.0
	for i in team.size():
		var hero_id: String = team[i]
		var path := "res://resources/heroes/%s.tres" % hero_id
		if not ResourceLoader.exists(path):
			continue
		var hero_data := load(path) as HeroData
		var walker: Node2D = WalkerScene.instantiate()
		hero_walkers.add_child(walker)
		walker.position = Vector2(start_x + i * 120.0, 50.0)
		if walker.has_method("setup"):
			walker.setup(hero_data)

# ─── Botones de Navegación ────────────────────────────────────────────────────
func _on_battle_pressed() -> void:
	GameManager.go_to_scene("battle_scene")  # Sin config = usa la etapa actual

func _on_gacha_pressed() -> void:
	GameManager.go_to_scene("gacha_screen")

func _on_roster_pressed() -> void:
	GameManager.go_to_scene("hero_roster")

func _on_settings_pressed() -> void:
	pass  # TODO: Abrir panel de configuración

func _on_currency_changed(_amount: int) -> void:
	_refresh_hud()
