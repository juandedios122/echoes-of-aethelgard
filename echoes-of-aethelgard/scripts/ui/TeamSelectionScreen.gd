## TeamSelectionScreen.gd
## Pantalla de selección de equipo antes de la batalla.
## Lee GameManager.pending_battle_config para saber contra qué se lucha.
extends Control

@onready var back_button: TextureButton  = $MarginContainer/VBoxContainer/TopBar/BackButton
@onready var hero_grid: GridContainer    = $MarginContainer/VBoxContainer/ContentContainer/AvailableHeroesPanel/VBoxContainer/ScrollContainer/HeroGrid
@onready var team_label: Label           = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Label
@onready var slot1: PanelContainer       = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot1
@onready var slot2: PanelContainer       = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot2
@onready var slot3: PanelContainer       = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot3
@onready var start_battle_button: Button = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/StartBattleButton

const HERO_CARD_SCENE := preload("res://scenes/ui/HeroRosterCard.tscn")

var all_heroes: Array[HeroData]  = []
var selected_team: Array[String] = []
var team_slots: Array[PanelContainer] = []

# ─── IDs de todos los héroes existentes ──────────────────────────────────────
const ALL_HERO_IDS := [
	"aethan_paladin", "aldric_archimago", "gorn_barbaro",
	"kael_soldado",   "lyra_arquera",     "mira_sanadora",
	"seraphel_jueza", "theron_cazador",   "varra_mercenaria", "vex_nigromante",
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	team_slots = [slot1, slot2, slot3]

	# Pre-cargar el equipo activo como selección inicial
	selected_team = GameManager.player_data.active_team.duplicate()

	_load_owned_heroes()
	_populate_hero_grid()
	_update_team_display()
	_update_enemy_preview()

func _load_owned_heroes() -> void:
	all_heroes.clear()
	for hero_id in ALL_HERO_IDS:
		if not GameManager.player_data.has_hero(hero_id):
			continue
		var path := "res://resources/heroes_data/%s.tres" % hero_id
		if ResourceLoader.exists(path):
			var hero := load(path) as HeroData
			if hero:
				all_heroes.append(hero)

func _populate_hero_grid() -> void:
	for child in hero_grid.get_children():
		child.queue_free()

	for hero in all_heroes:
		var card := HERO_CARD_SCENE.instantiate()
		hero_grid.add_child(card)
		card.setup(hero, true)
		card.pressed.connect(_on_hero_selected.bind(hero))

# ─── Mostrar previsualización del enemigo ─────────────────────────────────────
func _update_enemy_preview() -> void:
	## Mostrar el nombre del grupo de enemigos en el título de la pantalla
	var cfg     := GameManager.pending_battle_config
	var title   := get_node_or_null("MarginContainer/VBoxContainer/TopBar/TitleLabel") as Label
	var info    := get_node_or_null("MarginContainer/VBoxContainer/InfoLabel") as Label

	if title and not cfg.is_empty():
		title.text = "⚔️ Seleccionar Equipo"

	if info and not cfg.is_empty():
		var stage_name: String = cfg.get("stage_name", "Batalla")
		var enemy_level: int   = cfg.get("enemy_level", 1)
		var enemies: Array     = cfg.get("enemies", [])
		var enemy_names: Array = []
		for eid in enemies:
			var epath := "res://resources/heroes_data/%s.tres" % eid
			if ResourceLoader.exists(epath):
				var ed := load(epath) as HeroData
				if ed:
					enemy_names.append(ed.hero_name)
				else:
					enemy_names.append(eid)
			else:
				enemy_names.append(eid)
		info.text = "Vs. %s — %s  (Nivel %d)" % [
			stage_name,
			", ".join(enemy_names),
			enemy_level
		]

# ─── Selección de héroes ──────────────────────────────────────────────────────
func _on_hero_selected(hero: HeroData) -> void:
	if hero.hero_id in selected_team:
		selected_team.erase(hero.hero_id)
	elif selected_team.size() < 3:
		selected_team.append(hero.hero_id)
	_update_team_display()

func _update_team_display() -> void:
	team_label.text = "Equipo (%d/3)" % selected_team.size()

	for i in 3:
		var slot := team_slots[i]
		for child in slot.get_children():
			child.queue_free()

		if i < selected_team.size():
			var hero_id: String = selected_team[i]
			var hero: HeroData  = _get_hero_by_id(hero_id)
			if hero:
				var vbox := VBoxContainer.new()
				slot.add_child(vbox)

				# Portrait del héroe en el slot
				if hero.portrait:
					var tex := TextureRect.new()
					tex.texture            = hero.portrait
					tex.custom_minimum_size = Vector2(60, 60)
					tex.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					vbox.add_child(tex)

				var name_lbl := Label.new()
				name_lbl.text = hero.hero_name
				name_lbl.add_theme_color_override("font_color", hero.get_rarity_color())
				name_lbl.add_theme_font_size_override("font_size", 18)
				name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(name_lbl)

				var lvl_lbl := Label.new()
				lvl_lbl.text = "Lv. %d" % GameManager.player_data.get_hero_level(hero_id)
				lvl_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				lvl_lbl.add_theme_font_size_override("font_size", 14)
				lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(lvl_lbl)

				var remove_btn := Button.new()
				remove_btn.text = "✖"
				remove_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
				remove_btn.pressed.connect(_on_remove_hero.bind(i))
				vbox.add_child(remove_btn)
		else:
			var empty_lbl := Label.new()
			empty_lbl.text = "— Vacío —"
			empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
			empty_lbl.add_theme_font_size_override("font_size", 16)
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
			slot.add_child(empty_lbl)

	start_battle_button.disabled = selected_team.is_empty()

func _on_remove_hero(slot_index: int) -> void:
	if slot_index < selected_team.size():
		selected_team.remove_at(slot_index)
		_update_team_display()

func _get_hero_by_id(hero_id: String) -> HeroData:
	for hero in all_heroes:
		if hero.hero_id == hero_id:
			return hero
	return null

# ─── Iniciar batalla ──────────────────────────────────────────────────────────
func _on_start_battle_pressed() -> void:
	if selected_team.is_empty():
		return

	# Guardar el equipo elegido
	GameManager.player_data.set_active_team(selected_team)
	GameManager.save_game()

	# Usar la config de enemigos que el mapa guardó en pending_battle_config.
	# Si no hay config (p.ej. batalla desde el hub directamente), usar defaults.
	var battle_cfg := GameManager.pending_battle_config
	if battle_cfg.is_empty():
		var chapter := GameManager.player_data.current_chapter
		battle_cfg = {
			"enemies"    : ["vex_nigromante", "gorn_barbaro"],
			"enemy_level": maxi(1, chapter * 2),
			"stage_name" : "Capítulo %d" % chapter,
		}

	GameManager.pending_battle_config = {}   # Limpiar para el próximo uso
	GameManager.go_to_scene("battle_scene", battle_cfg)

func _on_back_pressed() -> void:
	GameManager.go_to_scene("exploration_map")
