## DamageLabel.gd
## Label flotante de daño/curación con juice: pop, float-up y fade.
extends Node2D

@onready var label: Label = $Label

func setup(amount: int, is_heal: bool) -> void:
	if not label:
		return

	# Configurar texto y color
	if is_heal:
		label.text    = "+%d" % amount
		label.modulate = Color(0.3, 1.0, 0.4)
	elif amount == 0:
		label.text    = "MISS"
		label.modulate = Color(0.7, 0.7, 0.7)
	else:
		label.text    = "-%d" % amount
		label.modulate = Color(1.0, 0.9, 0.9)

	# Pop inicial (crece rápido)
	scale = Vector2(0.4, 0.4)
	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06).set_ease(Tween.EASE_IN)

	# Flotar hacia arriba y desvanecerse
	var float_tween: Tween = create_tween()
	float_tween.tween_property(self, "position:y", position.y - 70.0, 0.7).set_ease(Tween.EASE_OUT)
	float_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.3)
	await float_tween.finished
	queue_free()
