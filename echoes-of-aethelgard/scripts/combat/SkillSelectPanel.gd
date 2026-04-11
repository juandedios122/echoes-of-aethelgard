## SkillSelectPanel.gd
## RUTA: res://scripts/combat/SkillSelectPanel.gd
## Panel que muestra las habilidades del héroe con costes de energía
class_name SkillSelectPanel
extends Control

signal skill_chosen(skill: SkillData)
signal panel_cancelled()

var _panel       : PanelContainer
var _skill_list  : VBoxContainer
var _desc_label  : Label
var _energy_bar  : ProgressBar
var _title_label : Label

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   = 20.0
	_panel.offset_top    = -340.0
	_panel.offset_right  = -20.0
	_panel.offset_bottom = -20.0
	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.06, 0.04, 0.02, 0.98)
	bg.border_color = Color(0.50, 0.38, 0.20, 1.0)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# Título
	_title_label = Label.new()
	_title_label.text = "Selecciona habilidad"
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.68))
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	# Barra de energía
	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size = Vector2(0, 18)
	_energy_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.10, 0.07)
	bar_bg.set_corner_radius_all(4)
	_energy_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.20, 0.50, 0.85)
	bar_fill.set_corner_radius_all(4)
	_energy_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_energy_bar)

	# Lista de habilidades
	_skill_list = VBoxContainer.new()
	_skill_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_skill_list)

	# Descripción
	_desc_label = Label.new()
	_desc_label.text = "Pasa el cursor para ver descripción"
	_desc_label.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55))
	_desc_label.add_theme_font_size_override("font_size", 16)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(_desc_label)

	# Botón volver
	var back_btn := Button.new()
	back_btn.text = "← Volver"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(0.75, 0.65, 0.50))
	var back_s := StyleBoxFlat.new()
	back_s.bg_color = Color(0.10, 0.08, 0.05)
	back_s.border_color = Color(0.40, 0.32, 0.20)
	back_s.set_border_width_all(2)
	back_s.set_corner_radius_all(6)
	back_btn.add_theme_stylebox_override("normal", back_s)
	back_btn.pressed.connect(func(): panel_cancelled.emit(); hide())
	vbox.add_child(back_btn)

## Llama esto desde BattleScene para mostrar las habilidades de un héroe
func populate(unit: CombatUnit) -> void:
	_title_label.text        = "Habilidades de %s" % unit.unit_name
	_energy_bar.max_value    = unit.max_energy
	_energy_bar.value        = unit.current_energy

	# Limpiar botones anteriores
	for child in _skill_list.get_children():
		child.queue_free()

	var skills : Array = [
		unit.hero_data.skill_basic,
		unit.hero_data.skill_active,
		unit.hero_data.skill_ultimate,
	]

	for skill in skills:
		if skill == null:
			continue
		_add_skill_button(skill, unit)

	show()

func _add_skill_button(skill: SkillData, unit: CombatUnit) -> void:
	var can_use  := unit.current_energy >= skill.energy_cost
	var cost_txt := "GRATIS" if skill.energy_cost == 0 else "⚡ %d" % skill.energy_cost

	var btn := Button.new()
	btn.text                = "%-18s [%s]" % [skill.skill_name, cost_txt]
	btn.custom_minimum_size = Vector2(0, 56)
	btn.disabled            = not can_use
	btn.add_theme_font_size_override("font_size", 19)

	var col := _get_skill_color(skill)
	var s   := StyleBoxFlat.new()
	s.bg_color     = Color(0.08, 0.05, 0.03) if can_use else Color(0.05, 0.05, 0.05, 0.6)
	s.border_color = col if can_use else Color(0.3, 0.3, 0.3)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", s)

	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = col
	h.bg_color.a = 0.30
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("focus", h)

	btn.add_theme_color_override("font_color",
		Color(0.95, 0.88, 0.75) if can_use else Color(0.40, 0.40, 0.40))

	btn.mouse_entered.connect(func(): _desc_label.text = skill.description)
	btn.focus_entered.connect(func(): _desc_label.text = skill.description)
	btn.pressed.connect(func():
		skill_chosen.emit(skill)
		hide()
	)
	_skill_list.add_child(btn)

func _get_skill_color(skill: SkillData) -> Color:
	match skill.effect_type:
		SkillData.EffectType.DAMAGE:  return Color(0.85, 0.25, 0.15)
		SkillData.EffectType.HEAL:    return Color(0.20, 0.75, 0.30)
		SkillData.EffectType.BUFF:    return Color(0.25, 0.50, 0.85)
		SkillData.EffectType.DEBUFF:  return Color(0.65, 0.20, 0.75)
		SkillData.EffectType.SHIELD:  return Color(0.45, 0.65, 0.90)
		SkillData.EffectType.DOT:     return Color(0.55, 0.75, 0.10)
		_:                            return Color(0.55, 0.43, 0.25)
