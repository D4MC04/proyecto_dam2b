extends Node

# Autoload: progreso del jugador. Se carga al arrancar y se guarda al desbloquear un nivel.
const PATH := "user://progress.cfg"
const SECTION := "progress"

signal progress_reset

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1

func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		# El archivo lo puede editar cualquiera: solo se acepta un entero >= 1.
		var value: Variant = file.get_value(SECTION, "current_level", 1)
		if typeof(value) == TYPE_INT and value >= 1:
			current_level = value

# i es el índice (desde 0) del nivel en GameData.levels.
func is_unlocked(i: int) -> bool:
	# Temporal: todos los niveles abiertos para probar mientras el juego no está terminado.
	# Para volver a la progresión normal: `return i < current_level`.
	return true

# Se llama al ganar el nivel número `number` (desde 1): si era el más alto desbloqueado, abre el siguiente.
func complete_level(number: int) -> void:
	if number != current_level or number >= GameData.levels.size():
		return
	current_level += 1
	_save()

# Vuelve al nivel 1, guarda y avisa para que el menú de niveles se reconstruya.
func reset_progress() -> void:
	current_level = 1
	_save()
	progress_reset.emit()

func _save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "current_level", current_level)
	if file.save(PATH) != OK:
		push_warning("GameState: no se pudo guardar " + PATH)
