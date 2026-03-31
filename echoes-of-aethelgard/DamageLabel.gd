# DamageLabel.gd — script simple
extends Node2D
func setup(amount: int, is_heal: bool) -> void:
	$Label.text = ("%+d" if is_heal else "%d") % amount
	$Label.modulate = Color.GREEN if is_heal else Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 80, 0.7)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
	await tween.finished
	queue_free()
