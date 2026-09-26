extends AudioStreamPlayer

# Autoload: al vivir fuera de la escena actual, la música no se corta con change_scene.
const MUSICA := "res://assets/audio/music/theme.mp3"

# El estado vive aquí, así que se conserva al cambiar de escena.
var volumen := 1.0  # lineal, 0..1
var muteado := false

func set_volume(v: float):
	volumen = clampf(v, 0.0, 1.0)
	_aplicar()

func toggle_mute():
	muteado = not muteado
	_aplicar()

func _aplicar():
	volume_linear = 0.0 if muteado else volumen

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue sonando con el juego en pausa
	if not ResourceLoader.exists(MUSICA):
		push_warning("MusicManager: falta " + MUSICA)
		return
	var pista: AudioStreamMP3 = load(MUSICA)
	pista.loop = true
	stream = pista
	play()
