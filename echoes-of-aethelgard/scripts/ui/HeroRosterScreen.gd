## HeroRosterScreen.gd
## Pantalla de lista de héroes del jugador.
## Árbol de nodos sugerido:
##   HeroRosterScreen (Control)
##   ├── Background (ColorRect)
##   ├── Title (Label)                    ← "Mis Héroes"
##   ├── ScrollContainer
##   │   └── HeroListContainer (VBoxContainer)
##   │       └── [HeroListItem instanciados]
##   └── BackButton (Button)
##
## HeroListItem (HBoxContainer):
##   ├── IconRect (TextureRect)           ← icono pequeño del héroe
##   ├── NameLabel (Label)
##   ├── LevelLabel (Label)
##   └── ViewButton (Button)
class_name HeroRosterScreen
extends Control

@onready var hero_list_container: VBoxContainer = $ScrollContainer/HeroListContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	_populate_hero_list()
	back_button.pressed.connect(_on_back_pressed)

func _populate_hero_list() -> void:
	# Limpiar lista existente
	for child in hero_list_container.get_children():
		child.queue_free()

	# Obtener héroes del jugador
	var player_heroes := GameManager.player_data.owned_heroes
	
	for hero_id in player_heroes:
		var hero_data: HeroData = GameManager.get_hero_data(hero_id)
		if hero_data == null:
			continue
		
		var item := _create_hero_list_item(hero_data)
		hero_list_container.add_child(item)

func _create_hero_list_item(hero: HeroData) -> HBoxContainer:
	var item := HBoxContainer.new()
	
	# ── Icono del héroe ─────────────────────────────────────────────────────
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Cargar icono desde el sistema de archivos
	var icon_path := "res://assets/sprites/heroes/%s/icon.png" % hero.hero_name
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	else:
		# Fallback: usar portrait si no hay icono
		var portrait_path := "res://assets/sprites/heroes/%s/portrait.png" % hero.hero_name
		if ResourceLoader.exists(portrait_path):
			icon_rect.texture = load(portrait_path)
	
	item.add_child(icon_rect)
	
	# ── Nombre ──────────────────────────────────────────────────────────────
	var name_label := Label.new()
	name_label.text = hero.hero_name
	name_label.custom_minimum_size = Vector2(150, 0)
	item.add_child(name_label)
	
	# ── Nivel ───────────────────────────────────────────────────────────────
	var level_label := Label.new()
	var hero_level := GameManager.player_data.get_hero_level(hero.hero_id)
	level_label.text = "Lv. %d" % hero_level
	level_label.custom_minimum_size = Vector2(60, 0)
	item.add_child(level_label)
	
	# ── Rareza ──────────────────────────────────────────────────────────────
	var rarity_label := Label.new()
	rarity_label.text = hero.get_rarity_label()
	rarity_label.modulate = hero.get_rarity_color()
	item.add_child(rarity_label)
	
	# ── Botón Ver ───────────────────────────────────────────────────────────
	var view_btn := Button.new()
	view_btn.text = "Ver"
	view_btn.pressed.connect(func(): _on_hero_selected(hero))
	item.add_child(view_btn)
	
	return item

func _on_hero_selected(hero: HeroData) -> void:
	print("[HeroRoster] Seleccionado: %s" % hero.hero_name)
	# TODO: Abrir pantalla de detalles del héroe

func _on_back_pressed() -> void:
	GameManager.go_to_scene("hub_camp")
