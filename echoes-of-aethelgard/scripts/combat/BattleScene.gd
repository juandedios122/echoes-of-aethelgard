## BattleScene.gd
## Controlador principal de la escena de combate.
## Árbol de nodos sugerido:
##   BattleScene (Node2D)
##   ├── Background (TextureRect / ParallaxBackground)
##   ├── PlayerUnitsContainer (Node2D)
##   ├── EnemyUnitsContainer (Node2D)
##   ├── CombatManager (Node)          ← script CombatManager.gd
##   ├── BattleUI (CanvasLayer)
##   │   ├── SkillBar (HBoxContainer)  ← botones de habilidades
##   │   ├── SpeedToggle (Button)      ← x1 / x2 velocidad
##   │   ├── AutoToggle (Button)       ← combate automático
##   │   └── ResultPanel (Panel)       ← resultado al terminar
##   └── Transition (ColorRect)        ← fundido entrada/salida
class_name BattleScene
extends Node2D

# ─── Nodos ────────────────────────────────────────────────────────────────────
@onready var combat_manager: CombatManager   = $CombatManager
@onready var player_container: Node2D        = $PlayerUnitsContainer
@onready var enemy_container: Node2D         = $EnemyUnitsContainer
@onready var skill_bar: HBoxContainer        = $BattleUI/SkillBar
@onready var speed_btn: Button               = $BattleUI/SpeedToggle
@onready var auto_btn: Button                = $BattleUI/AutoToggle
@onready var result_panel: Panel             = $BattleUI/ResultPanel
@onready var transition: ColorRect           = $Transition

# ─── Preloads ─────────────────────────────────────────────────────────────────
const CombatUnitScene: PackedScene = preload("res://CombatUnit.tscn")
const EnemyDataPath: String        = "res://resources/enemies/"

# ─── Estado ───────────────────────────────────────────────────────────────────
var auto_battle: bool   = false
var speed_x2: bool      = false
var selected_unit: CombatUnit = null
var battle_config: Dictionary = {}   # Recibido de GameManager

# ─── Posiciones de Unidades ───────────────────────────────────────────────────
const PLAYER_POSITIONS := [
	Vector2(-280, 80), Vector2(-220, 20), Vector2(-160, 80)
]
const ENEMY_POSITIONS := [
	Vector2(160, 80), Vector2(220, 20), Vector2(280, 80)
]

# ─── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	battle_config = GameManager.current_battle_config
	_fade_in()
	_spawn_units()
	_connect_signals()
	combat_manager.start_battle()

func _spawn_units() -> void:
	var pd := GameManager.player_data
	var team := pd.active_team

	var player_units: Array[CombatUnit] = []
	for i in team.size():
		var hero_id: String = team[i]
		if not pd.has_hero(hero_id):
			continue
		var hero_data: HeroData = _load_hero_data(hero_id)
		if hero_data == null:
			continue
		var unit := CombatUnitScene.instantiate() as CombatUnit
		player_container.add_child(unit)
		unit.position = PLAYER_POSITIONS[i % PLAYER_POSITIONS.size()]
		unit.setup(hero_data, pd.get_hero_level(hero_id), true)
		player_units.append(unit)

	var enemies := _load_stage_enemies()
	var enemy_units: Array[CombatUnit] = []
	for i in enemies.size():
		var unit := CombatUnitScene.instantiate() as CombatUnit
		enemy_container.add_child(unit)
		unit.position = ENEMY_POSITIONS[i % ENEMY_POSITIONS.size()]
		unit.scale.x  = -1   # Voltear para que miren al jugador
		unit.setup(enemies[i], battle_config.get("enemy_level", 1), false)
		enemy_units.append(unit)

	combat_manager.initialize(player_units, enemy_units)
	_build_skill_bar(player_units[0] if not player_units.is_empty() else null)

func _load_hero_data(hero_id: String) -> HeroData:
	var path := "res://resources/heroes/%s.tres" % hero_id
	if ResourceLoader.exists(path):
		return load(path) as HeroData
	push_error("[BattleScene] Hero resource no encontrado: %s" % path)
	return null

func _load_stage_enemies() -> Array[HeroData]:
	## Lee los enemigos definidos en la config de la etapa
	var enemy_list: Array[HeroData] = []
	var enemy_ids: Array = battle_config.get("enemies", [])
	for eid in enemy_ids:
		var path: String = EnemyDataPath + eid + ".tres"
		if ResourceLoader.exists(path):
			enemy_list.append(load(path) as HeroData)
	return enemy_list

# ─── Barra de Habilidades ────────────────────────────────────────────────────
func _build_skill_bar(unit: CombatUnit) -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	if unit == null or unit.hero_data == null:
		return

	selected_unit = unit
	var skills := [
		unit.hero_data.skill_basic,
		unit.hero_data.skill_active,
		unit.hero_data.skill_ultimate,
	]
	for skill in skills:
		if skill == null:
			continue
		var btn := Button.new()
		btn.text         = skill.skill_name
		btn.tooltip_text = skill.description
		btn.custom_minimum_size = Vector2(80, 80)
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		skill_bar.add_child(btn)

func _on_skill_pressed(skill: SkillData) -> void:
	if combat_manager.state != CombatManager.BattleState.PLAYER_TURN:
		return
	var targets := _pick_targets(skill)
	if targets.is_empty():
		return
	combat_manager.execute_skill(selected_unit, skill, targets)

func _pick_targets(skill: SkillData) -> Array[CombatUnit]:
	match skill.target_type:
		SkillData.TargetType.ALL_ENEMIES:
			return combat_manager.get_alive_enemies()
		SkillData.TargetType.ALL_ALLIES:
			return combat_manager.get_alive_players()
		SkillData.TargetType.SELF:
			return [selected_unit]
		_:   # SINGLE_ENEMY por defecto
			var enemies := combat_manager.get_alive_enemies()
			return [enemies[0]] if not enemies.is_empty() else []

# ─── Señales del CombatManager ───────────────────────────────────────────────
func _connect_signals() -> void:
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.battle_ended.connect(_on_battle_ended)
	combat_manager.action_executed.connect(_on_action_executed)

func _on_turn_started(unit: CombatUnit) -> void:
	if unit.is_player_unit:
		selected_unit = unit
		_build_skill_bar(unit)

func _on_action_executed(_atk, _def, _dmg, _label) -> void:
	pass   # La UI de daño la maneja CombatUnit con DamageLabel

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	result_panel.visible = true
	var label := result_panel.get_node_or_null("Label") as Label
	if label:
		if victory:
			label.text = "¡VICTORIA!\n+%d Oro  +%d Ámbar" % [
				rewards.get("gold", 0), rewards.get("amber", 0)
			]
		else:
			label.text = "DERROTA\nTus héroes han caído..."

# ─── Velocidad y Auto ─────────────────────────────────────────────────────────
func _on_speed_toggled() -> void:
	speed_x2 = not speed_x2
	Engine.time_scale = 2.0 if speed_x2 else 1.0
	speed_btn.text = "x2" if speed_x2 else "x1"

func _on_auto_toggled() -> void:
	auto_battle = not auto_battle
	auto_btn.text = "Auto ON" if auto_battle else "Auto OFF"

func _process(_delta: float) -> void:
	if auto_battle and combat_manager.state == CombatManager.BattleState.PLAYER_TURN:
		if selected_unit and selected_unit.hero_data.skill_basic:
			_on_skill_pressed(selected_unit.hero_data.skill_basic)

# ─── Transiciones ─────────────────────────────────────────────────────────────
func _fade_in() -> void:
	transition.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(transition, "modulate:a", 0.0, 0.5)

func _fade_out_and_go(scene_key: String) -> void:
	Engine.time_scale = 1.0
	var tween := create_tween()
	tween.tween_property(transition, "modulate:a", 1.0, 0.5)
	await tween.finished
	GameManager.go_to_scene(scene_key)

func _on_retreat_pressed() -> void:
	_fade_out_and_go("hub_camp")

func _on_continue_pressed() -> void:
	_fade_out_and_go("hub_camp")
