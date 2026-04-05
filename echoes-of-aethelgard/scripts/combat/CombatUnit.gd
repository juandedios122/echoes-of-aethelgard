## CombatUnit.gd
## Representación en tiempo de ejecución de un héroe o enemigo en combate.
## BattleScene instancia uno de estos por cada participante.
class_name CombatUnit
extends Node2D

# ─── Señales ──────────────────────────────────────────────────────────────────
signal hp_changed(current: int, maximum: int)
signal energy_changed(current: int, maximum: int)
signal died()

# ─── Datos Base ───────────────────────────────────────────────────────────────
var hero_data: HeroData = null
var unit_name: String   = "Unit"
var level: int          = 1
var is_player_unit: bool = true

# ─── Estadísticas en Combate ──────────────────────────────────────────────────
var max_hp: int       = 1000
var current_hp: int   = 1000
var atk: int          = 100
var def_stat: int     = 50
var spd: int          = 80
var crit_rate: float  = 0.05
var crit_dmg: float   = 1.5
var max_energy: int   = 100
var current_energy: int = 0
var shield: int       = 0   # Absorbe daño antes que el HP

# ─── Efectos de Estado Activos ────────────────────────────────────────────────
## Formato: { "status_id": { "value": float, "turns_remaining": int } }
var active_statuses: Dictionary = {}

# ─── Nodos de la Escena ───────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar      = $HpBar
@onready var energy_bar: ProgressBar  = $EnergyBar
@onready var damage_label_scene: PackedScene = preload("res://scenes/combat/DamageLabel.tscn")

# ─── Inicialización ───────────────────────────────────────────────────────────
func setup(data: HeroData, unit_level: int, player: bool = true) -> void:
	hero_data     = data
	unit_name     = data.hero_name
	level         = unit_level
	is_player_unit = player

	max_hp      = data.get_hp_at_level(level)
	current_hp  = max_hp
	atk         = data.get_atk_at_level(level)
	def_stat    = data.get_def_at_level(level)
	spd         = data.base_spd
	crit_rate   = data.base_crit_rate
	crit_dmg    = data.base_crit_dmg
	current_energy = 0

	# ── BUG FIX: Cargar SpriteFrames desde resources/heroes/{hero_id}.tres ──
	# La ruta correcta es resources/heroes/ (SpriteFrames),
	# NO assets/sprites/heroes/ (que no existe en este proyecto).
	var frames_path := "res://resources/heroes/%s.tres" % data.hero_id
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path) as SpriteFrames
		sprite.animation     = "idle"
		sprite.play()
	else:
		# Enemigo sin SpriteFrames propio: usar sprite de heroe similar con tinte
		var fallback_id := _get_enemy_fallback_sprite(data.hero_id)
		var fallback_path := "res://resources/heroes/%s.tres" % fallback_id
		if ResourceLoader.exists(fallback_path):
			sprite.sprite_frames = load(fallback_path) as SpriteFrames
			sprite.animation     = "idle"
			sprite.play()
			sprite.modulate = _get_enemy_tint(data.hero_id)
		else:
			_use_placeholder_sprite(data.hero_id)

	# Voltear si es enemigo
	sprite.flip_h = not is_player_unit

	# ── BUG FIX: Cargar portrait con ruta correcta ──────────────────────────
	# El hero_name es "Aethan", "Lyra", etc. — coincide con la carpeta del sprite.
	# Si el HeroData no tiene portrait asignado, lo cargamos dinámicamente.
	if data.portrait == null:
		var portrait_path := "res://assets/sprites/%s/portrait.png" % data.hero_name
		if ResourceLoader.exists(portrait_path):
			data.portrait = load(portrait_path)
		else:
			# Fallback: usar el battle_sprite como retrato
			var battle_path := "res://assets/sprites/%s/battle_sprite.png" % data.hero_name
			if ResourceLoader.exists(battle_path):
				data.portrait = load(battle_path)

	_update_ui()
	print("[CombatUnit] %s (Lv.%d) — HP:%d ATK:%d DEF:%d SPD:%d" % [
		unit_name, level, max_hp, atk, def_stat, spd
	])

# ─── Daño y Curación ──────────────────────────────────────────────────────────
func receive_damage(raw_dmg: int) -> int:
	var dmg := raw_dmg
	# Absorber con escudo primero
	if shield > 0:
		var absorbed := mini(shield, dmg)
		shield -= absorbed
		dmg    -= absorbed
	dmg = maxi(0, dmg)
	current_hp -= dmg
	current_hp  = maxi(0, current_hp)
	_spawn_damage_label(dmg, false)
	_play_hit_effects()
	hp_changed.emit(current_hp, max_hp)
	_update_ui()
	if current_hp <= 0:
		_on_died()
	return dmg

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	_spawn_damage_label(amount, true)
	hp_changed.emit(current_hp, max_hp)
	_update_ui()

func add_shield(amount: int) -> void:
	shield += amount

func gain_energy(amount: int) -> void:
	current_energy = mini(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)
	_update_ui()

# ─── Efectos de Estado ────────────────────────────────────────────────────────
func apply_status(status_id: String, value: float, duration: int) -> void:
	active_statuses[status_id] = {"value": value, "turns_remaining": duration}

func tick_statuses() -> void:
	var to_remove: Array[String] = []
	for sid in active_statuses:
		var s: Dictionary = active_statuses[sid]
		## Aplicar efecto de veneno / quemadura (DoT)
		if sid.begins_with("dot_"):
			receive_damage(roundi(max_hp * s["value"]))
		s["turns_remaining"] -= 1
		if s["turns_remaining"] <= 0:
			to_remove.append(sid)
	for sid in to_remove:
		active_statuses.erase(sid)

func get_status_multiplier(stat: String) -> float:
	var mult := 1.0
	for sid in active_statuses:
		if sid.begins_with("buff_" + stat):
			mult += active_statuses[sid]["value"]
		elif sid.begins_with("debuff_" + stat):
			mult -= active_statuses[sid]["value"]
	return clampf(mult, 0.1, 3.0)

func is_stunned() -> bool:
	return "stun" in active_statuses

# ─── Dibujo (Sombra Falsa) ────────────────────────────────────────────────────
func _draw() -> void:
	# Dibujar sombra ovalada debajo del personaje
	draw_circle(Vector2(0, 45), 35.0, Color(0, 0, 0, 0.4))

# ─── Animaciones y Efectos Visuales ──────────────────────────────────────────
func play_animation(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func play_idle() -> void:
	play_animation("idle")

func play_walk() -> void:
	play_animation("walk")

func play_attack() -> Signal:
	play_animation("attack")
	var tween := create_tween()
	var dir_x  := 60.0 if is_player_unit else -60.0
	tween.tween_property(self, "position:x", position.x + dir_x, 0.15)
	tween.tween_property(self, "position:x", position.x,         0.20)
	await sprite.animation_finished
	play_idle()
	return sprite.animation_finished

func play_hurt() -> void:
	play_animation("hurt")
	var original := position
	var tween    := create_tween()
	for i in 4:
		var offset := Vector2(randf_range(-6,6), randf_range(-3,3))
		tween.tween_property(self, "position", original + offset, 0.05)
	tween.tween_property(self, "position", original, 0.05)
	await sprite.animation_finished
	play_idle()

func _play_hit_effects() -> void:
	# Flash rojo al recibir daño
	var f_tween := create_tween()
	sprite.modulate = Color(5.0, 0.5, 0.5, 1.0)
	f_tween.tween_property(sprite, "modulate", Color(1,1,1,1), 0.2)

	# Partículas de impacto
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -30)
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector2(randf_range(-1, 1), -1)
	p.spread = 45.0
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 250.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(0.8, 0.1, 0.1, 1.0)
	p.amount = 12
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func play_death() -> void:
	play_animation("death")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.4)
	await tween.finished

# ─── Estado ───────────────────────────────────────────────────────────────────
func is_dead() -> bool:
	return current_hp <= 0

func is_energy_full() -> bool:
	return current_energy >= max_energy

# ─── UI Interna ───────────────────────────────────────────────────────────────
func _update_ui() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value     = current_hp
	if energy_bar:
		energy_bar.max_value = max_energy
		energy_bar.value     = current_energy

func _spawn_damage_label(amount: int, is_heal: bool) -> void:
	if not damage_label_scene:
		return
	var label: Node = damage_label_scene.instantiate()
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(0, -60)
	if label.has_method("setup"):
		label.setup(amount, is_heal)

# ─── Muerte ───────────────────────────────────────────────────────────────────
func _on_died() -> void:
	play_death()
	died.emit()
	print("[CombatUnit] %s ha sido derrotado." % unit_name)

# ─── Helpers de sprites para enemigos ────────────────────────────────────────
## Devuelve el hero_id de un SpriteFrames existente para usar como fallback visual.
func _get_enemy_fallback_sprite(enemy_id: String) -> String:
	var mapping := {
		"goblin_scout"      : "vex_nigromante",
		"skeleton_warrior"  : "kael_soldado",
		"bandit_rogue"      : "varra_mercenaria",
		"orc_brute"         : "gorn_barbaro",
		"dark_mage"         : "aldric_archimago",
		"cursed_archer"     : "theron_cazador",
		"corrupted_knight"  : "aethan_paladin",
		"shadow_assassin"   : "vex_nigromante",
		"bone_necromancer"  : "vex_nigromante",
	}
	return mapping.get(enemy_id, "vex_nigromante")

## Devuelve el color de tinte para cada tipo de enemigo.
func _get_enemy_tint(enemy_id: String) -> Color:
	var tints := {
		"goblin_scout"      : Color(0.4, 0.9, 0.4, 1),   # Verde goblin
		"skeleton_warrior"  : Color(0.9, 0.9, 0.85, 1),  # Hueso
		"bandit_rogue"      : Color(0.8, 0.55, 0.3, 1),  # Marrón cuero
		"orc_brute"         : Color(0.45, 0.75, 0.35, 1),# Verde orco
		"dark_mage"         : Color(0.5, 0.25, 0.85, 1), # Púrpura oscuro
		"cursed_archer"     : Color(0.7, 0.2, 0.2, 1),   # Rojo maldición
		"corrupted_knight"  : Color(0.35, 0.35, 0.65, 1),# Azul corrupto
		"shadow_assassin"   : Color(0.25, 0.15, 0.35, 1),# Negro sombra
		"bone_necromancer"  : Color(0.45, 0.15, 0.55, 1),# Morado necrosis
	}
	return tints.get(enemy_id, Color(0.8, 0.3, 0.3, 1))

## Crea un SpriteFrames placeholder de color sólido cuando no hay sprite real.
func _use_placeholder_sprite(enemy_id: String) -> void:
	var img := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	img.fill(_get_enemy_tint(enemy_id))
	var tex := ImageTexture.create_from_image(img)
	var sf  := SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_frame("idle", tex)
	sf.add_animation("attack")
	sf.add_frame("attack", tex)
	sf.add_animation("hurt")
	sf.add_frame("hurt", tex)
	sf.add_animation("death")
	sf.add_frame("death", tex)
	sprite.sprite_frames = sf
	sprite.animation     = "idle"
	sprite.play()
	push_warning("[CombatUnit] Usando placeholder para enemigo: %s" % enemy_id)
