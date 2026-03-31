## GachaScreen.gd
## Pantalla de invocaciones — "La Grieta del Destino".
## Árbol de nodos sugerido:
##   GachaScreen (Control)
##   ├── Background (TextureRect)         ← fondo mystical
##   ├── RiftAnimation (AnimatedSprite2D) ← la grieta animada
##   ├── PullButton1x (Button)
##   ├── PullButton10x (Button)
##   ├── AmberLabel (Label)               ← "🔶 1.440"
##   ├── PityBar (ProgressBar)
##   ├── PityLabel (Label)                ← "Pity: 23/90"
##   ├── ResultContainer (HBoxContainer)  ← tarjetas resultantes
##   │   └── [HeroCard instanciados]
##   ├── SkipButton (Button)              ← saltar animación
##   └── BackButton (Button)
class_name GachaScreen
extends Control

# ─── Nodos ────────────────────────────────────────────────────────────────────
@onready var amber_label: Label          = $TopBar/AmberLabel
@onready var pity_bar: ProgressBar       = $PityBar
@onready var pity_label: Label           = $TopBar/PityLabel
@onready var rift_anim: AnimatedSprite2D = $CenterContainer/VBoxContainer/RiftAnimation
@onready var result_container: HBoxContainer = $ResultContainer
@onready var pull_1x_btn: Button         = $CenterContainer/VBoxContainer/ButtonsContainer/PullButton1x
@onready var pull_10x_btn: Button        = $CenterContainer/VBoxContainer/ButtonsContainer/PullButton10x
@onready var skip_btn: Button            = $SkipButton

const HeroCardScene: PackedScene = preload("res://scenes/ui/HeroCard.tscn")

# ─── Estado ───────────────────────────────────────────────────────────────────
var is_animating: bool = false

# ─── Inicialización ───────────────────────────────────────────────────────────
func _ready() -> void:
	_refresh_currency_ui()
	_refresh_pity_ui()
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.gacha_system.pity_updated.connect(_on_pity_updated)
	GameManager.gacha_system.pull_completed.connect(_on_pull_completed)
	pull_1x_btn.text  = "Invocar x1\n🔶 %d" % GachaSystem.COST_SINGLE
	pull_10x_btn.text = "Invocar x10\n🔶 %d" % GachaSystem.COST_MULTI

# ─── UI ───────────────────────────────────────────────────────────────────────
func _refresh_currency_ui() -> void:
	amber_label.text = "🔶 %d" % GameManager.player_data.amber_shards

func _refresh_pity_ui() -> void:
	var pity := GameManager.player_data.pull_pity
	pity_bar.max_value = GachaSystem.PITY_CAP
	pity_bar.value     = pity
	pity_label.text    = "Pity: %d / %d  (%.1f%% Legendario)" % [
		pity,
		GachaSystem.PITY_CAP,
		GameManager.gacha_system.get_current_leg_rate() * 100.0
	]

# ─── Botones de Invocación ────────────────────────────────────────────────────
func _on_pull_1x_pressed() -> void:
	if is_animating:
		return
	_set_buttons_enabled(false)
	var success := GameManager.gacha_system.pull_single()
	if not success:
		_show_not_enough_amber()
		_set_buttons_enabled(true)

func _on_pull_10x_pressed() -> void:
	if is_animating:
		return
	_set_buttons_enabled(false)
	var success := GameManager.gacha_system.pull_multi()
	if not success:
		_show_not_enough_amber()
		_set_buttons_enabled(true)

# ─── Resultado ────────────────────────────────────────────────────────────────
func _on_pull_completed(results: Array[HeroData]) -> void:
	is_animating = true
	if skip_btn:
		skip_btn.visible = true
	_clear_results()

	# Animación de la grieta (opcional)
	if rift_anim and rift_anim.sprite_frames:
		rift_anim.play("open")
		await rift_anim.animation_finished

	# Mostrar tarjetas una a una
	for hero in results:
		var card: HeroCard = HeroCardScene.instantiate()
		result_container.add_child(card)
		card.setup(hero, GameManager.player_data.has_hero(hero.hero_id))
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(card, "modulate:a", 1.0, 0.3)
		await get_tree().create_timer(0.15).timeout

	is_animating = false
	if skip_btn:
		skip_btn.visible = false
	_set_buttons_enabled(true)

func _clear_results() -> void:
	for child in result_container.get_children():
		child.queue_free()

func _show_not_enough_amber() -> void:
	## Puedes reemplazar por un popup animado
	push_warning("[GachaScreen] Ámbar insuficiente.")
	# TODO: Mostrar popup "Ámbar insuficiente"

func _on_skip_pressed() -> void:
	## Muestra todos los resultados de golpe sin animación
	is_animating = false

# ─── Señales Externas ─────────────────────────────────────────────────────────
func _on_currency_changed(_new_amount: int) -> void:
	_refresh_currency_ui()

func _on_pity_updated(_current: int, _cap: int) -> void:
	_refresh_pity_ui()

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _set_buttons_enabled(enabled: bool) -> void:
	pull_1x_btn.disabled  = not enabled
	pull_10x_btn.disabled = not enabled

func _on_back_pressed() -> void:
	GameManager.go_to_scene("main_menu")
