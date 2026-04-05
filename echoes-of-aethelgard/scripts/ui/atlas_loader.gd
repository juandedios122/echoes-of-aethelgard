## atlas_loader.gd — función utilitaria
## Llama así: AtlasLoader.get_icon("icon (1)")

var _atlas_texture: Texture2D = null
var _atlas_data: Dictionary = {}

func _ready() -> void:
	_atlas_texture = load("res://assets/ui/heroes_icons_atlas.png")
	var json_file := FileAccess.open("res://assets/ui/heroes_icons_atlas.json", FileAccess.READ)
	if json_file:
		_atlas_data = JSON.parse_string(json_file.get_as_text())

func get_icon(icon_name: String) -> AtlasTexture:
	var frame: Dictionary = _atlas_data["frames"][icon_name + ".png"]["frame"]
	var atlas := AtlasTexture.new()
	atlas.atlas  = _atlas_texture
	atlas.region = Rect2(frame["x"], frame["y"], frame["w"], frame["h"])
	return atlas
