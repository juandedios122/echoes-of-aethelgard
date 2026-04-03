## TestManager.gd
## Script de prueba básica para validar GameManager.
extends Node

func _ready() -> void:
	print("=== Iniciando tests de GameManager ===")
	test_save_load()
	print("=== Tests completados ===")

func test_save_load() -> void:
	var gm = GameManager.new()
	gm.player_data.amber_shards = 100
	gm.player_data.gold = 50
	gm.save_game()
	
	# Simular nueva instancia
	var gm2 = GameManager.new()
	gm2._load_game()
	
	if gm2.player_data.amber_shards == 100 and gm2.player_data.gold == 50:
		print("✓ Test save/load: PASADO")
	else:
		print("✗ Test save/load: FALLADO")