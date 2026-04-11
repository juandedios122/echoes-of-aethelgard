## DialogBox.gd — VERSIÓN LIMPIA
## RUTA: res://scripts/ui/DialogBox.gd
## Añadir como nodo CanvasLayer en ExplorationMap.tscn
class_name DialogBox
extends CanvasLayer

signal dialog_finished()

var _panel        : PanelContainer
var _name_label   : Label
var _text_label   : Label
var _hint         : Label

var _lines   : Array[String] = []
var _idx     : int  = 0
var _writing : bool = false
const SPEED  := 0.025

func _ready() -> void:
	_build_ui()
	hide()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   = 20.0
	_panel.offset_top    = -170.0
	_panel.offset_right  = -20.0
	_panel.offset_bottom = -20.0

	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.05, 0.04, 0.02, 0.97)
	bg.border_color = Color(0.60, 0.47, 0.22, 1.0)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(12)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	vbox.add_child(_name_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 20)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	_text_label.autowrap_mode     = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0.0, 60.0)
	vbox.add_child(_text_label)

	_hint = Label.new()
	_hint.text = "▼ Pulsa ENTER para continuar"
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.75, 0.65, 0.40))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.visible = false
	vbox.add_child(_hint)

	var blink : Tween = create_tween()
	blink.set_loops()
	blink.tween_property(_hint, "modulate:a", 0.2, 0.6)
	blink.tween_property(_hint, "modulate:a", 1.0, 0.6)

## Llama esto para mostrar un diálogo. Espera hasta que el jugador cierre.
func show_dialog(speaker: String, lines: Array[String]) -> void:
	_lines         = lines
	_idx           = 0
	_name_label.text = speaker
	show()
	_write_line(_lines[0])
	await dialog_finished

func _write_line(text: String) -> void:
	_writing        = true
	_hint.visible   = false
	_text_label.text = ""
	for ch : String in text:
		_text_label.text += ch
		await get_tree().create_timer(SPEED).timeout
	_writing      = false
	_hint.visible = true

func _input(event: InputEvent) -> void:
	if not _panel.visible: return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _writing:
			_text_label.text = _lines[_idx]
			_writing      = false
			_hint.visible = true
		else:
			_idx += 1
			if _idx >= _lines.size():
				hide()
				dialog_finished.emit()
			else:
				_write_line(_lines[_idx])
