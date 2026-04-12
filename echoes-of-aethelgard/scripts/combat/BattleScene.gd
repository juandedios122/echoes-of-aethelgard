## BattleScene.gd — VERSIÓN CORREGIDA
## CORRECCIONES:
##   - ui_control eliminado (variable no usada)
##   - is_player → _is_player (parámetro no usado)
##   - mx → _mx (parámetro no usado en lambda)
##   - max_ep → _max_ep (parámetro no usado)
##   - Standalone ternary corregido (línea 332)
##   - TurnLabel ahora tiene tamaño mínimo para no colapsar verticalmente
##   - BattleMessageBox reposicionado para no tapar el centro de pantalla
##   - BattleMenu visible correctamente
class_name BattleScene
extends Node2D

# ── Referencias a nodos de la escena ──────────────────────────────────────────
@onready var combat_manager   : CombatManager = $CombatManager
@onready var player_container : Node2D        = $PlayerUnitsContainer
@onready var enemy_container  : Node2D        = $EnemyUnitsContainer
@onready var camera           : Camera2D      = $Camera2D
@onready var transition       : ColorRect     = $Transition
@onready var battle_ui        : CanvasLayer   = $BattleUI
@onready var result_panel     : Panel         = $BattleUI/Control/ResultPanel
@onready var speed_btn        : Button        = $BattleUI/Control/TopBar/TopBarHBox/SpeedToggle
@onready var auto_btn         : Button        = $BattleUI/Control/TopBar/TopBarHBox/AutoToggle
@onready var turn_label       : Label         = $BattleUI/Control/TopBar/TopBarHBox/TurnLabel
@onready var effect_label     : Label         = $BattleUI/Control/EffectLabel
@onready var player_hud_box   : HBoxContainer = $BattleUI/Control/PlayerHUDPanel/PlayerHUDBox
@onready var enemy_hud_box    : HBoxContainer = $BattleUI/Control/EnemyHUDPanel/EnemyHUDBox
@onready var turn_queue_bar   : HBoxContainer = $BattleUI/Control/TurnQueueBar

# ── UI creada por código ───────────────────────────────────────────────────────
var _message_box  : BattleMessageBox
var _battle_menu  : BattleMenu
var _skill_panel  : SkillSelectPanel

const CombatUnitScene := preload("res://scenes/combat/CombatUnit.tscn")

# ── Estado ────────────────────────────────────────────────────────────────────
var _speed_index    : int  = 0
var _auto_battle    : bool = false
var _selected_unit  : CombatUnit = null
var _battle_config  : Dictionary = {}
var _combo_count    : int   = 0
var _turn_number    : int   = 0

const PLAYER_POSITIONS : Array[Vector2] = [
	Vector2(-290, 60), Vector2(-210, 10), Vector2(-130, 60)
]
const ENEMY_POSITIONS : Array[Vector2] = [
	Vector2(130, 60), Vector2(210, 10), Vector2(290, 60)
]
const SPEED_VALUES : Array[float] = [1.0, 1.5, 2.0]
const SPEED_LABELS : Array[String] = ["⏩ x1", "⏩ x1.5", "⏩ x2"]

# ═════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_battle_config = GameManager.current_battle_config
	_fix_turn_label()        # CORRECCIÓN: asegurar que TurnLabel no colapse
	_build_code_ui()
	_fade_in()
	_spawn_units()
	_connect_signals()
	combat_manager.start_battle()
	AudioManager.play_music("battle_theme", 1.0)

# ── FIX: TurnLabel necesita tamaño mínimo para no colapsar letra a letra ──────
func _fix_turn_label() -> void:
	# El label dentro de un HBoxContainer sin tamaño mínimo colapsa a ancho 0
	# y las letras caen verticalmente. Forzamos tamaño mínimo horizontal.
	if turn_label:
		turn_label.custom_minimum_size = Vector2(300, 0)
		turn_label.clip_text = false
		turn_label.autowrap_mode = TextServer.AUTOWRAP_OFF

# ── Construcción de UI por código ─────────────────────────────────────────────
func _build_code_ui() -> void:
	# CORRECCIÓN: eliminada variable ui_control no usada (era: var ui_control := ...)

	# Message box — inferior izquierda, NO ocupa el centro de pantalla
	_message_box = BattleMessageBox.new()
	battle_ui.add_child(_message_box)
	_message_box.skip_requested.connect(_on_skip_message)

	# Battle menu — inferior derecha
	_battle_menu = BattleMenu.new()
	battle_ui.add_child(_battle_menu)
	_battle_menu.connect("action_selected", _on_menu_action)

	# Skill panel
	_skill_panel = SkillSelectPanel.new()
	battle_ui.add_child(_skill_panel)
	_skill_panel.connect("skill_chosen",    _on_skill_chosen)
	_skill_panel.connect("panel_cancelled", func() -> void:
		if _selected_unit: _battle_menu.show_for_unit(_selected_unit)
	)

# ── Spawn de unidades + creación del HUD ──────────────────────────────────────
func _spawn_units() -> void:
	var pd   := GameManager.player_data
	var team : Array[String] = pd.active_team

	var p_units : Array[CombatUnit] = []
	for i in team.size():
		var hid := team[i]
		if not pd.has_hero(hid): continue
		var hdata := _load_hero_data(hid)
		if hdata == null: continue
		var unit := CombatUnitScene.instantiate() as CombatUnit
		player_container.add_child(unit)
		unit.position = PLAYER_POSITIONS[i % PLAYER_POSITIONS.size()]
		unit.setup(hdata, pd.get_hero_level(hid), true)
		p_units.append(unit)
		_create_unit_hud_card(unit, player_hud_box, true)

	var enemies := _load_stage_enemies()
	var e_units : Array[CombatUnit] = []
	for i in enemies.size():
		var unit := CombatUnitScene.instantiate() as CombatUnit
		enemy_container.add_child(unit)
		unit.position = ENEMY_POSITIONS[i % ENEMY_POSITIONS.size()]
		unit.scale.x  = -1
		unit.setup(enemies[i], _battle_config.get("enemy_level", 1), false)
		e_units.append(unit)
		_create_unit_hud_card(unit, enemy_hud_box, false)

	combat_manager.initialize(p_units, e_units)

# ── Tarjeta HUD para cada unidad ──────────────────────────────────────────────
# CORRECCIÓN: is_player → _is_player (parámetro no usado)
func _create_unit_hud_card(unit: CombatUnit, container: HBoxContainer, _is_player: bool) -> void:
	var card := PanelContainer.new()
	card.name = "Card_" + unit.unit_name
	card.custom_minimum_size = Vector2(140.0, 100.0)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color     = Color(0.08, 0.06, 0.04, 0.90)
	card_style.border_color = unit.hero_data.get_rarity_color() if unit.hero_data else Color(0.5, 0.4, 0.2)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(7)
	card.add_theme_stylebox_override("panel", card_style)
	container.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = unit.unit_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	var rarity_col := unit.hero_data.get_rarity_color() if unit.hero_data else Color(0.9, 0.85, 0.7)
	name_lbl.add_theme_color_override("font_color", rarity_col)
	name_lbl.clip_text = true
	vbox.add_child(name_lbl)

	var hp_bar := ProgressBar.new()
	hp_bar.name          = "HPBar"
	hp_bar.custom_minimum_size = Vector2(0, 12)
	hp_bar.max_value     = float(unit.max_hp)
	hp_bar.value         = float(unit.current_hp)
	hp_bar.show_percentage = false
	_style_hp_bar(hp_bar)
	vbox.add_child(hp_bar)

	var hp_txt := Label.new()
	hp_txt.name = "HPText"
	hp_txt.text = "%d / %d" % [unit.current_hp, unit.max_hp]
	hp_txt.add_theme_font_size_override("font_size", 12)
	hp_txt.add_theme_color_override("font_color", Color(0.80, 0.75, 0.65))
	vbox.add_child(hp_txt)

	var ep_bar := ProgressBar.new()
	ep_bar.name          = "EPBar"
	ep_bar.custom_minimum_size = Vector2(0, 8)
	ep_bar.max_value     = float(unit.max_energy)
	ep_bar.value         = float(unit.current_energy)
	ep_bar.show_percentage = false
	_style_energy_bar(ep_bar)
	vbox.add_child(ep_bar)

	var status_row := HBoxContainer.new()
	status_row.name = "StatusRow"
	status_row.add_theme_constant_override("separation", 4)
	vbox.add_child(status_row)

	# CORRECCIÓN: mx → _mx (parámetro no usado en lambda)
	unit.hp_changed.connect(func(cur: int, _mx: int) -> void:
		_update_unit_hud_card(card, cur, unit.max_hp, unit.current_energy, unit.max_energy)
	)
	unit.energy_changed.connect(func(cur: int, _mx: int) -> void:
		if is_instance_valid(ep_bar):
			ep_bar.value = float(cur)
	)

func _style_hp_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.08, 0.06)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.14, 0.14)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

func _style_energy_bar(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.10, 0.14)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.22, 0.52, 0.88)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

# CORRECCIÓN: max_ep → _max_ep (parámetro no usado)
func _update_unit_hud_card(card: PanelContainer, cur_hp: int, max_hp: int, cur_ep: int, _max_ep: int) -> void:
	if not is_instance_valid(card): return
	var hp_bar  : ProgressBar = card.get_node_or_null("VBoxContainer/HPBar")
	var hp_txt  : Label       = card.get_node_or_null("VBoxContainer/HPText")
	var ep_bar  : ProgressBar = card.get_node_or_null("VBoxContainer/EPBar")
	if hp_bar: hp_bar.value = float(cur_hp)
	if hp_txt: hp_txt.text  = "%d / %d" % [cur_hp, max_hp]
	if ep_bar: ep_bar.value = float(cur_ep)

	if hp_bar:
		var ratio := float(cur_hp) / float(max_hp) if max_hp > 0 else 0.0
		var fill := StyleBoxFlat.new()
		fill.set_corner_radius_all(4)
		if ratio > 0.5:
			fill.bg_color = Color(0.72, 0.14, 0.14)
		elif ratio > 0.25:
			fill.bg_color = Color(0.85, 0.55, 0.08)
		else:
			fill.bg_color = Color(1.0, 0.15, 0.15)
		hp_bar.add_theme_stylebox_override("fill", fill)

# ── Cola de turnos visual ──────────────────────────────────────────────────────
func _update_turn_queue_display() -> void:
	for child in turn_queue_bar.get_children():
		child.queue_free()

	var queue := combat_manager.turn_queue
	var current_idx := combat_manager.current_turn_index
	var shown := 0
	var i     := current_idx

	while shown < 6 and i < queue.size():
		var unit : CombatUnit = queue[i]
		if not unit.is_dead():
			var dot := Label.new()
			dot.text = unit.unit_name[0].to_upper()
			dot.custom_minimum_size = Vector2(28, 28)
			dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dot.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			dot.add_theme_font_size_override("font_size", 14)

			var col : Color
			if shown == 0:
				col = Color(1.0, 0.90, 0.20)
			elif unit.is_player_unit:
				col = Color(0.35, 0.75, 0.35)
			else:
				col = Color(0.85, 0.30, 0.25)

			dot.add_theme_color_override("font_color", col)

			var bg := StyleBoxFlat.new()
			bg.bg_color   = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.85)
			bg.border_color = col
			bg.set_border_width_all(2 if shown == 0 else 1)
			bg.set_corner_radius_all(14)
			var panel := PanelContainer.new()
			panel.add_theme_stylebox_override("panel", bg)
			panel.add_child(dot)
			turn_queue_bar.add_child(panel)
			shown += 1
		i += 1

# ── Carga de datos ────────────────────────────────────────────────────────────
func _load_hero_data(hero_id: String) -> HeroData:
	var path := "res://resources/heroes_data/%s.tres" % hero_id
	if ResourceLoader.exists(path): return load(path) as HeroData
	return null

func _load_stage_enemies() -> Array[HeroData]:
	var list : Array[HeroData] = []
	for eid in _battle_config.get("enemies", []):
		var s := str(eid)
		var path := "res://resources/enemies/%s.tres" % s
		if not ResourceLoader.exists(path):
			path = "res://resources/heroes_data/%s.tres" % s
		if ResourceLoader.exists(path):
			list.append(load(path) as HeroData)
	return list

# ── Señales ───────────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.battle_ended.connect(_on_battle_ended)
	combat_manager.action_executed.connect(_on_action_executed)

# ── Turno ─────────────────────────────────────────────────────────────────────
func _on_turn_started(unit: CombatUnit) -> void:
	_selected_unit = unit
	_turn_number  += 1
	_update_turn_queue_display()

	if unit.is_player_unit:
		_combo_count = 0
		turn_label.text = "⚔ %s" % unit.unit_name
		_message_box.push("%s — ¡Tu turno!" % unit.unit_name)
		await _message_box.wait_done()
		if _auto_battle:
			await get_tree().create_timer(0.35).timeout
			_execute_player_skill(unit.hero_data.skill_basic)
		else:
			_battle_menu.show_for_unit(unit)
	else:
		turn_label.text = "👹 %s" % unit.unit_name

func _on_menu_action(action: String) -> void:
	match action:
		"attack":  _execute_player_skill(_selected_unit.hero_data.skill_basic)
		"skill":   _skill_panel.populate(_selected_unit)
		"item":
			_message_box.push("¡No tienes objetos todavía!")
			await get_tree().create_timer(1.2).timeout
			_battle_menu.show_for_unit(_selected_unit)
		"run":     _try_escape()

func _on_skill_chosen(skill: SkillData) -> void:
	_execute_player_skill(skill)

func _execute_player_skill(skill: SkillData) -> void:
	if _selected_unit == null or skill == null: return
	if combat_manager.state != CombatManager.BattleState.PLAYER_TURN: return

	if skill.energy_cost > 0 and _selected_unit.current_energy < skill.energy_cost:
		_message_box.push("¡No tienes suficiente energía! (%d/%d)" % [
			_selected_unit.current_energy, skill.energy_cost])
		JuiceManager.shake(3.0)
		await get_tree().create_timer(1.2).timeout
		_battle_menu.show_for_unit(_selected_unit)
		return

	var targets := _pick_targets(skill)
	if targets.is_empty(): return

	_combo_count += 1
	_message_box.push("¡%s usa %s!" % [_selected_unit.unit_name, skill.skill_name])
	await combat_manager.execute_skill(_selected_unit, skill, targets)

func _pick_targets(skill: SkillData) -> Array[CombatUnit]:
	match skill.target_type:
		SkillData.TargetType.ALL_ENEMIES: return combat_manager.get_alive_enemies()
		SkillData.TargetType.ALL_ALLIES:  return combat_manager.get_alive_players()
		SkillData.TargetType.SELF:
			var s : Array[CombatUnit] = [_selected_unit]; return s
		_:
			var enemies := combat_manager.get_alive_enemies()
			var single  : Array[CombatUnit] = []
			if not enemies.is_empty(): single.append(enemies[0])
			return single

func _try_escape() -> void:
	var player_spd : float = 0.0
	var enemy_spd  : float = 0.0
	for u in combat_manager.get_alive_players(): player_spd += u.spd
	for u in combat_manager.get_alive_enemies(): enemy_spd  += u.spd
	var ratio  := player_spd / maxf(enemy_spd, 1.0)
	var chance := clampf(0.45 + (ratio - 1.0) * 0.25, 0.20, 0.90)

	if randf() < chance:
		_message_box.push("¡Huiste con éxito!")
		await get_tree().create_timer(1.5).timeout
		_fade_out_and_go("hub_camp")
	else:
		_message_box.push("¡No pudiste escapar! (%.0f%%)" % (chance * 100))
		JuiceManager.shake(8.0)
		await get_tree().create_timer(1.2).timeout
		combat_manager.advance_turn()

func _on_skip_message() -> void:
	pass

# ── Feedback de acción ────────────────────────────────────────────────────────
func _on_action_executed(attacker: CombatUnit, target: CombatUnit, dmg: int, _label: String) -> void:
	if dmg <= 0: return

	var ratio := float(dmg) / float(target.max_hp) if target.max_hp > 0 else 0.1
	JuiceManager.shake(clampf(ratio * 60.0, 3.0, 22.0))

	if ratio > 0.20:
		JuiceManager.hit_freeze(0.04)

	if attacker.hero_data and target.hero_data:
		var mult := HeroData.get_elemental_multiplier(
			attacker.hero_data.element, target.hero_data.element)
		if mult > 1.1:
			_show_effect_label("¡Es muy efectivo!", Color(1.0, 0.88, 0.10))
		elif mult < 0.9:
			_show_effect_label("No es muy efectivo…", Color(0.65, 0.65, 0.65))

func _show_effect_label(text: String, col: Color) -> void:
	if effect_label == null: return
	effect_label.text    = text
	effect_label.modulate = Color(col.r, col.g, col.b, 0.0)
	effect_label.visible = true

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(effect_label, "modulate:a", 1.0, 0.15)
	tween.tween_property(effect_label, "position:y",
		effect_label.position.y - 18.0, 0.5).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.9).timeout
	var out := create_tween()
	out.tween_property(effect_label, "modulate:a", 0.0, 0.25)
	await out.finished
	effect_label.visible = false
	effect_label.position.y += 18.0

# ── Panel de resultado ────────────────────────────────────────────────────────
func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	Engine.time_scale = 1.0
	turn_label.text   = ""
	_message_box.push_instant("")

	JuiceManager.screen_flash(
		Color(1.0, 0.85, 0.1, 0.5) if victory else Color(0.8, 0.1, 0.1, 0.5),
		0.6
	)

	await get_tree().create_timer(0.5).timeout

	for child in result_panel.get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	result_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "✦  ¡VICTORIA!  ✦" if victory else "☠  DERROTA  ☠"
	title.modulate = Color(1.0, 0.88, 0.15) if victory else Color(1.0, 0.28, 0.28)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.scale = Vector2(0.5, 0.5)
	title.pivot_offset = Vector2(340, 22)
	vbox.add_child(title)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	if victory:
		var rewards_hbox := HBoxContainer.new()
		rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		rewards_hbox.add_theme_constant_override("separation", 28)
		vbox.add_child(rewards_hbox)

		_add_reward_label(rewards_hbox, "⚙ +%d Oro" % rewards.get("gold", 0), Color(0.95, 0.80, 0.25))
		_add_reward_label(rewards_hbox, "🔶 +%d Ámbar" % rewards.get("amber", 0), Color(1.0, 0.55, 0.10))
		_add_reward_label(rewards_hbox, "⚡ +%d EXP" % rewards.get("exp_per_hero", 0), Color(0.40, 0.82, 1.0))

		for lu : Dictionary in rewards.get("level_ups", []):
			var lv_lbl := Label.new()
			lv_lbl.text = "  ▲ %s  → Nivel %d" % [lu["hero_name"], lu["new_level"]]
			lv_lbl.add_theme_color_override("font_color", Color(0.30, 1.0, 0.45))
			lv_lbl.add_theme_font_size_override("font_size", 20)
			lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(lv_lbl)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var turns_lbl := Label.new()
	turns_lbl.text = "Turnos: %d" % _turn_number
	turns_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	turns_lbl.add_theme_font_size_override("font_size", 16)
	turns_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(turns_lbl)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	if victory:
		var cont_btn := _make_result_button("▶  Continuar", Color(0.25, 0.75, 0.30))
		cont_btn.pressed.connect(_on_continue_pressed)
		btn_hbox.add_child(cont_btn)

	var exit_btn := _make_result_button("✖  Salir", Color(0.75, 0.25, 0.20))
	exit_btn.pressed.connect(func() -> void: _fade_out_and_go("hub_camp"))
	btn_hbox.add_child(exit_btn)

	result_panel.visible  = true
	result_panel.modulate = Color(1, 1, 1, 0)
	var show_t := create_tween().set_parallel(true)
	show_t.tween_property(result_panel, "modulate:a", 1.0, 0.30)
	show_t.tween_property(title, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _add_reward_label(parent: HBoxContainer, text: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 24)
	parent.add_child(lbl)

func _make_result_button(txt: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(160.0, 56.0)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", col.lightened(0.4))
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 0.95)
	s.border_color = col
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = col
	h.bg_color.a = 0.35
	btn.add_theme_stylebox_override("hover", h)
	return btn

# ── Velocidad / Auto ──────────────────────────────────────────────────────────
func _on_speed_toggled() -> void:
	_speed_index  = (_speed_index + 1) % SPEED_VALUES.size()
	Engine.time_scale = SPEED_VALUES[_speed_index]
	speed_btn.text    = SPEED_LABELS[_speed_index]

func _on_auto_toggled(pressed: bool) -> void:
	_auto_battle  = pressed
	auto_btn.add_theme_color_override("font_color",
		Color(0.25, 1.0, 0.35) if pressed else Color(0.75, 0.75, 0.75))

# ── Shake de cámara ───────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	pass   # JuiceManager maneja el shake de cámara

# ── Transiciones ─────────────────────────────────────────────────────────────
func _fade_in() -> void:
	transition.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(transition, "modulate:a", 0.0, 0.5)

func _fade_out_and_go(scene_key: String) -> void:
	Engine.time_scale = 1.0
	var t := create_tween()
	t.tween_property(transition, "modulate:a", 1.0, 0.5)
	await t.finished
	GameManager.go_to_scene(scene_key)

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

func _on_retreat_pressed() -> void:
	_fade_out_and_go("hub_camp")
