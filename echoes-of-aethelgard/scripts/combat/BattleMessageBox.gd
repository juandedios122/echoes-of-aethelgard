## BattleMessageBox.gd — VERSIÓN MEJORADA
## RUTA: res://scripts/combat/BattleMessageBox.gd
class_name BattleMessageBox
extends Control

signal all_done()
signal skip_requested()   # emitido al tocar la caja durante escritura

var _panel  : PanelContainer
var _label  : Label
var _hint   : Label
var _skip_btn : Button        # botón "Saltar" visible al escribir

var _queue      : Array[String] = []
var _writing    : bool  = false
var _skip_now   : bool  = false   # true cuando el jugador quiere saltar
const CHAR_DELAY := 0.022

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Panel con posición ajustada para no tapar el menú de batalla
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left   = 14.0
	_panel.offset_top    = -148.0
	_panel.offset_right  = -610.0   # termina antes del BattleMenu (que empieza en 630)
	_panel.offset_bottom = -14.0

	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.05, 0.03, 0.01, 0.97)
	bg.border_color = Color(0.52, 0.40, 0.18, 1.0)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(10)
	bg.shadow_color = Color(0, 0, 0, 0.5)
	bg.shadow_size  = 10
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	# Permitir clic en el panel para saltar
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_gui_input)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Texto del mensaje
	_label = Label.new()
	_label.custom_minimum_size = Vector2(0.0, 58.0)
	_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.83))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_font_size_override("font_size", 21)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_label)

	# Fila inferior: hint + botón saltar
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bottom_row)

	_hint = Label.new()
	_hint.text = "▼  Continuar"
	_hint.add_theme_color_override("font_color", Color(0.75, 0.65, 0.35, 0.75))
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.visible = false
	bottom_row.add_child(_hint)

	_skip_btn = Button.new()
	_skip_btn.text   = "⏭ Saltar"
	_skip_btn.visible = false
	_skip_btn.custom_minimum_size = Vector2(80, 24)
	_skip_btn.add_theme_font_size_override("font_size", 14)
	_skip_btn.add_theme_color_override("font_color", Color(0.70, 0.65, 0.50))
	var skip_s := StyleBoxFlat.new()
	skip_s.bg_color = Color(0.12, 0.10, 0.07, 0.85)
	skip_s.border_color = Color(0.40, 0.33, 0.18, 0.8)
	skip_s.set_border_width_all(1)
	skip_s.set_corner_radius_all(5)
	_skip_btn.add_theme_stylebox_override("normal", skip_s)
	_skip_btn.pressed.connect(_request_skip)
	bottom_row.add_child(_skip_btn)

	# Animación de parpadeo del hint
	var blink : Tween = create_tween()
	blink.set_loops()
	blink.tween_property(_hint, "modulate:a", 0.2, 0.55)
	blink.tween_property(_hint, "modulate:a", 1.0, 0.55)

## Añade texto a la cola y lo escribe letra a letra
func push(text: String) -> void:
	if text.is_empty(): return
	_queue.append(text)
	if not _writing:
		_write_next()

## Muestra texto instantáneamente (para victoria/derrota)
func push_instant(text: String) -> void:
	_queue.clear()
	_skip_now     = true
	_writing      = false
	_label.text   = text
	_hint.visible = false
	_skip_btn.visible = false

## Espera a que la cola se vacíe
func wait_done() -> void:
	while _writing or not _queue.is_empty():
		await get_tree().create_timer(0.05).timeout

func _request_skip() -> void:
	_skip_now = true
	skip_requested.emit()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_request_skip()

func _write_next() -> void:
	if _queue.is_empty():
		_writing          = false
		_hint.visible     = false
		_skip_btn.visible = false
		all_done.emit()
		return

	_writing          = true
	_skip_now         = false
	_hint.visible     = false
	_skip_btn.visible = true

	var msg : String = _queue.pop_front()
	_label.text      = ""

	# Animar entrada del panel
	_panel.modulate.a = 0.8
	var entry := create_tween()
	entry.tween_property(_panel, "modulate:a", 1.0, 0.15)

	for ch : String in msg:
		if _skip_now:
			_label.text = msg
			break
		_label.text += ch
		await get_tree().create_timer(CHAR_DELAY).timeout

	_hint.visible     = true
	_skip_btn.visible = false
	_skip_now         = false

	await get_tree().create_timer(0.85).timeout
	_write_next()
