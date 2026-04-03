## HeroCollectionService.gd
## Lógica de datos de colección de héroes (carga y filtros) separada de la UI
extends Node

class_name HeroCollectionService

static func load_all_heroes() -> Array[HeroData]:
	var heroes: Array[HeroData] = []
	var source_path := "res://resources/heroes_data"
	
	print("[HeroCollectionService] Intentando cargar desde:", source_path)
	
	var dir = DirAccess.open(source_path)
	if not dir:
		push_error("[HeroCollectionService] No se pudo abrir DirAccess en: %s" % source_path)
		push_error("[HeroCollectionService] Error code: ", DirAccess.get_open_error())
		return heroes

	print("[HeroCollectionService] Directorio abierto correctamente")
	
	dir.list_dir_begin()
	var filename := dir.get_next()
	var file_count := 0
	
	while filename != "":
		if not filename.begins_with("."):
			file_count += 1
			print("[HeroCollectionService] Archivo encontrado: %s" % filename)
			
			if filename.ends_with(".tres"):
				var path := "%s/%s" % [source_path, filename]
				print("[HeroCollectionService] Intentando cargar: %s" % path)
				
				var hero = ResourceLoader.load(path) as HeroData
				if hero:
					heroes.append(hero)
					print("[HeroCollectionService] ✓ Héroe cargado: %s" % hero.hero_name)
				else:
					push_warning("[HeroCollectionService] ✗ No se pudo cargar %s" % path)
		
		filename = dir.get_next()
	
	print("[HeroCollectionService] Total de archivos encontrados: %d" % file_count)
	print("[HeroCollectionService] Total de héroes cargados: %d" % heroes.size())

	if heroes.size() > 0:
		heroes.sort_custom(func(a, b): return _sort_heroes_by_name(a, b))
	
	return heroes

static func filter_heroes(heroes: Array, filter: String) -> Array:
	match filter:
		"owned":
			return heroes.filter(func(h): return GameManager.player_data.has_hero(h.hero_id))
		"all":
			return heroes.duplicate()
		_:
			return heroes.duplicate()

static func _sort_heroes_by_name(a: HeroData, b: HeroData) -> bool:
	return String(a.hero_name).nocasecmp_to(String(b.hero_name)) < 0
