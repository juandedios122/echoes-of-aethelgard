## martial_hero_frames_builder.gd
## RUTA: Pega este archivo en res://tools/martial_hero_frames_builder.gd
## USO: Adjúntalo a un Node cualquiera en una escena temporal, corre la escena una vez,
##      y te genera el archivo res://resources/heroes/kael_soldado.tres actualizado.
## BORRA el script y el nodo después de usarlo.
##
## IMPORTANTE: Primero pon los archivos del Martial Hero aquí:
##   res://assets/sprites/Kael/Kael_spritesheet_idle.png    (era Idle.png)    1600×200 = 8 frames
##   res://assets/sprites/Kael/Kael_spritesheet_walk.png    (era Run.png)     1600×200 = 8 frames
##   res://assets/sprites/Kael/Kael_spritesheet_attack.png  (era Attack1.png) 1200×200 = 6 frames
##   res://assets/sprites/Kael/Kael_spritesheet_hurt.png    (era Take Hit.png) 800×200 = 4 frames
##   res://assets/sprites/Kael/Kael_spritesheet_death.png   (era Death.png)   1200×200 = 6 frames

extends Node

const FRAME_HEIGHT : int = 200

# Mapa de animación → { archivo, total_frames, loop, speed }
const ANIM_CONFIG := {
	"idle"   : { "file": "res://assets/sprites/Kael/Kael_spritesheet_idle.png",   "frames": 8, "loop": true,  "speed": 8.0  },
	"walk"   : { "file": "res://assets/sprites/Kael/Kael_spritesheet_walk.png",   "frames": 8, "loop": true,  "speed": 10.0 },
	"attack" : { "file": "res://assets/sprites/Kael/Kael_spritesheet_attack.png", "frames": 6, "loop": false, "speed": 12.0 },
	"hurt"   : { "file": "res://assets/sprites/Kael/Kael_spritesheet_hurt.png",   "frames": 4, "loop": false, "speed": 10.0 },
	"death"  : { "file": "res://assets/sprites/Kael/Kael_spritesheet_death.png",  "frames": 6, "loop": false, "speed": 6.0  },
}

const OUTPUT_PATH := "res://resources/heroes/kael_soldado.tres"

func _ready() -> void:
	print("[MartialHeroBuilder] Iniciando construcción de SpriteFrames...")
	
	# Verificar que existen los archivos antes de continuar
	for anim_name in ANIM_CONFIG:
		var cfg : Dictionary = ANIM_CONFIG[anim_name]
		if not ResourceLoader.exists(cfg["file"]):
			push_error("[MartialHeroBuilder] FALTA: %s" % cfg["file"])
			push_error("Asegúrate de haber copiado los archivos del Martial Hero con los nombres correctos.")
			return
	
	var sf := SpriteFrames.new()
	
	# Eliminar animación "default" que crea Godot automáticamente
	if sf.has_animation("default"):
		sf.remove_animation("default")
	
	for anim_name in ANIM_CONFIG:
		var cfg : Dictionary = ANIM_CONFIG[anim_name]
		var texture := load(cfg["file"]) as Texture2D
		
		if texture == null:
			push_error("[MartialHeroBuilder] No se pudo cargar: %s" % cfg["file"])
			continue
		
		var total_frames : int = cfg["frames"]
		var frame_width  : int = texture.get_width() / total_frames
		
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, cfg["loop"])
		sf.set_animation_speed(anim_name, cfg["speed"])
		
		for i in total_frames:
			var atlas := AtlasTexture.new()
			atlas.atlas  = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, FRAME_HEIGHT)
			sf.add_frame(anim_name, atlas)
		
		print("[MartialHeroBuilder] ✓ %s: %d frames de %dx%d" % [anim_name, total_frames, frame_width, FRAME_HEIGHT])
	
	# Guardar el recurso
	var err := ResourceSaver.save(sf, OUTPUT_PATH)
	if err == OK:
		print("[MartialHeroBuilder] ✓ Guardado en: %s" % OUTPUT_PATH)
		print("[MartialHeroBuilder] Ahora Kael usa los sprites del Martial Hero.")
		print("[MartialHeroBuilder] Puedes borrar este script.")
	else:
		push_error("[MartialHeroBuilder] Error al guardar: código %d" % err)
