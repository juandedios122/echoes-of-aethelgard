## MainMenu.gd
## Menú principal del juego
extends Control

@onready var play_button: TextureButton = $CenterContainer/VBoxContainer/PlayButton
@onready var gacha_button: TextureButton = $CenterContainer/VBoxContainer/GachaButton
@onready var heroes_button: TextureButton = $CenterContainer/VBoxContainer/HeroesButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	gacha_button.pressed.connect(_on_gacha_pressed)
	heroes_button.pressed.connect(_on_heroes_pressed)
	
	# Reproducir música del menú
	AudioManager.play_music("menu_theme", 2.0)

func _on_play_pressed() -> void:
	GameManager.go_to_scene("exploration_map")

func _on_gacha_pressed() -> void:
	GameManager.go_to_scene("gacha_screen")

func _on_heroes_pressed() -> void:
	GameManager.go_to_scene("hero_roster")
