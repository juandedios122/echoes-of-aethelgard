## HeroRosterCard.gd
## Tarjeta de héroe mejorada para el grid de la colección
extends Button

@onready var card_panel: PanelContainer = $CardPanel
@onready var portrait: TextureRect = $CardPanel/VBoxContainer/PortraitPanel/Portrait
@onready var glow_effect: ColorRect = $CardPanel/VBoxContainer/PortraitPanel/GlowEffect
@onready var locked_overlay: ColorRect = $CardPanel/VBoxContainer/PortraitPanel/LockedOverlay
@onready var stars_label: Label = $CardPanel/VBoxContainer/PortraitPanel/StarsContainer/StarsLabel
@onready var name_label: Label = $CardPanel/VBoxContainer/InfoPanel/InfoVBox/NameLabel
@onready var rarity_label: Label = $CardPanel/VBoxContainer/InfoPanel/InfoVBox/RarityLabel
@onready var level_label: Label = $CardPanel/VBoxContainer/InfoPanel/InfoVBox/LevelLabel
@onready var selection_border: ColorRect = $SelectionBorder

var hero_data: HeroData
var is_selected: bool = false
var hover_tween: Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(hero: HeroData, is_owned: bool) -> void:
	hero_data = hero
	
	# Configurar retrato
	if hero.portrait:
		portrait.texture = hero.portrait
	
	# Configurar nombre con color de rareza
	name_label.text = hero.hero_name
	name_label.add_theme_color_override("font_color", hero.get_rarity_color())
	
	# Configurar rareza
	rarity_label.text = hero.get_rarity_label()
	rarity_label.add_theme_color_override("font_color", hero.get_rarity_color())
	
	# Configurar estrellas y nivel
	if is_owned:
		var level: int = GameManager.player_data.get_hero_level(hero.hero_id)
		var hero_info: Dictionary = GameManager.player_data.owned_heroes[hero.hero_id]
		var stars: int = hero_info.get("stars", 1)
		
		# Mostrar estrellas
		stars_label.text = "⭐".repeat(stars)
		stars_label.visible = true
		
		level_label.text = "Nv. %d" % level
		level_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.5, 1))
		locked_overlay.visible = false
		
		# Efecto de brillo para héroes de alta rareza
		if hero.rarity >= HeroData.Rarity.EPICO:
			glow_effect.visible = true
			glow_effect.color = hero.get_rarity_color()
			glow_effect.color.a = 0.2
	else:
		stars_label.visible = false
		level_label.text = "Bloqueado"
		level_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.5, 1))
		locked_overlay.visible = true
		# Oscurecer el retrato para héroes bloqueados
		portrait.modulate = Color(0.4, 0.4, 0.4, 1)
	
	# Estilo del panel según rareza
	_apply_card_style(hero, is_owned)

func _apply_card_style(hero: HeroData, is_owned: bool) -> void:
	# Estilo medieval oscuro con bordes decorativos
	var style := StyleBoxFlat.new()
	
	if is_owned:
		# Fondo madera oscura para héroes desbloqueados
		style.bg_color = Color(0.18, 0.14, 0.10, 0.98)
		style.border_color = hero.get_rarity_color()
		style.set_border_width_all(3)
	else:
		# Fondo muy oscuro para héroes bloqueados
		style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
		style.border_color = Color(0.25, 0.25, 0.25, 1)
		style.set_border_width_all(2)
	
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	# Sombra para profundidad
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 8
	style.shadow_offset = Vector2(2, 3)
	
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Estilo del panel de info - más oscuro en la parte inferior
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	info_style.corner_radius_bottom_left = 4
	info_style.corner_radius_bottom_right = 4
	$CardPanel/VBoxContainer/InfoPanel.add_theme_stylebox_override("panel", info_style)

func set_selected(selected: bool) -> void:
	is_selected = selected
	selection_border.visible = selected
	
	if selected:
		selection_border.color = Color(0.7, 0.6, 0.45, 1)  # Bronce
		
		# Animación de pulso más suave
		var pulse_tween: Tween = create_tween().set_loops()
		pulse_tween.tween_property(selection_border, "modulate:a", 0.7, 0.6).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_property(selection_border, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_IN_OUT)
		
		# Escalar ligeramente la tarjeta seleccionada
		var scale_tween: Tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.2).set_ease(Tween.EASE_OUT)
	else:
		# Restaurar escala normal
		var scale_tween: Tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)

func _on_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(card_panel, "modulate:a", 1.0, 0.2)
	
	# Efecto de brillo en hover
	if glow_effect.visible:
		hover_tween.tween_property(glow_effect, "modulate:a", 0.6, 0.2)

func _on_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(card_panel, "modulate:a", 0.95, 0.2)
	
	if glow_effect.visible:
		hover_tween.tween_property(glow_effect, "modulate:a", 0.3, 0.2)
