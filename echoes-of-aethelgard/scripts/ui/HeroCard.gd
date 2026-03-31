## HeroCard.gd
## Tarjeta visual de un héroe para mostrar en gacha o roster.
class_name HeroCard
extends PanelContainer

# ─── Nodos ────────────────────────────────────────────────────────────────────
@onready var portrait: TextureRect = $VBoxContainer/Portrait
@onready var name_label: Label     = $VBoxContainer/NameLabel
@onready var rarity_label: Label   = $VBoxContainer/RarityLabel
@onready var new_label: Label      = $VBoxContainer/NewLabel

# ─── Setup ────────────────────────────────────────────────────────────────────
func setup(hero: HeroData, is_duplicate: bool) -> void:
	if hero.portrait:
		portrait.texture = hero.portrait
	name_label.text   = hero.hero_name
	rarity_label.text = _get_rarity_stars(hero.rarity) + " " + hero.get_rarity_label()
	rarity_label.add_theme_color_override("font_color", hero.get_rarity_color())
	new_label.visible = not is_duplicate
	
	# Aplicar color de fondo según rareza
	var style := StyleBoxFlat.new()
	style.bg_color = hero.get_rarity_color()
	style.bg_color.a = 0.3
	style.border_width_all = 2
	style.border_color = hero.get_rarity_color()
	style.corner_radius_all = 8
	add_theme_stylebox_override("panel", style)

func _get_rarity_stars(rarity: HeroData.Rarity) -> String:
	match rarity:
		HeroData.Rarity.COMUN:      return "★"
		HeroData.Rarity.RARO:       return "★★"
		HeroData.Rarity.EPICO:      return "★★★"
		HeroData.Rarity.LEGENDARIO: return "★★★★"
	return ""
