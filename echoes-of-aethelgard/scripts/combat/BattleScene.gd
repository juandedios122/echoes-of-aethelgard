## BattleScene.gd
## Controlador principal de la escena de combate.
## El ResultPanel se construye dinámicamente para mostrar EXP y level-ups.
class_name BattleScene
extends Node2D

# ─── Nodos ────────────────────────────────────────────────────────────────────
@onready var combat_manager: CombatManager = $CombatManager
@onready var player_container: Node2D      = $PlayerUnitsContainer
@onready var enemy_container: Node2D       = $EnemyUnitsContainer
@onready var skill_bar: HBoxContainer      = $BattleUI/Control/SkillBar
@onready var speed_btn: Button             = $BattleUI/Control/SpeedToggle
@onready var auto_btn: Button              = $BattleUI/Control/AutoToggle
@onready var result_panel: Panel           = $BattleUI/Control/ResultPanel
@onready var transition: ColorRect         = $Transition
@onready var camera: Camera2D              = $Camera2D

var _shake_intensity: float = 0.0
var _shake_decay: float     = 50.0

const CombatUnitScene: PackedScene = preload("res://scenes/combat/CombatUnit.tscn")
const EnemyDataPath: String        = "res://resources/enemies/"

var auto_battle: bool         = false
var speed_x2: bool            = false
var selected_unit: CombatUnit = null
var battle_config: Dictionary = {}

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
	AudioManager.play_music("battle_theme", 1.0)

func _spawn_units() -> void:
	var pd   := GameManager.player_data
	var team: Array[String] = pd.active_team

	var player_units: Array[CombatUnit] = []
	for i in team.size():
		var hero_id := team[i]
		if not pd.has_hero(hero_id):
			continue
		var hero_data := _load_hero_data(hero_id)
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
		unit.scale.x  = -1
		unit.setup(enemies[i], battle_config.get("enemy_level", 1), false)
		enemy_units.append(unit)

	combat_manager.initialize(player_units, enemy_units)
	_build_skill_bar(player_units[0] if not player_units.is_empty() else null)

func _load_hero_data(hero_id: String) -> HeroData:
	var path := "res://resources/heroes_data/%s.tres" % hero_id
	if ResourceLoader.exists(path):
		return load(path) as HeroData
	push_error("[BattleScene] HeroData no encontrado: %s" % path)
	return null

func _load_stage_enemies() -> Array[HeroData]:
	var enemy_list: Array[HeroData] = []
	for eid in battle_config.get("enemies", []):
		var eid_str := str(eid)
		var path: String = EnemyDataPath + eid_str + ".tres"
		if not ResourceLoader.exists(path):
			path = "res://resources/heroes_data/%s.tres" % eid_str
		if ResourceLoader.exists(path):
			enemy_list.append(load(path) as HeroData)
		else:
			push_warning("[BattleScene] Enemigo no encontrado: %s" % eid)
	return enemy_list

# ─── Barra de Habilidades ─────────────────────────────────────────────────────
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
		btn.text                = skill.skill_name
		btn.tooltip_text        = skill.description
		btn.custom_minimum_size = Vector2(100, 90)
		btn.add_theme_font_size_override("font_size", 14)
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
			var s: Array[CombatUnit] = [selected_unit]
			return s
		_:
			var enemies := combat_manager.get_alive_enemies()
			var single: Array[CombatUnit] = []
			if not enemies.is_empty():
				single.append(enemies[0])
			return single

# ─── Señales del CombatManager ────────────────────────────────────────────────
func _connect_signals() -> void:
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.battle_ended.connect(_on_battle_ended)
	combat_manager.action_executed.connect(_on_action_executed)

func _on_turn_started(unit: CombatUnit) -> void:
	if unit.is_player_unit:
		selected_unit = unit
		_build_skill_bar(unit)

func _on_action_executed(_atk, _def, _dmg, _label) -> void:
	if _dmg > 0:
		var percent := float(_dmg) / float(_def.max_hp) if _def and _def.max_hp > 0 else 0.1
		shake_camera(15.0 if percent > 0.3 else 5.0, 60.0 if percent > 0.3 else 40.0)

# ─── Panel de Resultado con EXP y Level-ups ───────────────────────────────────
func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	# Ampliar el panel para caber más información
	result_panel.offset_left   = -340.0
	result_panel.offset_top    = -240.0
	result_panel.offset_right  = 340.0
	result_panel.offset_bottom = 240.0

	# Estilo del panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.04, 0.97)
	panel_style.border_color = Color(0.75, 0.6, 0.25, 1) if victory else Color(0.6, 0.2, 0.2, 1)
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(10)
	result_panel.add_theme_stylebox_override("panel", panel_style)

	# Limpiar contenido anterior del panel
	var old_label  := result_panel.get_node_or_null("Label")
	var old_btn    := result_panel.get_node_or_null("RetreatButton")
	if old_label:  old_label.queue_free()
	if old_btn:    old_btn.queue_free()

	# Contenedor vertical principal
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	result_panel.add_child(margin)
	margin.add_child(vbox)

	# ── Título ────────────────────────────────────────────────────────────────
	var title := Label.new()
	if victory:
		title.text     = "¡ VICTORIA !"
		title.modulate = Color(1.0, 0.88, 0.2)
	else:
		title.text     = "D E R R O T A"
		title.modulate = Color(1.0, 0.3, 0.3)
	title.add_theme_font_size_override("font_size", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Animación de entrada del título
	title.modulate.a = 0.0
	var title_tween := create_tween()
	title_tween.tween_property(title, "modulate:a", 1.0, 0.4)

	# ── Recompensas (solo en victoria) ────────────────────────────────────────
	if victory:
		var sep1 := HSeparator.new()
		vbox.add_child(sep1)

		# Oro y Ámbar
		var rewards_hbox := HBoxContainer.new()
		rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		rewards_hbox.add_theme_constant_override("separation", 30)
		vbox.add_child(rewards_hbox)

		var gold_lbl := Label.new()
		gold_lbl.text = "⚙ +%d Oro" % rewards.get("gold", 0)
		gold_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.3))
		gold_lbl.add_theme_font_size_override("font_size", 24)
		rewards_hbox.add_child(gold_lbl)

		var amber_lbl := Label.new()
		amber_lbl.text = "🔶 +%d Ámbar" % rewards.get("amber", 0)
		amber_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.1))
		amber_lbl.add_theme_font_size_override("font_size", 24)
		rewards_hbox.add_child(amber_lbl)

		# ── EXP por héroe con barra animada ───────────────────────────────────
		var sep2 := HSeparator.new()
		vbox.add_child(sep2)

		var exp_title := Label.new()
		exp_title.text = "Experiencia obtenida"
		exp_title.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
		exp_title.add_theme_font_size_override("font_size", 18)
		exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(exp_title)

		var exp_per_hero: int    = rewards.get("exp_per_hero", 0)
		var level_ups: Array     = rewards.get("level_ups", [])
		var level_up_names       := {}
		for lu in level_ups:
			level_up_names[lu["hero_name"]] = lu["new_level"]

		var pd := GameManager.player_data

		for unit in combat_manager.player_units:
			if unit.hero_data == null:
				continue

			var hero_id   := unit.hero_data.hero_id
			var hero_name := unit.hero_data.hero_name
			var level     := pd.get_hero_level(hero_id)
			var leveled_up: bool = level_up_names.has(hero_name)

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			vbox.add_child(row)

			# Nombre del héroe
			var name_lbl := Label.new()
			name_lbl.text = hero_name
			name_lbl.custom_minimum_size = Vector2(90, 0)
			name_lbl.add_theme_color_override("font_color", unit.hero_data.get_rarity_color())
			name_lbl.add_theme_font_size_override("font_size", 16)
			row.add_child(name_lbl)

			# Barra de EXP
			var exp_bar := ProgressBar.new()
			exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			exp_bar.custom_minimum_size   = Vector2(0, 20)
			exp_bar.show_percentage       = false

			var bar_bg := StyleBoxFlat.new()
			bar_bg.bg_color = Color(0.12, 0.10, 0.07)
			bar_bg.set_corner_radius_all(3)
			exp_bar.add_theme_stylebox_override("background", bar_bg)

			var bar_fill := StyleBoxFlat.new()
			bar_fill.bg_color = Color(0.65, 0.50, 0.30) if not leveled_up else Color(0.3, 0.85, 0.4)
			bar_fill.set_corner_radius_all(3)
			exp_bar.add_theme_stylebox_override("fill", bar_fill)

			if level < 60:
				var exp_needed: int  = pd.get_exp_for_next_level(level)
				var current_exp: int = pd.get_hero_exp(hero_id)
				var prev_exp: int    = clampi(current_exp - exp_per_hero, 0, exp_needed)
				exp_bar.max_value = exp_needed
				exp_bar.value     = prev_exp
				row.add_child(exp_bar)

				var bar_tween: Tween = create_tween()
				bar_tween.tween_property(exp_bar, "value", float(current_exp), 0.6).set_ease(Tween.EASE_OUT)
			else:
				exp_bar.max_value = 1
				exp_bar.value     = 1
				row.add_child(exp_bar)

			# EXP ganada / level-up
			var exp_lbl := Label.new()
			if leveled_up:
				exp_lbl.text = "▲ Lv.%d" % level_up_names[hero_name]
				exp_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				# Animación de pulso en el level-up
				var pulse: Tween = create_tween()
				pulse.set_loops(3)
				pulse.tween_property(exp_lbl, "scale", Vector2(1.15, 1.15), 0.2)
				pulse.tween_property(exp_lbl, "scale", Vector2(1.0,  1.0),  0.2)
			else:
				exp_lbl.text = "+%d" % exp_per_hero
				exp_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
			exp_lbl.custom_minimum_size = Vector2(70, 0)
			exp_lbl.add_theme_font_size_override("font_size", 15)
			exp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(exp_lbl)

	# ── Botones ───────────────────────────────────────────────────────────────
	var sep_final := HSeparator.new()
	vbox.add_child(sep_final)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	if victory:
		var continue_btn := Button.new()
		continue_btn.text                = "▶  Continuar"
		continue_btn.custom_minimum_size = Vector2(180, 60)
		continue_btn.add_theme_font_size_override("font_size", 22)
		continue_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		continue_btn.pressed.connect(_on_continue_pressed)
		btn_hbox.add_child(continue_btn)

	var exit_btn := Button.new()
	exit_btn.text                = "✖  Salir"
	exit_btn.custom_minimum_size = Vector2(140, 60)
	exit_btn.add_theme_font_size_override("font_size", 22)
	exit_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	exit_btn.pressed.connect(_on_retreat_pressed)
	btn_hbox.add_child(exit_btn)

	# Mostrar el panel con fade-in
	result_panel.visible  = true
	result_panel.modulate = Color(1, 1, 1, 0)
	var panel_tween := create_tween()
	panel_tween.tween_property(result_panel, "modulate", Color(1, 1, 1, 1), 0.35)

# ─── Velocidad y Auto ─────────────────────────────────────────────────────────
func _on_speed_toggled() -> void:
	speed_x2          = not speed_x2
	Engine.time_scale = 2.0 if speed_x2 else 1.0
	speed_btn.text    = "x2" if speed_x2 else "x1"

func _on_auto_toggled() -> void:
	auto_battle   = not auto_battle
	auto_btn.text = "Auto ON" if auto_battle else "Auto OFF"

func _process(delta: float) -> void:
	if auto_battle and combat_manager.state == CombatManager.BattleState.PLAYER_TURN:
		if selected_unit and selected_unit.hero_data and selected_unit.hero_data.skill_basic:
			_on_skill_pressed(selected_unit.hero_data.skill_basic)

	if _shake_intensity > 0.0:
		_shake_intensity = move_toward(_shake_intensity, 0.0, _shake_decay * delta)
		camera.offset    = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

func shake_camera(intensity: float, decay: float = 50.0) -> void:
	_shake_intensity = intensity
	_shake_decay     = decay

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
	var pd := GameManager.player_data
	pd.complete_stage(pd.current_chapter, pd.current_stage)
	if pd.current_stage < 5:
		pd.current_stage += 1
	else:
		pd.current_stage   = 1
		pd.current_chapter = mini(pd.current_chapter + 1, pd.max_chapter_unlocked)
	GameManager.save_game()
	_fade_out_and_go("hub_camp")
