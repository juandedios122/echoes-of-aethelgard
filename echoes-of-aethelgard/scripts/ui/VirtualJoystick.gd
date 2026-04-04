## VirtualJoystick.gd
## Joystick virtual táctil para controles en Android.
## Colocar como hijo de un CanvasLayer para que aparezca siempre en pantalla.
## Uso: obtener la dirección con get_direction() en _physics_process del héroe.
class_name VirtualJoystick
extends Control

# ─── Apariencia ───────────────────────────────────────────────────────────────
@export var joystick_radius: float  = 90.0   ## Radio del área de fondo
@export var knob_radius: float      = 42.0   ## Radio del botón central
@export var base_color: Color       = Color(0.2, 0.2, 0.2, 0.45)
@export var knob_color: Color       = Color(0.9, 0.75, 0.3, 0.75)
@export var border_color: Color     = Color(0.9, 0.75, 0.3, 0.55)
@export var dead_zone: float        = 0.15   ## Zona muerta (ignorar inputs pequeños)

## Si es true el joystick aparece donde el jugador toca (flotante).
## Si es false aparece fijo en la esquina inferior izquierda.
@export var floating_mode: bool = true

# ─── Estado interno ───────────────────────────────────────────────────────────
var _touch_index: int    = -1
var _origin: Vector2     = Vector2.ZERO   ## Centro del joystick en coords globales
var _knob_pos: Vector2   = Vector2.ZERO   ## Posición del knob en coords globales
var _direction: Vector2  = Vector2.ZERO
var _active: bool        = false

## Posición fija en pantalla cuando floating_mode = false (esquina inf. izquierda)
var _fixed_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	# El Control debe cubrir toda la pantalla para recibir toques
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE  # No bloquear clics de otros controles

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_fixed_origin()

func _update_fixed_origin() -> void:
	var vp := get_viewport_rect().size
	_fixed_origin = global_position + Vector2(joystick_radius + 50.0, vp.y - joystick_radius - 50.0)
	if not floating_mode and not _active:
		_origin = _fixed_origin
		_knob_pos = _origin

## Devuelve un Vector2 normalizado con la dirección actual del joystick.
## Retorna Vector2.ZERO cuando no hay input.
func get_direction() -> Vector2:
	return _direction

# ─── Input ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp := get_viewport_rect().size

	if event.pressed:
		# Solo activar si no hay otro dedo usando el joystick
		if _touch_index != -1:
			return
		# Zona de activación: mitad izquierda de la pantalla
		if event.position.x > vp.x * 0.5:
			return

		_touch_index = event.index
		_active      = true

		if floating_mode:
			# El joystick aparece donde el jugador toca
			_origin   = event.position
			_knob_pos = _origin
		else:
			_origin   = _fixed_origin
			_knob_pos = _origin

		queue_redraw()

	elif event.index == _touch_index:
		# Levantar el dedo → resetear
		_touch_index = -1
		_active      = false
		_direction   = Vector2.ZERO
		if not floating_mode:
			_knob_pos = _fixed_origin
		queue_redraw()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return

	var offset := event.position - _origin
	# Limitar el knob al radio del joystick
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius
	_knob_pos = _origin + offset

	# Calcular dirección con zona muerta
	var raw_dir := offset / joystick_radius
	if raw_dir.length() < dead_zone:
		_direction = Vector2.ZERO
	else:
		_direction = raw_dir

	queue_redraw()

# ─── Dibujo ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	if not _active and floating_mode:
		# Modo flotante: dibujar un indicador tenue cuando está inactivo
		var vp := get_viewport_rect().size
		var hint_pos := Vector2(joystick_radius + 50.0, vp.y - joystick_radius - 50.0) - global_position
		draw_circle(hint_pos, joystick_radius * 0.4, Color(1, 1, 1, 0.08))
		draw_arc(hint_pos, joystick_radius * 0.4, 0, TAU, 32, Color(1, 1, 1, 0.15), 2.0)
		return

	if not _active and not floating_mode:
		# Modo fijo: mostrar joystick siempre
		var local_orig := _fixed_origin - global_position
		_draw_joystick(local_orig, local_orig)
		return

	var local_origin := _origin   - global_position
	var local_knob   := _knob_pos - global_position
	_draw_joystick(local_origin, local_knob)

func _draw_joystick(origin: Vector2, knob: Vector2) -> void:
	# Fondo circular
	draw_circle(origin, joystick_radius, base_color)
	# Borde exterior
	draw_arc(origin, joystick_radius, 0, TAU, 48, border_color, 3.0)
	# Indicadores de dirección (líneas)
	var arrow_len := joystick_radius * 0.55
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir_v := Vector2(cos(angle), sin(angle))
		draw_line(origin + dir_v * joystick_radius * 0.65,
		          origin + dir_v * arrow_len,
		          Color(1, 1, 1, 0.25), 2.0)
	# Knob central
	draw_circle(knob, knob_radius, knob_color)
	draw_arc(knob, knob_radius, 0, TAU, 32, Color(1, 0.9, 0.5, 0.9), 2.5)
