## SkillData.gd
## Resource para definir habilidades de combate.
class_name SkillData
extends Resource

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }
enum EffectType { DAMAGE, HEAL, BUFF, DEBUFF, SHIELD, DOT }

@export var skill_id: String        = ""
@export var skill_name: String      = ""
@export var description: String     = ""
@export var icon: Texture2D         = null

@export_group("Mechanics")
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var effect_type: EffectType = EffectType.DAMAGE
@export var energy_cost: int        = 0     # 0 = ataque básico gratuito
@export var cooldown_turns: int     = 0     # 0 = sin cooldown (usa energía)

@export_group("Values")
@export var power_multiplier: float = 1.0   # Multiplicador sobre ATK base
@export var effect_value: float     = 0.0   # Cantidad de heal/buff/etc.
@export var effect_duration: int    = 0     # Turnos que dura el efecto
@export var hit_count: int          = 1     # Golpes por uso

@export_group("Visuals")
@export var animation_name: String  = "skill_basic"
@export var vfx_scene: PackedScene  = null
