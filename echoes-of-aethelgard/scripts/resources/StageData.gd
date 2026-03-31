## StageData.gd
## Resource para definir cada etapa del modo historia.
## Crear archivos .tres en res://resources/stages/
class_name StageData
extends Resource

enum Biome { BOSQUE_SUSURRANTE, RUINAS_HIERRO, CIUDAD_CRISTAL }

@export var stage_id: String         = ""    # Ej: "1-3"
@export var chapter: int             = 1
@export var stage_number: int        = 1
@export var stage_name: String       = ""
@export var biome: Biome             = Biome.BOSQUE_SUSURRANTE
@export var background: Texture2D    = null

@export_group("Enemies")
@export var enemy_ids: Array[String] = []    # IDs de HeroData usados como enemigos
@export var enemy_level: int         = 1
@export var boss_id: String          = ""    # Si hay jefe de etapa

@export_group("Rewards")
@export var reward_gold: int         = 100
@export var reward_amber: int        = 0
@export var reward_exp: int          = 200
@export var first_clear_amber: int   = 30    # Bonus único por primera vez

@export_group("Modifiers")
## Modificadores de stat por bioma
@export var enemy_atk_modifier: float = 1.0
@export var enemy_def_modifier: float = 1.0
@export var player_spd_modifier: float = 1.0  # Ej: 0.8 si el bioma ralentiza

func get_biome_label() -> String:
	match biome:
		Biome.BOSQUE_SUSURRANTE: return "El Bosque Susurrante"
		Biome.RUINAS_HIERRO:     return "Las Ruinas de Hierro"
		Biome.CIUDAD_CRISTAL:    return "La Ciudad de Cristal"
	return ""

func to_battle_config() -> Dictionary:
	return {
		"stage_id"      : stage_id,
		"enemies"       : enemy_ids,
		"enemy_level"   : enemy_level,
		"boss_id"       : boss_id,
		"atk_mod"       : enemy_atk_modifier,
		"def_mod"       : enemy_def_modifier,
		"spd_mod"       : player_spd_modifier,
	}
