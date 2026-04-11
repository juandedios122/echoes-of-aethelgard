## TargetSelectOverlay.gd
## Resalta las unidades objetivo y permite al jugador seleccionar.
class_name TargetSelectOverlay
extends Node2D

signal target_selected(targets: Array[CombatUnit])

var _candidates : Array[CombatUnit] = []
var _index      : int = 0
var _multi      : bool = false   # true para habilidades de área

func show_for_skill(skill: SkillData, enemies: Array[CombatUnit], allies: Array[CombatUnit]) -> void:
	match skill.target_type:
		SkillData.TargetType.ALL_ENEMIES:
			_multi      = true
			_candidates = enemies.filter(func(u): return not u.is_dead())
			_confirm()   # Sin selección manual, se aplica a todos
			return
		SkillData.TargetType.ALL_ALLIES:
			_multi      = true
			_candidates = allies.filter(func(u): return not u.is_dead())
			_confirm()
			return
		SkillData.TargetType.SINGLE_ENEMY:
			_candidates = enemies.filter(func(u): return not u.is_dead())
		SkillData.TargetType.SINGLE_ALLY:
			_candidates = allies.filter(func(u): return not u.is_dead())
		SkillData.TargetType.SELF:
			target_selected.emit([allies[0]])   # Siempre self
			return

	_index = 0
	_multi = false
	_highlight_current()

func _input(event: InputEvent) -> void:
	if _candidates.is_empty(): return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_index = wrapi(_index + 1, 0, _candidates.size())
		_highlight_current()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_index = wrapi(_index - 1, 0, _candidates.size())
		_highlight_current()
	elif event.is_action_pressed("ui_accept"):
		_confirm()
	elif event.is_action_pressed("ui_cancel"):
		_clear_highlights()
		hide()

func _highlight_current() -> void:
	_clear_highlights()
	if _candidates.is_empty(): return
	var unit := _candidates[_index]
	# Pulso de escala
	var tween := create_tween().set_loops()
	tween.tween_property(unit, "scale", Vector2(1.08, 1.08), 0.25)
	tween.tween_property(unit, "scale", Vector2(1.00, 1.00), 0.25)
	unit.set_meta("_target_tween", tween)
	# Flecha indicadora encima de la unidad
	_spawn_arrow(unit)

func _clear_highlights() -> void:
	for unit in _candidates:
		if unit.has_meta("_target_tween"):
			(unit.get_meta("_target_tween") as Tween).kill()
			unit.scale = Vector2.ONE
			unit.remove_meta("_target_tween")
	for child in get_children():
		child.queue_free()

func _spawn_arrow(unit: CombatUnit) -> void:
	var lbl := Label.new()
	lbl.text = "▼"
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.global_position = unit.global_position + Vector2(-10, -100)
	add_child(lbl)
	var arrow_tween := create_tween().set_loops()
	arrow_tween.tween_property(lbl, "position:y", lbl.position.y + 10, 0.4).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(lbl, "position:y", lbl.position.y, 0.4).set_ease(Tween.EASE_IN_OUT)

func _confirm() -> void:
	var result: Array[CombatUnit] = [_candidates[_index]] if not _multi else _candidates.duplicate()
	_clear_highlights()
	target_selected.emit(result)
