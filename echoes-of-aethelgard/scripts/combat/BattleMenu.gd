## BattleMenu.gd — VERSIÓN MEJORADA
## RUTA: res://scripts/combat/BattleMenu.gd
## ASEGÚRATE de que NO existe res://scripts/ui/BattleMenu.gd (bórralo si hay)
class_name BattleMenu
extends Control

signal action_selected(action: String)

var _panel       : PanelContainer
var _hint_label  : Label
var _btn_attack  : Button
var _btn_skill   : Button
var _btn_item    : Button
var _btn_run     : Button
var _desc_label  : Label        # descripción del ataque básico al hover

var _selected_index : int = 0
const _ACTIONS : Array[String] = ["attack", "skill", "item", "run"]

# [texto, color_borde, color_texto, descripción]
const _BTN_DATA : Array = [
	["⚔  ATACAR",    Color(0.75, 0.22, 0.10), Color(1.0, 0.75, 0.70), "Ataque básico.\nGana energía."],
	["✨  HABILIDAD", Color(0.22, 0.38, 0.82), Color(0.70, 0.82, 1.0), "Seleccionar habilidad."],
	["🎒  OBJETO",   Color(0.26, 0.58, 0.22), Color(0.70, 1.0, 0.70), "Usar objeto de inventario."],
	["🏃  HUIR",     Color(0.48, 0.48, 0.48), Color(0.80, 0.80, 0.80), "Intentar escapar.\n(75% base)"],
]

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	# Panel principal
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   = 630.0
	_panel.offset_top    = -230.0
	_panel.offset_right  = -14.0
	_panel.offset_bottom = -14.0
	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.07, 0.04, 0.02, 0.97)
	bg.border_color = Color(0.58, 0.45, 0.20, 1.0)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(12)
	bg.shadow_color = Color(0, 0, 0, 0.6)
	bg.shadow_size  = 12
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Hint de quién actúa
	_hint_label = Label.new()
	_hint_label.text = "¿Qué harás?"
	_hint_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)

	# Separador
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color     = Color(0.45, 0.35, 0.15, 0.5)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Grid de botones 2x2
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var btns : Array[Button] = []
	for i in _BTN_DATA.size():
		var data   : Array = _BTN_DATA[i]
		var btn    := Button.new()
		btn.text   = data[0]
		btn.custom_minimum_size = Vector2(194.0, 60.0)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", data[2])

		# Estilo normal
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(data[1].r * 0.12, data[1].g * 0.12, data[1].b * 0.12, 0.98)
		s.border_color = data[1]
		s.border_color.a = 0.7
		s.set_border_width_all(2)
		s.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", s)

		# Estilo hover/focus
		var h := StyleBoxFlat.new()
		h.bg_color     = Color(data[1].r * 0.30, data[1].g * 0.30, data[1].b * 0.30, 1.0)
		h.border_color = data[1].lightened(0.25)
		h.set_border_width_all(3)
		h.set_corner_radius_all(8)
		h.shadow_color = data[1]
		h.shadow_size  = 10
		btn.add_theme_stylebox_override("hover",   h)
		btn.add_theme_stylebox_override("focus",   h)
		btn.add_theme_stylebox_override("pressed", h)

		var desc : String = data[3]
		btn.mouse_entered.connect(func() -> void: _desc_label.text = desc)
		btn.focus_entered.connect(func() -> void: _desc_label.text = desc)

		var action_str : String = _ACTIONS[i]
		btn.pressed.connect(func() -> void: _emit(action_str))
		grid.add_child(btn)
		btns.append(btn)

	_btn_attack = btns[0]
	_btn_skill  = btns[1]
	_btn_item   = btns[2]
	_btn_run    = btns[3]

	# Descripción de acción (debajo de los botones)
	_desc_label = Label.new()
	_desc_label.text = ""
	_desc_label.add_theme_color_override("font_color", Color(0.70, 0.65, 0.52))
	_desc_label.add_theme_font_size_override("font_size", 15)
	_desc_label.autowrap_mode     = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(_desc_label)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_right"):
		_move_cursor(1)
	elif event.is_action_pressed("ui_left"):
		_move_cursor(-1)
	elif event.is_action_pressed("ui_down"):
		_move_cursor(2)
	elif event.is_action_pressed("ui_up"):
		_move_cursor(-2)
	elif event.is_action_pressed("ui_accept"):
		_emit(_ACTIONS[_selected_index])

func _move_cursor(delta: int) -> void:
	_selected_index = wrapi(_selected_index + delta, 0, 4)
	_refresh_cursor()

func _refresh_cursor() -> void:
	var btns : Array[Button] = [_btn_attack, _btn_skill, _btn_item, _btn_run]
	for i in btns.size():
		if i == _selected_index:
			btns[i].grab_focus()

func _emit(action: String) -> void:
	# Animación de salida
	var t := create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.12)
	await t.finished
	action_selected.emit(action)
	hide()
	_panel.modulate.a = 1.0

## Muestra el menú con animación de entrada
func show_for_unit(unit: CombatUnit) -> void:
	_hint_label.text    = "¿Qué hará  %s?" % unit.unit_name
	_desc_label.text    = _BTN_DATA[0][3]  # descripción del ataque por defecto
	_selected_index     = 0
	_refresh_cursor()
	_panel.modulate.a   = 0.0
	_panel.position.x  += 30.0
	show()
	_btn_attack.grab_focus()
	var t := create_tween().set_parallel(true)
	t.tween_property(_panel, "modulate:a", 1.0, 0.18)
	t.tween_property(_panel, "position:x", _panel.position.x - 30.0, 0.18).set_ease(Tween.EASE_OUT)
