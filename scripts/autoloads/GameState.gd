extends Node

# Autoload: progreso del jugador. Se carga al arrancar y se guarda al desbloquear un nivel o acabar el tutorial.
const PATH := "user://progress.cfg"
const SECTION := "progress"

signal progress_reset

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1
# El tutorial del nivel 1 ya se ha hecho o saltado.
var tutorial_done := false
# Enemigos que ya han salido en una partida, por nombre de archivo del EnemyData.
var seen_enemies: Array[String] = []

func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		# El archivo lo puede editar cualquiera: solo se acepta un entero >= 1.
		var value: Variant = file.get_value(SECTION, "current_level", 1)
		if typeof(value) == TYPE_INT and value >= 1:
			current_level = value
		var done: Variant = file.get_value(SECTION, "tutorial_done", false)
		if typeof(done) == TYPE_BOOL:
			tutorial_done = done
		var seen: Variant = file.get_value(SECTION, "seen_enemies", [])
		if typeof(seen) == TYPE_ARRAY:
			for key: Variant in seen:
				if typeof(key) == TYPE_STRING:
					seen_enemies.append(key)

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

## El tutorial se ha acabado o saltado: no vuelve a salir.
func complete_tutorial() -> void:
	tutorial_done = true
	_save()

func has_seen_enemy(data: EnemyData) -> bool:
	return data.resource_path.get_file() in seen_enemies

## Marca el enemigo como visto y guarda solo la primera vez.
func mark_enemy_seen(data: EnemyData) -> void:
	if has_seen_enemy(data):
		return
	seen_enemies.append(data.resource_path.get_file())
	_save()

# Vuelve al nivel 1 (con el tutorial otra vez), guarda y avisa para que el menú de niveles se reconstruya.
func reset_progress() -> void:
	current_level = 1
	tutorial_done = false
	seen_enemies.clear()
	_save()
	progress_reset.emit()

func _save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "current_level", current_level)
	file.set_value(SECTION, "tutorial_done", tutorial_done)
	file.set_value(SECTION, "seen_enemies", seen_enemies)
	if file.save(PATH) != OK:
		push_warning("GameState: no se pudo guardar " + PATH)
