## HeroData.gd
## Resource personalizado para definir cada héroe del juego.
## Crear archivos .tres en res://resources/heroes/ con estos campos.
## Usar en el Inspector de Godot para diseñar cada personaje sin código.
class_name HeroData
extends Resource

# ─── Enums ────────────────────────────────────────────────────────────────────
enum Faction  { ORDEN_ALBA, CAZADORES_BOSQUE, CONCLAVE_ARCANO, RENEGADOS }
enum Rarity   { COMUN, RARO, EPICO, LEGENDARIO }
enum Role     { TANQUE, GUERRERO, ARQUERO, MAGO, CURANDERO, MERCENARIO }
enum Element  { LUZ, NATURALEZA, ARCANO, FUEGO, SOMBRA, NEUTRO }

# ─── Identidad ────────────────────────────────────────────────────────────────
@export var hero_id: String         = ""
@export var hero_name: String       = ""
@export var title: String           = ""   # Ej: "El Último Paladín"
@export var lore_text: String       = ""   # Descripción de lore corta
@export var faction: Faction        = Faction.ORDEN_ALBA
@export var rarity: Rarity          = Rarity.COMUN
@export var role: Role              = Role.GUERRERO
@export var element: Element        = Element.NEUTRO

# ─── Visuales ─────────────────────────────────────────────────────────────────
@export var portrait: Texture2D     = null  # Retrato del héroe (512×512)
@export var sprite_sheet: Texture2D = null  # Hoja de animaciones (combate)
@export var card_background: Texture2D = null  # Fondo de la carta gacha

# ─── Estadísticas Base (Nivel 1) ──────────────────────────────────────────────
@export_group("Base Stats")
@export var base_hp: int       = 1000
@export var base_atk: int      = 100
@export var base_def: int      = 50
@export var base_spd: int      = 80    # Determina orden de turno
@export var base_crit_rate: float = 0.05   # 5% base
@export var base_crit_dmg: float  = 1.5   # 150% daño crítico

# ─── Habilidades ──────────────────────────────────────────────────────────────
@export_group("Skills")
@export var skill_basic: SkillData  = null  # Ataque básico (siempre disponible)
@export var skill_active: SkillData = null  # Habilidad activa (coste de energía)
@export var skill_passive: SkillData = null # Habilidad pasiva permanente
@export var skill_ultimate: SkillData = null # Ultimate (requiere energía llena)

# ─── Crecimiento por Nivel ────────────────────────────────────────────────────
@export_group("Growth Rates")
@export var hp_growth: float  = 0.08   # +8% HP por nivel
@export var atk_growth: float = 0.06
@export var def_growth: float = 0.05
@export var spd_growth: float = 0.02

# ─── Sinergias de Facción ─────────────────────────────────────────────────────
@export_group("Faction Synergy")
## Bonus que se aplica al equipo si 3 héroes son de la misma facción.
@export var faction_bonus_hp:  float = 0.0
@export var faction_bonus_atk: float = 0.0
@export var faction_bonus_def: float = 0.0

# ─── Métodos de Utilidad ──────────────────────────────────────────────────────
func get_stat_at_level(base_val: int, growth: float, level: int) -> int:
	return roundi(base_val * pow(1.0 + growth, level - 1))

func get_hp_at_level(level: int) -> int:
	return get_stat_at_level(base_hp, hp_growth, level)

func get_atk_at_level(level: int) -> int:
	return get_stat_at_level(base_atk, atk_growth, level)

func get_def_at_level(level: int) -> int:
	return get_stat_at_level(base_def, def_growth, level)

func get_rarity_label() -> String:
	match rarity:
		Rarity.COMUN:      return "Común"
		Rarity.RARO:       return "Raro"
		Rarity.EPICO:      return "Épico"
		Rarity.LEGENDARIO: return "Legendario"
	return ""

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMUN:      return Color(0.5, 0.48, 0.45, 1)   # Hierro/gris piedra
		Rarity.RARO:       return Color(0.55, 0.6, 0.65, 1)   # Plata envejecida
		Rarity.EPICO:      return Color(0.65, 0.5, 0.4, 1)    # Cobre oxidado
		Rarity.LEGENDARIO: return Color(0.7, 0.6, 0.45, 1)    # Bronce antiguo
	return Color.WHITE

func get_faction_label() -> String:
	match faction:
		Faction.ORDEN_ALBA:        return "Orden del Alba"
		Faction.CAZADORES_BOSQUE:  return "Cazadores del Bosque"
		Faction.CONCLAVE_ARCANO:   return "Cónclave Arcano"
		Faction.RENEGADOS:         return "Los Renegados"
	return ""
