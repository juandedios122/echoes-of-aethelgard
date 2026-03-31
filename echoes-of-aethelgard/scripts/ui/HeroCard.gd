## HeroCard.gd
## Tarjeta visual de héroe para el resultado del gacha y el roster.
## Árbol de nodos sugerido:
##   HeroCard (PanelContainer)
##   ├── CardBG (TextureRect)          ← fondo según rareza
##   ├── Portrait (TextureRect)        ← retrato del héroe
##   ├── RarityGlow (ColorRect)        ← borde de color de rareza
##   ├── HeroName (Label)
##   ├── FactionLabel (Label)
##   ├── RarityLabel (Label)
##   ├── NewBadge (Label)              ← "¡NUEVO!" si es primera vez
##   └── ShineParticles (GPUParticles2D) ← destellos para legendarios
class_name HeroCard
extends PanelContainer

@onready var card_bg: TextureRect        = $CardBG
@onready var portrait: TextureRect       = $Portrait
@onready var rarity_glow: ColorRect      = $RarityGlow
@onready var hero_name_label: Label      = $HeroName
@onready var faction_label: Label        = $FactionLabel
@onready var rarity_label: Label         = $RarityLabel
@onready var new_badge: Label            = $NewBadge
@onready var shine_particles: GPUParticles2D = $ShineParticles

func setup(hero: HeroData, is_duplicate: bool = false) -> void:
	if hero == null:
		return

	# Cargar portrait desde el sistema de archivos de sprites
	var portrait_path := "res://assets/sprites/heroes/%s/portrait.png" % hero.hero_name
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
	elif hero.portrait:
		portrait.texture = hero.portrait  # fallback al resource

	# Fondo de carta personalizado
	if card_bg and hero.card_background:
		card_bg.texture = hero.card_background

	# Texto
	hero_name_label.text = hero.hero_name
	faction_label.text   = hero.get_faction_label()
	rarity_label.text    = "★ " + hero.get_rarity_label()

	# Color de rareza
	var rarity_color := hero.get_rarity_color()
	rarity_label.modulate = rarity_color
	if rarity_glow:
		rarity_glow.color = Color(rarity_color, 0.4)

	# Insignia de nuevo
	if new_badge:
		new_badge.visible = not is_duplicate

	# Partículas para legendarios
	if shine_particles:
		shine_particles.emitting = (hero.rarity == HeroData.Rarity.LEGENDARIO)

	# Animación de entrada según rareza
	_play_reveal_animation(hero.rarity)

func _play_reveal_animation(rarity: HeroData.Rarity) -> void:
	match rarity:
		HeroData.Rarity.LEGENDARIO:
			var tween := create_tween()
			tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		HeroData.Rarity.EPICO:
			var tween := create_tween()
			tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
