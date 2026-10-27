extends Node

# Autoload: progreso del jugador. Se carga al arrancar y se guarda al desbloquear un nivel o acabar el tutorial.
const PATH := "user://progress.cfg"
const SECTION := "progress"

signal progress_reset

const MENU_THEME: Theme = preload("res://assets/ui/menu_theme.tres")
const TOAST_TIME := 3.0
# Logros por orden: id -> [nombre, descripción]. Cómo se cumple cada uno está en _is_done().
const ACHIEVEMENTS: Dictionary = {
	"first_win": ["Primera victoria", "Gana un nivel"],
	"flawless": ["Intacto", "Gana un nivel sin perder vida"],
	"wins_5": ["Veterano", "Gana 5 niveles"],
	"all_levels": ["Sector despejado", "Gana el último nivel"],
	"kills_100": ["Cazador", "Destruye 100 naves"],
	"kills_1000": ["Exterminador", "Destruye 1000 naves"],
	"seen_10": ["Observador", "Descubre 10 tipos de nave"],
	"turrets_50": ["Constructor", "Construye 50 torretas"],
	"fuse_first": ["Primera mejora", "Mejora una torreta"],
	"fuse_all": ["Maestro de mejoras", "Mejora todas las torretas"],
	"power_first": ["Poder desatado", "Usa un poder"],
	"perfect_10": ["Defensa perfecta", "Logra 10 oleadas perfectas"],
}

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1
# El tutorial del nivel 1 ya se ha hecho o saltado.
var tutorial_done := false
# Enemigos que ya han salido en una partida, por nombre de archivo del EnemyData.
var seen_enemies: Array[String] = []
# Contadores acumulados entre partidas: wins, kills, turrets, powers, perfect_waves, spent y built_<torreta>.
var stats: Dictionary = {}
# Torretas fusionadas alguna vez, por nombre de archivo.
var fused_turrets: Array[String] = []
var unlocked: Array[String] = []
# Segundos jugados en niveles, en tiempo real.
var play_time: float = 0.0

var _toasts: VBoxContainer

func _ready() -> void:
	_make_toast_layer()
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
		var counters: Variant = file.get_value(SECTION, "stats", {})
		if typeof(counters) == TYPE_DICTIONARY:
			for key: Variant in counters:
				if typeof(key) == TYPE_STRING and typeof(counters[key]) == TYPE_INT:
					stats[key] = counters[key]
		# El progreso guardado antes del cambio de tower a turret usa los nombres antiguos: se pasan a los nuevos.
		_load_list(file, "fused_turrets" if file.has_section_key(SECTION, "fused_turrets") else "fused_towers", fused_turrets)
		_load_list(file, "unlocked", unlocked)
		if stats.has("towers"):
			stats["turrets"] = stats.get("turrets", 0) + stats["towers"]
			stats.erase("towers")
		var old_achievement := unlocked.find("towers_50")
		if old_achievement >= 0:
			unlocked[old_achievement] = "turrets_50"
		var time: Variant = file.get_value(SECTION, "play_time", 0.0)
		if typeof(time) == TYPE_FLOAT and time >= 0.0:
			play_time = time

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
	_check_achievements()
	_save()

## Suma `amount` a un contador de logros (wins, kills, turrets, powers, perfect_waves). No guarda: ver flush().
func add_stat(key: String, amount: int = 1) -> void:
	stats[key] = stats.get(key, 0) + amount
	_check_achievements()

## Suma segundos jugados. No guarda: ver flush().
func add_play_time(seconds: float) -> void:
	play_time += seconds

## Torreta más construida: su nombre de archivo sin extensión, o "" si no se ha construido ninguna.
func favorite_turret() -> String:
	var best := ""
	var best_count := 0
	for key: String in stats:
		if key.begins_with("built_") and stats[key] > best_count:
			best = key.trim_prefix("built_")
			best_count = stats[key]
	return best

## Anota que esta torreta se ha fusionado alguna vez.
func register_fusion(fused: TurretData) -> void:
	var file := fused.resource_path.get_file()
	if file not in fused_turrets:
		fused_turrets.append(file)
	_check_achievements()

## Un nivel se ha ganado; `flawless` es que la estación acabó sin daño.
func register_win(number: int, flawless: bool) -> void:
	if flawless:
		_unlock("flawless")
	if number == GameData.levels.size():
		_unlock("all_levels")
	add_stat("wins")
	flush()

## Guarda los contadores (se llama al acabar oleadas y niveles, no a cada baja).
func flush() -> void:
	_save()

func _is_done(id: String) -> bool:
	match id:
		"first_win": return stats.get("wins", 0) >= 1
		"wins_5": return stats.get("wins", 0) >= 5
		"kills_100": return stats.get("kills", 0) >= 100
		"kills_1000": return stats.get("kills", 0) >= 1000
		"seen_10": return seen_enemies.size() >= 10
		"turrets_50": return stats.get("turrets", 0) >= 50
		"fuse_first": return not fused_turrets.is_empty()
		"fuse_all": return fused_turrets.size() >= Navedex.TURRET_FILES.size() / 2
		"power_first": return stats.get("powers", 0) >= 1
		"perfect_10": return stats.get("perfect_waves", 0) >= 10
	return false

func _check_achievements() -> void:
	for id in ACHIEVEMENTS:
		if id not in unlocked and _is_done(id):
			_unlock(id)

func _unlock(id: String) -> void:
	if id in unlocked:
		return
	unlocked.append(id)
	_save()
	_show_toast(ACHIEVEMENTS[id][0])

func _make_toast_layer() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 200
	add_child(layer)
	_toasts = VBoxContainer.new()
	_toasts.theme = MENU_THEME
	_toasts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toasts.position = Vector2(-12, 12)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_toasts)

# Aviso pequeño arriba a la derecha que se desvanece solo.
func _show_toast(title: String) -> void:
	var label := Label.new()
	label.text = "LOGRO: " + title
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("40e0f0"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	_toasts.add_child(label)
	var tween := create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _load_list(file: ConfigFile, key: String, into: Array[String]) -> void:
	var list: Variant = file.get_value(SECTION, key, [])
	if typeof(list) == TYPE_ARRAY:
		for item: Variant in list:
			if typeof(item) == TYPE_STRING:
				into.append(item)

# Vuelve al nivel 1 (con el tutorial otra vez), guarda y avisa para que el menú de niveles se reconstruya.
func reset_progress() -> void:
	current_level = 1
	tutorial_done = false
	seen_enemies.clear()
	stats.clear()
	fused_turrets.clear()
	unlocked.clear()
	play_time = 0.0
	_save()
	progress_reset.emit()

func _save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "current_level", current_level)
	file.set_value(SECTION, "tutorial_done", tutorial_done)
	file.set_value(SECTION, "seen_enemies", seen_enemies)
	file.set_value(SECTION, "stats", stats)
	file.set_value(SECTION, "fused_turrets", fused_turrets)
	file.set_value(SECTION, "unlocked", unlocked)
	file.set_value(SECTION, "play_time", play_time)
	if file.save(PATH) != OK:
		push_warning("GameState: no se pudo guardar " + PATH)
