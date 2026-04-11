## TestManager.gd
## Validador de integridad de datos del juego.
## Ejecutar desde TestScene.tscn para detectar heroes_data incompletos.
## NO instancia Autoloads — usa los que ya están activos en el árbol.
extends Node

const HERO_IDS := [
	"aethan_paladin", "aldric_archimago", "gorn_barbaro",
	"kael_soldado",   "lyra_arquera",     "mira_sanadora",
	"seraphel_jueza", "theron_cazador",   "varra_mercenaria", "vex_nigromante",
]

func _ready() -> void:
	print("=== Validación de integridad de datos ===")
	_validate_hero_data()
	_validate_save_roundtrip()
	print("=== Validación completada ===")

# ─── Validar que todos los HeroData tienen campos críticos ───────────────────
func _validate_hero_data() -> void:
	var errors := 0
	for hero_id in HERO_IDS:
		var path := "res://resources/heroes_data/%s.tres" % hero_id
		if not ResourceLoader.exists(path):
			push_error("[Test] FALTA archivo: %s" % path)
			errors += 1
			continue

		var hero := load(path) as HeroData
		if hero == null:
			push_error("[Test] No se pudo cargar como HeroData: %s" % path)
			errors += 1
			continue

		# Validar campos críticos para combate
		if hero.base_hp <= 0:
			push_error("[Test] %s tiene base_hp = %d (debe ser > 0)" % [hero_id, hero.base_hp])
			errors += 1
		if hero.base_atk <= 0:
			push_error("[Test] %s tiene base_atk = %d (debe ser > 0)" % [hero_id, hero.base_atk])
			errors += 1
		if hero.base_def < 0:
			push_error("[Test] %s tiene base_def negativo" % hero_id)
			errors += 1
		if hero.skill_basic == null:
			push_error("[Test] %s no tiene skill_basic" % hero_id)
			errors += 1
		if hero.hero_id != hero_id:
			push_error("[Test] %s tiene hero_id incorrecto: '%s'" % [hero_id, hero.hero_id])
			errors += 1

	if errors == 0:
		print("✓ HeroData: todos los %d héroes son válidos" % HERO_IDS.size())
	else:
		push_error("✗ HeroData: %d errores encontrados" % errors)

# ─── Validar que el save/load no pierde datos ─────────────────────────────────
func _validate_save_roundtrip() -> void:
	# Usar el GameManager activo, NO instanciar uno nuevo
	var original_amber: int = GameManager.player_data.amber_shards
	var original_gold: int  = GameManager.player_data.gold
	var original_team: Array = GameManager.player_data.active_team.duplicate()

	# Serializar y deserializar
	var saved_dict: Dictionary = GameManager.player_data.to_dict()
	var test_player := PlayerData.new()
	test_player.load_from_dict(saved_dict)

	var ok := true
	if test_player.amber_shards != original_amber:
		push_error("[Test] Save/load: amber_shards no coincide (%d → %d)" % [original_amber, test_player.amber_shards])
		ok = false
	if test_player.gold != original_gold:
		push_error("[Test] Save/load: gold no coincide (%d → %d)" % [original_gold, test_player.gold])
		ok = false
	if test_player.active_team != original_team:
		push_error("[Test] Save/load: active_team no coincide")
		ok = false

	if ok:
		print("✓ Save/load roundtrip: datos íntegros")
	else:
		push_error("✗ Save/load roundtrip: pérdida de datos detectada")
