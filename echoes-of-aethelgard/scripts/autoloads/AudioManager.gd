## AudioManager.gd
## Sistema de audio global para música y efectos de sonido
extends Node

# Reproductores de audio
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Volúmenes
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# Música actual
var current_music: String = ""

func _ready() -> void:
	# Crear reproductores
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	# Configurar volúmenes
	music_player.volume_db = linear_to_db(music_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume)
	
	print("[AudioManager] Iniciado")

func play_music(music_name: String, fade_duration: float = 1.0) -> void:
	if current_music == music_name and music_player.playing:
		return
	
	var music_path := "res://assets/audio/music/%s.mp3" % music_name
	if not FileAccess.file_exists(music_path):
		music_path = "res://assets/audio/music/%s.ogg" % music_name
		if not FileAccess.file_exists(music_path):
			push_warning("[AudioManager] Música no encontrada: %s" % music_name)
			return
	
	var stream := load(music_path)
	if stream:
		# Fade out de la música actual
		if music_player.playing:
			var tween := create_tween()
			tween.tween_property(music_player, "volume_db", -80, fade_duration)
			await tween.finished
		
		# Cargar nueva música
		music_player.stream = stream
		music_player.volume_db = -80
		music_player.play()
		current_music = music_name
		
		# Fade in
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_duration)

func stop_music(fade_duration: float = 1.0) -> void:
	if music_player.playing:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await tween.finished
		music_player.stop()
		current_music = ""

func play_sfx(sfx_name: String) -> void:
	var sfx_path := "res://assets/audio/sfx/%s.wav" % sfx_name
	if not FileAccess.file_exists(sfx_path):
		sfx_path = "res://assets/audio/sfx/%s.ogg" % sfx_name
		if not FileAccess.file_exists(sfx_path):
			return
	
	var stream := load(sfx_path)
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	sfx_player.volume_db = linear_to_db(sfx_volume)
