## Chest.gd — VERSIÓN LIMPIA SIN SPRITES
## RUTA: res://scripts/exploration/Chest.gd
## No necesitas ningún sprite. Dibuja un rectángulo dorado por código.
class_name Chest
extends Area2D

@export var chest_id : String     = "chest_001"
@export var gold_reward  : int = 150
@export var amber_reward : int = 5

var _opened : bool = false

# Nodos creados por código — no necesitas ningún asset
var _rect   : ColorRect
var _label  : Label
@warning_ignore("unused_private_class_variable")
var _opened_label : Label

func _ready() -> void:
	_opened = GameManager.player_data.completed_stages.has("chest_" + chest_id)
	_build_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_visuals() -> void:
	# Caja del cofre (rectángulo dorado o gris si ya está abierto)
	_rect = ColorRect.new()
	_rect.size          = Vector2(64.0, 64.0)
	_rect.position      = Vector2(-32.0, -32.0)
	_rect.color         = Color(0.15, 0.12, 0.06) if _opened else Color(0.65, 0.50, 0.10)
	add_child(_rect)

	# Borde decorativo
	var border := ColorRect.new()
	border.size     = Vector2(60.0, 60.0)
	border.position = Vector2(-30.0, -30.0)
	border.color    = Color(0.85, 0.70, 0.20) if not _opened else Color(0.35, 0.32, 0.28)
	_rect.add_child(border)

	# Símbolo central
	var icon := Label.new()
	icon.text = "◆" if not _opened else "○"
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color",
		Color(1.0, 0.90, 0.30) if not _opened else Color(0.4, 0.4, 0.4))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.add_child(icon)

	# Label de hint (visible al acercarse)
	_label = Label.new()
	_label.text     = "[ E ] Abrir cofre"
	_label.position = Vector2(-50.0, -55.0)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.visible = false
	add_child(_label)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_hero") and not _opened:
		_label.visible = true
		# Notificar al mapa de exploración
		var map := _find_map()
		if map and map.has_method("register_interactable"):
			map.register_interactable(self, true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player_hero"):
		_label.visible = false
		var map := _find_map()
		if map and map.has_method("register_interactable"):
			map.register_interactable(self, false)

## Llamado por ExplorationMap cuando el jugador pulsa interactuar
func interact() -> void:
	if _opened: return
	_opened = true

	# Animación de apertura: parpadeo dorado
	var tween : Tween = create_tween()
	tween.tween_property(_rect, "color", Color(1.0, 0.85, 0.2), 0.12)
	tween.tween_property(_rect, "color", Color(0.15, 0.12, 0.06), 0.25)

	await get_tree().create_timer(0.35).timeout

	# Dar recompensas
	if gold_reward  > 0: GameManager.add_gold(gold_reward)
	if amber_reward > 0: GameManager.add_amber(amber_reward)

	# Marcar como abierto
	GameManager.player_data.completed_stages.append("chest_" + chest_id)
	GameManager.save_game()

	# Notificación
	var msg := ""
	if gold_reward  > 0: msg += "+%d Oro  " % gold_reward
	if amber_reward > 0: msg += "+%d Ámbar" % amber_reward
	if has_node("/root/Notifications"):
		get_node("/root/Notifications").notify("Cofre: " + msg.strip_edges(), "chest")

	# Cambiar visual a abierto
	_rect.color = Color(0.15, 0.12, 0.06)
	_label.visible = false

func _find_map() -> Node:
	return get_tree().get_root().find_child("ExplorationMap", true, false)
