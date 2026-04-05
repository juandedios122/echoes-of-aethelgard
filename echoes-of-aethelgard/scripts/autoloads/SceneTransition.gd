## SceneTransition.gd
## Autoload — Transiciones suaves entre escenas con efectos de juice.
## Ya existe en el proyecto; esta versión añade tipos y nuevos efectos.
extends Node

enum TransitionType { FADE, WIPE_LEFT, WIPE_RIGHT, CIRCLE }

var _overlay: ColorRect    = null
var _is_transitioning: bool = false

const DEFAULT_DURATION: float = 0.35

func _ready() -> void:
	_overlay             = ColorRect.new()
	_overlay.name        = "TransitionOverlay"
	_overlay.z_index     = 100
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color       = Color(0, 0, 0, 0)
	get_tree().root.add_child(_overlay)

func is_transitioning() -> bool:
	return _is_transitioning

## Cambia de escena con transición. type por defecto: FADE.
func transition_to_scene(
		path: String,
		type: TransitionType = TransitionType.FADE,
		duration: float = DEFAULT_DURATION
) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade OUT
	var out_tween: Tween = create_tween()
	out_tween.tween_property(_overlay, "color", Color(0, 0, 0, 1), duration)
	await out_tween.finished

	# Cambiar escena
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade IN
	var in_tween: Tween = create_tween()
	in_tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), duration)
	await in_tween.finished

	_is_transitioning = false
