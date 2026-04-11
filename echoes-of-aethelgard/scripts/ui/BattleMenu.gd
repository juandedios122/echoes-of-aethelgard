## BattleMenu.gd — VERSIÓN FINAL SIN class_name
## RUTA: res://scripts/combat/BattleMenu.gd
##
## IMPORTANTE: Borra res://scripts/ui/BattleMenu.gd si todavía existe.
## Este archivo no usa class_name para evitar conflictos.
extends Control

signal action_selected(action: String)

var _btn_attack  : Button
var _btn_skill   : Button
var _btn_item    : Button
var _btn_run     : Button
var _hint_label  : Label
var _panel       : PanelContainer

var _selected_index : int = 0
const _ACTIONS : Array[String] = ["attack", "skill", "item", "run"]

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   = 640.0
	_panel.offset_top    = -220.0
	_panel.offset_right  = -20.0
	_panel.offset_bottom = -20.0
	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.08, 0.05, 0.03, 0.97)
	bg.border_color = Color(0.60, 0.48, 0.30, 1.0)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(10)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	_hint_label = Label.new()
	_hint_label.text = "¿Qué harás?"
	_hint_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
	_hint_label.add_theme_font_size_override("font_size", 20)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	var labels : Array[String] = ["⚔ ATACAR", "✨ HABILIDAD", "🎒 OBJETO", "🏃 HUIR"]
	var colors : Array[Color]  = [
		Color(0.70, 0.20, 0.10),
		Color(0.20, 0.35, 0.70),
		Color(0.25, 0.55, 0.20),
		Color(0.45, 0.45, 0.45),
	]

	var btns : Array[Button] = []
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = Vector2(200.0, 64.0)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))

		var s := StyleBoxFlat.new()
		s.bg_color     = Color(0.08, 0.05, 0.03, 1.0)
		s.border_color = colors[i]
		s.set_border_width_all(3)
		s.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", s)

		var h := s.duplicate() as StyleBoxFlat
		h.bg_color.a   = 0.40
		h.border_color = colors[i].lightened(0.3)
		h.shadow_color = colors[i]
		h.shadow_size  = 8
		btn.add_theme_stylebox_override("hover", h)
		btn.add_theme_stylebox_override("focus", h)

		# Capturar el índice como String tipada para evitar error de inferencia
		var action_str : String = _ACTIONS[i]
		btn.pressed.connect(func() -> void: _on_button_pressed(action_str))
		grid.add_child(btn)
		btns.append(btn)

	_btn_attack = btns[0]
	_btn_skill  = btns[1]
	_btn_item   = btns[2]
	_btn_run    = btns[3]

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_right"):   _move_cursor(1)
	elif event.is_action_pressed("ui_left"):  _move_cursor(-1)
	elif event.is_action_pressed("ui_down"):  _move_cursor(2)
	elif event.is_action_pressed("ui_up"):    _move_cursor(-2)
	elif event.is_action_pressed("ui_accept"):
		_on_button_pressed(_ACTIONS[_selected_index])

func _move_cursor(delta: int) -> void:
	_selected_index = wrapi(_selected_index + delta, 0, 4)
	_refresh_cursor()

func _refresh_cursor() -> void:
	var btns : Array[Button] = [_btn_attack, _btn_skill, _btn_item, _btn_run]
	for i in btns.size():
		if i == _selected_index:
			btns[i].grab_focus()

func _on_button_pressed(action: String) -> void:
	action_selected.emit(action)
	hide()

func show_for_unit(unit: CombatUnit) -> void:
	_hint_label.text = "¿Qué hará %s?" % unit.unit_name
	_selected_index  = 0
	_refresh_cursor()
	show()
	_btn_attack.grab_focus()
