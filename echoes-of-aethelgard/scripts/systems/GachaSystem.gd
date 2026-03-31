## GachaSystem.gd
## Sistema de Gacha completo con pity, tasas por rareza y pools de héroes.
## Instanciado y gestionado por GameManager.
class_name GachaSystem
extends Node

# ─── Señales ──────────────────────────────────────────────────────────────────
signal pull_completed(results: Array[HeroData])
signal pity_updated(current_pity: int, pity_cap: int)

# ─── Referencia ───────────────────────────────────────────────────────────────
var player_data: PlayerData  # Asignado por GameManager

# ─── Costos ───────────────────────────────────────────────────────────────────
const COST_SINGLE: int = 160    # Ámbar por 1 invocación
const COST_MULTI: int  = 1440   # Ámbar por 10 invocaciones (10% descuento)
const PITY_CAP: int    = 90     # Garantía legendario al tirar N

# ─── Tasas Base (sin pity activo) ─────────────────────────────────────────────
const RATE_LEGENDARIO: float = 0.006   #  0.6%
const RATE_EPICO:      float = 0.060   #  6.0%
const RATE_RARO:       float = 0.240   # 24.0%
# Común: el resto ≈ 69.4%

# ─── Pools de Héroes (IDs de los .tres resources) ─────────────────────────────
## Rellenar con las rutas a los HeroData resources de cada rareza.
var pool_legendario: Array[HeroData] = []
var pool_epico:      Array[HeroData] = []
var pool_raro:       Array[HeroData] = []
var pool_comun:      Array[HeroData] = []

# ─── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	_load_hero_pools()

func _load_hero_pools() -> void:
	## Carga todos los HeroData desde res://resources/heroes_data/
	var dir := DirAccess.open("res://resources/heroes_data/")
	if dir == null:
		push_warning("[GachaSystem] Directorio de héroes no encontrado.")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://resources/heroes_data/" + file_name
			var hero := load(path) as HeroData
			if hero:
				_add_to_pool(hero)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("[GachaSystem] Pools cargados — L:%d E:%d R:%d C:%d" % [
		pool_legendario.size(), pool_epico.size(),
		pool_raro.size(), pool_comun.size()
	])

func _add_to_pool(hero: HeroData) -> void:
	match hero.rarity:
		HeroData.Rarity.LEGENDARIO: pool_legendario.append(hero)
		HeroData.Rarity.EPICO:      pool_epico.append(hero)
		HeroData.Rarity.RARO:       pool_raro.append(hero)
		HeroData.Rarity.COMUN:      pool_comun.append(hero)

# ─── Invocación ───────────────────────────────────────────────────────────────
func pull_single() -> bool:
	if not GameManager.spend_amber(COST_SINGLE):
		return false
	var result: Array[HeroData] = [_do_single_pull()]
	player_data.total_pulls += 1
	pull_completed.emit(result)
	pity_updated.emit(player_data.pull_pity, PITY_CAP)
	GameManager.save_game()
	return true

func pull_multi() -> bool:
	if not GameManager.spend_amber(COST_MULTI):
		return false
	var results: Array[HeroData] = []
	for i in 10:
		results.append(_do_single_pull())
		player_data.total_pulls += 1
	# Garantía: al menos 1 Raro en x10
	var has_raro := results.any(func(h): return h.rarity >= HeroData.Rarity.RARO)
	if not has_raro:
		var idx := randi() % results.size()
		results[idx] = _pick_from_pool(pool_raro)
	pull_completed.emit(results)
	pity_updated.emit(player_data.pull_pity, PITY_CAP)
	GameManager.save_game()
	return true

# ─── Lógica Interna ───────────────────────────────────────────────────────────
func _do_single_pull() -> HeroData:
	player_data.pull_pity += 1
	var hero: HeroData

	# Pity duro: al llegar al límite, garantiza legendario
	if player_data.pull_pity >= PITY_CAP:
		hero = _pick_from_pool(pool_legendario)
		player_data.pull_pity = 0
	else:
		hero = _roll_rarity()

	# Registrar
	player_data.add_hero(hero.hero_id)
	player_data.pull_history.append(hero.hero_id)
	GameManager.hero_unlocked.emit(hero)
	return hero

func _roll_rarity() -> HeroData:
	## Pity suave: la tasa de legendario aumenta a partir del tirada 75
	var leg_rate := RATE_LEGENDARIO
	if player_data.pull_pity >= 75:
		leg_rate += (player_data.pull_pity - 74) * 0.06  # +6% por tirada

	var roll := randf()
	if roll < leg_rate:
		player_data.pull_pity = 0
		return _pick_from_pool(pool_legendario)
	elif roll < leg_rate + RATE_EPICO:
		return _pick_from_pool(pool_epico)
	elif roll < leg_rate + RATE_EPICO + RATE_RARO:
		return _pick_from_pool(pool_raro)
	else:
		return _pick_from_pool(pool_comun)

func _pick_from_pool(pool: Array[HeroData]) -> HeroData:
	if pool.is_empty():
		push_error("[GachaSystem] Pool vacío, devolviendo placeholder.")
		return HeroData.new()
	return pool[randi() % pool.size()]

# ─── Información para la UI ───────────────────────────────────────────────────
func get_pity_percentage() -> float:
	return float(player_data.pull_pity) / float(PITY_CAP)

func get_current_leg_rate() -> float:
	var leg_rate := RATE_LEGENDARIO
	if player_data.pull_pity >= 75:
		leg_rate += (player_data.pull_pity - 74) * 0.06
	return clampf(leg_rate, 0.0, 1.0)
