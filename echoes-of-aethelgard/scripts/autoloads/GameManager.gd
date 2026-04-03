## GameManager.gd
## Autoload Singleton — Núcleo central del juego.
## Añadir en: Proyecto > Configuración > Autoloads como "GameManager"
extends Node

# ─── Señales Globales ────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal hero_unlocked(hero_data: HeroData)
signal currency_changed(new_amount: int)
signal scene_transition_requested(scene_path: String)

# ─── Constantes ──────────────────────────────────────────────────────────────
const SAVE_PATH := "user://aethelgard_save.dat"
const VERSION   := "0.1.0"

# ─── Escenas Principales ─────────────────────────────────────────────────────
const SCENES := {
	"main_menu"        : "res://scenes/ui/MainMenu.tscn",
	"exploration_map"  : "res://scenes/exploration/ExplorationMap.tscn",
	"gacha_screen"     : "res://scenes/ui/GachaScreen.tscn",
	"battle_scene"     : "res://scenes/combat/BattleScene.tscn",
	"hub_camp"         : "res://scenes/ui/hub_camp.tscn",
	"hero_roster"      : "res://scenes/ui/HeroRosterScreen.tscn",
	"team_selection"   : "res://scenes/ui/TeamSelectionScreen.tscn",
}

# ─── Estado de la Partida en Curso ───────────────────────────────────────────
var player_data: PlayerData
var gacha_system: GachaSystem
var current_battle_config: Dictionary = {}

# ─── Inicialización ──────────────────────────────────────────────────────────
func _ready() -> void:
	player_data  = PlayerData.new()
	gacha_system = GachaSystem.new()
	gacha_system.player_data = player_data
	add_child(gacha_system)
	_load_game()
	print("[GameManager] Iniciado — Versión %s" % VERSION)

# ─── Guardado / Carga ────────────────────────────────────────────────────────
func _load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data: Variant = file.get_var()
			file.close()
			if data is Dictionary and _validate_save_data(data):
				player_data.load_from_dict(data)
				print("[GameManager] Partida cargada.")
			else:
				push_warning("[GameManager] Datos de guardado inválidos. Eliminando archivo y empezando nueva partida.")
				DirAccess.remove_absolute(SAVE_PATH)
				_new_game()
		else:
			push_error("[GameManager] Error al abrir archivo de guardado.")
			_new_game()
	else:
		_new_game()

func _validate_save_data(data: Dictionary) -> bool:
	# Validar campos esenciales
	return data.has("amber_shards") and data.has("gold") and data.has("heroes") and data.has("current_chapter")

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(player_data.to_dict())
	file.close()
	print("[GameManager] Partida guardada.")

func _new_game() -> void:
	player_data.amber_shards    = 10000  # Moneda gacha de inicio (aumentada para pruebas)
	player_data.gold            = 5000   # Oro inicial para pruebas
	player_data.current_chapter = 1
	player_data.current_stage   = 1
	player_data.pull_pity       = 0
	
	# Agregar algunos héroes de inicio para pruebas
	player_data.add_hero("aethan_paladin")
	player_data.add_hero("mira_sanadora")
	player_data.add_hero("lyra_arquera")
	
	print("[GameManager] Nueva partida iniciada.")

# ─── Cambio de Escena con Transición ─────────────────────────────────────────
func go_to_scene(scene_key: String, battle_cfg: Dictionary = {}) -> void:
	if scene_key == "battle_scene":
		current_battle_config = battle_cfg
	var path: String = SCENES.get(scene_key, "")
	if path.is_empty():
		push_error("[GameManager] Escena no encontrada: %s" % scene_key)
		return
	scene_transition_requested.emit(path)
	get_tree().change_scene_to_file.call_deferred(path)

# ─── Monedas ─────────────────────────────────────────────────────────────────
func spend_amber(amount: int) -> bool:
	if player_data.amber_shards >= amount:
		player_data.amber_shards -= amount
		currency_changed.emit(player_data.amber_shards)
		save_game()
		return true
	return false

func add_amber(amount: int) -> void:
	player_data.amber_shards += amount
	currency_changed.emit(player_data.amber_shards)

func add_gold(amount: int) -> void:
	player_data.gold += amount
