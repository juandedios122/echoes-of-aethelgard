## PlayerData.gd
## Datos persistentes del jugador
class_name PlayerData
extends RefCounted

# ─── Monedas ──────────────────────────────────────────────────────────────────
var amber_shards: int = 1000  # Moneda premium para gacha
var gold: int = 500           # Moneda común

# ─── Progreso ─────────────────────────────────────────────────────────────────
var current_chapter: int = 1
var current_stage: int = 1

# ─── Gacha ────────────────────────────────────────────────────────────────────
var pull_pity: int = 0        # Contador de pity para legendario
var total_pulls: int = 0      # Total de invocaciones realizadas
var pull_history: Array[String] = []  # IDs de héroes obtenidos

# ─── Héroes ───────────────────────────────────────────────────────────────────
var owned_heroes: Dictionary = {}  # hero_id -> cantidad de copias
var hero_levels: Dictionary = {}   # hero_id -> nivel actual

# ─── Métodos ──────────────────────────────────────────────────────────────────
func add_hero(hero_id: String) -> void:
	if owned_heroes.has(hero_id):
		owned_heroes[hero_id] += 1
	else:
		owned_heroes[hero_id] = 1
		hero_levels[hero_id] = 1

func has_hero(hero_id: String) -> bool:
	return owned_heroes.has(hero_id)

func get_hero_copies(hero_id: String) -> int:
	return owned_heroes.get(hero_id, 0)

# ─── Serialización ────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"amber_shards": amber_shards,
		"gold": gold,
		"current_chapter": current_chapter,
		"current_stage": current_stage,
		"pull_pity": pull_pity,
		"total_pulls": total_pulls,
		"pull_history": pull_history,
		"owned_heroes": owned_heroes,
		"hero_levels": hero_levels,
	}

func load_from_dict(data: Dictionary) -> void:
	amber_shards = data.get("amber_shards", 1000)
	gold = data.get("gold", 500)
	current_chapter = data.get("current_chapter", 1)
	current_stage = data.get("current_stage", 1)
	pull_pity = data.get("pull_pity", 0)
	total_pulls = data.get("total_pulls", 0)
	pull_history = data.get("pull_history", [])
	owned_heroes = data.get("owned_heroes", {})
	hero_levels = data.get("hero_levels", {})
