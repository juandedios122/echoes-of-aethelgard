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
@onready var damage_label_scene: PackedScene = preload("res://DamageLabel.tscn")

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

	# ── Cargar SpriteFrames dinámicamente ──────────────────────────────────
	var frames_path := "res://assets/sprites/heroes/%s/%s_frames.tres" % [
		data.hero_name, data.hero_name.to_lower()
	]
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path)
		sprite.animation     = "idle"
		sprite.play()
	else:
		push_warning("[CombatUnit] SpriteFrames no encontrado: " + frames_path)

	# Voltear si es enemigo
	sprite.flip_h = not is_player_unit

	# ── Cargar portrait para UI ─────────────────────────────────────────────
	var portrait_path := "res://assets/sprites/heroes/%s/portrait.png" % data.hero_name
	if ResourceLoader.exists(portrait_path):
		data.portrait = load(portrait_path)

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

# ─── Animaciones ──────────────────────────────────────────────────────────────
func play_animation(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func play_idle() -> void:
	play_animation("idle")

func play_walk() -> void:
	play_animation("walk")

func play_attack() -> Signal:
	play_animation("attack")
	# Desplazamiento hacia el enemigo durante el ataque
	var tween := create_tween()
	var dir_x  := 60.0 if is_player_unit else -60.0
	tween.tween_property(self, "position:x", position.x + dir_x, 0.15)
	tween.tween_property(self, "position:x", position.x,         0.20)
	await sprite.animation_finished
	play_idle()
	return sprite.animation_finished

func play_hurt() -> void:
	play_animation("hurt")
	# Shake rápido
	var original := position
	var tween    := create_tween()
	for i in 4:
		var offset := Vector2(randf_range(-6,6), randf_range(-3,3))
		tween.tween_property(self, "position", original + offset, 0.05)
	tween.tween_property(self, "position", original, 0.05)
	await sprite.animation_finished
	play_idle()

func play_death() -> void:
	play_animation("death")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.4)
	await tween.finished
	# No volver a idle; la unidad permanece invisible

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
