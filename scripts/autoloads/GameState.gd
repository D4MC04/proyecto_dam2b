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
# Fases de un logro. Los de una sola fase se consiguen directamente en oro.
const PHASE_NONE: int = 0
const PHASE_BRONZE: int = 1
const PHASE_SILVER: int = 2
const PHASE_GOLD: int = 3
const PHASE_NAMES: Array[String] = ["", "ACH_PHASE_BRONZE", "ACH_PHASE_SILVER", "ACH_PHASE_GOLD"]
# Color del texto de cada fase (aviso y lista de logros).
const PHASE_COLORS: Array[Color] = [Color("606a7c"), Color("e08a4a"), Color("c8d2e0"), Color("ecb23c")]
# Meta que vale "todos" (tipos de nave de la Navedex, torretas base): ver get_goals().
const GOAL_ALL: int = -1
# Logros por orden: id -> [clave del nombre, clave de la descripción, metas]. Metas: 3 (bronce, plata y
# oro) o 1 (oro). La descripción lleva %d con la meta; si la meta es 1 se usa la clave con _ONE detrás.
# Qué cuenta cada uno está en _progress(); flawless y all_levels no tienen contador (register_win).
const ACHIEVEMENTS: Dictionary = {
	"first_win": ["ACH_FIRST_WIN_NAME", "ACH_FIRST_WIN_DESC", [1]],
	"flawless": ["ACH_FLAWLESS_NAME", "ACH_FLAWLESS_DESC", [1]],
	"all_levels": ["ACH_ALL_LEVELS_NAME", "ACH_ALL_LEVELS_DESC", [1]],
	"wins": ["ACH_WINS_NAME", "ACH_WINS_DESC", [5, 15, 30]],
	"kills": ["ACH_KILLS_NAME", "ACH_KILLS_DESC", [100, 1000, 3000]],
	"seen": ["ACH_SEEN_NAME", "ACH_SEEN_DESC", [5, 10, GOAL_ALL]],
	"turrets": ["ACH_TURRETS_NAME", "ACH_TURRETS_DESC", [50, 200, 500]],
	"fusions": ["ACH_FUSIONS_NAME", "ACH_FUSIONS_DESC", [1, 5, GOAL_ALL]],
	"powers": ["ACH_POWERS_NAME", "ACH_POWERS_DESC", [1, 25, 100]],
	"perfect_waves": ["ACH_PERFECT_WAVES_NAME", "ACH_PERFECT_WAVES_DESC", [10, 30, 90]],
}
# Logros de antes de las fases (lista `unlocked` de las ranuras viejas): id viejo -> [id nuevo, fase mínima].
const LEGACY_ACHIEVEMENTS: Dictionary = {
	"first_win": ["first_win", PHASE_GOLD],
	"flawless": ["flawless", PHASE_GOLD],
	"all_levels": ["all_levels", PHASE_GOLD],
	"wins_5": ["wins", PHASE_BRONZE],
	"kills_100": ["kills", PHASE_BRONZE],
	"kills_1000": ["kills", PHASE_SILVER],
	"seen_10": ["seen", PHASE_SILVER],
	"towers_50": ["turrets", PHASE_BRONZE],
	"turrets_50": ["turrets", PHASE_BRONZE],
	"fuse_first": ["fusions", PHASE_BRONZE],
	"fuse_all": ["fusions", PHASE_SILVER],
	"power_first": ["powers", PHASE_BRONZE],
	"perfect_10": ["perfect_waves", PHASE_BRONZE],
}

# Número (desde 1) del nivel más alto desbloqueado.
var current_level: int = 1
# El tutorial del nivel 1 ya se ha hecho o saltado.
var tutorial_done: bool = false
# Enemigos que ya han salido en una partida, por nombre de archivo del EnemyData.
var seen_enemies: Array[String] = []
# Contadores acumulados entre partidas: wins, kills, turrets, powers, perfect_waves, spent y built_<torreta>.
var stats: Dictionary = {}
# Torretas fusionadas alguna vez, por nombre de archivo.
var fused_turrets: Array[String] = []
# Fase conseguida de cada logro: id -> PHASE_BRONZE..PHASE_GOLD (los que faltan no están).
var achievement_phases: Dictionary[String, int] = {}
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
	if stats.has("towers"):
		stats["turrets"] = stats.get("turrets", 0) + stats["towers"]
		stats.erase("towers")
	achievement_phases = _read_phases(file)
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
	# Las ranuras de antes de las fases se recalculan con los contadores, sin avisos, y se guardan ya.
	if _update_phases(false) or not file.has_section_key(SECTION, "achievements"):
		_save()

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
	var count: int = 0
	var phases: Dictionary[String, int] = _read_phases(file)
	for id: String in phases:
		count += _goals_for(id, phases[id])
	return {
		"saved_at": saved_at if typeof(saved_at) == TYPE_INT else 0,
		"play_time": time if typeof(time) == TYPE_FLOAT and time >= 0.0 else 0.0,
		"sector": level if typeof(level) == TYPE_INT and level >= 1 else 1,
		"achievements": count,
		"achievements_total": total_phase_count(),
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

## Fase conseguida del logro (PHASE_NONE si ninguna).
func get_phase(id: String) -> int:
	return achievement_phases.get(id, PHASE_NONE)

## Fases que tiene el logro: 3 (bronce, plata y oro) o 1 (oro).
func phase_count(id: String) -> int:
	return (ACHIEVEMENTS[id][2] as Array).size()

## Fases de todos los logros juntos (el total de las ranuras).
func total_phase_count() -> int:
	var total: int = 0
	for id: String in ACHIEVEMENTS:
		total += phase_count(id)
	return total

## Metas de cada fase del logro, con GOAL_ALL ya cambiado por el total que toca.
func get_goals(id: String) -> Array[int]:
	var goals: Array[int] = []
	for goal: int in ACHIEVEMENTS[id][2]:
		goals.append(_goal_all(id) if goal == GOAL_ALL else goal)
	return goals

## Valor actual del contador del logro; -1 si no tiene (flawless, all_levels).
func get_progress(id: String) -> int:
	match id:
		"first_win", "wins": return stats.get("wins", 0)
		"kills": return stats.get("kills", 0)
		"seen":
			var count: int = 0
			for file: String in Navedex.ENEMY_FILES:
				if file + ".tres" in seen_enemies:
					count += 1
			return count
		"turrets": return stats.get("turrets", 0)
		"fusions": return fused_turrets.size()
		"powers": return stats.get("powers", 0)
		"perfect_waves": return stats.get("perfect_waves", 0)
	return -1

## Meta de la siguiente fase por conseguir (o la del oro si ya está).
func next_goal(id: String) -> int:
	var goals: Array[int] = get_goals(id)
	return goals[mini(_goals_for(id, get_phase(id)), goals.size() - 1)]

## Descripción traducida con la meta de la siguiente fase.
func achievement_description(id: String) -> String:
	var key: String = ACHIEVEMENTS[id][1]
	var goal: int = next_goal(id)
	if goal == 1 and tr(key + "_ONE") != key + "_ONE":
		return tr(key + "_ONE")
	var text: String = tr(key)
	return text % goal if "%d" in text else text

## Nombre traducido de la fase ("Bronce", "Plata", "Oro"); "" si ninguna.
func phase_name(phase: int) -> String:
	return tr(PHASE_NAMES[phase]) if phase > PHASE_NONE else ""

# Total para la meta GOAL_ALL del logro.
func _goal_all(id: String) -> int:
	match id:
		"seen": return Navedex.ENEMY_FILES.size()
		"fusions": return Navedex.TURRET_FILES.size()
	return 1

# Fase que toca por haber cumplido `reached` metas de un logro de `count` fases. 3 fases: 1 bronce,
# 2 plata, 3 oro. 1 fase: oro.
func _phase_for(reached: int, count: int) -> int:
	return PHASE_NONE if reached <= 0 else PHASE_GOLD - count + reached

# Metas cumplidas del logro con la fase `phase` (lo contrario de _phase_for).
func _goals_for(id: String, phase: int) -> int:
	return 0 if phase == PHASE_NONE else phase - (PHASE_GOLD - phase_count(id))

# Sube la fase de los logros con contador que hayan llegado a otra meta. Con `notify` sale el aviso
# (solo de la fase más alta, si se salta alguna). Devuelve si cambió alguno; no guarda.
func _update_phases(notify: bool) -> bool:
	var changed: bool = false
	for id: String in ACHIEVEMENTS:
		var progress: int = get_progress(id)
		if progress < 0:
			continue
		var reached: int = 0
		for goal: int in get_goals(id):
			if progress >= goal:
				reached += 1
		var phase: int = _phase_for(reached, phase_count(id))
		if phase > get_phase(id):
			achievement_phases[id] = phase
			changed = true
			if notify:
				_show_toast(id, phase)
	return changed

func _check_achievements() -> void:
	if _update_phases(true):
		_save()

# Da el oro de un logro de una fase sin contador (flawless, all_levels).
func _unlock(id: String) -> void:
	if get_phase(id) == PHASE_GOLD:
		return
	achievement_phases[id] = PHASE_GOLD
	_save()
	_show_toast(id, PHASE_GOLD)

# Fases guardadas en el archivo de una ranura. Las ranuras viejas tienen la lista `unlocked` con los
# ids de antes: cada uno cuenta como mínimo para la fase que le toca (LEGACY_ACHIEVEMENTS).
func _read_phases(file: ConfigFile) -> Dictionary[String, int]:
	var phases: Dictionary[String, int] = {}
	var saved: Variant = file.get_value(SECTION, "achievements", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for id: Variant in saved:
			var phase: Variant = saved[id]
			if typeof(id) == TYPE_STRING and ACHIEVEMENTS.has(id) and typeof(phase) == TYPE_INT \
					and phase >= PHASE_BRONZE and phase <= PHASE_GOLD:
				phases[id] = phase
	var old: Variant = file.get_value(SECTION, "unlocked", [])
	if typeof(old) == TYPE_ARRAY:
		for old_id: Variant in old:
			if typeof(old_id) == TYPE_STRING and LEGACY_ACHIEVEMENTS.has(old_id):
				var entry: Array = LEGACY_ACHIEVEMENTS[old_id]
				phases[entry[0]] = maxi(phases.get(entry[0], PHASE_NONE), entry[1])
	return phases

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

# Aviso pequeño arriba a la derecha con el logro y su fase, en el color de la fase; se desvanece solo.
func _show_toast(id: String, phase: int) -> void:
	var label: Label = Label.new()
	label.text = tr("ACHIEVEMENT_TOAST") % [tr(ACHIEVEMENTS[id][0]), phase_name(phase)]
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", PHASE_COLORS[phase])
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

# Vuelve al nivel 1 (con el tutorial otra vez), guarda y avisa para que el menú de niveles se reconstruya.
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
	achievement_phases.clear()
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
	file.set_value(SECTION, "achievements", achievement_phases)
	file.set_value(SECTION, "play_time", play_time)
	file.set_value(SECTION, "level_stars", level_stars)
	file.set_value(SECTION, "saved_at", int(Time.get_unix_time_from_system()))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if file.save(_slot_path(active_slot)) != OK:
		push_warning("GameState: no se pudo guardar " + _slot_path(active_slot))
