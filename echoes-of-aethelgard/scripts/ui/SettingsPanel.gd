## SettingsPanel.gd
## Panel de configuración con controles de volumen, velocidad y datos.
## Se instancia como popup desde HubCamp o MainMenu.
class_name SettingsPanel
extends PanelContainer

signal closed()

var music_slider: HSlider
var sfx_slider: HSlider
var battle_speed_option: OptionButton
var screen_shake_toggle: CheckButton

func _ready() -> void:
	_build_ui()
	_load_settings()

func _build_ui() -> void:
	# Panel principal con estilo medieval oscuro
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.04, 0.98)
	panel_style.border_color = Color(0.5, 0.4, 0.3, 1)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0, 0, 0, 0.7)
	panel_style.shadow_size = 20
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	add_child(main_vbox)

	# Título
	var title := Label.new()
	title.text = "⚙️ CONFIGURACIÓN"
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.65, 1))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 1))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	_add_settings_separator(main_vbox)

	# ─── Audio ───
	var audio_title := _create_section_title("🔊 Audio")
	main_vbox.add_child(audio_title)

	# Música
	var music_row := _create_slider_row("Música", 0.0, 1.0, AudioManager.music_volume)
	main_vbox.add_child(music_row.container)
	music_slider = music_row.slider
	music_slider.value_changed.connect(_on_music_volume_changed)

	# SFX
	var sfx_row := _create_slider_row("Efectos", 0.0, 1.0, AudioManager.sfx_volume)
	main_vbox.add_child(sfx_row.container)
	sfx_slider = sfx_row.slider
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	_add_settings_separator(main_vbox)

	# ─── Gameplay ───
	var gameplay_title := _create_section_title("🎮 Gameplay")
	main_vbox.add_child(gameplay_title)

	# Velocidad de batalla
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(speed_row)

	var speed_label := Label.new()
	speed_label.text = "Velocidad de Batalla"
	speed_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1))
	speed_label.add_theme_font_size_override("font_size", 18)
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(speed_label)

	battle_speed_option = OptionButton.new()
	battle_speed_option.add_item("x1 Normal", 0)
	battle_speed_option.add_item("x1.5 Rápido", 1)
	battle_speed_option.add_item("x2 Turbo", 2)
	battle_speed_option.custom_minimum_size = Vector2(160, 40)
	battle_speed_option.item_selected.connect(_on_battle_speed_changed)
	speed_row.add_child(battle_speed_option)

	# Screen shake
	var shake_row := HBoxContainer.new()
	shake_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(shake_row)

	var shake_label := Label.new()
	shake_label.text = "Vibración de Pantalla"
	shake_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1))
	shake_label.add_theme_font_size_override("font_size", 18)
	shake_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake_row.add_child(shake_label)

	screen_shake_toggle = CheckButton.new()
	screen_shake_toggle.button_pressed = true
	screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	shake_row.add_child(screen_shake_toggle)

	_add_settings_separator(main_vbox)

	# ─── Información ───
	var info_title := _create_section_title("📋 Información")
	main_vbox.add_child(info_title)

	var version_label := Label.new()
	version_label.text = "Versión: %s" % GameManager.VERSION
	version_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))
	version_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(version_label)

	var stats_label := Label.new()
	var pd := GameManager.player_data
	stats_label.text = "Batallas: %d ganadas, %d perdidas | Pulls: %d" % [
		pd.total_battles_won, pd.total_battles_lost, pd.total_pulls
	]
	stats_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(stats_label)

	_add_settings_separator(main_vbox)

	# Botón cerrar
	var close_btn := Button.new()
	close_btn.text = "✖ CERRAR"
	close_btn.custom_minimum_size = Vector2(0, 50)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1))
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.4, 0.15, 0.1, 1)
	close_style.border_color = Color(0.7, 0.3, 0.2, 1)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_hover := close_style.duplicate()
	close_hover.bg_color = close_style.bg_color.lightened(0.2)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.pressed.connect(_on_close_pressed)
	main_vbox.add_child(close_btn)

func _create_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6, 1))
	label.add_theme_font_size_override("font_size", 22)
	return label

func _create_slider_row(label_text: String, min_val: float, max_val: float, current: float) -> Dictionary:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1))
	label.add_theme_font_size_override("font_size", 18)
	label.custom_minimum_size = Vector2(100, 0)
	container.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.05
	slider.value = current
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 0)
	container.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % roundi(current * 100)
	value_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55, 1))
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.custom_minimum_size = Vector2(50, 0)
	container.add_child(value_label)

	slider.value_changed.connect(func(val: float): value_label.text = "%d%%" % roundi(val * 100))

	return {"container": container, "slider": slider}

func _add_settings_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	var style := StyleBoxLine.new()
	style.color = Color(0.35, 0.28, 0.20, 0.5)
	style.thickness = 1
	sep.add_theme_stylebox_override("separator", style)
	parent.add_child(sep)

func _load_settings() -> void:
	if GameManager.player_data.has_method("get") and "settings" in GameManager.player_data:
		var s: Dictionary = GameManager.player_data.settings
		music_slider.value = s.get("music_volume", 0.7)
		sfx_slider.value = s.get("sfx_volume", 0.8)
		battle_speed_option.selected = s.get("battle_speed", 0)
		screen_shake_toggle.button_pressed = s.get("screen_shake", true)

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_save_setting("music_volume", value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	_save_setting("sfx_volume", value)

func _on_battle_speed_changed(index: int) -> void:
	_save_setting("battle_speed", index)

func _on_screen_shake_toggled(pressed: bool) -> void:
	_save_setting("screen_shake", pressed)

func _save_setting(key: String, value: Variant) -> void:
	GameManager.player_data.settings[key] = value
	GameManager.save_game()
	SignalBus.settings_changed.emit(key, value)

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
