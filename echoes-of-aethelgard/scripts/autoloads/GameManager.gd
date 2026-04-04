## GameManager.gd
## Autoload Singleton — Núcleo central del juego.
extends Node

@warning_ignore("unused_signal")
signal hero_unlocked(hero_data: HeroData)
signal currency_changed(new_amount: int)
signal scene_transition_requested(scene_path: String)

const SAVE_PATH   := "user://aethelgard_save.dat"
const BACKUP_PATH := "user://aethelgard_save_backup.dat"
const VERSION     := "0.2.0"
const AUTO_SAVE_INTERVAL := 60.0

const SCENES := {
	"main_menu"       : "res://scenes/ui/MainMenu.tscn",
	"exploration_map" : "res://scenes/exploration/ExplorationMap.tscn",
	"gacha_screen"    : "res://scenes/ui/GachaScreen.tscn",
	"battle_scene"    : "res://scenes/combat/BattleScene.tscn",
	"hub_camp"        : "res://scenes/ui/hub_camp.tscn",
	"hero_roster"     : "res://scenes/ui/HeroRosterScreen.tscn",
	"team_selection"  : "res://scenes/ui/TeamSelectionScreen.tscn",
}

var player_data: PlayerData
var gacha_system: GachaSystem
var current_battle_config: Dictionary  = {}

## Config que el mapa pasa a TeamSelection antes de la batalla.
## TeamSelection lo lee para saber qué enemigos habrá.
var pending_battle_config: Dictionary  = {}

var _auto_save_timer: Timer
var _play_time_timer: Timer

func _ready() -> void:
	player_data  = PlayerData.new()
	gacha_system = GachaSystem.new()
	gacha_system.player_data = player_data
	add_child(gacha_system)
	_load_game()

	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)

	_play_time_timer = Timer.new()
	_play_time_timer.wait_time = 1.0
	_play_time_timer.autostart = true
	_play_time_timer.timeout.connect(func(): player_data.play_time_seconds += 1.0)
	add_child(_play_time_timer)

	AudioManager.apply_saved_settings(player_data.settings)

	var daily_reward := player_data.check_daily_login()
	if not daily_reward.is_empty():
		_apply_daily_rewards(daily_reward)

	print("[GameManager] Iniciado — Versión %s" % VERSION)

func _apply_daily_rewards(rewards: Dictionary) -> void:
	if rewards.has("gold"):
		player_data.gold += rewards["gold"]
	if rewards.has("amber"):
		player_data.amber_shards += rewards["amber"]
	if rewards.has("stamina"):
		player_data.refill_stamina(rewards["stamina"])
	SignalBus.daily_login_reward.emit(player_data.consecutive_login_days, rewards)
	save_game()

# ─── Guardado / Carga ─────────────────────────────────────────────────────────
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
				push_warning("[GameManager] Datos inválidos, intentando backup...")
				if not _load_backup():
					DirAccess.remove_absolute(SAVE_PATH)
					_new_game()
		else:
			if not _load_backup():
				_new_game()
	else:
		_new_game()

func _load_backup() -> bool:
	if not FileAccess.file_exists(BACKUP_PATH):
		return false
	var file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file:
		var data: Variant = file.get_var()
		file.close()
		if data is Dictionary and _validate_save_data(data):
			player_data.load_from_dict(data)
			save_game()
			return true
	return false

func _validate_save_data(data: Dictionary) -> bool:
	return data.has("amber_shards") and data.has("gold") and data.has("owned_heroes") and data.has("current_chapter")

func save_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(player_data.to_dict())
		file.close()
	else:
		push_error("[GameManager] Error al guardar.")

func _on_auto_save() -> void:
	save_game()

func _new_game() -> void:
	player_data.amber_shards    = 10000
	player_data.gold            = 5000
	player_data.current_chapter = 1
	player_data.current_stage   = 1
	player_data.pull_pity       = 0
	player_data.stamina         = player_data.max_stamina
	player_data.last_stamina_time = Time.get_unix_time_from_system()
	player_data.add_hero("aethan_paladin")
	player_data.add_hero("mira_sanadora")
	player_data.add_hero("lyra_arquera")
	player_data.set_active_team(["aethan_paladin", "mira_sanadora", "lyra_arquera"])
	print("[GameManager] Nueva partida iniciada.")

# ─── Navegación ───────────────────────────────────────────────────────────────
func go_to_scene(scene_key: String, battle_cfg: Dictionary = {}) -> void:
	if scene_key == "battle_scene":
		current_battle_config = battle_cfg
	var path: String = SCENES.get(scene_key, "")
	if path.is_empty():
		push_error("[GameManager] Escena no encontrada: %s" % scene_key)
		return
	scene_transition_requested.emit(path)
	if SceneTransition and not SceneTransition.is_transitioning():
		SceneTransition.transition_to_scene(path)
	else:
		get_tree().change_scene_to_file.call_deferred(path)

## Guarda la config de enemigos y va a la pantalla de selección de equipo.
## TeamSelectionScreen leerá pending_battle_config al confirmar el equipo.
func go_to_team_selection(battle_cfg: Dictionary) -> void:
	pending_battle_config = battle_cfg
	go_to_scene("team_selection")

# ─── Monedas ──────────────────────────────────────────────────────────────────
func spend_amber(amount: int) -> bool:
	if player_data.amber_shards >= amount:
		player_data.amber_shards -= amount
		currency_changed.emit(player_data.amber_shards)
		SignalBus.currency_changed.emit("amber", player_data.amber_shards)
		save_game()
		return true
	SignalBus.insufficient_currency.emit("amber", amount, player_data.amber_shards)
	return false

func add_amber(amount: int) -> void:
	player_data.amber_shards += amount
	currency_changed.emit(player_data.amber_shards)
	SignalBus.currency_changed.emit("amber", player_data.amber_shards)

func spend_gold(amount: int) -> bool:
	if player_data.gold >= amount:
		player_data.gold -= amount
		SignalBus.currency_changed.emit("gold", player_data.gold)
		return true
	SignalBus.insufficient_currency.emit("gold", amount, player_data.gold)
	return false

func add_gold(amount: int) -> void:
	player_data.gold += amount
	SignalBus.currency_changed.emit("gold", player_data.gold)

func can_battle() -> bool:
	return player_data.has_stamina()

func spend_battle_stamina() -> bool:
	return player_data.spend_stamina()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
