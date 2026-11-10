extends SceneTree
## Genera las oleadas de todos los niveles a partir de la tabla LEVELS y las enlaza en su nivel.
##
## Uso: godot --headless --path . -s scripts/tools/make_waves.gd [-- simulation]
## Con "simulation" solo genera el simulacro (el nivel de prueba del tutorial); sin argumentos, todo.
##
## Escribe resources/wave_data/level_N.tres (oleada 1) y level_N_K.tres (oleada K). Si el archivo
## ya existe se carga y se rellena, así conserva su uid. Después pone la lista de oleadas en
## resources/level_data/level_N.tres.
##
## Cada oleada gasta un presupuesto: cada nave cuesta su recompensa (más la de sus trozos, si se
## parte). El presupuesto de la primera oleada sale de la tabla y crece por oleada; las naves salen
## en grupos del mismo tipo, cada vez más grandes y más juntos, y la vida sube cada vez más deprisa
## (`health` de la tabla): la recompensa no cambia con ella, así que la dificultad crece más que el dinero.
## Los grupos alternan entre las naves nuevas del nivel (las protagonistas) y todas las del nivel;
## las naves de niveles anteriores se van sumando según avanzan las oleadas. Cada grupo va por un
## camino, sacado de una bolsa mezclada para que se usen todos; en niveles con varios caminos los
## grupos se solapan cada vez más.
## Las tiradas usan una semilla fija por nivel y oleada: volver a lanzarlo da las mismas oleadas.

const WAVE_DIR: String = "res://resources/wave_data/"
const LEVEL_DIR: String = "res://resources/level_data/"
const ENEMY_DIR: String = "res://resources/enemy_data/"

## "dart" es un Dart de color al azar.
const DART: String = "dart"
const DART_COLORS: Array[String] = ["dart_rojo", "dart_verde", "dart_morado", "dart_hielo"]
## El jefe: solo sale, uno, al final de la última oleada de los niveles que lo tienen en `boss`.
const BOSS: String = "nodriza"

## Cada oleada multiplica la separación entre naves por esto, sin bajar de MIN_GAP.
const GAP_SHRINK: float = 0.91
const MIN_GAP: float = 0.3
## Pausa entre grupos, en separaciones de nave.
const GROUP_PAUSE: float = 2.5
## Con varios caminos, el siguiente grupo sale cuando el anterior lleva esta fracción de su duración:
## 1 en la primera oleada (uno detrás de otro) y MIN_OVERLAP_WAIT en la última.
const MIN_OVERLAP_WAIT: float = 0.3
## En cuántas oleadas se han sumado todas las naves de niveles anteriores.
const OLD_RAMP_WAVES: int = 7
## Valor (en presupuesto) de un grupo en la primera oleada y cuánto crece por oleada.
const GROUP_VALUE: float = 100.0
const GROUP_VALUE_STEP: float = 15.0
const MAX_GROUP: int = 6
## Forma de la curva de vida: la vida pasa del primer valor de `health` al segundo con la oleada
## elevada a esto (más de 1: sube poco al principio y mucho al final).
const HEALTH_CURVE: float = 1.4

## Por nivel: oleadas, caminos del mapa, presupuesto de la primera oleada, crecimiento por oleada,
## separación inicial entre naves (s), multiplicador de vida de la primera y de la última oleada
## (`health`, la recompensa no cambia con él), naves nuevas del nivel, naves de niveles anteriores
## (de las más fáciles a las más duras: se van sumando por ese orden) y si sale la Nodriza.
const LEVELS: Array[Dictionary] = [
	{"waves": 10, "paths": 1, "budget": 150.0, "growth": 1.13, "gap": 1.0, "health": Vector2(1.1, 2.8),
		"new": [DART, "wasp"], "old": [], "boss": false},
	{"waves": 10, "paths": 2, "budget": 230.0, "growth": 1.13, "gap": 0.95, "health": Vector2(1.2, 2.5),
		"new": ["nave_normal"], "old": [DART, "wasp"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 330.0, "growth": 1.125, "gap": 0.9, "health": Vector2(1.4, 2.8),
		"new": ["nave_agresiva"], "old": [DART, "wasp", "nave_normal"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 440.0, "growth": 1.125, "gap": 0.85, "health": Vector2(1.4, 3.0),
		"new": ["acorazado"], "old": [DART, "wasp", "nave_normal", "nave_agresiva"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 560.0, "growth": 1.12, "gap": 0.8, "health": Vector2(1.5, 3.5),
		"new": ["ariete", "divisora"], "old": ["wasp", "nave_normal", "nave_agresiva", "acorazado"], "boss": false},
	{"waves": 10, "paths": 3, "budget": 680.0, "growth": 1.12, "gap": 0.75, "health": Vector2(2.0, 4.2),
		"new": ["reparadora"], "old": ["wasp", "nave_normal", "nave_agresiva", "acorazado", "ariete", "divisora"], "boss": true},
	{"waves": 10, "paths": 4, "budget": 800.0, "growth": 1.12, "gap": 0.7, "health": Vector2(2.3, 4.9),
		"new": ["espectro"], "old": ["wasp", "nave_agresiva", "acorazado", "ariete", "divisora", "reparadora"], "boss": false},
	{"waves": 10, "paths": 4, "budget": 920.0, "growth": 1.12, "gap": 0.65, "health": Vector2(2.4, 5.3),
		"new": ["saboteadora"], "old": ["wasp", "nave_agresiva", "acorazado", "ariete", "divisora", "reparadora", "espectro"], "boss": false},
	{"waves": 10, "paths": 8, "budget": 1050.0, "growth": 1.12, "gap": 0.6, "health": Vector2(2.6, 5.5),
		"new": ["espectro", "saboteadora", "divisora", "reparadora"],
		"old": [DART, "wasp", "nave_normal", "nave_agresiva", "acorazado", "ariete"], "boss": true},
]

## Simulacro (nivel de prueba del tutorial): sus oleadas no salen del presupuesto, se escriben grupo a
## grupo para controlar el dinero. Por oleada: multiplicador de vida y grupos [nave, cuántas, separación].
## La 1 da 200 € (lo justo para mejorar un Cañón doble), la 2 da 400 € (las otras dos mejoras) y la 3
## aprieta, pero se pasa con dos Cañones dobles y uno mejorado.
const SIMULATION: Array[Dictionary] = [
	{"health": 0.7, "groups": [["dart_rojo", 5, 1.0], ["wasp", 8, 1.2], ["dart_verde", 5, 1.0], ["wasp", 7, 1.2]]},
	{"health": 0.8, "groups": [["dart_rojo", 6, 0.8], ["wasp", 5, 1.0], ["nave_normal", 7, 1.4], ["dart_morado", 6, 0.8],
			["wasp", 5, 1.0], ["nave_normal", 7, 1.4], ["dart_hielo", 6, 0.8]]},
	{"health": 0.9, "groups": [["dart_rojo", 8, 0.6], ["wasp", 10, 0.8], ["nave_normal", 6, 1.1], ["dart_verde", 8, 0.6],
			["wasp", 10, 0.8], ["nave_normal", 6, 1.1]]},
]
## Segundos entre la última nave de un grupo del simulacro y la primera del siguiente.
const SIMULATION_PAUSE: float = 2.5
const SIMULATION_NAME: String = "simulation"
const SIMULATION_MAP: String = "res://scenes/maps/levels/Simulation.tscn"
const SIMULATION_MONEY: int = 300
const SIMULATION_TURRET: String = "res://resources/turret_data/turret.tres"

var _enemies: Dictionary[String, EnemyData] = {}


func _initialize() -> void:
	if not SIMULATION_NAME in OS.get_cmdline_user_args():
		for i: int in LEVELS.size():
			var level_number: int = i + 1
			var waves: Array[WaveData] = _make_level(level_number, LEVELS[i])
			_save_level(level_number, waves)
	_make_simulation()
	quit()


# Escribe wave_data/simulation_K.tres y los enlaza en level_data/simulation.tres (que crea si no existe,
# con su mapa, su dinero y el Cañón doble como única torreta).
func _make_simulation() -> void:
	var waves: Array[WaveData] = []
	for k: int in SIMULATION.size():
		var path: String = WAVE_DIR + "%s_%d.tres" % [SIMULATION_NAME, k + 1]
		var wave: WaveData = load(path) if ResourceLoader.exists(path) else WaveData.new()
		var groups: Array[SpawnGroup] = []
		var reward: int = 0
		for row: Array in SIMULATION[k]["groups"]:
			var group: SpawnGroup = SpawnGroup.new()
			group.enemy_data = _enemy(row[0])
			group.count = row[1]
			group.spacing = row[2]
			group.pause_after = SIMULATION_PAUSE
			group.path_index = 0
			groups.append(group)
			reward += group.enemy_data.reward * group.count
		wave.groups = groups
		wave.health_multiplier = SIMULATION[k]["health"]
		_save(wave, path)
		waves.append(load(path) as WaveData)
		print("Simulacro, oleada %d: %d naves, %d €, vida x%.2f" % [k + 1, wave.get_entries().size(), reward,
				wave.health_multiplier])
	var level_path: String = LEVEL_DIR + SIMULATION_NAME + ".tres"
	var level: LevelData = load(level_path) if ResourceLoader.exists(level_path) else LevelData.new()
	if level.map == null:
		level.map = load(SIMULATION_MAP)
		level.starting_money = SIMULATION_MONEY
		var turrets: Array[TurretData] = [load(SIMULATION_TURRET) as TurretData]
		level.turrets = turrets
	level.waves = waves
	_save(level, level_path)


func _make_level(level_number: int, table: Dictionary) -> Array[WaveData]:
	var waves: Array[WaveData] = []
	var count: int = table["waves"]
	var min_ships: int = 0
	for k: int in count:
		var path: String = _wave_path(level_number, k)
		var wave: WaveData = load(path) if ResourceLoader.exists(path) else WaveData.new()
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = level_number * 1000 + k
		var is_last: bool = k == count - 1
		wave.groups = _make_groups(table, k, min_ships, is_last and table["boss"], rng)
		var entries: Array[SpawnEntry] = wave.get_entries()
		min_ships = entries.size() + 1
		# Redondeado a centésimas, para que el .tres no guarde 1.1500000000000001.
		wave.health_multiplier = roundf(_health(table, k) * 100.0) / 100.0
		_save(wave, path)
		# Cargado desde el archivo, para que el nivel lo enlace y no lo meta dentro.
		waves.append(load(path) as WaveData)
		print("Nivel %d, oleada %d: %d naves, última a %.1f s, vida x%.2f" % [level_number, k + 1,
				entries.size(), entries[-1].time, wave.health_multiplier])
	return waves


# Multiplicador de vida de la oleada k: sube de `health.x` a `health.y` con una curva que se acelera.
func _health(table: Dictionary, k: int) -> float:
	var health: Vector2 = table["health"]
	return lerpf(health.x, health.y, pow(float(k) / (table["waves"] - 1), HEALTH_CURVE))


# Saca naves hasta gastar el presupuesto y llegar a `min_ships` (una más que la oleada anterior).
func _make_groups(table: Dictionary, k: int, min_ships: int, with_boss: bool, rng: RandomNumberGenerator) -> Array[SpawnGroup]:
	var budget: float = table["budget"] * pow(table["growth"], k)
	var paths: int = table["paths"]
	var gap: float = maxf(table["gap"] * pow(GAP_SHRINK, k), MIN_GAP)
	# Con varios caminos los grupos se achican para que haya al menos uno por camino.
	var group_value: float = minf(GROUP_VALUE + GROUP_VALUE_STEP * k, budget / paths)
	var new_ships: Array = table["new"]
	var all_ships: Array = new_ships + _unlocked_old(table["old"], k)
	var groups: Array[Array] = []
	var spent: float = 0.0
	var count: int = 0
	var last_key: String = ""
	while spent < budget or count < min_ships:
		# Los grupos pares son de naves nuevas, para que sean las protagonistas del nivel.
		var pool: Array = new_ships if groups.size() % 2 == 0 else all_ships
		var key: String = _pick(pool, last_key, rng)
		last_key = key
		var cost: float = _cost(_enemy(key))
		var size: int = clampi(roundi(group_value / cost), 1, MAX_GROUP)
		size = clampi(maxi(ceili((budget - spent) / cost), min_ships - count), 1, size)
		var group: Array[EnemyData] = []
		for n: int in size:
			group.append(_enemy(key, rng))
			spent += cost
			count += 1
		groups.append(group)
	var result: Array[SpawnGroup] = []
	var path_bag: Array[int] = []
	var last_path: int = -1
	# La primera nave sale en 0: la espera inicial la pone el Spawner (WAVE_START_DELAY).
	var start: float = 0.0
	# Segundo de la última nave del grupo anterior y de la última de todas (con solapes no coinciden).
	var end: float = 0.0
	var last_time: float = 0.0
	var wait: float = lerpf(1.0, MIN_OVERLAP_WAIT, float(k) / (table["waves"] - 1)) if paths > 1 else 1.0
	for group: Array in groups:
		var path: int = _next_path(path_bag, paths, last_path, rng)
		last_path = path
		var time: float = start
		var n: int = 0
		# Un SpawnGroup por tramo de naves iguales: los Darts de un grupo pueden ser de varios colores.
		while n < group.size():
			var run: int = 1
			while n + run < group.size() and group[n + run] == group[n]:
				run += 1
			var spacing: float = gap * _spacing(group[n])
			if n > 0:
				time += spacing
			end = _add_group(result, group[n], run, spacing, path, time, end)
			time = end
			n += run
		last_time = maxf(last_time, end)
		start += (time - start) * wait + gap * GROUP_PAUSE
	if with_boss:
		# La Nodriza sale la última, cuando ya han salido todas las demás.
		_add_group(result, _enemy(BOSS), 1, 0.5, _next_path(path_bag, paths, last_path, rng), last_time + gap * GROUP_PAUSE, end)
	return result


# Añade un grupo que empieza en `time`, ajustando la pausa del anterior (que acabó en `end`).
# Devuelve el segundo de su última nave, calculado con los valores ya redondeados.
func _add_group(result: Array[SpawnGroup], data: EnemyData, count: int, spacing: float, path: int, time: float, end: float) -> float:
	var group: SpawnGroup = SpawnGroup.new()
	group.enemy_data = data
	group.count = count
	group.spacing = _round(spacing)
	group.path_index = path
	var start: float = 0.0
	if not result.is_empty():
		result[-1].pause_after = _round(time - end)
		start = end + result[-1].pause_after
	result.append(group)
	return start + group.spacing * (count - 1)


# Redondeado a centésimas: roundf(x * 100) / 100 da 2.9 y no 2.9000000000000004 como snappedf.
func _round(value: float) -> float:
	return roundf(value * 100.0) / 100.0


# Las naves de niveles anteriores que ya salen en la oleada k: van sumándose por orden de la lista.
func _unlocked_old(old: Array, k: int) -> Array:
	return old.slice(0, clampi(roundi(float(k + 1) * old.size() / OLD_RAMP_WAVES), mini(1, old.size()), old.size()))


# Una nave de la lista que no sea la del grupo anterior (si hay otra).
func _pick(pool: Array, last_key: String, rng: RandomNumberGenerator) -> String:
	var options: Array = pool.filter(func(key: String) -> bool: return key != last_key)
	if options.is_empty():
		options = pool
	return options[rng.randi() % options.size()]


# Siguiente camino de una bolsa con todos mezclados: se usan todos antes de repetir y, si hay
# más de uno, nunca el mismo camino dos grupos seguidos.
func _next_path(bag: Array[int], paths: int, last_path: int, rng: RandomNumberGenerator) -> int:
	if bag.is_empty():
		for index: int in paths:
			bag.append(index)
		for i: int in range(paths - 1, 0, -1):
			var j: int = rng.randi() % (i + 1)
			var swap: int = bag[i]
			bag[i] = bag[j]
			bag[j] = swap
		if paths > 1 and bag[0] == last_path:
			var other: int = 1 + rng.randi() % (paths - 1)
			bag[0] = bag[other]
			bag[other] = last_path
	return bag.pop_front()


# Lo que cuesta una nave del presupuesto: su recompensa y la de sus trozos.
func _cost(data: EnemyData) -> float:
	var cost: float = float(data.reward)
	for piece: EnemyData in data.split_into:
		cost += _cost(piece)
	return cost


# Las naves caras (lentas y duras) salen más separadas que los Darts.
func _spacing(data: EnemyData) -> float:
	return clampf(_cost(data) / 35.0, 0.6, 2.0)


func _enemy(key: String, rng: RandomNumberGenerator = null) -> EnemyData:
	if key == DART:
		key = DART_COLORS[rng.randi() % DART_COLORS.size()] if rng != null else DART_COLORS[0]
	if not _enemies.has(key):
		_enemies[key] = load(ENEMY_DIR + key + ".tres")
	return _enemies[key]


func _wave_path(level_number: int, k: int) -> String:
	if k == 0:
		return WAVE_DIR + "level_%d.tres" % level_number
	return WAVE_DIR + "level_%d_%d.tres" % [level_number, k + 1]


func _save_level(level_number: int, waves: Array[WaveData]) -> void:
	var path: String = LEVEL_DIR + "level_%d.tres" % level_number
	var level: LevelData = load(path)
	level.waves = waves
	_save(level, path)


# Guarda el recurso conservando el uid de su cabecera (o uno nuevo si no tenía).
func _save(resource: Resource, path: String) -> void:
	var old_uid: int = _read_uid(path)
	var error: Error = ResourceSaver.save(resource, path)
	if error != OK:
		push_error("No se pudo guardar %s (%s)" % [path, error_string(error)])
		return
	_write_uids(path, old_uid if old_uid != ResourceUID.INVALID_ID else ResourceUID.create_id())


# Uid escrito en la cabecera del archivo, o INVALID_ID si no existe o no lo tiene.
func _read_uid(path: String) -> int:
	if not FileAccess.file_exists(path):
		return ResourceUID.INVALID_ID
	var header: String = FileAccess.get_file_as_string(path).get_slice("\n", 0)
	if not header.contains(" uid=\""):
		return ResourceUID.INVALID_ID
	return ResourceUID.text_to_id(header.get_slice(" uid=\"", 1).get_slice("\"", 0))


# Desde un script (-s) Godot guarda sin uid propio ni en los ext_resource (como en
# map_generator.gd): se añaden a mano, el del recurso y el de cada archivo enlazado.
func _write_uids(path: String, uid: int) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	for i: int in lines.size():
		var line: String = lines[i]
		if line.begins_with("[gd_resource") and not line.contains(" uid="):
			lines[i] = line.trim_suffix("]") + " uid=\"%s\"]" % ResourceUID.id_to_text(uid)
		elif line.begins_with("[ext_resource") and not line.contains(" uid="):
			var linked: String = line.get_slice("path=\"", 1).get_slice("\"", 0)
			var linked_uid: int = _read_uid(linked) if linked.ends_with(".tres") else ResourceLoader.get_resource_uid(linked)
			if linked_uid == ResourceUID.INVALID_ID:
				linked_uid = ResourceLoader.get_resource_uid(linked)
			if linked_uid != ResourceUID.INVALID_ID:
				lines[i] = line.replace(" path=\"", " uid=\"%s\" path=\"" % ResourceUID.id_to_text(linked_uid))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
