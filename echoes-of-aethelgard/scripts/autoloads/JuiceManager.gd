## JuiceManager.gd
## Autoload Singleton — Efectos de "juice" centralizados.
## Añadir en Proyecto > Autoloads como "JuiceManager".
## Uso: JuiceManager.shake(10.0)  /  JuiceManager.hit_freeze(0.05)
extends Node

# ─── Referencia a la cámara activa ───────────────────────────────────────────
var _active_camera: Camera2D = null
var _shake_intensity: float  = 0.0
var _shake_decay: float      = 8.0     # Velocidad de suavizado (mayor = más rápido)
var _base_offset: Vector2    = Vector2.ZERO

# ─── Parámetros de Hit-Freeze ─────────────────────────────────────────────────
var _freeze_timer: float = 0.0

func _ready() -> void:
	set_process(true)

## Registrar la cámara activa (llamar desde BattleScene._ready())
func register_camera(camera: Camera2D) -> void:
	_active_camera = camera
	_base_offset   = camera.offset if camera else Vector2.ZERO

func _process(delta: float) -> void:
	# Hit freeze: congelar el tiempo brevemente (para golpes fuertes)
	if _freeze_timer > 0.0:
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			Engine.time_scale = 1.0

	# Camera shake suave
	if _active_camera and _shake_intensity > 0.0:
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
		if _shake_intensity < 0.5:
			_shake_intensity = 0.0
			_active_camera.offset = _base_offset
		else:
			_active_camera.offset = _base_offset + Vector2(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity * 0.6, _shake_intensity * 0.6)
			)

# ─── API pública ──────────────────────────────────────────────────────────────

## Sacude la cámara. intensity: 2–20 para combate normal, 40+ para golpe épico.
func shake(intensity: float, decay: float = 8.0) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)  # No resetear si ya hay shake
	_shake_decay     = decay

## Congela el tiempo por duration segundos (0.03–0.1 es suficiente).
## Hace que los golpes fuertes "peguen" visualmente.
func hit_freeze(duration: float = 0.05) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.0
	_freeze_timer     = duration   # _process usará delta real para descontar

## Flash de pantalla completa (para golpes críticos, ultimates, etc.).
## color: el color del flash. duration: segundos totales.
func screen_flash(color: Color = Color(1, 1, 1, 0.4), duration: float = 0.15) -> void:
	var tree := get_tree()
	if not tree:
		return
	var root := tree.get_root()
	if not root:
		return

	# Buscar o crear el ColorRect de flash
	var flash_node := root.get_node_or_null("_juice_flash") as ColorRect
	if flash_node == null:
		flash_node           = ColorRect.new()
		flash_node.name      = "_juice_flash"
		flash_node.z_index   = 999
		flash_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash_node.color     = Color(0, 0, 0, 0)
		root.add_child(flash_node)

	# Animar: aparece rápido, desaparece lento
	flash_node.color = Color(color.r, color.g, color.b, 0.0)
	var tween: Tween = flash_node.create_tween()
	tween.tween_property(flash_node, "color", color, duration * 0.25)
	tween.tween_property(flash_node, "color", Color(color.r, color.g, color.b, 0.0), duration * 0.75)

## Pulso de escala en un nodo (para botones, labels de daño, etc.).
func pop(node: Node2D, scale_mult: float = 1.25, duration: float = 0.15) -> void:
	if not is_instance_valid(node):
		return
	var original_scale: Vector2 = node.scale
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", original_scale * scale_mult, duration * 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale, duration * 0.6).set_ease(Tween.EASE_IN_OUT)

## Versión para nodos Control (UI).
func pop_control(node: Control, scale_mult: float = 1.15, duration: float = 0.12) -> void:
	if not is_instance_valid(node):
		return
	var original_scale: Vector2 = node.scale
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", original_scale * scale_mult, duration * 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", original_scale, duration * 0.65).set_ease(Tween.EASE_IN_OUT)

## Sacudida de un nodo UI (para mensajes de error, ámbar insuficiente, etc.).
func shake_node(node: Control, strength: float = 8.0, count: int = 5) -> void:
	if not is_instance_valid(node):
		return
	var original_x: float = node.position.x
	var tween: Tween = node.create_tween()
	for i: int in count:
		var offset: float = strength if i % 2 == 0 else -strength
		tween.tween_property(node, "position:x", original_x + offset, 0.05)
	tween.tween_property(node, "position:x", original_x, 0.05)
