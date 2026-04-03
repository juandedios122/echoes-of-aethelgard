## SceneTransition.gd
## Autoload Singleton — Sistema de transiciones de escena animadas.
## Añadir en: Proyecto > Configuración > Autoloads como "SceneTransition"
extends CanvasLayer

enum TransitionType { FADE, FADE_COLOR, DISSOLVE }

var _color_rect: ColorRect
var _is_transitioning: bool = false
var _default_duration: float = 0.4
var _default_color: Color = Color(0.02, 0.01, 0.03, 1.0)  # Negro medieval oscuro

func _ready() -> void:
	layer = 100  # Siempre encima de todo
	_color_rect = ColorRect.new()
	_color_rect.color = _default_color
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.modulate.a = 0.0
	add_child(_color_rect)

## Transición completa: fade out → cambiar escena → fade in
func transition_to_scene(scene_path: String, duration: float = -1.0, color: Color = Color(-1, 0, 0, 0)) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	var dur := duration if duration > 0 else _default_duration
	var col := color if color.r >= 0 else _default_color
	_color_rect.color = col

	# Bloquear input durante transición
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fade out
	var tween_out := create_tween()
	tween_out.tween_property(_color_rect, "modulate:a", 1.0, dur * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	await tween_out.finished

	# Cambiar escena
	get_tree().change_scene_to_file(scene_path)

	# Esperar un frame para que la nueva escena se inicialice
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade in
	var tween_in := create_tween()
	tween_in.tween_property(_color_rect, "modulate:a", 0.0, dur * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

## Fade out manual (útil para cinemáticas)
func fade_out(duration: float = 0.3, color: Color = Color(-1, 0, 0, 0)) -> void:
	var col := color if color.r >= 0 else _default_color
	_color_rect.color = col
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration)
	await tween.finished

## Fade in manual
func fade_in(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration)
	await tween.finished

## Flash rápido (victoria, derrota, crítico)
func flash(color: Color = Color.WHITE, duration: float = 0.15) -> void:
	_color_rect.color = color
	_color_rect.modulate.a = 0.6
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration)
	await tween.finished

func is_transitioning() -> bool:
	return _is_transitioning
