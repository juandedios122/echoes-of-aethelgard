## GachaScreen.gd
## Pantalla de invocaciones con animaciones completas procedurales.
## CORRECCIÓN Bug 3: Usa GameManager.gacha_system en vez de GachaSystem global.
class_name GachaScreen
extends Control

@onready var amber_label: Label              = $TopBar/AmberLabel
@onready var pity_bar: ProgressBar           = $PityBar
@onready var pity_label: Label               = $TopBar/PityLabel
@onready var result_container: HBoxContainer = $ResultContainer
@onready var pull_1x_btn: Button             = $CenterContainer/VBoxContainer/ButtonsContainer/PullButton1x
@onready var pull_10x_btn: Button            = $CenterContainer/VBoxContainer/ButtonsContainer/PullButton10x
@onready var skip_btn: Button                = $SkipButton
@onready var background: ColorRect           = $Background

const HeroCardScene: PackedScene = preload("res://scenes/ui/HeroCard.tscn")

var is_animating: bool       = false
var _skip_requested: bool    = false
var _pending_results: Array  = []

var _overlay: ColorRect      = null
var _rift_container: Node2D  = null
var _particles: CPUParticles2D = null
var _center_label: Label     = null

func _ready() -> void:
	_build_overlay()
	_build_rift()
	_refresh_currency_ui()
	_refresh_pity_ui()
	_style_buttons()

	# CORRECCIÓN Bug 3: acceder a las constantes a través de la instancia
	var gacha := GameManager.gacha_system
	pull_1x_btn.text  = "Invocar  ×1\n🔶 %d" % gacha.COST_SINGLE
	pull_10x_btn.text = "Invocar ×10\n🔶 %d" % gacha.COST_MULTI

	GameManager.currency_changed.connect(_on_currency_changed)
	gacha.pity_updated.connect(_on_pity_updated)
	gacha.pull_completed.connect(_on_pull_completed)

	AudioManager.play_music("gacha_theme", 1.5)

func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index   = 10
	_overlay.color     = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_center_label = Label.new()
	_center_label.set_anchors_preset(Control.PRESET_CENTER)
	_center_label.z_index = 11
	_center_label.add_theme_font_size_override("font_size", 72)
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_center_label.visible = false
	_center_label.pivot_offset = _center_label.size * 0.5
	add_child(_center_label)

func _build_rift() -> void:
	_rift_container = Node2D.new()
	_rift_container.z_index = 5
	_rift_container.position = Vector2(960, 480)
	_rift_container.visible  = false
	add_child(_rift_container)

	_particles = CPUParticles2D.new()
	_particles.emitting              = false
	_particles.amount                = 60
	_particles.lifetime              = 1.2
	_particles.one_shot              = false
	_particles.explosiveness         = 0.0
	_particles.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(80, 200)
	_particles.direction             = Vector2(0, -1)
	_particles.spread                = 60.0
	_particles.gravity               = Vector2(0, -80)
	_particles.initial_velocity_min  = 60.0
	_particles.initial_velocity_max  = 180.0
	_particles.scale_amount_min      = 2.0
	_particles.scale_amount_max      = 5.0
	_particles.color                 = Color(0.6, 0.3, 1.0, 1.0)
	_rift_container.add_child(_particles)

func _style_buttons() -> void:
	for btn in [pull_1x_btn, pull_10x_btn]:
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(0.12, 0.07, 0.20, 1)
		s.border_color = Color(0.65, 0.45, 0.90, 1)
		s.set_border_width_all(3)
		s.set_corner_radius_all(10)
		s.shadow_color = Color(0.5, 0.2, 0.9, 0.5)
		s.shadow_size  = 8
		btn.add_theme_stylebox_override("normal", s)
		var h := s.duplicate() as StyleBoxFlat
		h.bg_color = Color(0.20, 0.10, 0.32, 1)
		btn.add_theme_stylebox_override("hover", h)
		btn.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
		btn.add_theme_font_size_override("font_size", 24)

func _refresh_currency_ui() -> void:
	amber_label.text = "🔶 %d" % GameManager.player_data.amber_shards

func _refresh_pity_ui() -> void:
	var gacha := GameManager.gacha_system
	var pity: int = GameManager.player_data.pull_pity
	pity_bar.max_value = gacha.PITY_CAP
	pity_bar.value     = pity
	pity_label.text    = "Pity: %d/%d  (%.1f%%)" % [
		pity, gacha.PITY_CAP,
		gacha.get_current_leg_rate() * 100.0
	]

func _on_pull_1x_pressed() -> void:
	if is_animating:
		return
	_set_buttons_enabled(false)
	if not GameManager.gacha_system.pull_single():
		_show_not_enough_amber()
		_set_buttons_enabled(true)

func _on_pull_10x_pressed() -> void:
	if is_animating:
		return
	_set_buttons_enabled(false)
	if not GameManager.gacha_system.pull_multi():
		_show_not_enough_amber()
		_set_buttons_enabled(true)

func _on_pull_completed(results: Array) -> void:
	is_animating     = true
	_skip_requested  = false
	_pending_results = results
	skip_btn.visible = true

	_clear_results()
	await _animate_rift_open()

	var has_legendary: bool = results.any(func(h: HeroData): return h.rarity == HeroData.Rarity.LEGENDARIO)

	if has_legendary:
		await _flash_legendary_intro()

	var cards: Array[HeroCard] = []
	for hero in results:
		var card := HeroCardScene.instantiate() as HeroCard
		result_container.add_child(card)
		card.setup_hidden(hero, GameManager.player_data.owned_heroes.has(hero.hero_id)
			and GameManager.player_data.owned_heroes[hero.hero_id].get("copies", 1) > 1)
		card.scale = Vector2(0.0, 1.0)
		cards.append(card)

	for card in cards:
		if _skip_requested:
			card.scale = Vector2(1, 1)
		else:
			var t: Tween = create_tween()
			t.tween_property(card, "scale:x", 1.0, 0.20).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(0.12).timeout

	await get_tree().create_timer(0.3).timeout

	for i in cards.size():
		var card := cards[i]
		var hero := results[i] as HeroData

		if _skip_requested:
			card.setup(hero, false)
			continue

		await card.reveal()

		match hero.rarity:
			HeroData.Rarity.LEGENDARIO:
				await _flash_on_reveal(Color(1.0, 0.85, 0.1, 0.7), 0.5)
				_spawn_rarity_particles(card, Color(1.0, 0.85, 0.1), 50)
			HeroData.Rarity.EPICO:
				await _flash_on_reveal(Color(0.65, 0.2, 0.85, 0.45), 0.3)
				_spawn_rarity_particles(card, Color(0.7, 0.4, 1.0), 25)
			HeroData.Rarity.RARO:
				_spawn_rarity_particles(card, Color(0.4, 0.6, 1.0), 12)
			_:
				pass

		await get_tree().create_timer(0.18).timeout

	await _animate_rift_close()

	is_animating     = false
	skip_btn.visible = false
	_set_buttons_enabled(true)

func _animate_rift_open() -> void:
	_rift_container.visible = true
	_particles.color        = Color(0.6, 0.3, 1.0, 1.0)
	_particles.emitting     = true

	_overlay.color = Color(0.05, 0.0, 0.10, 0.0)
	var fade_in: Tween = create_tween()
	fade_in.tween_property(_overlay, "color", Color(0.05, 0.0, 0.10, 0.88), 0.3)
	await fade_in.finished

	for i in 4:
		var shake: Tween = create_tween()
		shake.tween_property(_overlay, "position", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.06)
		await shake.finished
	_overlay.position = Vector2.ZERO

	await get_tree().create_timer(0.25).timeout

	var open: Tween = create_tween()
	open.tween_property(_overlay, "color", Color(0.05, 0.0, 0.10, 0.55), 0.35)
	await open.finished

func _animate_rift_close() -> void:
	_particles.emitting = false
	var close: Tween = create_tween()
	close.tween_property(_overlay, "color", Color(0, 0, 0, 0), 0.5)
	await close.finished
	_rift_container.visible = false

func _flash_legendary_intro() -> void:
	_center_label.text    = "✨ LEGENDARIO ✨"
	_center_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.1))
	_center_label.modulate = Color(1, 1, 1, 0)
	_center_label.scale    = Vector2(0.5, 0.5)
	_center_label.visible  = true
	_center_label.pivot_offset = get_viewport_rect().size * 0.5

	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(_center_label, "modulate:a", 1.0, 0.25)
	t.tween_property(_center_label, "scale", Vector2(1.2, 1.2), 0.30).set_ease(Tween.EASE_OUT)
	t.tween_property(_overlay, "color", Color(0.5, 0.4, 0.0, 0.85), 0.20)
	await t.finished

	await get_tree().create_timer(0.7).timeout

	var t2: Tween = create_tween().set_parallel(true)
	t2.tween_property(_center_label, "modulate:a", 0.0, 0.3)
	t2.tween_property(_overlay, "color", Color(0.05, 0.0, 0.10, 0.55), 0.3)
	await t2.finished
	_center_label.visible = false

func _flash_on_reveal(color: Color, duration: float) -> void:
	var old_color: Color = _overlay.color
	var t1: Tween = create_tween()
	t1.tween_property(_overlay, "color", color, duration * 0.35)
	await t1.finished
	var t2: Tween = create_tween()
	t2.tween_property(_overlay, "color", old_color, duration * 0.65)
	await t2.finished

func _spawn_rarity_particles(card: Control, color: Color, count: int) -> void:
	var p := CPUParticles2D.new()
	var card_center: Vector2 = card.global_position + card.size * 0.5
	p.global_position       = card_center
	p.z_index               = 12
	p.emitting              = false
	p.amount                = count
	p.lifetime              = 0.9
	p.one_shot              = true
	p.explosiveness         = 0.85
	p.emission_shape        = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 40.0
	p.direction             = Vector2(0, -1)
	p.spread                = 90.0
	p.gravity               = Vector2(0, 120)
	p.initial_velocity_min  = 80.0
	p.initial_velocity_max  = 220.0
	p.scale_amount_min      = 2.0
	p.scale_amount_max      = 5.0
	p.color                 = color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _show_not_enough_amber() -> void:
	var original_pos: Vector2 = amber_label.position
	var shake: Tween = create_tween()
	for i in 5:
		shake.tween_property(amber_label, "position:x", original_pos.x + (6.0 if i % 2 == 0 else -6.0), 0.06)
	shake.tween_property(amber_label, "position", original_pos, 0.06)

	amber_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	var restore: Tween = create_tween()
	restore.tween_interval(0.5)
	restore.tween_callback(func():
		amber_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	)

	var popup := Label.new()
	popup.text = "¡Ámbar insuficiente!"
	popup.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	popup.add_theme_font_size_override("font_size", 28)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.z_index = 20
	add_child(popup)
	popup.modulate.a = 0.0

	var pop_tween: Tween = create_tween().set_parallel(true)
	pop_tween.tween_property(popup, "modulate:a", 1.0, 0.2)
	pop_tween.tween_property(popup, "position:y", popup.position.y - 40.0, 0.8)
	await pop_tween.finished

	var hide_tween: Tween = create_tween()
	hide_tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	await hide_tween.finished
	popup.queue_free()

func _on_skip_pressed() -> void:
	_skip_requested = true

func _clear_results() -> void:
	for child in result_container.get_children():
		child.queue_free()

func _set_buttons_enabled(enabled: bool) -> void:
	pull_1x_btn.disabled  = not enabled
	pull_10x_btn.disabled = not enabled

func _on_currency_changed(_new_amount: int) -> void:
	_refresh_currency_ui()

func _on_pity_updated(_current: int, _cap: int) -> void:
	_refresh_pity_ui()

func _on_back_pressed() -> void:
	GameManager.go_to_scene("hub_camp")
