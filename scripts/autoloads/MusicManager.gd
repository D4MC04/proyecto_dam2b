extends AudioStreamPlayer

# Autoload: al vivir fuera de la escena actual, la música no se corta con change_scene.
const MUSIC_PATH := "res://assets/audio/music/theme.ogg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue sonando con el juego en pausa
	bus = &"Music"  # el volumen lo lleva Settings a través del bus
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("MusicManager: falta " + MUSIC_PATH)
		return
	var track: AudioStreamOggVorbis = load(MUSIC_PATH)
	stream = track
	play()
