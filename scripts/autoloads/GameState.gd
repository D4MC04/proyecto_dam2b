extends Node

# Autoload: progreso del jugador. Hay SLOT_COUNT partidas, cada una en su archivo; se guarda al desbloquear un nivel, acabar el tutorial, etc.
const SLOT_COUNT: int = 3
const SAVE_DIR: String = "user://saves/"
# Archivo del progreso de antes de las ranuras: se migra a la ranura 1.
const LEGACY_PATH: String = "user://progress.cfg"
const SECTION: String = "progress"
# Estrellas máximas que da un nivel ganado.
const MAX_STARS: int = 3

signal progress_reset

const MENU_THEME: Theme = preload("res://assets/ui/menu_theme.tres")
const TOAST_TIME: float = 3.0
# Logros por orden: id -> [clave del nombre, clave de la descripción]. Cómo se cumple cada uno está en _is_done().
const ACHIEVEMENTS: Dictionary = {
	"first_win": ["ACH_FIRST_WIN_NAME", "ACH_FIRST_WIN_DESC"],
	"flawless": ["ACH_FLAWLESS_NAME", "ACH_FLAWLESS_DESC"],
	"wins_5": ["ACH_WINS_5_NAME", "ACH_WINS_5_DESC"],
	"all_levels": ["ACH_ALL_LEVELS_NAME", "ACH_ALL_LEVELS_DESC"],
	"kills_100": ["ACH_KILLS_100_NAME", "ACH_KILLS_100_DESC"],
	"kills_1000": ["ACH_KILLS_1000_NAME", "ACH_KILLS_1000_DESC"],
	"seen_10": ["ACH_SEEN_10_NAME", "ACH_SEEN_10_DESC"],
	"turrets_50": ["ACH_TURRETS_50_NAME", "ACH_TURRETS_50_DESC"],
	"fuse_first": ["ACH_FUSE_FIRST_NAME", "ACH_FUSE_FIRST_DESC"],
	"fuse_all": ["ACH_FUSE_ALL_NAME", "ACH_FUSE_ALL_DESC"],
	"power_first": ["ACH_POWER_FIRST_NAME", "ACH_POWER_FIRST_DESC"],
	"perfect_10": ["ACH_PERFECT_10_NAME", "ACH_PERFECT_10_DESC"],
}

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1
# El nivel de emergencia (el nivel de prueba con el tutorial) ya se ha hecho, saltado o abandonado.
var tutorial_done: bool = false
# Enemigos que ya han salido en una partida, por nombre de archivo del EnemyData.
var seen_enemies: Array[String] = []
# Contadores acumulados entre partidas: wins, kills, turrets, powers, perfect_waves, spent y built_<torreta>.
var stats: Dictionary = {}
# Torretas fusionadas alguna vez, por nombre de archivo.
var fused_turrets: Array[String] = []
var unlocked: Array[String] = []
# Mejor marca de estrellas (1..MAX_STARS) de cada nivel ganado: número de nivel (desde 1) -> estrellas.
var level_stars: Dictionary[int, int] = {}
# Segundos jugados en niveles, en tiempo real.
var play_time: float = 0.0
# Ranura de la partida en curso (1..SLOT_COUNT). 0 = ninguna: mientras tanto no se guarda nada.
var active_slot: int = 0

var _toasts: VBoxContainer

func _ready() -> void:
	_make_toast_layer()
	_migrate_legacy_save()

## Carga la ranura (partida nueva con los valores por defecto si no tiene archivo) y la deja activa.
func load_slot(slot: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return
	_set_defaults()
	active_slot = slot
	var file: ConfigFile = ConfigFile.new()
	if file.load(_slot_path(slot)) != OK:
		return
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
	var old_achievement: int = unlocked.find("towers_50")
	if old_achievement >= 0:
		unlocked[old_achievement] = "turrets_50"
	var time: Variant = file.get_value(SECTION, "play_time", 0.0)
	if typeof(time) == TYPE_FLOAT and time >= 0.0:
		play_time = time
	# Las partidas de antes de las estrellas no tienen esta clave: se quedan sin estrellas.
	var stars: Variant = file.get_value(SECTION, "level_stars", {})
	if typeof(stars) == TYPE_DICTIONARY:
		for key: Variant in stars:
			var value_stars: Variant = stars[key]
			if typeof(key) == TYPE_INT and key >= 1 and typeof(value_stars) == TYPE_INT \
					and value_stars >= 1 and value_stars <= MAX_STARS:
				level_stars[key] = value_stars

func has_save(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT and FileAccess.file_exists(_slot_path(slot))

## Borra la partida de la ranura. Si era la activa, se queda sin ranura y con los valores por defecto.
func delete_slot(slot: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return
	if FileAccess.file_exists(_slot_path(slot)):
		DirAccess.remove_absolute(_slot_path(slot))
	if slot == active_slot:
		active_slot = 0
		_set_defaults()

## Resumen de la ranura sin cargarla en la partida activa. Vacío si no hay partida.
func get_slot_summary(slot: int) -> Dictionary:
	var file: ConfigFile = ConfigFile.new()
	if not has_save(slot) or file.load(_slot_path(slot)) != OK:
		return {}
	var level: Variant = file.get_value(SECTION, "current_level", 1)
	var time: Variant = file.get_value(SECTION, "play_time", 0.0)
	var saved_at: Variant = file.get_value(SECTION, "saved_at", 0)
	var done: Variant = file.get_value(SECTION, "unlocked", [])
	var count: int = 0
	if typeof(done) == TYPE_ARRAY:
		for id: Variant in done:
			if typeof(id) == TYPE_STRING and ACHIEVEMENTS.has(id):
				count += 1
	return {
		"saved_at": saved_at if typeof(saved_at) == TYPE_INT else 0,
		"play_time": time if typeof(time) == TYPE_FLOAT and time >= 0.0 else 0.0,
		"sector": level if typeof(level) == TYPE_INT and level >= 1 else 1,
		"achievements": count,
		"achievements_total": ACHIEVEMENTS.size(),
	}

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

## Estrellas que da ganar con la estación a `health` de `max_health`: 3 sin daño, 2 con más de la mitad, 1 si no.
func stars_for_health(health: int, max_health: int) -> int:
	if health >= max_health:
		return MAX_STARS
	if health * 2 > max_health:
		return 2
	return 1

## Mejor marca de estrellas del nivel número `number` (desde 1). 0 si no se ha ganado nunca.
func get_level_stars(number: int) -> int:
	return level_stars.get(number, 0)

## Anota las estrellas de una victoria en el nivel `number` (desde 1). Solo guarda si mejora la marca.
func record_level_stars(number: int, stars: int) -> void:
	if number < 1 or stars <= get_level_stars(number):
		return
	level_stars[number] = clampi(stars, 1, MAX_STARS)
	_save()

## El nivel de emergencia se ha acabado, saltado o abandonado: no vuelve a salir.
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
	var best: String = ""
	var best_count: int = 0
	for key: String in stats:
		if key.begins_with("built_") and stats[key] > best_count:
			best = key.trim_prefix("built_")
			best_count = stats[key]
	return best

## Anota que esta torreta se ha fusionado alguna vez.
func register_fusion(fused: TurretData) -> void:
	var file: String = fused.resource_path.get_file()
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
	for id: String in ACHIEVEMENTS:
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
	var layer: CanvasLayer = CanvasLayer.new()
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
	var label: Label = Label.new()
	label.text = tr("ACHIEVEMENT_TOAST") % tr(title)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("40e0f0"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	_toasts.add_child(label)
	var tween: Tween = create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _load_list(file: ConfigFile, key: String, into: Array[String]) -> void:
	var list: Variant = file.get_value(SECTION, key, [])
	if typeof(list) == TYPE_ARRAY:
		for item: Variant in list:
			if typeof(item) == TYPE_STRING:
				into.append(item)

# Vuelve al nivel 1 (con el nivel de emergencia otra vez), guarda y avisa para que el menú de niveles se reconstruya.
func reset_progress() -> void:
	_set_defaults()
	_save()
	progress_reset.emit()

func _set_defaults() -> void:
	current_level = 1
	tutorial_done = false
	seen_enemies.clear()
	stats.clear()
	fused_turrets.clear()
	unlocked.clear()
	level_stars.clear()
	play_time = 0.0

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.cfg" % slot

# Si existe el progress.cfg de antes de las ranuras y no hay ninguna ranura, pasa a la 1 y se borra el antiguo.
func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	for slot: int in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return
	var file: ConfigFile = ConfigFile.new()
	if file.load(LEGACY_PATH) != OK:
		return
	file.set_value(SECTION, "saved_at", int(Time.get_unix_time_from_system()))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if file.save(_slot_path(1)) == OK:
		DirAccess.remove_absolute(LEGACY_PATH)
	else:
		push_warning("GameState: no se pudo migrar " + LEGACY_PATH)

func _save() -> void:
	if active_slot == 0:
		return
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "current_level", current_level)
	file.set_value(SECTION, "tutorial_done", tutorial_done)
	file.set_value(SECTION, "seen_enemies", seen_enemies)
	file.set_value(SECTION, "stats", stats)
	file.set_value(SECTION, "fused_turrets", fused_turrets)
	file.set_value(SECTION, "unlocked", unlocked)
	file.set_value(SECTION, "play_time", play_time)
	file.set_value(SECTION, "level_stars", level_stars)
	file.set_value(SECTION, "saved_at", int(Time.get_unix_time_from_system()))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if file.save(_slot_path(active_slot)) != OK:
		push_warning("GameState: no se pudo guardar " + _slot_path(active_slot))
