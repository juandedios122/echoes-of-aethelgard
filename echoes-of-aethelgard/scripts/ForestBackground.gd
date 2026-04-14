## ForestBackground.gd — VERSIÓN FINAL
## RUTA: res://scripts/ForestBackground.gd
extends Node2D

@export var battle_tint : Color = Color(0.60, 0.55, 0.70, 1.0)

const LAYER_FILES : Array[String] = [
	"Layer_0011_0.png",
	"Layer_0010_1.png",
	"Layer_0009_2.png",
	"Layer_0008_3.png",
	"Layer_0007_Lights.png",
	"Layer_0006_4.png",
	"Layer_0005_5.png",
	"Layer_0004_Lights.png",
	"Layer_0003_6.png",
	"Layer_0002_7.png",
	"Layer_0001_8.png",
	"Layer_0000_9.png",
]

const PARALLAX_SPEEDS : Array[float] = [
	0.04, 0.07, 0.10, 0.14, 0.18, 0.22,
	0.27, 0.32, 0.38, 0.45, 0.54, 0.64
]

var _layers : Array[Sprite2D] = []

func _ready() -> void:
	_build_background()

func _build_background() -> void:
	var base_path := "res://assets/backgrounds/forest_layers/"
	for i in LAYER_FILES.size():
		var path := base_path + LAYER_FILES[i]
		if not ResourceLoader.exists(path):
			push_warning("[ForestBackground] No encontrado: %s" % path)
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture  = tex
		sprite.z_index  = -(LAYER_FILES.size() - i)
		sprite.modulate = battle_tint
		var scale_x := 1920.0 / float(tex.get_width())
		var scale_y := 1080.0 / float(tex.get_height())
		var sf      := maxf(scale_x, scale_y) * 1.15
		sprite.scale    = Vector2(sf, sf)
		sprite.position = Vector2.ZERO
		add_child(sprite)
		_layers.append(sprite)
	print("[ForestBackground] %d capas cargadas." % _layers.size())

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in _layers.size():
		var speed := PARALLAX_SPEEDS[mini(i, PARALLAX_SPEEDS.size() - 1)]
		_layers[i].position.x = sin(t * speed * 0.25) * 10.0 * (i + 1) * 0.4
