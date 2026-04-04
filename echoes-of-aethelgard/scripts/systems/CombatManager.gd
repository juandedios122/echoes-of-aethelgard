## CombatManager.gd
## Sistema de combate por turnos con animaciones y distribución de EXP.
class_name CombatManager
extends Node

signal turn_started(unit: CombatUnit)
signal action_executed(attacker: CombatUnit, target: CombatUnit, damage: int, label: String)
signal status_applied(unit: CombatUnit, status_name: String, duration: int)
signal unit_defeated(unit: CombatUnit)
signal battle_ended(victory: bool, rewards: Dictionary)

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }
var state: BattleState = BattleState.IDLE

var player_units: Array[CombatUnit] = []
var enemy_units: Array[CombatUnit]  = []
var turn_queue: Array[CombatUnit]   = []
var current_turn_index: int         = 0
var turn_number: int                = 0

const FACTION_BONUS_THRESHOLD: int = 3

func initialize(p_units: Array[CombatUnit], e_units: Array[CombatUnit]) -> void:
	player_units = p_units
	enemy_units  = e_units
	_apply_faction_synergies()
	_build_turn_queue()
	state = BattleState.IDLE
	print("[CombatManager] %d jugadores vs %d enemigos" % [p_units.size(), e_units.size()])

func start_battle() -> void:
	turn_number        = 0
	current_turn_index = 0
	_next_turn()

# ─── Gestión de Turnos ────────────────────────────────────────────────────────
func _build_turn_queue() -> void:
	turn_queue.clear()
	turn_queue.append_array(player_units)
	turn_queue.append_array(enemy_units)
	turn_queue.sort_custom(func(a, b): return a.spd > b.spd)

func _next_turn() -> void:
	if state == BattleState.ENDED:
		return

	while current_turn_index < turn_queue.size() and turn_queue[current_turn_index].is_dead():
		current_turn_index += 1

	if current_turn_index >= turn_queue.size():
		current_turn_index = 0
		turn_number       += 1
		_tick_status_effects()
		_rebuild_queue_if_needed()

	if _check_battle_end():
		return

	var unit: CombatUnit = turn_queue[current_turn_index]
	turn_started.emit(unit)

	if _is_enemy(unit):
		state = BattleState.ENEMY_TURN
		await get_tree().create_timer(0.6).timeout
		_execute_enemy_ai(unit)
	else:
		state = BattleState.PLAYER_TURN

func advance_turn() -> void:
	current_turn_index += 1
	_next_turn()

# ─── Ejecución de Habilidades ─────────────────────────────────────────────────
func execute_skill(attacker: CombatUnit, skill: SkillData, targets: Array[CombatUnit]) -> void:
	state = BattleState.ANIMATING

	var alive_targets := targets.filter(func(t): return not t.is_dead())
	if alive_targets.is_empty():
		state = BattleState.IDLE
		advance_turn()
		return

	# Mover atacante hacia el objetivo
	var original_x := attacker.position.x
	var dir_x      := 70.0 if attacker.is_player_unit else -70.0
	attacker.play_animation("attack")
	var atk_tween := create_tween()
	atk_tween.tween_property(attacker, "position:x", original_x + dir_x, 0.18)

	await get_tree().create_timer(0.20).timeout

	for target in alive_targets:
		if target.is_dead():
			continue
		for _hit in skill.hit_count:
			match skill.effect_type:
				SkillData.EffectType.DAMAGE:
					var dmg := _calculate_damage(attacker, target, skill)
					_apply_damage_with_anim(attacker, target, dmg, skill)
					await get_tree().create_timer(0.15).timeout

				SkillData.EffectType.HEAL:
					var heal_amount := roundi(attacker.atk * skill.effect_value)
					target.heal(heal_amount)
					action_executed.emit(attacker, target, heal_amount, "CURAR")
					await get_tree().create_timer(0.15).timeout

				SkillData.EffectType.BUFF:
					target.apply_status("buff_" + skill.skill_id, skill.effect_value, skill.effect_duration)
					status_applied.emit(target, skill.skill_name, skill.effect_duration)

				SkillData.EffectType.DEBUFF:
					target.apply_status("debuff_atk_" + skill.skill_id, skill.effect_value, skill.effect_duration)
					if skill.effect_value > 0 and skill.effect_duration > 0:
						target.apply_status("dot_" + skill.skill_id, skill.effect_value, skill.effect_duration)
					status_applied.emit(target, skill.skill_name, skill.effect_duration)

				SkillData.EffectType.SHIELD:
					var shield_val := roundi(skill.effect_value) if skill.effect_value > 1 else roundi(attacker.max_hp * skill.effect_value)
					target.add_shield(shield_val)
					if skill.effect_duration > 0:
						target.apply_status("buff_def_" + skill.skill_id, 0.2, skill.effect_duration)

				SkillData.EffectType.DOT:
					target.apply_status("dot_" + skill.skill_id, skill.effect_value, skill.effect_duration)
					action_executed.emit(attacker, target, 0, "VENENO")
					status_applied.emit(target, skill.skill_name, skill.effect_duration)

		if target.is_dead():
			unit_defeated.emit(target)
			await get_tree().create_timer(0.4).timeout

	# Volver a posición original
	var ret_tween := create_tween()
	ret_tween.tween_property(attacker, "position:x", original_x, 0.20)
	attacker.play_idle()

	# Ganar energía si es básico
	if skill.energy_cost == 0:
		attacker.gain_energy(20)

	attacker.current_energy -= skill.energy_cost
	attacker.current_energy  = clamp(attacker.current_energy, 0, attacker.max_energy)

	await get_tree().create_timer(0.25).timeout
	state = BattleState.IDLE
	advance_turn()

func _apply_damage_with_anim(attacker: CombatUnit, target: CombatUnit, raw_dmg: int, skill: SkillData) -> void:
	var final_dmg := target.receive_damage(raw_dmg)
	action_executed.emit(attacker, target, final_dmg, skill.skill_name)
	if not target.is_dead() and target.sprite and target.sprite.sprite_frames:
		if target.sprite.sprite_frames.has_animation("hurt"):
			target.play_animation("hurt")
			get_tree().create_timer(0.4).timeout.connect(func():
				if is_instance_valid(target) and not target.is_dead():
					target.play_idle()
			)

# ─── Cálculo de Daño ──────────────────────────────────────────────────────────
func _calculate_damage(atk: CombatUnit, def: CombatUnit, skill: SkillData) -> int:
	var base := atk.atk * skill.power_multiplier
	base     *= atk.get_status_multiplier("atk")
	var def_mult := def.get_status_multiplier("def")
	var dmg  := base * (100.0 / (100.0 + def.def_stat * def_mult))

	if atk.hero_data and def.hero_data:
		dmg *= HeroData.get_elemental_multiplier(atk.hero_data.element, def.hero_data.element)

	if randf() < atk.crit_rate:
		dmg *= atk.crit_dmg

	dmg *= randf_range(0.92, 1.08)
	return maxi(1, roundi(dmg))

# ─── IA Enemiga ───────────────────────────────────────────────────────────────
func _execute_enemy_ai(enemy: CombatUnit) -> void:
	var alive_players := player_units.filter(func(u): return not u.is_dead())
	if alive_players.is_empty():
		return

	alive_players.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	var target: CombatUnit = alive_players[0]

	var chosen_skill: SkillData
	if enemy.is_energy_full() and enemy.hero_data and enemy.hero_data.skill_ultimate:
		chosen_skill         = enemy.hero_data.skill_ultimate
		enemy.current_energy = 0
	elif enemy.hero_data and enemy.hero_data.skill_basic:
		chosen_skill          = enemy.hero_data.skill_basic
		enemy.current_energy += 25

	if chosen_skill:
		var targets: Array[CombatUnit] = []
		if chosen_skill.target_type == SkillData.TargetType.ALL_ENEMIES:
			targets = alive_players
		else:
			targets = [target]
		await execute_skill(enemy, chosen_skill, targets)
	else:
		advance_turn()

# ─── Sinergias de Facción ─────────────────────────────────────────────────────
func _apply_faction_synergies() -> void:
	var faction_count := {}
	for unit in player_units:
		if unit.hero_data:
			var f := unit.hero_data.faction
			faction_count[f] = faction_count.get(f, 0) + 1
	for faction_id in faction_count:
		if faction_count[faction_id] >= FACTION_BONUS_THRESHOLD:
			_apply_faction_bonus(faction_id)

func _apply_faction_bonus(faction_id: int) -> void:
	for unit in player_units:
		if unit.hero_data and unit.hero_data.faction == faction_id:
			var hd := unit.hero_data
			unit.max_hp     = roundi(unit.max_hp   * (1.0 + hd.faction_bonus_hp))
			unit.current_hp = unit.max_hp
			unit.atk        = roundi(unit.atk      * (1.0 + hd.faction_bonus_atk))
			unit.def_stat   = roundi(unit.def_stat  * (1.0 + hd.faction_bonus_def))
	print("[CombatManager] Sinergia facción %d aplicada" % faction_id)

# ─── Efectos de Estado ────────────────────────────────────────────────────────
func _tick_status_effects() -> void:
	for unit in turn_queue:
		if not unit.is_dead():
			unit.tick_statuses()

func _rebuild_queue_if_needed() -> void:
	turn_queue = turn_queue.filter(func(u): return not u.is_dead())

# ─── Victoria / Derrota ───────────────────────────────────────────────────────
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

		# ── Distribuir EXP a todos los héroes del equipo ──────────────────────
		var exp_per_hero: int = rewards.get("exp", 0)
		var level_ups: Array  = []   # Lista de { hero_name, new_level }

		for unit in player_units:
			if unit.hero_data == null:
				continue
			var hero_id := unit.hero_data.hero_id
			if not GameManager.player_data.has_hero(hero_id):
				continue

			var old_level := GameManager.player_data.get_hero_level(hero_id)
			var leveled   := GameManager.player_data.add_hero_exp(hero_id, exp_per_hero)
			var new_level := GameManager.player_data.get_hero_level(hero_id)

			if leveled:
				level_ups.append({
					"hero_name" : unit.hero_data.hero_name,
					"old_level" : old_level,
					"new_level" : new_level,
				})
				print("[CombatManager] %s subió al nivel %d" % [unit.hero_data.hero_name, new_level])

		rewards["exp_per_hero"] = exp_per_hero
		rewards["level_ups"]    = level_ups
	else:
		GameManager.player_data.total_battles_lost += 1

	GameManager.save_game()
	battle_ended.emit(victory, rewards)
	print("[CombatManager] Batalla terminada. Victoria: %s" % str(victory))

func _calculate_rewards() -> Dictionary:
	var chapter := GameManager.player_data.current_chapter
	var stage   := GameManager.player_data.current_stage
	# EXP escala con capítulo y etapa, con un poco de varianza
	var base_exp := 150 + (chapter - 1) * 80 + stage * 20
	return {
		"gold"    : 80 + (chapter * 40) + stage * 10 + randi() % 40,
		"amber"   : 1 if randi() % 3 == 0 else 0,   # ~33% de obtener 1 ámbar
		"exp"     : base_exp + randi() % 50,
	}

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _is_enemy(unit: CombatUnit) -> bool:
	return unit in enemy_units

func get_alive_enemies() -> Array[CombatUnit]:
	return enemy_units.filter(func(u): return not u.is_dead())

func get_alive_players() -> Array[CombatUnit]:
	return player_units.filter(func(u): return not u.is_dead())
