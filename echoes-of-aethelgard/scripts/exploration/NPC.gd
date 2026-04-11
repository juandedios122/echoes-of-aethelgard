## NPC.gd — VERSIÓN SIN SPRITES
## RUTA: res://scripts/exploration/NPC.gd
## No necesitas ningún sprite. Dibuja un personaje simple con rectángulos.
class_name NPC
extends Area2D

@export var npc_name : String        = "Aldeano"
@export var dialogue : Array[String] = ["Hola, viajero."]

# Colores de NPC: cambia estos para diferenciar NPCs
@export var body_color : Color = Color(0.30, 0.22, 0.50)   # túnica
@export var skin_color : Color = Color(0.90, 0.72, 0.55)   # piel

var _hint  : Label
var _nearby : bool = false

func _ready() -> void:
	_build_visuals()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_visuals() -> void:
	# Cuerpo (rectángulo con color)
	var body := ColorRect.new()
	body.size     = Vector2(36.0, 52.0)
	body.position = Vector2(-18.0, -52.0)
	body.color    = body_color
	add_child(body)

	# Cabeza (rectángulo pequeño)
	var head := ColorRect.new()
	head.size     = Vector2(28.0, 28.0)
	head.position = Vector2(-14.0, -80.0)
	head.color    = skin_color
	add_child(head)

	# Ojos (puntos)
	var eye_l := ColorRect.new()
	eye_l.size     = Vector2(5.0, 5.0)
	eye_l.position = Vector2(-9.0, -72.0)
	eye_l.color    = Color(0.1, 0.1, 0.1)
	add_child(eye_l)

	var eye_r := ColorRect.new()
	eye_r.size     = Vector2(5.0, 5.0)
	eye_r.position = Vector2(4.0, -72.0)
	eye_r.color    = Color(0.1, 0.1, 0.1)
	add_child(eye_r)

	# Nombre del NPC
	var name_lbl := Label.new()
	name_lbl.text     = npc_name
	name_lbl.position = Vector2(-60.0, -100.0)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_lbl)

	# Hint de interacción
	_hint = Label.new()
	_hint.text     = "[ E ] Hablar"
	_hint.position = Vector2(-40.0, -118.0)
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.92, 0.60))
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("shadow_offset_x", 2)
	_hint.add_theme_constant_override("shadow_offset_y", 2)
	_hint.visible = false
	add_child(_hint)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player_hero"):
		_nearby     = true
		_hint.visible = true
		var map := _find_map()
		if map and map.has_method("register_interactable"):
			map.register_interactable(self, true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player_hero"):
		_nearby       = false
		_hint.visible = false
		var map := _find_map()
		if map and map.has_method("register_interactable"):
			map.register_interactable(self, false)

## Llamado por ExplorationMap cuando el jugador pulsa interactuar
func interact() -> void:
	if dialogue.is_empty(): return
	var dialog : Node = _find_dialog()
	if dialog == null:
		push_warning("[NPC] No se encontró DialogBox en la escena")
		return
	await dialog.show_dialog(npc_name, dialogue)

func _find_map() -> Node:
	return get_tree().get_root().find_child("ExplorationMap", true, false)

func _find_dialog() -> Node:
	return get_tree().get_root().find_child("DialogBox", true, false)
