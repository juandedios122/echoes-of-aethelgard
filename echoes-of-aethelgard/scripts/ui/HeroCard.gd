## HeroCard.gd
## Tarjeta de héroe para el gacha con animación de volteo y reveal por rareza.
class_name HeroCard
extends PanelContainer

@onready var portrait: TextureRect = $VBoxContainer/Portrait
@onready var name_label: Label     = $VBoxContainer/NameLabel
@onready var rarity_label: Label   = $VBoxContainer/RarityLabel
@onready var new_label: Label      = $VBoxContainer/NewLabel

var _hero: HeroData = null
var _is_duplicate: bool = false

# ─── Setup estático (sin animación) ──────────────────────────────────────────
func setup(hero: HeroData, is_duplicate: bool) -> void:
	_hero        = hero
	_is_duplicate = is_duplicate
	_apply_visual(hero, is_duplicate)

# ─── Setup con animación de reveal ───────────────────────────────────────────
func setup_hidden(hero: HeroData, is_duplicate: bool) -> void:
	_hero         = hero
	_is_duplicate = is_duplicate

	# Mostrar cara trasera (fondo oscuro sin datos)
	modulate      = Color(1, 1, 1, 1)
	scale         = Vector2(1, 1)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color     = Color(0.08, 0.05, 0.12, 1)
	back_style.border_color = Color(0.35, 0.25, 0.5, 1)
	back_style.set_border_width_all(3)
	back_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", back_style)

	# Símbolo de interrogación como placeholder
	if portrait:
		portrait.texture = null
	if name_label:
		name_label.text = "?"
		name_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.55))
	if rarity_label:
		rarity_label.text = "???"
		rarity_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.55))
	if new_label:
		new_label.visible = false

## Anima el volteo de la carta y revela el héroe.
## Retorna cuando la animación termina.
func reveal() -> void:
	# Fase 1: encoger horizontalmente (giro a la mitad)
	var tween1: Tween = create_tween()
	tween1.tween_property(self, "scale:x", 0.0, 0.18).set_ease(Tween.EASE_IN)
	await tween1.finished

	# Fase 2: aplicar visual real del héroe (mientras está "de lado")
	_apply_visual(_hero, _is_duplicate)

	# Fase 3: expandir de vuelta
	var tween2: Tween = create_tween()
	tween2.tween_property(self, "scale:x", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	await tween2.finished

	# Si es Épico o Legendario: pulso extra de brillo
	if _hero.rarity >= HeroData.Rarity.EPICO:
		var glow: Tween = create_tween()
		glow.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.12)
		glow.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
		await glow.finished

# ─── Visual del héroe ─────────────────────────────────────────────────────────
func _apply_visual(hero: HeroData, is_duplicate: bool) -> void:
	if hero.portrait and portrait:
		portrait.texture = hero.portrait

	if name_label:
		name_label.text = hero.hero_name
		name_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80))

	if rarity_label:
		rarity_label.text = _get_rarity_stars(hero.rarity) + "  " + hero.get_rarity_label()
		rarity_label.add_theme_color_override("font_color", hero.get_rarity_color())

	if new_label:
		new_label.visible = not is_duplicate

	# Fondo según rareza
	var style := StyleBoxFlat.new()
	style.bg_color = hero.get_rarity_color()
	style.bg_color.a = 0.28
	style.border_color = hero.get_rarity_color()
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = hero.get_rarity_color()
	style.shadow_color.a = 0.5
	style.shadow_size = 6 if hero.rarity >= HeroData.Rarity.EPICO else 2
	add_theme_stylebox_override("panel", style)

func _get_rarity_stars(rarity: HeroData.Rarity) -> String:
	match rarity:
		HeroData.Rarity.COMUN:      return "★"
		HeroData.Rarity.RARO:       return "★★"
		HeroData.Rarity.EPICO:      return "★★★"
		HeroData.Rarity.LEGENDARIO: return "★★★★"
	return ""
