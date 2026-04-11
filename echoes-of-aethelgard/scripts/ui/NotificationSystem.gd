## NotificationSystem.gd — VERSIÓN CORREGIDA
## RUTA: res://scripts/ui/NotificationSystem.gd
## CAMBIO: show() renombrado a notify() para no chocar con CanvasLayer.show()
extends CanvasLayer

const MAX_VISIBLE    := 4
const DEFAULT_DURATION := 2.5

var _queue  : Array[Dictionary] = []
var _active : Array[Control]    = []

const ICONS := {
	"level_up"  : "▲",
	"gold"      : "G",
	"amber"     : "A",
	"hero"      : "★",
	"chest"     : "◆",
	"exp"       : "E",
	"battle_won": "!",
	"chapter"   : "M",
	"default"   : "●",
}

func _ready() -> void:
	layer = 100
	if SignalBus.has_signal("notification_queued"):
		SignalBus.notification_queued.connect(_on_signal_queued)

func _on_signal_queued(text: String, icon: String, duration: float) -> void:
	notify(text, icon, duration)

## Usa notify() en vez de show() para evitar conflicto con CanvasLayer
## Ejemplo: Notifications.notify("¡Subiste de nivel!", "level_up")
func notify(text: String, type: String = "default", duration: float = DEFAULT_DURATION) -> void:
	_queue.append({ "text": text, "type": type, "duration": duration })
	_process_queue()

func _process_queue() -> void:
	if _active.size() >= MAX_VISIBLE or _queue.is_empty():
		return
	var data : Dictionary = _queue.pop_front()
	_display(data)

func _display(data: Dictionary) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var notif   := _build_notif(data)
	add_child(notif)
	_active.append(notif)
	_reposition_all()

	notif.modulate.a = 0.0
	notif.position.x = vp_size.x + 10.0

	var enter_t := create_tween().set_parallel(true)
	enter_t.tween_property(notif, "modulate:a", 1.0, 0.22)
	enter_t.tween_property(notif, "position:x",
		vp_size.x - notif.custom_minimum_size.x - 20.0, 0.22).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(data["duration"]).timeout

	var exit_t := create_tween().set_parallel(true)
	exit_t.tween_property(notif, "modulate:a", 0.0, 0.28)
	exit_t.tween_property(notif, "position:x", vp_size.x + 10.0, 0.28).set_ease(Tween.EASE_IN)
	await exit_t.finished

	_active.erase(notif)
	notif.queue_free()
	_reposition_all()
	_process_queue()

func _reposition_all() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var base_y  := vp_size.y - 90.0
	for i in _active.size():
		var notif  := _active[i]
		var target := base_y - i * 68.0
		var rt     := create_tween()
		rt.tween_property(notif, "position:y", target, 0.18).set_ease(Tween.EASE_OUT)

func _build_notif(data: Dictionary) -> PanelContainer:
	var notif := PanelContainer.new()
	notif.custom_minimum_size = Vector2(320.0, 56.0)

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.07, 0.05, 0.03, 0.96)
	style.border_color = _get_border_color(data["type"])
	style.set_border_width_all(3)
	style.border_width_left = 6
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size  = 6
	notif.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	notif.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = ICONS.get(data["type"], ICONS["default"])
	icon_lbl.add_theme_color_override("font_color", _get_border_color(data["type"]))
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var text_lbl := Label.new()
	text_lbl.text = data["text"]
	text_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	text_lbl.add_theme_font_size_override("font_size", 18)
	text_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_lbl)

	return notif

func _get_border_color(type: String) -> Color:
	match type:
		"level_up":   return Color(0.30, 1.00, 0.40)
		"gold":       return Color(0.95, 0.80, 0.25)
		"amber":      return Color(1.00, 0.55, 0.10)
		"hero":       return Color(0.70, 0.45, 1.00)
		"chest":      return Color(0.55, 0.75, 1.00)
		"exp":        return Color(0.25, 0.75, 1.00)
		"battle_won": return Color(1.00, 0.40, 0.25)
		"chapter":    return Color(0.40, 0.80, 1.00)
		_:            return Color(0.60, 0.55, 0.45)
