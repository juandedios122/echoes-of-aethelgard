## forest_background_setup.gd
## RUTA: res://scripts/combat/ForestBackground.gd
## Añade este nodo como hijo de BattleScene (antes de Camera2D en el árbol).
## Crea el fondo de bosque multicapa automáticamente desde las capas del Free Pixel Art Forest.
##
## PRIMERO copia las capas aquí (renombrándolas por número):
##   res://assets/backgrounds/forest_layers/layer_00.png  ← Layer_0011_0.png (cielo, más lejano)
##   res://assets/backgrounds/forest_layers/layer_01.png  ← Layer_0010_1.png
##   res://assets/backgrounds/forest_layers/layer_02.png  ← Layer_0009_2.png
##   res://assets/backgrounds/forest_layers/layer_03.png  ← Layer_0008_3.png
##   res://assets/backgrounds/forest_layers/layer_04.png  ← Layer_0007_Lights.png
##   res://assets/backgrounds/forest_layers/layer_05.png  ← Layer_0006_4.png
##   res://assets/backgrounds/forest_layers/layer_06.png  ← Layer_0005_5.png
##   res://assets/backgrounds/forest_layers/layer_07.png  ← Layer_0004_Lights.png
##   res://assets/backgrounds/forest_layers/layer_08.png  ← Layer_0003_6.png
##   res://assets/backgrounds/forest_layers/layer_09.png  ← Layer_0002_7.png
##   res://assets/backgrounds/forest_layers/layer_10.png  ← Layer_0001_8.png
##   res://assets/backgrounds/forest_layers/layer_11.png  ← Layer_0000_9.png (primer plano)

extends Node2D

# Cuántas capas cargar (máximo 12, mínimo 4 para un buen efecto)
@export var num_layers : int = 8

# Velocidades de parallax por capa (índice 0 = más lejano = más lento)
const PARALLAX_SPEEDS : Array[float] = [0.05, 0.08, 0.12, 0.18, 0.22, 0.28, 0.35, 0.42, 0.50, 0.60, 0.72, 0.85]

# Color tinte oscuro para dar ambiente de batalla
@export var battle_tint : Color = Color(0.55, 0.52, 0.62, 1.0)

var _layers : Array[Sprite2D] = []

func _ready() -> void:
	_build_background()

func _build_background() -> void:
	for i in mini(num_layers, 12):
		var path := "res://assets/backgrounds/forest_layers/layer_%02d.png" % i
		if not ResourceLoader.exists(path):
			continue
		
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		
		var sprite := Sprite2D.new()
		sprite.texture   = tex
		sprite.z_index   = -(num_layers - i)   # Capas traseras con z negativo
		sprite.modulate  = battle_tint
		
		# Escalar para cubrir 1920×1080 (el viewport del juego)
		# El original mide 928×793, necesitamos ~2.07× para cubrir 1920px
		var scale_x : float = 1920.0 / float(tex.get_width())
		var scale_y : float = 1080.0 / float(tex.get_height())
		var scale_f : float = maxf(scale_x, scale_y) * 1.1   # 10% extra para parallax
		sprite.scale = Vector2(scale_f, scale_f)
		
		# Centrar en pantalla
		sprite.position = Vector2.ZERO
		
		add_child(sprite)
		_layers.append(sprite)
	
	print("[ForestBackground] %d capas cargadas." % _layers.size())

func _process(delta: float) -> void:
	# Parallax horizontal suave basado en el tiempo
	# En BattleScene no hay cámara que se mueva, así que hacemos un desplazamiento sutil
	var t := Time.get_ticks_msec() / 1000.0
	for i in _layers.size():
		var speed  : float  = PARALLAX_SPEEDS[mini(i, PARALLAX_SPEEDS.size() - 1)]
		var offset : float  = sin(t * speed * 0.3) * 8.0   # Oscilación muy suave
		_layers[i].position.x = offset * (i + 1) * 0.5
