extends SceneTree
## Genera las oleadas de todos los niveles a partir de la tabla LEVELS y las enlaza en su nivel.
##
## Uso: godot --headless --path . -s scripts/tools/make_waves.gd
##
## Escribe resources/wave_data/level_N.tres (oleada 1) y level_N_K.tres (oleada K). Si el archivo
## ya existe se carga y se rellena, así conserva su uid. Después pone la lista de oleadas en
## resources/level_data/level_N.tres y en el nivel 5 de scenes/GameData.tscn (que lo define dentro).
##
## Cada oleada gasta un presupuesto: cada nave cuesta su recompensa (más la de sus trozos, si se
## parte). El presupuesto de la primera oleada sale de la tabla y crece por oleada; las naves salen
## en grupos del mismo tipo, cada vez más grandes y más juntos, y la vida sube un poco por oleada.
## Los grupos alternan entre las naves nuevas del nivel (las protagonistas) y todas las del nivel;
## las naves de niveles anteriores se van sumando según avanzan las oleadas. Cada grupo va por un
## camino, sacado de una bolsa mezclada para que se usen todos; en niveles con varios caminos los
## grupos se solapan cada vez más.
## Las tiradas usan una semilla fija por nivel y oleada: volver a lanzarlo da las mismas oleadas.

const WAVE_DIR := "res://resources/wave_data/"
const LEVEL_DIR := "res://resources/level_data/"
const ENEMY_DIR := "res://resources/enemy_data/"
const GAME_DATA_PATH := "res://scenes/GameData.tscn"
## Nivel que está definido dentro de GameData.tscn en vez de en su level_N.tres.
const SCENE_LEVEL := 5

## "dart" es un Dart de color al azar.
const DART := "dart"
const DART_COLORS: Array[String] = ["dart_rojo", "dart_verde", "dart_morado", "dart_hielo"]
## El jefe: solo sale, uno, al final de la última oleada de los niveles que lo tienen en `boss`.
const BOSS := "nodriza"

## Segundo en que sale la primera nave: en la primera oleada y en las demás.
const FIRST_WAVE_START := 3.0
const WAVE_START := 2.0
## Cada oleada multiplica la separación entre naves por esto, sin bajar de MIN_GAP.
const GAP_SHRINK := 0.93
const MIN_GAP := 0.3
## Pausa entre grupos, en separaciones de nave.
const GROUP_PAUSE := 2.5
## Con varios caminos, el siguiente grupo sale cuando el anterior lleva esta fracción de su duración:
## 1 en la primera oleada (uno detrás de otro) y MIN_OVERLAP_WAIT en la última.
const MIN_OVERLAP_WAIT := 0.4
## En cuántas oleadas se han sumado todas las naves de niveles anteriores.
const OLD_RAMP_WAVES := 7
## Valor (en presupuesto) de un grupo en la primera oleada y cuánto crece por oleada.
const GROUP_VALUE := 100.0
const GROUP_VALUE_STEP := 15.0
const MAX_GROUP := 6
## Vida extra por oleada (la oleada K lleva 1 + HEALTH_STEP * (K - 1)).
const HEALTH_STEP := 0.05

## Por nivel: oleadas, caminos del mapa, presupuesto de la primera oleada, crecimiento por oleada,
## separación inicial entre naves (s), naves nuevas del nivel, naves de niveles anteriores (de las
## más fáciles a las más duras: se van sumando por ese orden) y si sale la Nodriza.
const LEVELS: Array[Dictionary] = [
	{"waves": 10, "paths": 1, "budget": 150.0, "growth": 1.13, "gap": 1.0,
		"new": [DART, "wasp"], "old": [], "boss": false},
	{"waves": 10, "paths": 2, "budget": 230.0, "growth": 1.13, "gap": 0.95,
		"new": ["nave_normal"], "old": [DART, "wasp"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 330.0, "growth": 1.125, "gap": 0.9,
		"new": ["nave_agresiva"], "old": [DART, "wasp", "nave_normal"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 440.0, "growth": 1.125, "gap": 0.85,
		"new": ["acorazado"], "old": [DART, "wasp", "nave_normal", "nave_agresiva"], "boss": false},
	{"waves": 10, "paths": 2, "budget": 560.0, "growth": 1.12, "gap": 0.8,
		"new": ["ariete", "divisora"], "old": ["wasp", "nave_normal", "nave_agresiva", "acorazado"], "boss": false},
	{"waves": 10, "paths": 3, "budget": 680.0, "growth": 1.12, "gap": 0.75,
		"new": ["reparadora"], "old": ["wasp", "nave_normal", "nave_agresiva", "acorazado", "ariete", "divisora"], "boss": true},
	{"waves": 10, "paths": 4, "budget": 800.0, "growth": 1.12, "gap": 0.7,
		"new": ["espectro"], "old": ["wasp", "nave_agresiva", "acorazado", "ariete", "divisora", "reparadora"], "boss": false},
	{"waves": 10, "paths": 4, "budget": 920.0, "growth": 1.12, "gap": 0.65,
		"new": ["saboteadora"], "old": ["wasp", "nave_agresiva", "acorazado", "ariete", "divisora", "reparadora", "espectro"], "boss": false},
	{"waves": 10, "paths": 8, "budget": 1050.0, "growth": 1.12, "gap": 0.6,
		"new": ["espectro", "saboteadora", "divisora", "reparadora"],
		"old": [DART, "wasp", "nave_normal", "nave_agresiva", "acorazado", "ariete"], "boss": true},
]

var _enemies: Dictionary[String, EnemyData] = {}


func _initialize() -> void:
	for i in LEVELS.size():
		var level_number := i + 1
		var waves := _make_level(level_number, LEVELS[i])
		_save_level(level_number, waves)
	quit()


func _make_level(level_number: int, table: Dictionary) -> Array[WaveData]:
	var waves: Array[WaveData] = []
	var count: int = table["waves"]
	var min_ships := 0
	for k in count:
		var path := _wave_path(level_number, k)
		var wave: WaveData = load(path) if ResourceLoader.exists(path) else WaveData.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = level_number * 1000 + k
		var is_last := k == count - 1
		wave.entries = _make_entries(table, k, min_ships, is_last and table["boss"], rng)
		min_ships = wave.entries.size() + 1
		# Redondeado a centésimas, para que el .tres no guarde 1.1500000000000001.
		wave.health_multiplier = roundf((1.0 + HEALTH_STEP * k) * 100.0) / 100.0
		_save(wave, path)
		# Cargado desde el archivo, para que el nivel lo enlace y no lo meta dentro.
		waves.append(load(path) as WaveData)
		print("Nivel %d, oleada %d: %d naves, última a %.1f s, vida x%.2f" % [level_number, k + 1,
				wave.entries.size(), wave.entries[-1].time, wave.health_multiplier])
	return waves


# Saca naves hasta gastar el presupuesto y llegar a `min_ships` (una más que la oleada anterior).
func _make_entries(table: Dictionary, k: int, min_ships: int, with_boss: bool, rng: RandomNumberGenerator) -> Array[SpawnEntry]:
	var budget: float = table["budget"] * pow(table["growth"], k)
	var paths: int = table["paths"]
	var gap := maxf(table["gap"] * pow(GAP_SHRINK, k), MIN_GAP)
	# Con varios caminos los grupos se achican para que haya al menos uno por camino.
	var group_value := minf(GROUP_VALUE + GROUP_VALUE_STEP * k, budget / paths)
	var new_ships: Array = table["new"]
	var all_ships: Array = new_ships + _unlocked_old(table["old"], k)
	var groups: Array[Array] = []
	var spent := 0.0
	var count := 0
	var last_key := ""
	while spent < budget or count < min_ships:
		# Los grupos pares son de naves nuevas, para que sean las protagonistas del nivel.
		var pool: Array = new_ships if groups.size() % 2 == 0 else all_ships
		var key := _pick(pool, last_key, rng)
		last_key = key
		var cost := _cost(_enemy(key))
		var size := clampi(roundi(group_value / cost), 1, MAX_GROUP)
		size = clampi(maxi(ceili((budget - spent) / cost), min_ships - count), 1, size)
		var group: Array[EnemyData] = []
		for n in size:
			group.append(_enemy(key, rng))
			spent += cost
			count += 1
		groups.append(group)
	var entries: Array[SpawnEntry] = []
	var path_bag: Array[int] = []
	var last_path := -1
	var start := FIRST_WAVE_START if k == 0 else WAVE_START
	var wait := lerpf(1.0, MIN_OVERLAP_WAIT, float(k) / (table["waves"] - 1)) if paths > 1 else 1.0
	for group in groups:
		var path := _next_path(path_bag, paths, last_path, rng)
		last_path = path
		var time := start
		for n in group.size():
			if n > 0:
				time += gap * _spacing(group[n])
			entries.append(_entry(group[n], time, path))
		start += (time - start) * wait + gap * GROUP_PAUSE
	if with_boss:
		# La Nodriza sale la última, cuando ya han salido todas las demás.
		var last_time := 0.0
		for entry in entries:
			last_time = maxf(last_time, entry.time)
		entries.append(_entry(_enemy(BOSS), last_time + gap * GROUP_PAUSE, _next_path(path_bag, paths, last_path, rng)))
	return entries


func _entry(data: EnemyData, time: float, path: int) -> SpawnEntry:
	var entry := SpawnEntry.new()
	entry.enemy_data = data
	# Redondeado a décimas: roundf(x * 10) / 10 da 2.9 y no 2.9000000000000004 como snappedf.
	entry.time = roundf(time * 10.0) / 10.0
	entry.path_index = path
	return entry


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
		for index in paths:
			bag.append(index)
		for i in range(paths - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var swap := bag[i]
			bag[i] = bag[j]
			bag[j] = swap
		if paths > 1 and bag[0] == last_path:
			var other := 1 + rng.randi() % (paths - 1)
			bag[0] = bag[other]
			bag[other] = last_path
	return bag.pop_front()


# Lo que cuesta una nave del presupuesto: su recompensa y la de sus trozos.
func _cost(data: EnemyData) -> float:
	var cost := float(data.reward)
	for piece in data.split_into:
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
	var path := LEVEL_DIR + "level_%d.tres" % level_number
	var level: LevelData = load(path)
	level.waves = waves
	_save(level, path)
	if level_number == SCENE_LEVEL:
		_patch_game_data(level_number, waves.size())


# Guarda el recurso conservando el uid de su cabecera (o uno nuevo si no tenía).
func _save(resource: Resource, path: String) -> void:
	var old_uid := _read_uid(path)
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("No se pudo guardar %s (%s)" % [path, error_string(error)])
		return
	_write_uids(path, old_uid if old_uid != ResourceUID.INVALID_ID else ResourceUID.create_id())


# Uid escrito en la cabecera del archivo, o INVALID_ID si no existe o no lo tiene.
func _read_uid(path: String) -> int:
	if not FileAccess.file_exists(path):
		return ResourceUID.INVALID_ID
	var header := FileAccess.get_file_as_string(path).get_slice("\n", 0)
	if not header.contains(" uid=\""):
		return ResourceUID.INVALID_ID
	return ResourceUID.text_to_id(header.get_slice(" uid=\"", 1).get_slice("\"", 0))


# Desde un script (-s) Godot guarda sin uid propio ni en los ext_resource (como en
# map_generator.gd): se añaden a mano, el del recurso y el de cada archivo enlazado.
func _write_uids(path: String, uid: int) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i in lines.size():
		var line := lines[i]
		if line.begins_with("[gd_resource") and not line.contains(" uid="):
			lines[i] = line.trim_suffix("]") + " uid=\"%s\"]" % ResourceUID.id_to_text(uid)
		elif line.begins_with("[ext_resource") and not line.contains(" uid="):
			var linked := line.get_slice("path=\"", 1).get_slice("\"", 0)
			var linked_uid := _read_uid(linked) if linked.ends_with(".tres") else ResourceLoader.get_resource_uid(linked)
			if linked_uid == ResourceUID.INVALID_ID:
				linked_uid = ResourceLoader.get_resource_uid(linked)
			if linked_uid != ResourceUID.INVALID_ID:
				lines[i] = line.replace(" path=\"", " uid=\"%s\" path=\"" % ResourceUID.id_to_text(linked_uid))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()


# El nivel 5 vive dentro de GameData.tscn: se toca su texto para no reescribir la escena entera
# (y no cambiar sus ids). Añade las ext_resource que falten y reescribe la línea de oleadas.
func _patch_game_data(level_number: int, count: int) -> void:
	var file := FileAccess.open(GAME_DATA_PATH, FileAccess.READ)
	var lines := file.get_as_text().split("\n")
	file.close()
	var ids: Dictionary[String, String] = {}
	var regex := RegEx.create_from_string('^\\[ext_resource .*path="([^"]+)" id="([^"]+)"\\]$')
	var last_ext := 0
	var last_wave_ext := 0
	for i in lines.size():
		var found := regex.search(lines[i])
		if found == null:
			continue
		ids[found.get_string(1)] = found.get_string(2)
		last_ext = i
		if found.get_string(1).begins_with(WAVE_DIR):
			last_wave_ext = i
	var insert_at := (last_wave_ext if last_wave_ext > 0 else last_ext) + 1
	var refs: Array[String] = []
	for k in count:
		var path := _wave_path(level_number, k)
		if not ids.has(path):
			ids[path] = "wave_%d_%d" % [level_number, k + 1]
			var uid := ResourceUID.id_to_text(_read_uid(path))
			lines.insert(insert_at, '[ext_resource type="Resource" uid="%s" path="%s" id="%s"]' % [uid, path, ids[path]])
			insert_at += 1
		refs.append('ExtResource("%s")' % ids[path])
	var first_ref := 'ExtResource("%s")' % ids[_wave_path(level_number, 0)]
	for i in lines.size():
		if lines[i].begins_with("waves = ") and lines[i].contains(first_ref):
			lines[i] = lines[i].substr(0, lines[i].find("([") + 2) + ", ".join(refs) + "])"
	file = FileAccess.open(GAME_DATA_PATH, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
