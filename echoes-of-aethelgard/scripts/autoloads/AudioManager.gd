## AudioManager.gd
## Sistema de audio global con pool de SFX y persistencia de volumen
extends Node

# Pool de reproductores de audio
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 6  # Reproductores SFX simultáneos

# Volúmenes
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var is_muted: bool = false
var _pre_mute_music: float = 0.7
var _pre_mute_sfx: float = 0.8

# Música actual
var current_music: String = ""

func _ready() -> void:
	# Crear reproductor de música
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	# Crear pool de reproductores SFX
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

	# Cargar volúmenes guardados
	_load_volume_settings()

	# Configurar volúmenes
	music_player.volume_db = linear_to_db(music_volume)
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)

	print("[AudioManager] Iniciado — Pool SFX: %d" % SFX_POOL_SIZE)

func _load_volume_settings() -> void:
	# Se carga después de GameManager, así que intentamos leer settings
	# Los valores se actualizarán cuando GameManager esté listo
	pass

func apply_saved_settings(settings: Dictionary) -> void:
	music_volume = settings.get("music_volume", 0.7)
	sfx_volume = settings.get("sfx_volume", 0.8)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume)
	for player in sfx_players:
		if player:
			player.volume_db = linear_to_db(sfx_volume)

# ─── Música ───────────────────────────────────────────────────────────────────
func play_music(music_name: String, fade_duration: float = 1.0) -> void:
	if current_music == music_name and music_player.playing:
		return

	var music_path := _find_audio_file("res://assets/audio/music/", music_name)
	if music_path.is_empty():
		push_warning("[AudioManager] Música no encontrada: %s" % music_name)
		return

	var stream := load(music_path)
	if stream:
		# Fade out de la música actual
		if music_player.playing:
			var tween := create_tween()
			tween.tween_property(music_player, "volume_db", -80, fade_duration * 0.5)
			await tween.finished

		# Cargar nueva música
		music_player.stream = stream
		music_player.volume_db = -80
		music_player.play()
		current_music = music_name

		# Fade in
		var target_db := linear_to_db(music_volume) if not is_muted else -80.0
		var tween_in := create_tween()
		tween_in.tween_property(music_player, "volume_db", target_db, fade_duration * 0.5)

func stop_music(fade_duration: float = 1.0) -> void:
	if music_player.playing:
		var tween := create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await tween.finished
		music_player.stop()
		current_music = ""

# ─── Efectos de Sonido (Pool) ────────────────────────────────────────────────
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	if is_muted:
		return

	var sfx_path := _find_audio_file("res://assets/audio/sfx/", sfx_name)
	if sfx_path.is_empty():
		return

	var stream := load(sfx_path)
	if not stream:
		return

	# Buscar reproductor libre
	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume)
		if pitch_variation > 0:
			player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		else:
			player.pitch_scale = 1.0
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Primero buscar uno que no esté reproduciendo
	for player in sfx_players:
		if not player.playing:
			return player
	# Si todos están ocupados, usar el que lleve más tiempo (el primero)
	return sfx_players[0]

# ─── Volumen ──────────────────────────────────────────────────────────────────
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if not is_muted:
		music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	if not is_muted:
		for player in sfx_players:
			player.volume_db = linear_to_db(sfx_volume)

# ─── Mute ─────────────────────────────────────────────────────────────────────
func toggle_mute() -> void:
	if is_muted:
		unmute()
	else:
		mute()

func mute() -> void:
	is_muted = true
	_pre_mute_music = music_volume
	_pre_mute_sfx = sfx_volume
	music_player.volume_db = -80
	for player in sfx_players:
		player.volume_db = -80

func unmute() -> void:
	is_muted = false
	music_player.volume_db = linear_to_db(_pre_mute_music)
	for player in sfx_players:
		player.volume_db = linear_to_db(_pre_mute_sfx)

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _find_audio_file(base_path: String, file_name: String) -> String:
	for ext in ["mp3", "ogg", "wav"]:
		var path := "%s%s.%s" % [base_path, file_name, ext]
		if FileAccess.file_exists(path):
			return path
	return ""
