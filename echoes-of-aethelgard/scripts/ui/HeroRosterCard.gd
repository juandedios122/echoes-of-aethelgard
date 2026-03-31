## HeroRosterCard.gd
## Tarjeta de héroe para el grid de la colección
extends Button

@onready var portrait: TextureRect = $VBoxContainer/PortraitPanel/Portrait
@onready var locked_overlay: ColorRect = $VBoxContainer/PortraitPanel/LockedOverlay
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var rarity_label: Label = $VBoxContainer/RarityLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel

var hero_data: HeroData

func setup(hero: HeroData, is_owned: bool) -> void:
	hero_data = hero
	
	# Configurar retrato
	if hero.portrait:
		portrait.texture = hero.portrait
	
	# Configurar nombre
	name_label.text = hero.hero_name
	name_label.add_theme_color_override("font_color", hero.get_rarity_color())
	
	# Configurar rareza
	rarity_label.text = hero.get_rarity_label()
	rarity_label.add_theme_color_override("font_color", hero.get_rarity_color())
	
	# Configurar nivel y estado de desbloqueo
	if is_owned:
		var level: int = GameManager.player_data.get_hero_level(hero.hero_id)
		level_label.text = "Nv. %d" % level
		level_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3, 1))
		locked_overlay.visible = false
	else:
		level_label.text = "No desbloqueado"
		level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		locked_overlay.visible = true
