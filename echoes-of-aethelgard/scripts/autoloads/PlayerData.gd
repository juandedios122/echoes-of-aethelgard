## PlayerData.gd
## Clase que encapsula todo el estado persistente del jugador.
## No es un Autoload; GameManager la instancia y gestiona.
class_name PlayerData
extends RefCounted

# ─── Recursos ─────────────────────────────────────────────────────────────────
var amber_shards: int    = 0   # Moneda premium / gacha
var gold: int            = 0   # Moneda de farmeo

# ─── Progresión ───────────────────────────────────────────────────────────────
var current_chapter: int = 1
var current_stage: int   = 1
var completed_stages: Array[String] = []  # Ej: ["1-1", "1-2", "2-1"]

# ─── Sistema Gacha ────────────────────────────────────────────────────────────
var pull_pity: int = 0           # Contador de pity (max 90 en legendario)
var pull_history: Array[String] = []  # IDs de héroes obtenidos

# ─── Colección de Héroes ──────────────────────────────────────────────────────
## Diccionario: hero_id → { "level": int, "copies": int, "stars": int }
var owned_heroes: Dictionary = {}

## Equipo activo (máximo 3 héroes)
var active_team: Array[String] = []

# ─── Estadísticas ─────────────────────────────────────────────────────────────
var total_pulls: int         = 0
var total_battles_won: int   = 0
var total_battles_lost: int  = 0
var play_time_seconds: float = 0.0

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
	return owned_heroes.get(hero_id, {}).get("exp", 0)

func get_exp_for_next_level(current_level: int) -> int:
	# Fórmula exponencial tipo Dragon Ball Legends
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
		return true
	return false

func set_active_team(team: Array[String]) -> void:
	active_team = team.slice(0, 3)

# ─── Etapas ───────────────────────────────────────────────────────────────────
func complete_stage(chapter: int, stage: int) -> void:
	var key := "%d-%d" % [chapter, stage]
	if key not in completed_stages:
		completed_stages.append(key)

func is_stage_complete(chapter: int, stage: int) -> bool:
	return "%d-%d" % [chapter, stage] in completed_stages

# ─── Serialización ────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"amber_shards"      : amber_shards,
		"gold"              : gold,
		"current_chapter"   : current_chapter,
		"current_stage"     : current_stage,
		"completed_stages"  : completed_stages,
		"pull_pity"         : pull_pity,
		"pull_history"      : pull_history,
		"owned_heroes"      : owned_heroes,
		"active_team"       : active_team,
		"total_pulls"       : total_pulls,
		"total_battles_won" : total_battles_won,
		"total_battles_lost": total_battles_lost,
		"play_time_seconds" : play_time_seconds,
	}

func load_from_dict(data: Dictionary) -> void:
	amber_shards       = data.get("amber_shards", 0)
	gold               = data.get("gold", 0)
	current_chapter    = data.get("current_chapter", 1)
	current_stage      = data.get("current_stage", 1)
	completed_stages   = Array(data.get("completed_stages", []), TYPE_STRING, "", null)
	pull_pity          = data.get("pull_pity", 0)
	pull_history       = Array(data.get("pull_history", []), TYPE_STRING, "", null)
	owned_heroes       = data.get("owned_heroes", {})
	active_team        = Array(data.get("active_team", []), TYPE_STRING, "", null)
	total_pulls        = data.get("total_pulls", 0)
	total_battles_won  = data.get("total_battles_won", 0)
	total_battles_lost = data.get("total_battles_lost", 0)
	play_time_seconds  = data.get("play_time_seconds", 0.0)
