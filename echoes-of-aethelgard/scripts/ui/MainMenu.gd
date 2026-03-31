## MainMenu.gd
## Menú principal del juego
extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	GameManager.go_to_scene("exploration_map")
