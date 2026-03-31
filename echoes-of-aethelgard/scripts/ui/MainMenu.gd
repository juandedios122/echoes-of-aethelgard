## MainMenu.gd
## Menú principal del juego
extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var gacha_button: Button = $CenterContainer/VBoxContainer/GachaButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	gacha_button.pressed.connect(_on_gacha_pressed)

func _on_play_pressed() -> void:
	GameManager.go_to_scene("exploration_map")

func _on_gacha_pressed() -> void:
	GameManager.go_to_scene("gacha_screen")
