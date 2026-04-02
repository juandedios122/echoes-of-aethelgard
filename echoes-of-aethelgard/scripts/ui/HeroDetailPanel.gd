## HeroDetailPanel.gd
## Panel de detalles del héroe con interfaz optimizada
extends PanelContainer

# Referencias a nodos
@onready var name_label: Label = $ScrollContainer/DetailContent/Header/NameLabel
@onready var title_label: Label = $ScrollContainer/DetailContent/Header/TitleLabel
@onready var level_container: HBoxContainer = $ScrollContainer/DetailContent/Header/LevelContainer
@onready var level_text: Label = $ScrollContainer/DetailContent/Header/LevelContainer/LevelText
@onready var exp_bar: ProgressBar = $ScrollContainer/DetailContent/Header/ExpBar
@onready var exp_text: Label = $ScrollContainer/DetailContent/Header/ExpText
@onready var stats_grid: GridContainer = $ScrollContainer/DetailContent/StatsPanel/StatsVBox/StatsGrid
@onready var hp_value: Label = $ScrollContainer/DetailContent/StatsPanel/StatsVBox/StatsGrid/HpValue
@onready var atk_value: Label = $ScrollContainer/DetailContent/StatsPanel/StatsVBox/StatsGrid/AtkValue
@onready var def_value: Label = $ScrollContainer/DetailContent/StatsPanel/StatsVBox/StatsGrid/DefValue
@onready var spd_value: Label = $ScrollContainer/DetailContent/StatsPanel/StatsVBox/StatsGrid/SpdValue
@onready var abilities_grid: HBoxContainer = $ScrollContainer/DetailContent/AbilitiesPanel/AbilitiesVBox/AbilitiesGrid
@onready var buttons_container: VBoxContainer = $ScrollContainer/DetailContent/ButtonsContainer
@onready var level_up_button: Button = $ScrollContainer/DetailContent/ButtonsContainer/LevelUpButton
@onready var ascend_button: Button = $ScrollContainer/DetailContent/ButtonsContainer/AscendButton
@onready var particle_spawn: Node2D = $ScrollContainer/DetailContent/ParticleSpawn

var current_hero: HeroData = null

func _ready() -> void:
	_setup_styles()
	level_up_button.pressed.connect(_on_level_up_pressed)
	ascend_button.pressed.connect(_on_ascend_pressed)

func _setup_styles() -> void:
	# Configurar estilos de barras de progreso
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.10, 1)
	bar_bg.set_corner_radius_all(4)
	exp_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.65, 0.50, 0.30, 1)
	bar_fill.set_corner_radius_all(4)
	exp_bar.add_theme_stylebox_override("fill", bar_fill)
	
	# Colores de texto
	name_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05, 1))
	name_label.add_theme_constant_override("outline_size", 3)
	
	title_label.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60, 1))
	level_text.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
	exp_text.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60, 1))
	
	# Colores de stats
	hp_value.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	atk_value.add_theme_color_override("font_color", Color(1, 0.6, 0.3, 1))
	def_value.add_theme_color_override("font_color", Color(0.5, 0.7, 1, 1))
	spd_value.add_theme_color_override("font_color", Color(1, 1, 0.4, 1))

func display_hero(hero: HeroData, is_owned: bool) -> void:
	current_hero = hero
	
	if not is_owned:
		_display_locked()
		return
	
	var level: int = GameManager.player_data.get_hero_level(hero.hero_id)
	
	# Actualizar header
	name_label.text = hero.hero_name
	title_label.text = hero.title
	level_text.text = "Nivel %d / 60" % level
	level_container.visible = true
	
	# Actualizar barra de experiencia
	if level < 60:
		var current_exp: int = GameManager.player_data.get_hero_exp(hero.hero_id)
		var exp_needed: int = GameManager.player_data.get_exp_for_next_level(level)
		exp_bar.value = float(current_exp) / float(exp_needed) * 100.0
		exp_text.text = "%d / %d EXP" % [current_exp, exp_needed]
		exp_bar.visible = true
		exp_text.visible = true
	else:
		exp_bar.visible = false
		exp_text.text = "✨ NIVEL MÁXIMO ✨"
	
	# Actualizar stats
	hp_value.text = str(hero.get_hp_at_level(level))
	atk_value.text = str(hero.get_atk_at_level(level))
	def_value.text = str(hero.get_def_at_level(level))
	spd_value.text = str(hero.base_spd + (level - 1) * 2)
	
	# Actualizar habilidades
	_update_abilities(hero)
	
	# Actualizar botones
	_update_buttons(hero, level)

func _display_locked() -> void:
	name_label.text = "🔒 HÉROE BLOQUEADO"
	title_label.text = "Desbloquea este héroe en el Gacha"
	level_container.visible = false
	exp_bar.visible = false
	exp_text.visible = false
	buttons_container.visible = false

func _update_abilities(hero: HeroData) -> void:
	# Limpiar habilidades anteriores
	for child in abilities_grid.get_children():
		child.queue_free()
	
	var skills := [hero.skill_basic, hero.skill_active, hero.skill_passive, hero.skill_ultimate]
	var skill_icons := ["⚔️", "💥", "🌟", "💫"]
	
	for i in skills.size():
		if skills[i]:
			var ability_card := _create_ability_card(skills[i], skill_icons[i])
			abilities_grid.add_child(ability_card)

func _create_ability_card(skill: SkillData, icon: String) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.10, 1)
	style.border_color = Color(0.45, 0.35, 0.25, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(80, 80)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)
	
	var name_label := Label.new()
	name_label.text = skill.skill_name if skill.skill_name else "Habilidad"
	name_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	return card

func _update_buttons(hero: HeroData, level: int) -> void:
	buttons_container.visible = true
	
	# Botón de subir nivel
	if level < 60:
		var cost: int = GameManager.player_data.get_level_up_cost(hero.hero_id)
		var can_afford := GameManager.player_data.gold >= cost
		level_up_button.text = "⬆️ MEJORAR\n💰 %s Oro" % _format_number(cost)
		level_up_button.disabled = not can_afford
		level_up_button.visible = true
		_apply_button_style(level_up_button, can_afford, 
			Color(0.15, 0.5, 0.2, 1), Color(0.3, 1, 0.4, 1))
	else:
		level_up_button.visible = false
	
	# Botón de ascensión
	var hero_info: Dictionary = GameManager.player_data.owned_heroes.get(hero.hero_id, {})
	var stars: int = hero_info.get("stars", 1)
	var copies: int = hero_info.get("copies", 1)
	
	if stars < 5:
		var ascension_cost: int = GameManager.player_data.get_ascension_cost(hero.hero_id)
		var can_ascend := copies >= ascension_cost
		ascend_button.text = "✨ ASCENDER A %d★\n🎴 Copias: %d / %d" % [stars + 1, copies, ascension_cost]
		ascend_button.disabled = not can_ascend
		ascend_button.visible = true
		_apply_button_style(ascend_button, can_ascend,
			Color(0.3, 0.2, 0.35, 1), Color(0.7, 0.6, 0.45, 1))
	else:
		ascend_button.visible = false

func _apply_button_style(button: Button, is_enabled: bool, bg_color: Color, border_color: Color) -> void:
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
	
	var final_bg = bg_color if is_enabled else Color(0.2, 0.2, 0.25, 1)
	button.add_theme_stylebox_override("normal", create_style.call(final_bg, 10, 6, 2, 0))
	button.add_theme_stylebox_override("hover", create_style.call(final_bg.lightened(0.2), 14, 8, 2, 0))
	button.add_theme_stylebox_override("pressed", create_style.call(final_bg.darkened(0.15), 4, 2, 0, 2))
	button.add_theme_stylebox_override("disabled", create_style.call(Color(0.2, 0.2, 0.2, 0.8), 0, 0, 0, 0))

func _format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	return str(num)

func _on_level_up_pressed() -> void:
	if not current_hero:
		return
	
	var cost: int = GameManager.player_data.get_level_up_cost(current_hero.hero_id)
	if GameManager.player_data.gold >= cost:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("level_up_success")
		GameManager.player_data.gold -= cost
		if GameManager.player_data.level_up_hero(current_hero.hero_id):
			GameManager.save_game()
			# Animación de éxito
			_play_success_animation(level_up_button)
			_spawn_level_up_particles()
			# Refrescar display
			display_hero(current_hero, true)
	else:
		_play_error_animation(level_up_button)

func _on_ascend_pressed() -> void:
	if not current_hero:
		return
	
	if GameManager.player_data.ascend_hero(current_hero.hero_id):
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("ascend_success")
		GameManager.save_game()
		# Animación de destello
		_play_flash_animation(ascend_button)
		_spawn_ascension_particles()
		# Refrescar display
		display_hero(current_hero, true)
	else:
		_play_error_animation(ascend_button)

func _play_success_animation(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _play_flash_animation(button: Button) -> void:
	var tween = create_tween()
	button.modulate = Color(2, 2, 2, 1)
	tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.5)

func _play_error_animation(button: Button) -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("error_buzz")
	var tween = create_tween()
	var original_pos = button.position
	tween.tween_property(button, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(button, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(button, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(button, "position:x", original_pos.x, 0.05)

func _spawn_level_up_particles() -> void:
	var particles := CPUParticles2D.new()
	particle_spawn.add_child(particles)
	
	# Configurar partículas doradas
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 50.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1, 0.8, 0.2, 1)
	
	# Auto-eliminar después de la animación
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func _spawn_ascension_particles() -> void:
	var particles := CPUParticles2D.new()
	particle_spawn.add_child(particles)
	
	# Configurar partículas de ascensión (más espectaculares)
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 80.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, -100)
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(0.9, 0.7, 1, 1)
	
	await get_tree().create_timer(2.5).timeout
	particles.queue_free()
