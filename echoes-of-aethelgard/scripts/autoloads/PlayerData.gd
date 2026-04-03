## PlayerData.gd
## Clase que encapsula todo el estado persistente del jugador.
## No es un Autoload; GameManager la instancia y gestiona.
class_name PlayerData
extends RefCounted

# ─── Versión de Save Data ─────────────────────────────────────────────────────
const SAVE_VERSION: int = 2

# ─── Recursos ─────────────────────────────────────────────────────────────────
var amber_shards: int    = 0   # Moneda premium / gacha
var gold: int            = 0   # Moneda de farmeo

# ─── Stamina (Energía de Combate) ─────────────────────────────────────────────
var stamina: int              = 60   # Stamina actual
var max_stamina: int          = 60   # Máximo de stamina
var stamina_regen_rate: float = 300.0  # Segundos por punto (5 min)
var last_stamina_time: float  = 0.0   # Timestamp último regen
const STAMINA_COST_BATTLE: int = 6    # Costo por batalla

# ─── Progresión ───────────────────────────────────────────────────────────────
var current_chapter: int = 1
var current_stage: int   = 1
var completed_stages: Array[String] = []  # Ej: ["1-1", "1-2", "2-1"]
var max_chapter_unlocked: int = 1

# ─── Sistema Gacha ────────────────────────────────────────────────────────────
var pull_pity: int = 0           # Contador de pity (max 90 en legendario)
var pull_history: Array[String] = []  # IDs de héroes obtenidos

# ─── Colección de Héroes ──────────────────────────────────────────────────────
## Diccionario: hero_id → { "level": int, "copies": int, "stars": int, "exp": int }
var owned_heroes: Dictionary = {}

## Equipo activo (máximo 3 héroes)
var active_team: Array[String] = []

# ─── Estadísticas ─────────────────────────────────────────────────────────────
var total_pulls: int         = 0
var total_battles_won: int   = 0
var total_battles_lost: int  = 0
var play_time_seconds: float = 0.0

# ─── Daily Login ──────────────────────────────────────────────────────────────
var last_login_date: String     = ""   # "YYYY-MM-DD"
var consecutive_login_days: int = 0
var total_login_days: int       = 0
var daily_rewards_claimed: bool = false

# ─── Settings ─────────────────────────────────────────────────────────────────
var settings: Dictionary = {
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"battle_speed": 0,    # 0=x1, 1=x1.5, 2=x2
	"screen_shake": true,
	"auto_battle": false,
}

# ─── Métodos de Stamina ──────────────────────────────────────────────────────
func has_stamina(cost: int = STAMINA_COST_BATTLE) -> bool:
	_regen_stamina()
	return stamina >= cost

func spend_stamina(cost: int = STAMINA_COST_BATTLE) -> bool:
	_regen_stamina()
	if stamina >= cost:
		stamina -= cost
		SignalBus.stamina_changed.emit(stamina, max_stamina)
		return true
	return false

func refill_stamina(amount: int) -> void:
	stamina = mini(stamina + amount, max_stamina)
	SignalBus.stamina_changed.emit(stamina, max_stamina)

func _regen_stamina() -> void:
	if stamina >= max_stamina:
		last_stamina_time = Time.get_unix_time_from_system()
		return
	var now := Time.get_unix_time_from_system()
	if last_stamina_time <= 0:
		last_stamina_time = now
		return
	var elapsed := now - last_stamina_time
	var points_gained := int(elapsed / stamina_regen_rate)
	if points_gained > 0:
		stamina = mini(stamina + points_gained, max_stamina)
		last_stamina_time += points_gained * stamina_regen_rate
		SignalBus.stamina_changed.emit(stamina, max_stamina)

func get_stamina_time_to_next() -> float:
	if stamina >= max_stamina:
		return 0.0
	var now := Time.get_unix_time_from_system()
	var elapsed := now - last_stamina_time
	return maxf(0.0, stamina_regen_rate - elapsed)

# ─── Daily Login ──────────────────────────────────────────────────────────────
func check_daily_login() -> Dictionary:
	var today := Time.get_date_string_from_system()
	if today == last_login_date:
		return {}  # Ya se registró hoy

	var yesterday := _get_yesterday_string()
	if last_login_date == yesterday:
		consecutive_login_days += 1
	else:
		consecutive_login_days = 1

	last_login_date = today
	total_login_days += 1
	daily_rewards_claimed = false

	# Calcular recompensa basada en días consecutivos
	var rewards := _calculate_daily_reward(consecutive_login_days)
	return rewards

func _get_yesterday_string() -> String:
	var unix := Time.get_unix_time_from_system() - 86400
	var dict := Time.get_datetime_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]

func _calculate_daily_reward(day: int) -> Dictionary:
	var rewards := {}
	# Escala de recompensas por día consecutivo
	rewards["gold"] = 200 + (day * 100)
	if day >= 3:
		rewards["amber"] = 20 + (day * 5)
	if day >= 7:
		rewards["stamina"] = 30
	if day == 7 or day == 14 or day == 28:
		rewards["amber"] = rewards.get("amber", 0) + 100  # Bonus milestone
	return rewards

# ─── Métodos de Héroes ────────────────────────────────────────────────────────
func add_hero(hero_id: String) -> void:
	if hero_id in owned_heroes:
		owned_heroes[hero_id]["copies"] += 1
	else:
		owned_heroes[hero_id] = {"level": 1, "copies": 1, "stars": 1, "exp": 0}

func has_hero(hero_id: String) -> bool:
	return hero_id in owned_heroes

func get_hero_level(hero_id: String) -> int:
	return owned_heroes.get(hero_id, {}).get("level", 0)

func get_hero_exp(hero_id: String) -> int:
	if not owned_heroes.has(hero_id):
		return 0
	return owned_heroes[hero_id].get("exp", 0)

func get_exp_for_next_level(current_level: int) -> int:
	# Fórmula exponencial suave
	return int(100 * pow(1.15, current_level - 1))

func add_hero_exp(hero_id: String, exp_amount: int) -> bool:
	if not has_hero(hero_id):
		return false

	var hero: Dictionary = owned_heroes[hero_id]
	var current_level: int = hero.get("level", 1)
	if current_level >= 60:
		return false

	var current_exp: int = hero.get("exp", 0)
	hero["exp"] = current_exp + exp_amount

	# Subir niveles automáticamente
	var leveled_up := false
	while current_level < 60:
		var exp_needed: int = get_exp_for_next_level(current_level)
		if hero["exp"] >= exp_needed:
			hero["exp"] -= exp_needed
			current_level += 1
			hero["level"] = current_level
			leveled_up = true
			SignalBus.hero_leveled_up.emit(hero_id, current_level)
		else:
			break

	return leveled_up

func level_up_hero(hero_id: String) -> bool:
	if not has_hero(hero_id):
		return false
	var hero: Dictionary = owned_heroes[hero_id]
	if hero["level"] >= 60:
		return false
	hero["level"] += 1
	hero["exp"] = 0
	SignalBus.hero_leveled_up.emit(hero_id, hero["level"])
	return true

## Obtiene el oro necesario para subir al siguiente nivel
func get_level_up_cost(hero_id: String) -> int:
	var level := get_hero_level(hero_id)
	if level >= 60:
		return 0
	return 100 + (level * 50)

## Obtiene las copias necesarias para ascender estrellas
func get_ascension_cost(hero_id: String) -> int:
	if not has_hero(hero_id):
		return 0
	var stars: int = owned_heroes[hero_id].get("stars", 1)
	match stars:
		1: return 2  # 2 copias para 2 estrellas
		2: return 3  # 3 copias para 3 estrellas
		3: return 5  # 5 copias para 4 estrellas
		4: return 10 # 10 copias para 5 estrellas
	return 0

## Intenta ascender un héroe si tiene suficientes copias
func ascend_hero(hero_id: String) -> bool:
	if not has_hero(hero_id):
		return false
	var hero: Dictionary = owned_heroes[hero_id]
	var stars: int = hero.get("stars", 1)
	if stars >= 5:
		return false
	var cost := get_ascension_cost(hero_id)
	if hero["copies"] >= cost:
		hero["copies"] -= cost
		hero["stars"] += 1
		SignalBus.hero_ascended.emit(hero_id, hero["stars"])
		return true
	return false

func set_active_team(team: Array[String]) -> void:
	active_team = team.slice(0, 3)
	SignalBus.team_changed.emit(active_team)

## Calcula el poder total del equipo activo
func get_team_power() -> int:
	var power := 0
	for hero_id in active_team:
		if has_hero(hero_id):
			var level := get_hero_level(hero_id)
			var path := "res://resources/heroes_data/%s.tres" % hero_id
			if ResourceLoader.exists(path):
				var hd := load(path) as HeroData
				if hd:
					power += hd.get_hp_at_level(level) + hd.get_atk_at_level(level) * 3 + hd.get_def_at_level(level) * 2
	return power

# ─── Etapas ───────────────────────────────────────────────────────────────────
func complete_stage(chapter: int, stage: int) -> void:
	var key := "%d-%d" % [chapter, stage]
	if key not in completed_stages:
		completed_stages.append(key)
		SignalBus.stage_completed.emit(chapter, stage)
	# Desbloquear siguiente etapa/capítulo
	if stage >= 5:
		if chapter >= max_chapter_unlocked:
			max_chapter_unlocked = chapter + 1
			SignalBus.chapter_unlocked.emit(max_chapter_unlocked)

func is_stage_complete(chapter: int, stage: int) -> bool:
	return "%d-%d" % [chapter, stage] in completed_stages

func is_stage_unlocked(chapter: int, stage: int) -> bool:
	if chapter > max_chapter_unlocked:
		return false
	if stage == 1:
		return true
	return is_stage_complete(chapter, stage - 1)

# ─── Serialización ────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"save_version"          : SAVE_VERSION,
		"amber_shards"          : amber_shards,
		"gold"                  : gold,
		"stamina"               : stamina,
		"max_stamina"           : max_stamina,
		"last_stamina_time"     : last_stamina_time,
		"current_chapter"       : current_chapter,
		"current_stage"         : current_stage,
		"completed_stages"      : completed_stages,
		"max_chapter_unlocked"  : max_chapter_unlocked,
		"pull_pity"             : pull_pity,
		"pull_history"          : pull_history,
		"owned_heroes"          : owned_heroes,
		"active_team"           : active_team,
		"total_pulls"           : total_pulls,
		"total_battles_won"     : total_battles_won,
		"total_battles_lost"    : total_battles_lost,
		"play_time_seconds"     : play_time_seconds,
		"last_login_date"       : last_login_date,
		"consecutive_login_days": consecutive_login_days,
		"total_login_days"      : total_login_days,
		"daily_rewards_claimed" : daily_rewards_claimed,
		"settings"              : settings,
	}

func load_from_dict(data: Dictionary) -> void:
	# Migrar desde versiones anteriores si es necesario
	var version: int = data.get("save_version", 1)
	
	amber_shards         = data.get("amber_shards", 0)
	gold                 = data.get("gold", 0)
	stamina              = data.get("stamina", 60)
	max_stamina          = data.get("max_stamina", 60)
	last_stamina_time    = data.get("last_stamina_time", Time.get_unix_time_from_system())
	current_chapter      = data.get("current_chapter", 1)
	current_stage        = data.get("current_stage", 1)
	completed_stages     = Array(data.get("completed_stages", []), TYPE_STRING, "", null)
	max_chapter_unlocked = data.get("max_chapter_unlocked", 1)
	pull_pity            = data.get("pull_pity", 0)
	pull_history         = Array(data.get("pull_history", []), TYPE_STRING, "", null)
	owned_heroes         = data.get("owned_heroes", {})
	active_team          = Array(data.get("active_team", []), TYPE_STRING, "", null)
	total_pulls          = data.get("total_pulls", 0)
	total_battles_won    = data.get("total_battles_won", 0)
	total_battles_lost   = data.get("total_battles_lost", 0)
	play_time_seconds    = data.get("play_time_seconds", 0.0)
	last_login_date      = data.get("last_login_date", "")
	consecutive_login_days = data.get("consecutive_login_days", 0)
	total_login_days     = data.get("total_login_days", 0)
	daily_rewards_claimed = data.get("daily_rewards_claimed", false)
	settings             = data.get("settings", settings)

	# Asegurar que todos los héroes tengan el campo "exp"
	for hero_id in owned_heroes.keys():
		if not owned_heroes[hero_id].has("exp"):
			owned_heroes[hero_id]["exp"] = 0

	# Migración v1 → v2: agregar campos nuevos
	if version < 2:
		if not data.has("stamina"):
			stamina = max_stamina
			last_stamina_time = Time.get_unix_time_from_system()
		print("[PlayerData] Save migrado de v%d a v%d" % [version, SAVE_VERSION])

	# Regenerar stamina al cargar
	_regen_stamina()
