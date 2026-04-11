## CombatAI.gd — VERSIÓN FINAL SIN ERRORES
## RUTA: res://scripts/systems/CombatAI.gd
##
## IMPORTANTE: Borra res://scripts/combat/CombatAI.gd si existe.
## Este archivo NO usa class_name para evitar conflicto de duplicados.
##
## Se accede con: CombatAI.decide(...)  gracias al autoload de GDScript,
## o directamente mediante load() si es necesario. Pero como es una clase
## estática sin class_name, CombatManager la referencia con preload.
extends RefCounted

static func decide(enemy: CombatUnit, players: Array[CombatUnit], allies: Array[CombatUnit]) -> Dictionary:
	var alive_players : Array[CombatUnit] = players.filter(
		func(u: CombatUnit) -> bool: return not u.is_dead()
	)
	if alive_players.is_empty():
		return {}

	if enemy.hero_data == null:
		return _fallback(enemy, alive_players)

	var hp_pct := float(enemy.current_hp) / float(enemy.max_hp)
	if hp_pct <= 0.25:
		return _berserker(enemy, alive_players)

	# CORRECCIÓN: acceso directo .role (no .get("role", default))
	match enemy.hero_data.role:
		HeroData.Role.TANQUE:    return _defensive(enemy, alive_players, allies)
		HeroData.Role.CURANDERO: return _defensive(enemy, alive_players, allies)
		HeroData.Role.MAGO:      return _tactical(enemy, alive_players)
		HeroData.Role.ARQUERO:   return _tactical(enemy, alive_players)
		_:                       return _aggressive(enemy, alive_players)

static func _aggressive(enemy: CombatUnit, players: Array[CombatUnit]) -> Dictionary:
	var target : CombatUnit = _get_lowest_hp(players)
	var skill  : SkillData  = _pick_best_attack(enemy)
	return { "skill": skill, "targets": players if skill != null and skill.target_type == SkillData.TargetType.ALL_ENEMIES else [target] }

static func _defensive(enemy: CombatUnit, players: Array[CombatUnit], allies: Array[CombatUnit]) -> Dictionary:
	var hp_pct := float(enemy.current_hp) / float(enemy.max_hp)

	if hp_pct < 0.40 and _can_use_ultimate(enemy):
		var ult : SkillData = enemy.hero_data.skill_ultimate
		if ult != null and ult.effect_type == SkillData.EffectType.HEAL:
			return { "skill": ult, "targets": [enemy] }

	if not allies.is_empty():
		var wounded : CombatUnit = _get_most_wounded(allies)
		if wounded != null:
			var w_pct := float(wounded.current_hp) / float(wounded.max_hp)
			if w_pct < 0.50 and _can_use_active(enemy):
				var act : SkillData = enemy.hero_data.skill_active
				if act != null and act.effect_type == SkillData.EffectType.HEAL:
					return { "skill": act, "targets": [wounded] }

	return _aggressive(enemy, players)

static func _tactical(enemy: CombatUnit, players: Array[CombatUnit]) -> Dictionary:
	var threat : CombatUnit = _get_highest_atk(players)

	if _can_use_active(enemy):
		var act : SkillData = enemy.hero_data.skill_active
		if act != null and act.effect_type in [SkillData.EffectType.DEBUFF, SkillData.EffectType.DOT]:
			if not _has_debuff(threat):
				return { "skill": act, "targets": [threat] }

	if players.size() >= 2 and _can_use_ultimate(enemy):
		var ult : SkillData = enemy.hero_data.skill_ultimate
		if ult != null and ult.target_type == SkillData.TargetType.ALL_ENEMIES:
			return { "skill": ult, "targets": players }

	return { "skill": enemy.hero_data.skill_basic, "targets": [_get_lowest_hp(players)] }

static func _berserker(enemy: CombatUnit, players: Array[CombatUnit]) -> Dictionary:
	var skill : SkillData = enemy.hero_data.skill_basic
	if enemy.hero_data.skill_ultimate != null:
		skill = enemy.hero_data.skill_ultimate
		enemy.current_energy = enemy.max_energy
	var target : CombatUnit = players[randi() % players.size()]
	return { "skill": skill, "targets": [target] }

static func _fallback(enemy: CombatUnit, players: Array[CombatUnit]) -> Dictionary:
	if enemy.hero_data == null or enemy.hero_data.skill_basic == null:
		return {}
	return { "skill": enemy.hero_data.skill_basic, "targets": [_get_lowest_hp(players)] }

static func _get_lowest_hp(units: Array[CombatUnit]) -> CombatUnit:
	var result : CombatUnit = units[0]
	for u : CombatUnit in units:
		if u.current_hp < result.current_hp:
			result = u
	return result

static func _get_highest_atk(units: Array[CombatUnit]) -> CombatUnit:
	var result : CombatUnit = units[0]
	for u : CombatUnit in units:
		if u.atk > result.atk:
			result = u
	return result

static func _get_most_wounded(units: Array[CombatUnit]) -> CombatUnit:
	var alive : Array[CombatUnit] = units.filter(
		func(u: CombatUnit) -> bool: return not u.is_dead()
	)
	if alive.is_empty(): return null
	var result  : CombatUnit = alive[0]
	var lowest  : float      = float(result.current_hp) / float(result.max_hp)
	for u : CombatUnit in alive:
		var pct := float(u.current_hp) / float(u.max_hp)
		if pct < lowest:
			lowest = pct
			result = u
	return result

static func _pick_best_attack(enemy: CombatUnit) -> SkillData:
	if _can_use_ultimate(enemy): return enemy.hero_data.skill_ultimate
	if _can_use_active(enemy) and randf() < 0.55: return enemy.hero_data.skill_active
	return enemy.hero_data.skill_basic

static func _can_use_active(enemy: CombatUnit) -> bool:
	return enemy.hero_data != null \
		and enemy.hero_data.skill_active != null \
		and enemy.current_energy >= enemy.hero_data.skill_active.energy_cost

static func _can_use_ultimate(enemy: CombatUnit) -> bool:
	return enemy.hero_data != null \
		and enemy.hero_data.skill_ultimate != null \
		and enemy.current_energy >= enemy.max_energy

static func _has_debuff(unit: CombatUnit) -> bool:
	for sid : String in unit.active_statuses.keys():
		if sid.begins_with("debuff_") or sid.begins_with("dot_"):
			return true
	return false
