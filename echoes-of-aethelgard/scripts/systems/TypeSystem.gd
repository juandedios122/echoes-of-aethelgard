## TypeSystem.gd — Autoload o clase estática
## Tabla de ventajas medievales:
##
##  LUZ      → SOMBRA     (+30%)
##  SOMBRA   → ARCANO     (+30%)
##  ARCANO   → NATURALEZA (+30%)
##  NATURALEZA → FUEGO    (+30%)
##  FUEGO    → LUZ        (+30%)
##
##  Cadena circular: L→S→A→N→F→L
##
##  NEUTRO nunca tiene ventaja ni desventaja.
##
class_name TypeSystem
extends RefCounted

const ADVANTAGE_BONUS      : float = 0.35   # +35% (más impactante que tu actual 30%)
const DISADVANTAGE_PENALTY : float = 0.20   # -20%
const IMMUNE_THRESHOLD     : float = 0.0    # para futura implementación de inmunidades

static func get_multiplier(atk_elem: HeroData.Element, def_elem: HeroData.Element) -> float:
	if atk_elem == HeroData.Element.NEUTRO or def_elem == HeroData.Element.NEUTRO:
		return 1.0
	if _is_advantage(atk_elem, def_elem):
		return 1.0 + ADVANTAGE_BONUS
	if _is_disadvantage(atk_elem, def_elem):
		return 1.0 - DISADVANTAGE_PENALTY
	return 1.0

static func get_effectiveness_label(mult: float) -> String:
	if mult > 1.1:   return "¡Es muy efectivo!"
	if mult < 0.9:   return "No es muy efectivo..."
	return ""

static func get_effectiveness_color(mult: float) -> Color:
	if mult > 1.1:   return Color(1.0, 0.85, 0.1)   # Dorado
	if mult < 0.9:   return Color(0.5, 0.5, 0.5)    # Gris
	return Color(1, 1, 1)

static func _is_advantage(atk: HeroData.Element, def: HeroData.Element) -> bool:
	var table := {
		HeroData.Element.LUZ        : HeroData.Element.SOMBRA,
		HeroData.Element.SOMBRA     : HeroData.Element.ARCANO,
		HeroData.Element.ARCANO     : HeroData.Element.NATURALEZA,
		HeroData.Element.NATURALEZA : HeroData.Element.FUEGO,
		HeroData.Element.FUEGO      : HeroData.Element.LUZ,
	}
	return table.get(atk) == def

static func _is_disadvantage(atk: HeroData.Element, def: HeroData.Element) -> bool:
	return _is_advantage(def, atk)
