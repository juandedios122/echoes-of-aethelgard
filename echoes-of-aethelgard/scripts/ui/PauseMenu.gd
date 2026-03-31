## PauseMenu.gd
## Menú de pausa que se puede abrir con ESC
extends CanvasLayer

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()

func toggle_pause() -> void:
	if visible:
		resume()
	else:
		pause()

func pause() -> void:
	show()
	get_tree().paused = true

func resume() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	resume()

func _on_gacha_pressed() -> void:
	resume()
	GameManager.go_to_scene("gacha_screen")

func _on_main_menu_pressed() -> void:
	resume()
	GameManager.go_to_scene("main_menu")

func _on_quit_pressed() -> void:
	get_tree().quit()
