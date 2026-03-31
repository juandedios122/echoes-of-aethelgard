## CombatManager.gd
## Sistema de combate por turnos para BattleScene.
## Gestiona el flujo de turnos, aplicación de habilidades y condiciones de victoria.
class_name CombatManager
extends Node

# ─── Señales ──────────────────────────────────────────────────────────────────
signal turn_started(unit: CombatUnit)
signal action_executed(attacker: CombatUnit, target: CombatUnit, damage: int, label: String)
signal status_applied(unit: CombatUnit, status_name: String, duration: int)
signal unit_defeated(unit: CombatUnit)
signal battle_ended(victory: bool, rewards: Dictionary)

# ─── Estado del Combate ───────────────────────────────────────────────────────
enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }
var state: BattleState = BattleState.IDLE

var player_units: Array[CombatUnit] = []
var enemy_units: Array[CombatUnit]  = []
var turn_queue: Array[CombatUnit]   = []   # Ordenado por SPD
var current_turn_index: int         = 0
var turn_number: int                = 0

# ─── Sinergias de Facción ─────────────────────────────────────────────────────
const FACTION_BONUS_THRESHOLD: int = 3   # Necesita 3 héroes de la misma facción

# ─── Inicialización ───────────────────────────────────────────────────────────
func initialize(p_units: Array[CombatUnit], e_units: Array[CombatUnit]) -> void:
	player_units = p_units
	enemy_units  = e_units
	_apply_faction_synergies()
	_build_turn_queue()
	state = BattleState.IDLE
	print("[CombatManager] Combate inicializado. Unidades: %d vs %d" % [
		player_units.size(), enemy_units.size()
	])

func start_battle() -> void:
	turn_number = 0
	current_turn_index = 0
	_next_turn()

# ─── Gestión de Turnos ────────────────────────────────────────────────────────
func _build_turn_queue() -> void:
	turn_queue.clear()
	turn_queue.append_array(player_units)
	turn_queue.append_array(enemy_units)
	# Ordenar de mayor a menor velocidad
	turn_queue.sort_custom(func(a, b): return a.spd > b.spd)

func _next_turn() -> void:
	if state == BattleState.ENDED:
		return

	# Saltar unidades muertas
	while current_turn_index < turn_queue.size() and turn_queue[current_turn_index].is_dead():
		current_turn_index += 1

	if current_turn_index >= turn_queue.size():
		# Nueva ronda
		current_turn_index = 0
		turn_number += 1
		_tick_status_effects()
		_rebuild_queue_if_needed()

	if _check_battle_end():
		return

	var unit: CombatUnit = turn_queue[current_turn_index]
	turn_started.emit(unit)

	if _is_enemy(unit):
		state = BattleState.ENEMY_TURN
		await get_tree().create_timer(0.8).timeout
		_execute_enemy_ai(unit)
	else:
		state = BattleState.PLAYER_TURN

func advance_turn() -> void:
	current_turn_index += 1
	_next_turn()

# ─── Ejecución de Habilidades ─────────────────────────────────────────────────
func execute_skill(attacker: CombatUnit, skill: SkillData, targets: Array[CombatUnit]) -> void:
	state = BattleState.ANIMATING

	for target in targets:
		if target.is_dead():
			continue

		match skill.effect_type:
			SkillData.EffectType.DAMAGE:
				var dmg := _calculate_damage(attacker, target, skill)
				_apply_damage(attacker, target, dmg, skill)
			SkillData.EffectType.HEAL:
				var heal_amount := roundi(attacker.atk * skill.effect_value)
				target.heal(heal_amount)
				action_executed.emit(attacker, target, heal_amount, "HEAL")
			SkillData.EffectType.BUFF:
				target.apply_status(skill.skill_id, skill.effect_value, skill.effect_duration)
				status_applied.emit(target, skill.skill_name, skill.effect_duration)
			SkillData.EffectType.SHIELD:
				target.add_shield(roundi(attacker.atk * skill.effect_value))

		if target.is_dead():
			unit_defeated.emit(target)

	# Consumir energía
	attacker.current_energy -= skill.energy_cost
	attacker.current_energy = clamp(attacker.current_energy, 0, attacker.max_energy)

	await get_tree().create_timer(0.5).timeout
	state = BattleState.IDLE
	advance_turn()

# ─── Cálculo de Daño ─────────────────────────────────────────────────────────
func _calculate_damage(atk: CombatUnit, def: CombatUnit, skill: SkillData) -> int:
	var base := atk.atk * skill.power_multiplier
	var dmg   := base * (100.0 / (100.0 + def.def_stat))  # Fórmula de reducción

	# Crítico
	var is_crit := randf() < atk.crit_rate
	if is_crit:
		dmg *= atk.crit_dmg
		print("  [CRÍTICO]")

	# Varianza ±10%
	dmg *= randf_range(0.9, 1.1)

	return maxi(1, roundi(dmg))

func _apply_damage(atk: CombatUnit, def: CombatUnit, raw_dmg: int, skill: SkillData) -> void:
	var final_dmg := def.receive_damage(raw_dmg)
	action_executed.emit(atk, def, final_dmg, skill.skill_name)

# ─── IA Enemiga ───────────────────────────────────────────────────────────────
func _execute_enemy_ai(enemy: CombatUnit) -> void:
	## IA simple: siempre ataca al jugador con menos HP
	var alive_players := player_units.filter(func(u): return not u.is_dead())
	if alive_players.is_empty():
		return

	alive_players.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	var target: CombatUnit = alive_players[0]

	# Usa ultimate si tiene energía llena
	var chosen_skill: SkillData
	if enemy.current_energy >= enemy.max_energy and enemy.hero_data.skill_ultimate:
		chosen_skill = enemy.hero_data.skill_ultimate
	elif enemy.hero_data.skill_basic:
		chosen_skill = enemy.hero_data.skill_basic
		enemy.current_energy += 20  # Gana energía atacando

	if chosen_skill:
		await execute_skill(enemy, chosen_skill, [target])
	else:
		advance_turn()

# ─── Sinergias ────────────────────────────────────────────────────────────────
func _apply_faction_synergies() -> void:
	var faction_count := {}
	for unit in player_units:
		var f := unit.hero_data.faction
		faction_count[f] = faction_count.get(f, 0) + 1

	for faction_id in faction_count:
		if faction_count[faction_id] >= FACTION_BONUS_THRESHOLD:
			_apply_faction_bonus(faction_id)

func _apply_faction_bonus(faction_id: int) -> void:
	for unit in player_units:
		if unit.hero_data.faction == faction_id:
			var hd := unit.hero_data
			unit.max_hp   = roundi(unit.max_hp   * (1.0 + hd.faction_bonus_hp))
			unit.current_hp = unit.max_hp
			unit.atk      = roundi(unit.atk      * (1.0 + hd.faction_bonus_atk))
			unit.def_stat = roundi(unit.def_stat  * (1.0 + hd.faction_bonus_def))
	print("[CombatManager] Sinergia de facción aplicada: %d" % faction_id)

# ─── Efectos de Estado ────────────────────────────────────────────────────────
func _tick_status_effects() -> void:
	for unit in turn_queue:
		unit.tick_statuses()

# ─── Cola de Turnos ───────────────────────────────────────────────────────────
func _rebuild_queue_if_needed() -> void:
	turn_queue = turn_queue.filter(func(u): return not u.is_dead())
	if turn_queue.is_empty():
		_check_battle_end()

# ─── Condición de Victoria / Derrota ─────────────────────────────────────────
func _check_battle_end() -> bool:
	var all_players_dead := player_units.all(func(u): return u.is_dead())
	var all_enemies_dead  := enemy_units.all(func(u): return u.is_dead())

	if all_enemies_dead:
		_end_battle(true)
		return true
	elif all_players_dead:
		_end_battle(false)
		return true
	return false

func _end_battle(victory: bool) -> void:
	state = BattleState.ENDED
	var rewards := {}
	if victory:
		rewards = _calculate_rewards()
		GameManager.player_data.total_battles_won += 1
		GameManager.add_gold(rewards.get("gold", 0))
		GameManager.add_amber(rewards.get("amber", 0))
	else:
		GameManager.player_data.total_battles_lost += 1
	GameManager.save_game()
	battle_ended.emit(victory, rewards)
	print("[CombatManager] Batalla terminada. Victoria: %s" % str(victory))

func _calculate_rewards() -> Dictionary:
	## Escala con el capítulo actual
	var chapter := GameManager.player_data.current_chapter
	return {
		"gold"  : 100 + (chapter * 50) + randi() % 50,
		"amber" : randi() % 3,   # 0-2 ámbar por etapa normal
		"exp"   : 200 + chapter * 100,
	}

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _is_enemy(unit: CombatUnit) -> bool:
	return unit in enemy_units

func get_alive_enemies() -> Array[CombatUnit]:
	return enemy_units.filter(func(u): return not u.is_dead())

func get_alive_players() -> Array[CombatUnit]:
	return player_units.filter(func(u): return not u.is_dead())
