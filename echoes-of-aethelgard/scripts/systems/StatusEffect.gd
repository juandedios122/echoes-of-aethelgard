## StatusEffect.gd — Resource que define un efecto de estado
class_name StatusEffect
extends Resource

enum Type {
	POISON,      # DoT: % de HP por turno
	BURN,        # DoT: daño + reduce DEF
	BLEED,       # DoT: escala con ATK del atacante
	STUN,        # Salta el turno
	FREEZE,      # Salta el turno + vulnerable a físico
	SLEEP,       # Salta el turno, se rompe al recibir daño
	BLIND,       # Reduce precisión (ataques físicos tienen 60% de fallar)
	SILENCE,     # No puede usar habilidades de coste > 0
	SHIELD_BREAK,# Reduce DEF 35% durante N turnos
	HASTE,       # +50% SPD durante N turnos (buff)
	REGEN,       # Recupera % HP por turno (buff)
	BARRIER,     # Absorbe próximo hit de daño (buff)
}

@export var type           : Type   = Type.POISON
@export var duration_turns : int    = 3
@export var value          : float  = 0.05   # Uso varía por tipo (% para DoT, mult para stats)
@export var source_id      : String = ""     # Hero ID que aplicó el efecto

func get_label() -> String:
	match type:
		Type.POISON:       return "☠ Veneno"
		Type.BURN:         return "🔥 Quemadura"
		Type.BLEED:        return "🩸 Sangrado"
		Type.STUN:         return "⚡ Aturdido"
		Type.FREEZE:       return "❄ Congelado"
		Type.SLEEP:        return "💤 Dormido"
		Type.BLIND:        return "👁 Cegado"
		Type.SILENCE:      return "🔇 Silenciado"
		Type.SHIELD_BREAK: return "💔 Armadura rota"
		Type.HASTE:        return "⚡ Celeridad"
		Type.REGEN:        return "💚 Regeneración"
		Type.BARRIER:      return "🛡 Barrera"
	return "?"

func get_color() -> Color:
	match type:
		Type.POISON, Type.BLEED:      return Color(0.5, 0.0, 0.6)
		Type.BURN:                    return Color(1.0, 0.4, 0.1)
		Type.STUN, Type.FREEZE:       return Color(0.4, 0.6, 1.0)
		Type.SLEEP:                   return Color(0.5, 0.3, 0.7)
		Type.HASTE, Type.REGEN:       return Color(0.3, 0.9, 0.5)
		Type.BARRIER:                 return Color(0.5, 0.7, 1.0)
		_:                            return Color(0.7, 0.7, 0.7)

## Retorna true si el efecto impide actuar
func blocks_action() -> bool:
	return type in [Type.STUN, Type.FREEZE, Type.SLEEP]

## Retorna true si es un buff (no debuff)
func is_buff() -> bool:
	return type in [Type.HASTE, Type.REGEN, Type.BARRIER]
