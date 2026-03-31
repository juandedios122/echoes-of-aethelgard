## HeroRosterScreen.gd
## Pantalla de colección de héroes con UI estilo Dragon Ball Legends
extends Control

@onready var back_button: Button = $MarginContainer/VBoxContainer/TopBar/BackButton
@onready var hero_grid: GridContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/ScrollContainer/HeroGrid
@onready var all_button: Button = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/FilterButtons/AllButton
@onready var owned_button: Button = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/FilterButtons/OwnedButton
@onready var detail_content: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroDetailPanel/ScrollContainer/DetailContent
@onready var no_selection_label: Label = $MarginContainer/VBoxContainer/ContentContainer/HeroDetailPanel/ScrollContainer/DetailContent/NoSelectionLabel
@onready var background_gradient: ColorRect = $BackgroundGradient

const HERO_CARD_SCENE := preload("res://scenes/ui/HeroRosterCard.tscn")

var all_heroes: Array[HeroData] = []
var current_filter: String = "all"
var selected_hero: HeroData = null

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	all_button.pressed.connect(func(): _apply_filter("all"))
	owned_button.pressed.connect(func(): _apply_filter("owned"))
	
	_setup_animated_background()
	_load_all_heroes()
	_populate_hero_grid()
	
	# Reproducir música del menú (misma que main menu)
	AudioManager.play_music("menu_theme", 1.0)

func _setup_animated_background() -> void:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.1, 0.05, 0.2, 0.3))
	gradient.add_point(0.5, Color(0.2, 0.1, 0.3, 0.2))
	gradient.add_point(1.0, Color(0.15, 0.1, 0.25, 0.3))
	
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(1, 1)
	
	background_gradient.material = ShaderMaterial.new()

func _load_all_heroes() -> void:
	var hero_paths := [
		"res://resources/heroes_data/aethan_paladin.tres",
		"res://resources/heroes_data/aldric_archimago.tres",
		"res://resources/heroes_data/gorn_barbaro.tres",
		"res://resources/heroes_data/kael_soldado.tres",
		"res://resources/heroes_data/lyra_arquera.tres",
		"res://resources/heroes_data/mira_sanadora.tres",
		"res://resources/heroes_data/seraphel_jueza.tres",
		"res://resources/heroes_data/theron_cazador.tres",
		"res://resources/heroes_data/varra_mercenaria.tres",
		"res://resources/heroes_data/vex_nigromante.tres",
	]
	
	for path in hero_paths:
		var hero: HeroData = load(path)
		if hero:
			all_heroes.append(hero)

func _populate_hero_grid() -> void:
	for child in hero_grid.get_children():
		child.queue_free()
	
	var filtered_heroes := _get_filtered_heroes()
	
	for hero in filtered_heroes:
		var card := HERO_CARD_SCENE.instantiate()
		hero_grid.add_child(card)
		card.setup(hero, GameManager.player_data.has_hero(hero.hero_id))
		card.pressed.connect(_on_hero_selected.bind(hero))

func _get_filtered_heroes() -> Array[HeroData]:
	if current_filter == "owned":
		return all_heroes.filter(func(h): return GameManager.player_data.has_hero(h.hero_id))
	return all_heroes

func _apply_filter(filter: String) -> void:
	current_filter = filter
	_populate_hero_grid()

func _on_hero_selected(hero: HeroData) -> void:
	selected_hero = hero
	_display_hero_details(hero)

func _display_hero_details(hero: HeroData) -> void:
	for child in detail_content.get_children():
		child.queue_free()
	
	var is_owned := GameManager.player_data.has_hero(hero.hero_id)
	var hero_level: int = GameManager.player_data.get_hero_level(hero.hero_id) if is_owned else 1
	
	# Header con nombre y título - Estilo DBL
	_create_hero_header(hero, hero_level, is_owned)
	
	_add_separator(Color(0.4, 0.35, 0.2, 0.5))
	
	# Estado de desbloqueo o información de nivel
	if not is_owned:
		_create_locked_display()
	else:
		_create_level_display(hero, hero_level)
		_create_exp_bar(hero.hero_id, hero_level)
		_create_stars_display(hero)
	
	_add_separator(Color(0.4, 0.35, 0.2, 0.5))
	
	# Estadísticas con estilo visual mejorado
	_create_stats_section(hero, hero_level)
	
	_add_separator(Color(0.4, 0.35, 0.2, 0.5))
	
	# Lore
	_create_lore_section(hero)
	
	# Botones de acción
	if is_owned:
		_add_separator(Color(0.4, 0.35, 0.2, 0.5))
		_create_action_buttons(hero, hero_level)

func _create_hero_header(hero: HeroData, level: int, is_owned: bool) -> void:
	# Nombre con efecto de brillo
	var name_label := Label.new()
	name_label.text = hero.hero_name.to_upper()
	name_label.add_theme_color_override("font_color", hero.get_rarity_color())
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("outline_size", 6)
	name_label.add_theme_font_size_override("font_size", 42)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(name_label)
	
	# Título
	var title_label := Label.new()
	title_label.text = hero.title
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5, 1))
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(title_label)
	
	# Rareza y facción con iconos
	var info_label := Label.new()
	info_label.text = "✦ %s | %s ✦" % [hero.get_rarity_label(), hero.get_faction_label()]
	info_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1))
	info_label.add_theme_font_size_override("font_size", 19)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(info_label)
	
	# Nivel actual (si está desbloqueado)
	if is_owned:
		var level_badge := _create_level_badge(level)
		detail_content.add_child(level_badge)

func _create_level_badge(level: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.3, 0.8)
	style.border_color = Color(1, 0.8, 0.3, 1)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = "  LV. %d  " % level
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1))
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	
	return panel

func _create_locked_display() -> void:
	var locked_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.1, 0.1, 0.6)
	style.border_color = Color(0.8, 0.3, 0.3, 1)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	locked_panel.add_theme_stylebox_override("panel", style)
	
	var locked_label := Label.new()
	locked_label.text = "  🔒 HÉROE NO DESBLOQUEADO  "
	locked_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	locked_label.add_theme_font_size_override("font_size", 28)
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_panel.add_child(locked_label)
	
	detail_content.add_child(locked_panel)

func _create_level_display(_hero: HeroData, level: int) -> void:
	var level_container := HBoxContainer.new()
	level_container.alignment = BoxContainer.ALIGNMENT_CENTER
	detail_content.add_child(level_container)
	
	var level_label := Label.new()
	level_label.text = "NIVEL %d / 60" % level
	level_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1))
	level_label.add_theme_color_override("font_outline_color", Color(0, 0.3, 0, 1))
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.add_theme_font_size_override("font_size", 32)
	level_container.add_child(level_label)

func _create_exp_bar(hero_id: String, level: int) -> void:
	if level >= 60:
		var max_label := Label.new()
		max_label.text = "✨ NIVEL MÁXIMO ALCANZADO ✨"
		max_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
		max_label.add_theme_font_size_override("font_size", 24)
		max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_content.add_child(max_label)
		return
	
	var current_exp: int = GameManager.player_data.get_hero_exp(hero_id)
	var exp_needed: int = GameManager.player_data.get_exp_for_next_level(level)
	var exp_percent := float(current_exp) / float(exp_needed) * 100.0
	
	# Panel contenedor para la barra de EXP
	var exp_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.1, 0.2, 0.8)
	panel_style.border_color = Color(0.5, 0.4, 0.3, 1)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	exp_panel.add_theme_stylebox_override("panel", panel_style)
	detail_content.add_child(exp_panel)
	
	var exp_vbox := VBoxContainer.new()
	exp_vbox.add_theme_constant_override("separation", 8)
	exp_panel.add_child(exp_vbox)
	
	# Etiqueta de EXP
	var exp_title := Label.new()
	exp_title.text = "⚡ EXPERIENCIA"
	exp_title.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	exp_title.add_theme_font_size_override("font_size", 20)
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_vbox.add_child(exp_title)
	
	# Barra de progreso estilo DBL
	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 35)
	progress_bar.max_value = 100
	progress_bar.value = exp_percent
	progress_bar.show_percentage = false
	
	# Estilo de la barra
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.15, 0.1, 1)
	bar_bg.corner_radius_top_left = 5
	bar_bg.corner_radius_top_right = 5
	bar_bg.corner_radius_bottom_left = 5
	bar_bg.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(1, 0.7, 0.2, 1)
	bar_fill.corner_radius_top_left = 5
	bar_fill.corner_radius_top_right = 5
	bar_fill.corner_radius_bottom_left = 5
	bar_fill.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	
	exp_vbox.add_child(progress_bar)
	
	# Texto de progreso
	var progress_text := Label.new()
	progress_text.text = "%d / %d EXP (%.1f%%)" % [current_exp, exp_needed, exp_percent]
	progress_text.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
	progress_text.add_theme_font_size_override("font_size", 18)
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_vbox.add_child(progress_text)

func _create_stars_display(hero: HeroData) -> void:
	var hero_info: Dictionary = GameManager.player_data.owned_heroes[hero.hero_id]
	var stars: int = hero_info.get("stars", 1)
	var copies: int = hero_info.get("copies", 1)
	
	# Panel de estrellas
	var stars_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.25, 0.7)
	style.border_color = Color(1, 0.8, 0.2, 0.8)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	stars_panel.add_theme_stylebox_override("panel", style)
	detail_content.add_child(stars_panel)
	
	var stars_vbox := VBoxContainer.new()
	stars_vbox.add_theme_constant_override("separation", 10)
	stars_panel.add_child(stars_vbox)
	
	# Estrellas visuales
	var stars_label := Label.new()
	var filled_stars := "⭐".repeat(stars)
	var empty_stars := "☆".repeat(5 - stars)
	stars_label.text = filled_stars + empty_stars
	stars_label.add_theme_font_size_override("font_size", 32)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_vbox.add_child(stars_label)
	
	# Información de copias
	var copies_label := Label.new()
	if stars < 5:
		var needed: int = GameManager.player_data.get_ascension_cost(hero.hero_id)
		copies_label.text = "Copias: %d / %d para ★%d" % [copies, needed, stars + 1]
		copies_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1))
	else:
		copies_label.text = "✨ MÁXIMO ALCANZADO ✨ (Copias: %d)" % copies
		copies_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	copies_label.add_theme_font_size_override("font_size", 18)
	copies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_vbox.add_child(copies_label)

func _create_stats_section(hero: HeroData, level: int) -> void:
	var stats_title := Label.new()
	stats_title.text = "📊 ESTADÍSTICAS"
	stats_title.add_theme_color_override("font_color", Color(1, 0.85, 0.5, 1))
	stats_title.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0, 1))
	stats_title.add_theme_constant_override("outline_size", 2)
	stats_title.add_theme_font_size_override("font_size", 28)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(stats_title)
	
	# Grid de stats con estilo
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 12)
	detail_content.add_child(stats_grid)
	
	_add_stat_to_grid(stats_grid, "❤️ HP", hero.get_hp_at_level(level), Color(1, 0.3, 0.3, 1))
	_add_stat_to_grid(stats_grid, "⚔️ ATK", hero.get_atk_at_level(level), Color(1, 0.6, 0.2, 1))
	_add_stat_to_grid(stats_grid, "🛡️ DEF", hero.get_def_at_level(level), Color(0.4, 0.7, 1, 1))
	_add_stat_to_grid(stats_grid, "⚡ SPD", hero.base_spd + (level - 1) * 2, Color(1, 1, 0.3, 1))
	_add_stat_to_grid(stats_grid, "💥 Crit Rate", "%.1f%%" % (hero.base_crit_rate * 100), Color(1, 0.5, 0.8, 1))
	_add_stat_to_grid(stats_grid, "💢 Crit Dmg", "%.0f%%" % (hero.base_crit_dmg * 100), Color(1, 0.3, 0.5, 1))

func _add_stat_to_grid(grid: GridContainer, label_text: String, value, color: Color) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 1))
	label.add_theme_font_size_override("font_size", 20)
	grid.add_child(label)
	
	var value_label := Label.new()
	value_label.text = str(value)
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	value_label.add_theme_constant_override("outline_size", 2)
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)

func _create_lore_section(hero: HeroData) -> void:
	var lore_title := Label.new()
	lore_title.text = "📜 HISTORIA"
	lore_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1))
	lore_title.add_theme_font_size_override("font_size", 26)
	detail_content.add_child(lore_title)
	
	var lore_label := Label.new()
	lore_label.text = hero.lore_text if hero.lore_text else "Historia no disponible."
	lore_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75, 1))
	lore_label.add_theme_font_size_override("font_size", 17)
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_content.add_child(lore_label)

func _create_action_buttons(hero: HeroData, level: int) -> void:
	# Botón de subir nivel
	if level < 60:
		var level_up_button := _create_styled_button(
			"⬆️ SUBIR NIVEL",
			Color(0.2, 0.6, 0.3, 1),
			Color(0.3, 1, 0.4, 1)
		)
		
		var cost: int = GameManager.player_data.get_level_up_cost(hero.hero_id)
		level_up_button.text += " (Costo: %d Oro)" % cost
		level_up_button.pressed.connect(_on_level_up_pressed.bind(hero))
		
		if GameManager.player_data.gold < cost:
			level_up_button.disabled = true
			level_up_button.text += "\n💰 Oro insuficiente: %d" % GameManager.player_data.gold
		
		detail_content.add_child(level_up_button)
	
	# Botón de ascensión
	var hero_info: Dictionary = GameManager.player_data.owned_heroes[hero.hero_id]
	var stars: int = hero_info.get("stars", 1)
	var copies: int = hero_info.get("copies", 1)
	
	if stars < 5:
		var ascension_cost: int = GameManager.player_data.get_ascension_cost(hero.hero_id)
		var ascend_button := _create_styled_button(
			"✨ ASCENDER A %d★" % (stars + 1),
			Color(0.5, 0.3, 0.7, 1),
			Color(1, 0.8, 0.3, 1)
		)
		ascend_button.text += " (%d copias)" % ascension_cost
		ascend_button.pressed.connect(_on_ascend_pressed.bind(hero))
		
		if copies < ascension_cost:
			ascend_button.disabled = true
			ascend_button.text += "\n❌ Faltan %d copias" % (ascension_cost - copies)
		
		detail_content.add_child(ascend_button)

func _create_styled_button(text: String, bg_color: Color, border_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 70)
	button.add_theme_font_size_override("font_size", 22)
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style := style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	return button

func _add_separator(color: Color) -> void:
	var separator := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	separator.add_theme_stylebox_override("separator", style)
	separator.add_theme_constant_override("separation", 3)
	detail_content.add_child(separator)

func _on_level_up_pressed(hero: HeroData) -> void:
	var cost: int = GameManager.player_data.get_level_up_cost(hero.hero_id)
	
	if GameManager.player_data.gold >= cost:
		GameManager.player_data.gold -= cost
		if GameManager.player_data.level_up_hero(hero.hero_id):
			GameManager.save_game()
			_display_hero_details(hero)
			var new_level: int = GameManager.player_data.get_hero_level(hero.hero_id)
			print("[HeroRoster] %s subió a nivel %d" % [hero.hero_name, new_level])
	else:
		print("[HeroRoster] Oro insuficiente para subir de nivel")

func _on_ascend_pressed(hero: HeroData) -> void:
	if GameManager.player_data.ascend_hero(hero.hero_id):
		GameManager.save_game()
		_display_hero_details(hero)
		var hero_info: Dictionary = GameManager.player_data.owned_heroes[hero.hero_id]
		var stars: int = hero_info.get("stars", 1)
		print("[HeroRoster] %s ascendió a %d estrellas" % [hero.hero_name, stars])
	else:
		print("[HeroRoster] No se pudo ascender el héroe")

func _on_back_pressed() -> void:
	GameManager.go_to_scene("main_menu")
