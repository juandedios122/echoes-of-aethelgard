## HeroRosterScreen.gd
## Pantalla de colección de héroes con UI estilo Dragon Ball Legends
extends Control

@onready var back_button: TextureButton = $MarginContainer/VBoxContainer/TopBar/BackButton
@onready var hero_grid: GridContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/ScrollContainer/HeroGrid
@onready var hero_list_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel
@onready var hero_detail_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroDetailPanel
@onready var all_button: TextureButton = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/FilterButtons/AllButton
@onready var owned_button: TextureButton = $MarginContainer/VBoxContainer/ContentContainer/HeroListPanel/VBoxContainer/FilterButtons/OwnedButton
@onready var detail_content: VBoxContainer = $MarginContainer/VBoxContainer/ContentContainer/HeroDetailPanel/ScrollContainer/DetailContent

const HERO_CARD_SCENE := preload("res://scenes/ui/HeroRosterCard.tscn")

var all_heroes: Array[HeroData] = []
var current_filter: String = "all"
var selected_hero: HeroData = null
var selected_card: Button = null
var current_detail_tab: String = "Habilidades"

func _ready() -> void:
	_init_ui()
	_load_collection()
	_apply_filter("all")
	AudioManager.play_music("menu_theme", 1.0)
	get_viewport().size_changed.connect(_update_grid_columns)

func _init_ui() -> void:
	back_button.pressed.connect(_on_back_pressed)
	all_button.pressed.connect(func(): _apply_filter("all"))
	owned_button.pressed.connect(func(): _apply_filter("owned"))
	all_button.toggle_mode = true
	owned_button.toggle_mode = true

	if ResourceLoader.exists("res://assets/ui/Todos.png"):
		all_button.focus_mode = Control.FOCUS_NONE
	if ResourceLoader.exists("res://assets/ui/Desbloqueados.png"):
		owned_button.focus_mode = Control.FOCUS_NONE

	_create_collection_banner()
	_update_filter_button_states()
	_setup_panel_styles()
	_update_grid_columns()

	hero_list_panel.size_flags_horizontal = Control.SIZE_FILL
	hero_list_panel.custom_minimum_size = Vector2(380, 0)
	hero_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	print("[HeroRosterScreen] hero_list_panel size_flags:", hero_list_panel.size_flags_horizontal, hero_list_panel.size_flags_vertical)
	print("[HeroRosterScreen] hero_grid size_flags:", hero_grid.size_flags_horizontal, hero_grid.size_flags_vertical)

func _load_collection() -> void:
	print("[HeroRosterScreen] ======== _load_collection INICIO ========")
	all_heroes = HeroCollectionService.load_all_heroes()
	print("[HeroRosterScreen] total heroes cargados en all_heroes:", all_heroes.size())
	if all_heroes.size() > 0:
		print("[HeroRosterScreen] Nombres de héroes:", all_heroes.map(func(h): return h.hero_name))
	else:
		push_error("[HeroRosterScreen] ⚠️ ¡NO se cargaron héroes!")

func _setup_panel_styles() -> void:
	# Cargar textura de fondo para los paneles
	var _bg_texture := load("res://assets/ui/Fondo.png") as Texture2D
	
	
	# Estilo para el panel de detalles - estilo pergamino claro
	
func _create_collection_banner() -> void:
	# El nodo HeroCollectionBanner está bajo la raíz de la pantalla, no dentro de MarginContainer/VBoxContainer
	var banner := $HeroCollectionBanner
	if not banner:
		banner = $MarginContainer/VBoxContainer/HeroCollectionBanner if has_node("MarginContainer/VBoxContainer/HeroCollectionBanner") else null
	if banner and ResourceLoader.exists("res://assets/ui/Barra_Coleccion_Heroes.png"):
		banner.texture = load("res://assets/ui/Barra_Coleccion_Heroes.png")
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner.size_flags_vertical = Control.SIZE_FILL
		banner.custom_minimum_size = Vector2(0, 110)
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.visible = true

func _update_grid_columns() -> void:
	var available_width: float = hero_list_panel.size.x - 60  # Restar márgenes
	var card_width: float = 140.0
	var spacing: float = 12.0
	
	# Calcular columnas óptimas basado en el ancho disponible
	var optimal_columns: int = max(1, int(available_width / (card_width + spacing)))
	hero_grid.columns = clamp(optimal_columns, 2, 3)

# Carga de datos ahora delegada a HeroCollectionService
func _load_all_heroes() -> void:
	# Método legado, mantenido por compatibilidad pero sin efecto.
	# Se utiliza _load_collection() a partir de la versión reorganizada.
	pass

func _populate_hero_grid() -> void:
	print("[HeroRosterScreen] ======== _populate_hero_grid INICIO ========")
	print("[HeroRosterScreen] all_heroes.size() = ", all_heroes.size())
	print("[HeroRosterScreen] current_filter = ", current_filter)
	
	for child in hero_grid.get_children():
		child.queue_free()
	
	print("[HeroRosterScreen] Grid limpiado")

	# Solo configurar en _init_ui, aquí no tocamos layout
	var filtered_heroes := HeroCollectionService.filter_heroes(all_heroes, current_filter)
	print("[HeroRosterScreen] filtered_heroes.size() = ", filtered_heroes.size())
	print("[HeroRosterScreen] Héroes filtrados: ", filtered_heroes.map(func(h): return h.hero_name))

	for hero in filtered_heroes:
		var card := HERO_CARD_SCENE.instantiate()
		hero_grid.add_child(card)
		card.modulate = Color(1, 1, 1, 1)
		card.custom_minimum_size = Vector2(140, 220)
		card.setup(hero, GameManager.player_data.has_hero(hero.hero_id))
		card.pressed.connect(_on_hero_selected.bind(hero, card))

		# Animación de entrada escalonada
		card.modulate.a = 0
		card.scale = Vector2(0.8, 0.8)
		var delay := hero_grid.get_child_count() * 0.05
		var tween := create_tween()
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(delay)
		tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_delay(delay).set_ease(Tween.EASE_OUT)

		# Nota de debug por cada card
		print("[HeroRosterScreen] añadida card:", hero.hero_name)

	if hero_grid.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "No se encontraron héroes (comprueba si los datos están cargados)."
		empty_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6, 1))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_grid.add_child(empty_label)
		print("[HeroRosterScreen] HeroGrid está vacío")
	else:
		# Seleccionar automáticamente el primer héroe filtrado para mostrar detalles
		var first_card := hero_grid.get_child(0)
		if first_card and first_card.has_method("set_selected"):
			first_card.set_selected(true)
			selected_card = first_card
			selected_hero = filtered_heroes[0] if filtered_heroes.size() > 0 else null
			if selected_hero:
				_display_hero_details(selected_hero)
		print("[HeroRosterScreen] HeroGrid tiene ", hero_grid.get_child_count(), "cards")

func _apply_filter(filter: String) -> void:
	print("[HeroRosterScreen] ======== _apply_filter INICIO ========")
	print("[HeroRosterScreen] Filtro solicitado: %s" % filter)
	current_filter = filter
	_update_filter_button_states()
	print("[HeroRosterScreen] Llamando a _populate_hero_grid()...")
	_populate_hero_grid()
	print("[HeroRosterScreen] _populate_hero_grid() completado")
	print("[HeroRosterScreen] ======== _apply_filter FIN ========")

func _update_filter_button_states() -> void:
	# Cambiar estado visual de toggle sin tocar la señal 'pressed'
	all_button.set_pressed(current_filter == "all")
	owned_button.set_pressed(current_filter == "owned")

	if current_filter == "all":
		all_button.modulate = Color(1, 1, 1, 1)
		owned_button.modulate = Color(0.82, 0.82, 0.82, 0.9)
	else:
		all_button.modulate = Color(0.82, 0.82, 0.82, 0.9)
		owned_button.modulate = Color(1, 1, 1, 1)

	# Texto alternativo para accesibilidad
	# Se puede añadir aquí si se quiere mostrar un Label de estado

func _on_hero_selected(hero: HeroData, card: Button) -> void:
	# Deseleccionar tarjeta anterior
	if selected_card and selected_card.has_method("set_selected"):
		selected_card.set_selected(false)
	
	# Seleccionar nueva tarjeta
	selected_hero = hero
	selected_card = card
	if card.has_method("set_selected"):
		card.set_selected(true)
	
	# Empezar siempre en Habilidades al seleccionar un héroe nuevo
	current_detail_tab = "Habilidades"
	_display_hero_details(hero)

func _display_hero_details(hero: HeroData) -> void:
	for child in detail_content.get_children():
		child.queue_free()
	
	var is_owned := GameManager.player_data.has_hero(hero.hero_id)
	var hero_level: int = GameManager.player_data.get_hero_level(hero.hero_id) if is_owned else 1
	
	# Header con nombre y título
	_create_hero_header(hero, hero_level, is_owned)
	
	# Pestañas de navegación (Habilidades, Historia, Equipo)
	_create_tab_navigation(hero, is_owned)
	
	_add_separator(Color(0.35, 0.28, 0.20, 0.6))
	
	# Estado de desbloqueo o información de nivel
	if not is_owned:
		_create_locked_display()
	else:
		# Mostrar contenido de la pestaña activa
		_update_detail_tab_content(hero, hero_level)
	
	# Botones de acción
	if is_owned:
		_add_separator(Color(0.35, 0.28, 0.20, 0.6))
		_create_action_buttons(hero, hero_level)

func _create_hero_header(hero: HeroData, level: int, is_owned: bool) -> void:
	# Panel contenedor con fondo decorativo
	
	
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	

	
	
	
	# Nivel y barra de progreso
	if is_owned:
		var level_container := HBoxContainer.new()
		level_container.alignment = BoxContainer.ALIGNMENT_CENTER
		level_container.add_theme_constant_override("separation", 8)
		header_vbox.add_child(level_container)
		
		var level_icon := Label.new()
		level_icon.text = "⚡"
		level_icon.add_theme_font_size_override("font_size", 20)
		level_container.add_child(level_icon)
		
		var level_text := Label.new()
		level_text.text = "Nivel %d / 60" % level
		level_text.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
		level_text.add_theme_font_size_override("font_size", 18)
		level_container.add_child(level_text)
		
		# Barra de experiencia compacta
		_create_compact_exp_bar(hero.hero_id, level, header_vbox)

func _create_hero_portrait(hero: HeroData, is_owned: bool) -> void:
	var portrait_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	panel_style.border_color = hero.get_rarity_color()
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = hero.get_rarity_color()
	panel_style.shadow_color.a = 0.4
	panel_style.shadow_size = 12
	portrait_panel.add_theme_stylebox_override("panel", panel_style)
	detail_content.add_child(portrait_panel)
	
	# Contenedor centrado
	var center_container := CenterContainer.new()
	portrait_panel.add_child(center_container)
	
	# Imagen del retrato
	var portrait_rect := TextureRect.new()
	portrait_rect.texture = hero.portrait
	portrait_rect.custom_minimum_size = Vector2(256, 256)
	portrait_rect.expand = true
	portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Si está bloqueado, aplicar filtro oscuro
	if not is_owned:
		portrait_rect.modulate = Color(0.3, 0.3, 0.3, 1)
	
	center_container.add_child(portrait_rect)

func _create_compact_exp_bar(hero_id: String, level: int, container: VBoxContainer) -> void:
	if level >= 60:
		return
	
	var current_exp: int = GameManager.player_data.get_hero_exp(hero_id)
	var exp_needed: int = GameManager.player_data.get_exp_for_next_level(level)
	var exp_percent := float(current_exp) / float(exp_needed) * 100.0
	
	# Barra de progreso compacta
	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 20)
	progress_bar.max_value = 100
	progress_bar.value = exp_percent
	progress_bar.show_percentage = false
	
	# Estilo de la barra
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.10, 1)
	bar_bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.65, 0.50, 0.30, 1)
	bar_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	
	container.add_child(progress_bar)
	
	# Texto de progreso pequeño
	var progress_text := Label.new()
	progress_text.text = "%d / %d EXP" % [current_exp, exp_needed]
	progress_text.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60, 1))
	progress_text.add_theme_font_size_override("font_size", 14)
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(progress_text)

func _create_tab_navigation(hero: HeroData, _is_owned: bool) -> void:
	# Contenedor de pestañas con imagen decorativa
	var tab_frame := PanelContainer.new()
	var toolbar_image_path := "res://assets/ui/Barra_Equipamientos.png"
	if ResourceLoader.exists(toolbar_image_path):
		var tab_style := _create_decorative_stylebox_from_image(toolbar_image_path, 10, Color(1,1,1,0.92))
		tab_frame.add_theme_stylebox_override("panel", tab_style)
	else:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = Color(0.14, 0.1, 0.08, 0.9)
		fallback.border_color = Color(0.34, 0.25, 0.20, 1)
		fallback.set_border_width_all(2)
		fallback.set_corner_radius_all(8)
		tab_frame.add_theme_stylebox_override("panel", fallback)

	tab_frame.custom_minimum_size = Vector2(0, 120)
	tab_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(tab_frame)

	var tabs_container := HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 8)
	# Ajuste de margenes internos para mejorar vista
	tabs_container.add_theme_constant_override("margin_left", 20)
	tabs_container.add_theme_constant_override("margin_right", 20)
	tab_frame.add_child(tabs_container)

	# Pestañas
	var abilities_tab := _create_tab_button("Habilidades", current_detail_tab == "Habilidades")
	abilities_tab.pressed.connect(func(): _on_detail_tab_changed("Habilidades", hero))
	tabs_container.add_child(abilities_tab)

	var history_tab := _create_tab_button("Historia", current_detail_tab == "Historia")
	history_tab.pressed.connect(func(): _on_detail_tab_changed("Historia", hero))
	tabs_container.add_child(history_tab)

	var equipment_tab := _create_tab_button("Equipo", current_detail_tab == "Equipo")
	equipment_tab.pressed.connect(func(): _on_detail_tab_changed("Equipo", hero))
	tabs_container.add_child(equipment_tab)

func _create_tab_button(text: String, is_active: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 40)
	button.add_theme_font_size_override("font_size", 16)
	
	var style := StyleBoxFlat.new()
	if is_active:
		style.bg_color = Color(0.25, 0.20, 0.15, 1)
		style.border_color = Color(0.55, 0.45, 0.35, 1)
		button.add_theme_color_override("font_color", Color(0.95, 0.90, 0.80, 1))
	else:
		style.bg_color = Color(0.15, 0.12, 0.10, 1)
		style.border_color = Color(0.35, 0.28, 0.20, 1)
		button.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55, 1))
	
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	
	return button

func _on_detail_tab_changed(tab: String, hero: HeroData) -> void:
	current_detail_tab = tab
	_display_hero_details(hero)

func _create_decorative_stylebox_from_image(image_path: String, margin: int = 12, tint: Color = Color(1,1,1,1)) -> StyleBoxTexture:
	var stylebox := StyleBoxTexture.new()
	stylebox.texture = load(image_path)
	stylebox.draw_center = true
	stylebox.content_margin_left = margin
	stylebox.content_margin_right = margin
	stylebox.content_margin_top = margin
	stylebox.content_margin_bottom = margin
	stylebox.modulate_color = tint
	return stylebox

func _update_detail_tab_content(hero: HeroData, hero_level: int) -> void:
	match current_detail_tab:
		"Habilidades":
			_create_abilities_tab_content(hero, hero_level)
		"Historia":
			_create_history_tab_content(hero)
		"Equipo":
			_create_equipment_tab_content(hero)
		_:
			_create_abilities_tab_content(hero, hero_level)

func _create_abilities_tab_content(hero: HeroData, hero_level: int) -> void:
	# Panel de estadísticas de combate
	_create_compact_stats_section(hero, hero_level)
	
	_add_separator(Color(0.35, 0.28, 0.20, 0.6))
	
	# Panel de habilidades
	_create_abilities_section(hero)

func _create_history_tab_content(hero: HeroData) -> void:
	_create_lore_section(hero)

func _create_equipment_tab_content(_hero: HeroData) -> void:
	var equip_panel := PanelContainer.new()
	var equip_image_path := "res://assets/ui/Barra_Equipamientos.png"
	if ResourceLoader.exists(equip_image_path):
		var equip_style := _create_decorative_stylebox_from_image(equip_image_path, 14, Color(1,1,1,0.90))
		equip_panel.add_theme_stylebox_override("panel", equip_style)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
		style.border_color = Color(0.5, 0.4, 0.3, 1)
		style.set_border_width_all(2)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		equip_panel.add_theme_stylebox_override("panel", style)
	end
	detail_content.add_child(equip_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	equip_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🛠️ EQUIPO"
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7, 1))
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var info := Label.new()
	info.text = "Aquí aparecerán los objetos equipados."
	info.add_theme_color_override("font_color", Color(0.88, 0.83, 0.74, 1))
	info.add_theme_font_size_override("font_size", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

func _create_compact_stats_section(hero: HeroData, level: int) -> void:
	# Priorizar barra decorativa si existe, después Fondo.png
	var banner_path := "res://assets/ui/Barra_Equipamientos.png"
	var panel_style := null

	if ResourceLoader.exists(banner_path):
		panel_style = _create_decorative_stylebox_from_image(banner_path, 12, Color(1,1,1,0.92))
	else:
		var bg_texture := load("res://assets/ui/Fondo.png") as Texture2D
		if bg_texture:
			panel_style = StyleBoxTexture.new()
			panel_style.texture = bg_texture
			panel_style.texture_margin_left = 15
			panel_style.texture_margin_right = 15
			panel_style.texture_margin_top = 15
			panel_style.texture_margin_bottom = 15
			panel_style.modulate_color = Color(0.28, 0.22, 0.18, 0.98)
		end
	end

	# Panel contenedor para las estadísticas
	var stats_panel := PanelContainer.new()

	if panel_style:
		stats_panel.add_theme_stylebox_override("panel", panel_style)
	else:
		panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.10, 0.08, 0.06, 0.98)
		panel_style.border_color = Color(0.40, 0.32, 0.24, 0.9)
		panel_style.set_border_width_all(2)
		panel_style.corner_radius_top_left = 8
		panel_style.corner_radius_top_right = 8
		panel_style.corner_radius_bottom_left = 8
		panel_style.corner_radius_bottom_right = 8
		panel_style.content_margin_left = 15
		panel_style.content_margin_right = 15
		panel_style.content_margin_top = 15
		panel_style.content_margin_bottom = 15
		stats_panel.add_theme_stylebox_override("panel", panel_style)
	
	detail_content.add_child(stats_panel)
	
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)
	
	var stats_title := Label.new()
	stats_title.text = "Estadísticas de Combate"
	stats_title.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
	stats_title.add_theme_color_override("font_outline_color", Color(0.15, 0.10, 0.05, 1))
	stats_title.add_theme_constant_override("outline_size", 2)
	stats_title.add_theme_font_size_override("font_size", 20)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(stats_title)
	
	# Grid de stats principales en 2 columnas
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 8)
	stats_vbox.add_child(stats_grid)
	
	_add_compact_stat(stats_grid, "❤️ HP:", hero.get_hp_at_level(level), Color(1, 0.4, 0.4, 1))
	_add_compact_stat(stats_grid, "⚔️ ATK:", hero.get_atk_at_level(level), Color(1, 0.6, 0.3, 1))
	_add_compact_stat(stats_grid, "🛡️ DEF:", hero.get_def_at_level(level), Color(0.5, 0.7, 1, 1))
	_add_compact_stat(stats_grid, "⚡ SPD:", hero.base_spd + (level - 1) * 2, Color(1, 1, 0.4, 1))
	
	# Stats secundarias
	var secondary_grid := GridContainer.new()
	secondary_grid.columns = 2
	secondary_grid.add_theme_constant_override("h_separation", 20)
	secondary_grid.add_theme_constant_override("v_separation", 8)
	stats_vbox.add_child(secondary_grid)
	
	_add_compact_stat(secondary_grid, "💥 Crit Rate:", "%.1f%%" % (hero.base_crit_rate * 100), Color(1, 0.6, 0.8, 1))
	_add_compact_stat(secondary_grid, "💢 Crit Dmg:", "%.0f%%" % (hero.base_crit_dmg * 100), Color(1, 0.4, 0.6, 1))

func _add_compact_stat(container: GridContainer, label_text: String, value, color: Color) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.80, 0.75, 0.65, 1))
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)
	
	var value_label := Label.new()
	value_label.text = str(value)
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	value_label.add_theme_constant_override("outline_size", 1)
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(value_label)

func _create_abilities_section(hero: HeroData) -> void:
	# Panel de habilidades
	var abilities_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.08, 0.06, 0.98)
	panel_style.border_color = Color(0.40, 0.32, 0.24, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	abilities_panel.add_theme_stylebox_override("panel", panel_style)
	detail_content.add_child(abilities_panel)
	
	var abilities_vbox := VBoxContainer.new()
	abilities_vbox.add_theme_constant_override("separation", 12)
	abilities_panel.add_child(abilities_vbox)
	
	var abilities_title := Label.new()
	abilities_title.text = "Habilidades"
	abilities_title.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
	abilities_title.add_theme_color_override("font_outline_color", Color(0.15, 0.10, 0.05, 1))
	abilities_title.add_theme_constant_override("outline_size", 2)
	abilities_title.add_theme_font_size_override("font_size", 20)
	abilities_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abilities_vbox.add_child(abilities_title)
	
	# Grid de habilidades (4 skills)
	var abilities_grid := HBoxContainer.new()
	abilities_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	abilities_grid.add_theme_constant_override("separation", 15)
	abilities_vbox.add_child(abilities_grid)
	
	# Mostrar las habilidades del héroe
	var skills := [hero.skill_basic, hero.skill_active, hero.skill_passive, hero.skill_ultimate]
	var skill_names := ["Básico", "Activa", "Pasiva", "Ultimate"]
	
	for i in skills.size():
		var skill: SkillData = skills[i]
		if skill:
			var ability_card := _create_ability_card(skill, skill_names[i])
			abilities_grid.add_child(ability_card)

func _create_ability_card(skill: SkillData, skill_type: String) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.10, 1)
	style.border_color = Color(0.45, 0.35, 0.25, 1)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(80, 80)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	# Icono de habilidad
	var icon_label := Label.new()
	var icon_map := {
		"Básico": "⚔️",
		"Activa": "💥",
		"Pasiva": "🌟",
		"Ultimate": "💫"
	}
	icon_label.text = icon_map.get(skill_type, "⚔️")
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)
	
	# Nombre de habilidad
	var name_label := Label.new()
	name_label.text = skill.skill_name if skill.skill_name else skill_type
	name_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	return card

func _create_level_badge(level: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.08, 0.95)  # Madera oscura
	style.border_color = Color(0.6, 0.5, 0.35, 1)  # Bronce
	style.set_border_width_all(3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0.4, 0.3, 0.2, 0.5)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	var icon := Label.new()
	icon.text = "⚡"
	icon.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon)
	
	var label := Label.new()
	label.text = "NIVEL %d" % level
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6, 1))  # Pergamino claro
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	
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
	level_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.5, 1))  # Verde musgo
	level_label.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.05, 1))
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.add_theme_font_size_override("font_size", 32)
	level_container.add_child(level_label)

func _create_exp_bar(hero_id: String, level: int) -> void:
	if level >= 60:
		var max_label := Label.new()
		max_label.text = "✨ NIVEL MÁXIMO ALCANZADO ✨"
		max_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 1))  # Oro viejo
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
	
	# Etiqueta de EXP con icono
	var exp_title := Label.new()
	exp_title.text = "⚡ EXPERIENCIA"
	exp_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 1))  # Oro viejo
	exp_title.add_theme_font_size_override("font_size", 22)
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
	bar_fill.bg_color = Color(0.7, 0.55, 0.35, 1)  # Bronce/cobre
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
	style.bg_color = Color(0.2, 0.15, 0.12, 0.7)  # Madera oscura
	style.border_color = Color(0.65, 0.55, 0.4, 0.8)  # Bronce envejecido
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
		copies_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.55, 1))  # Pergamino
	else:
		copies_label.text = "✨ MÁXIMO ALCANZADO ✨ (Copias: %d)" % copies
		copies_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 1))  # Oro viejo
	copies_label.add_theme_font_size_override("font_size", 18)
	copies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_vbox.add_child(copies_label)

func _create_stats_section(hero: HeroData, level: int) -> void:
	# Panel contenedor para las estadísticas
	var stats_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	panel_style.border_color = Color(0.5, 0.4, 0.6, 0.9)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	stats_panel.add_theme_stylebox_override("panel", panel_style)
	detail_content.add_child(stats_panel)
	
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 15)
	stats_panel.add_child(stats_vbox)
	
	var stats_title := Label.new()
	stats_title.text = "⚔ ESTADÍSTICAS DE COMBATE ⚔"
	stats_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.55, 1))  # Pergamino/bronce
	stats_title.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1, 1))
	stats_title.add_theme_constant_override("outline_size", 3)
	stats_title.add_theme_font_size_override("font_size", 28)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(stats_title)
	
	# Grid de stats con barras visuales
	var stats_grid := VBoxContainer.new()
	stats_grid.add_theme_constant_override("separation", 12)
	stats_vbox.add_child(stats_grid)
	
	_add_stat_bar(stats_grid, "❤️ HP", hero.get_hp_at_level(level), 5000, Color(1, 0.3, 0.3, 1))
	_add_stat_bar(stats_grid, "⚔️ ATK", hero.get_atk_at_level(level), 1000, Color(1, 0.6, 0.2, 1))
	_add_stat_bar(stats_grid, "🛡️ DEF", hero.get_def_at_level(level), 800, Color(0.4, 0.7, 1, 1))
	_add_stat_bar(stats_grid, "⚡ SPD", hero.base_spd + (level - 1) * 2, 200, Color(1, 1, 0.3, 1))
	
	# Stats secundarias en grid
	var secondary_grid := GridContainer.new()
	secondary_grid.columns = 2
	secondary_grid.add_theme_constant_override("h_separation", 30)
	secondary_grid.add_theme_constant_override("v_separation", 10)
	stats_vbox.add_child(secondary_grid)
	
	_add_stat_to_grid(secondary_grid, "💥 Crit Rate", "%.1f%%" % (hero.base_crit_rate * 100), Color(1, 0.5, 0.8, 1))
	_add_stat_to_grid(secondary_grid, "💢 Crit Dmg", "%.0f%%" % (hero.base_crit_dmg * 100), Color(1, 0.3, 0.5, 1))

func _add_stat_bar(container: VBoxContainer, label_text: String, value: int, max_value: int, color: Color) -> void:
	var stat_container := VBoxContainer.new()
	stat_container.add_theme_constant_override("separation", 5)
	container.add_child(stat_container)
	
	# Etiqueta y valor
	var header := HBoxContainer.new()
	stat_container.add_child(header)
	
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1))
	label.add_theme_font_size_override("font_size", 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	
	var value_label := Label.new()
	value_label.text = str(value)
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	value_label.add_theme_constant_override("outline_size", 2)
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)
	
	# Determinar qué textura usar según la estadística
	var texture_path: String = ""
	
	# Detectar el tipo de estadística
	if "HP" in label_text:
		texture_path = "res://assets/ui/Barra_Vida.png"
	elif "ATK" in label_text:
		texture_path = "res://assets/ui/Barra_Ataque.png"
	elif "DEF" in label_text:
		texture_path = "res://assets/ui/Barra_Defensa.png"
	elif "SPD" in label_text:
		texture_path = "res://assets/ui/Barra_Sped.png"
	
	if texture_path != "" and ResourceLoader.exists(texture_path):
		# Usar TextureProgressBar con la textura personalizada
		var texture_bar := TextureProgressBar.new()
		texture_bar.custom_minimum_size = Vector2(0, 50)
		texture_bar.max_value = max_value
		texture_bar.value = value
		texture_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		
		# Cargar la textura específica para esta estadística
		var bar_texture: Texture2D = load(texture_path)
		
		if bar_texture:
			# Usar la misma textura para fondo y relleno
			texture_bar.texture_under = bar_texture
			texture_bar.texture_progress = bar_texture
			
			# Aplicar tintes: fondo oscuro, relleno con el color de la estadística
			texture_bar.tint_under = Color(0.25, 0.25, 0.25, 1)  # Fondo muy oscuro
			texture_bar.tint_progress = color  # Relleno con color de la estadística (rojo para HP, naranja para ATK, etc.)
			
			stat_container.add_child(texture_bar)
		else:
			_add_fallback_bar(stat_container, value, max_value, color)
	else:
		_add_fallback_bar(stat_container, value, max_value, color)

func _add_fallback_bar(container: VBoxContainer, value: int, max_value: int, color: Color) -> void:
	# Fallback: usar ProgressBar normal
	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 25)
	progress_bar.max_value = max_value
	progress_bar.value = value
	progress_bar.show_percentage = false
	
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.18, 1)
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = color
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	
	container.add_child(progress_bar)

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
	var lore_panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.08, 0.1, 0.95)
	panel_style.border_color = Color(0.6, 0.5, 0.4, 0.7)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	lore_panel.add_theme_stylebox_override("panel", panel_style)
	detail_content.add_child(lore_panel)
	
	var lore_vbox := VBoxContainer.new()
	lore_vbox.add_theme_constant_override("separation", 12)
	lore_panel.add_child(lore_vbox)
	
	var lore_title := Label.new()
	lore_title.text = "📜 HISTORIA"
	lore_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.55, 1))
	lore_title.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05, 0.8))
	lore_title.add_theme_constant_override("outline_size", 2)
	lore_title.add_theme_font_size_override("font_size", 26)
	lore_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_vbox.add_child(lore_title)
	
	_add_separator(Color(0.6, 0.5, 0.4, 0.4))
	
	var lore_label := Label.new()
	lore_label.text = hero.lore_text if hero.lore_text else "Los registros de este héroe se perdieron en la guerra..."
	lore_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8, 1))
	lore_label.add_theme_font_size_override("font_size", 18)
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_vbox.add_child(lore_label)

func _create_action_buttons(hero: HeroData, level: int) -> void:
	var buttons_container := VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 15)
	detail_content.add_child(buttons_container)
	
	# Botón de subir nivel
	if level < 60:
		var cost: int = GameManager.player_data.get_level_up_cost(hero.hero_id)
		var can_afford := GameManager.player_data.gold >= cost
		var level_up_button := _create_styled_button("⬆️ MEJORAR",
			Color(0.15, 0.5, 0.2, 1) if can_afford else Color(0.2, 0.2, 0.25, 1),
			Color(0.3, 1, 0.4, 1) if can_afford else Color(0.4, 0.4, 0.45, 1))
		level_up_button.text += "\n💰 %s Oro" % _format_number(cost)
		if can_afford:
			level_up_button.pressed.connect(_on_level_up_pressed.bind(hero, level_up_button))
		else:
			level_up_button.disabled = true
			level_up_button.text += " (Tienes: %s)" % _format_number(GameManager.player_data.gold)
		buttons_container.add_child(level_up_button)
	
	# Botón de ascensión
	var hero_info: Dictionary = GameManager.player_data.owned_heroes.get(hero.hero_id, {})
	var stars: int = hero_info.get("stars", 1)
	var copies: int = hero_info.get("copies", 1)
	if stars < 5:
		var ascension_cost: int = GameManager.player_data.get_ascension_cost(hero.hero_id)
		var can_ascend := copies >= ascension_cost
		var ascend_button := _create_styled_button("✨ ASCENDER A %d★" % (stars + 1),
			Color(0.3, 0.2, 0.35, 1) if can_ascend else Color(0.2, 0.2, 0.25, 1),
			Color(0.7, 0.6, 0.45, 1) if can_ascend else Color(0.4, 0.4, 0.45, 1))
		ascend_button.text += "\n🎴 Copias: %d / %d" % [copies, ascension_cost]
		if can_ascend:
			ascend_button.pressed.connect(_on_ascend_pressed.bind(hero, ascend_button))
		else:
			ascend_button.disabled = true
		buttons_container.add_child(ascend_button)

func _format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)

func _create_styled_button(text: String, bg_color: Color, border_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 80)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	button.add_theme_constant_override("outline_size", 3)
	
	# Función auxiliar para no repetir código de bordes
	var create_style = func(bg: Color, shadow_s: int, shadow_o: int, margin_t: int, margin_b: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border_color
		s.set_border_width_all(4)
		s.set_corner_radius_all(8)
		s.shadow_color = Color(0, 0, 0, 0.7)
		s.shadow_size = shadow_s
		s.shadow_offset = Vector2(0, shadow_o)
		s.set_expand_margin(SIDE_TOP, margin_t)
		s.set_expand_margin(SIDE_BOTTOM, margin_b)
		return s
	
	button.add_theme_stylebox_override("normal", create_style.call(bg_color, 10, 6, 2, 0))
	button.add_theme_stylebox_override("hover", create_style.call(bg_color.lightened(0.2), 14, 8, 2, 0))
	button.add_theme_stylebox_override("pressed", create_style.call(bg_color.darkened(0.15), 4, 2, 0, 2))
	button.add_theme_stylebox_override("disabled", create_style.call(Color(0.2, 0.2, 0.2, 0.8), 0, 0, 0, 0))
	
	return button

func _add_separator(color: Color) -> void:
	var separator := HSeparator.new()
	var style := StyleBoxLine.new()
	style.color = color
	style.thickness = 2
	style.grow_begin = -10
	style.grow_end = -10
	separator.add_theme_stylebox_override("separator", style)
	detail_content.add_child(separator)

func _on_level_up_pressed(hero: HeroData, button_node: Button) -> void:
	var cost: int = GameManager.player_data.get_level_up_cost(hero.hero_id)
	if GameManager.player_data.gold >= cost:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("level_up_success")
		GameManager.player_data.gold -= cost
		if GameManager.player_data.level_up_hero(hero.hero_id):
			GameManager.save_game()
			# Animación Tween para el botón (Pequeño "salto")
			var tween = create_tween()
			tween.tween_property(button_node, "scale", Vector2(1.05, 1.05), 0.1)
			tween.tween_property(button_node, "scale", Vector2(1.0, 1.0), 0.1)
			_display_hero_details(hero)
			var new_level: int = GameManager.player_data.get_hero_level(hero.hero_id)
			print("[HeroRoster] %s subió a nivel %d" % [hero.hero_name, new_level])
	else:
		_play_error_animation(button_node)

func _on_ascend_pressed(hero: HeroData, button_node: Button) -> void:
	if GameManager.player_data.ascend_hero(hero.hero_id):
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("ascend_success")
		GameManager.save_game()
		# Efecto de destello al ascender
		var tween = create_tween()
		button_node.modulate = Color(2, 2, 2, 1)
		tween.tween_property(button_node, "modulate", Color(1, 1, 1, 1), 0.5)
		_display_hero_details(hero)
		var hero_info: Dictionary = GameManager.player_data.owned_heroes[hero.hero_id]
		var stars: int = hero_info.get("stars", 1)
		print("[HeroRoster] %s ascendió a %d estrellas" % [hero.hero_name, stars])
	else:
		_play_error_animation(button_node)

func _play_error_animation(node: Control) -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("error_buzz")
	# Efecto de "sacudida" (Shake)
	var tween = create_tween()
	var original_pos = node.position
	tween.tween_property(node, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(node, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(node, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(node, "position:x", original_pos.x, 0.05)

func _on_back_pressed() -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("button_click")
	GameManager.go_to_scene("main_menu")
