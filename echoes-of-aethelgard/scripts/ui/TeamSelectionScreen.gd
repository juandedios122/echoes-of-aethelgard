## TeamSelectionScreen.gd
## Pantalla para seleccionar el equipo antes de entrar a batalla
extends Control

@onready var back_button: TextureButton = $MarginContainer/VBoxContainer/TopBar/BackButton
@onready var hero_grid: GridContainer = $MarginContainer/VBoxContainer/ContentContainer/AvailableHeroesPanel/VBoxContainer/ScrollContainer/HeroGrid
@onready var team_label: Label = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Label
@onready var slot1: PanelContainer = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot1
@onready var slot2: PanelContainer = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot2
@onready var slot3: PanelContainer = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/Slot3
@onready var start_battle_button: Button = $MarginContainer/VBoxContainer/ContentContainer/SelectedTeamPanel/VBoxContainer/StartBattleButton

const HERO_CARD_SCENE := preload("res://scenes/ui/HeroRosterCard.tscn")

var all_heroes: Array[HeroData] = []
var selected_team: Array[String] = []
var team_slots: Array[PanelContainer] = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	start_battle_button.pressed.connect(_on_start_battle_pressed)
	
	team_slots = [slot1, slot2, slot3]
	
	_load_owned_heroes()
	_populate_hero_grid()
	_update_team_display()

func _load_owned_heroes() -> void:
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
		if hero and GameManager.player_data.has_hero(hero.hero_id):
			all_heroes.append(hero)

func _populate_hero_grid() -> void:
	for child in hero_grid.get_children():
		child.queue_free()
	
	for hero in all_heroes:
		var card := HERO_CARD_SCENE.instantiate()
		hero_grid.add_child(card)
		card.setup(hero, true)
		card.pressed.connect(_on_hero_selected.bind(hero))

func _on_hero_selected(hero: HeroData) -> void:
	# Si ya está en el equipo, lo removemos
	if hero.hero_id in selected_team:
		selected_team.erase(hero.hero_id)
	# Si no está y hay espacio, lo agregamos
	elif selected_team.size() < 3:
		selected_team.append(hero.hero_id)
	
	_update_team_display()

func _update_team_display() -> void:
	team_label.text = "Equipo Seleccionado (%d/3)" % selected_team.size()
	
	# Actualizar slots
	for i in 3:
		var slot := team_slots[i]
		# Limpiar contenido anterior
		for child in slot.get_children():
			child.queue_free()
		
		if i < selected_team.size():
			var hero_id: String = selected_team[i]
			var hero: HeroData = _get_hero_by_id(hero_id)
			if hero:
				var vbox := VBoxContainer.new()
				slot.add_child(vbox)
				
				var name_label := Label.new()
				name_label.text = hero.hero_name
				name_label.add_theme_color_override("font_color", hero.get_rarity_color())
				name_label.add_theme_font_size_override("font_size", 20)
				name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(name_label)
				
				var level: int = GameManager.player_data.get_hero_level(hero_id)
				var level_label := Label.new()
				level_label.text = "Nivel %d" % level
				level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
				level_label.add_theme_font_size_override("font_size", 16)
				level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(level_label)
				
				var remove_btn := Button.new()
				remove_btn.text = "✖ Remover"
				remove_btn.pressed.connect(_on_remove_hero.bind(i))
				vbox.add_child(remove_btn)
		else:
			var empty_label := Label.new()
			empty_label.text = "Vacío - Click en un héroe"
			empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			empty_label.add_theme_font_size_override("font_size", 18)
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			slot.add_child(empty_label)
	
	# Habilitar/deshabilitar botón de batalla
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

func _on_start_battle_pressed() -> void:
	if selected_team.is_empty():
		return
	
	# Guardar el equipo seleccionado
	GameManager.player_data.set_active_team(selected_team)
	GameManager.save_game()
	
	# Configurar batalla de prueba
	var battle_config := {
		"enemies": ["wolf_common", "skeleton_warrior"],
		"enemy_level": 5,
		"stage_name": "Prueba de Combate"
	}
	
	GameManager.go_to_scene("battle_scene", battle_config)

func _on_back_pressed() -> void:
	GameManager.go_to_scene("exploration_map")
