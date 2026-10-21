class_name Spawner
extends Node

signal enemy_died(reward: int)
signal enemy_reached_end(damage: int)
## Se emite al empezar cada oleada, con su índice (desde 0) y el total de oleadas.
signal wave_started(index: int, total: int)
## Se emite cuando la oleada `index` ha sacado su último enemigo; puede haber enemigos vivos.
signal wave_spawn_finished(index: int)
## Se emite cuando, tras la oleada `index`, no quedan entradas pendientes ni enemigos vivos.
signal wave_cleared(index: int)
## Se emite cuando se limpia la última oleada.
signal all_waves_cleared
## Se emite al cambiar `auto_waves`.
signal auto_waves_changed(enabled: bool)

const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/Enemy.tscn")
## Pausa entre que el nivel queda limpio y el arranque de la siguiente oleada con AUTO.
const AUTO_WAVE_DELAY := 1.5

## Con AUTO activo, la siguiente oleada empieza sola cuando el nivel queda limpio.
var auto_waves: bool = false:
	set(value):
		if auto_waves == value:
			return
		auto_waves = value
		if auto_waves:
			_try_schedule_auto_wave()
		else:
			_auto_countdown = -1.0
		auto_waves_changed.emit(auto_waves)

var paths: Array[Path2D]
var waves: Array[WaveData]
var _elapsed: float = 0.0
var _next_index: int = 0
var _wave_index: int = -1
var _entries: Array[SpawnEntry] = []
var _spawning: bool = false
# Enemigos vivos; cada uno se borra una sola vez, al morir o al llegar al final.
var _alive: Dictionary[Enemy, bool] = {}
# Segundos que faltan para que AUTO lance la siguiente oleada; negativo si no hay cuenta atrás.
var _auto_countdown: float = -1.0
# Los caminos empiezan 2 casillas fuera del mapa: el portal y la salida de las naves van
# 40 px más adelante, media casilla dentro del borde, para que se vean.
const PORTAL_OFFSET := 40.0

# Portales abiertos de la oleada actual, por índice de camino.
var _portals: Dictionary[int, Portal] = {}

func setup(p: Array[Path2D], w: Array[WaveData]) -> void:
	paths = p
	waves = w

## Lanza la siguiente oleada. Devuelve false si el nivel no está limpio o no quedan oleadas.
func start_next_wave() -> bool:
	if not can_start_next_wave():
		return false
	_auto_countdown = -1.0
	_wave_index += 1
	_entries = waves[_wave_index].entries.duplicate()
	_entries.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)
	_elapsed = 0.0
	_next_index = 0
	_spawning = true
	_open_portals()
	wave_started.emit(_wave_index, waves.size())
	return true

func can_start_next_wave() -> bool:
	return is_clear() and has_waves_left()

func has_waves_left() -> bool:
	return _wave_index + 1 < waves.size()

## Índice de la última oleada lanzada; -1 si aún no ha empezado ninguna.
func get_wave_index() -> int:
	return _wave_index

## La oleada actual aún tiene entradas pendientes.
func is_spawning() -> bool:
	return _spawning

## La última oleada lanzada ya sacó todos sus enemigos (o no se ha lanzado ninguna).
func has_finished_spawning() -> bool:
	return not _spawning

## No quedan entradas de ninguna oleada lanzada ni enemigos vivos.
func is_clear() -> bool:
	return not _spawning and _alive.is_empty()

func get_alive_count() -> int:
	return _alive.size()

func _process(delta: float) -> void:
	if _auto_countdown >= 0.0:
		_auto_countdown -= delta
		if _auto_countdown < 0.0:
			start_next_wave()
	if not _spawning:
		return
	_elapsed += delta
	while _next_index < _entries.size() and _entries[_next_index].time <= _elapsed:
		_spawn(_entries[_next_index])
		_next_index += 1
	if _next_index >= _entries.size():
		_spawning = false
		_close_portals()
		wave_spawn_finished.emit(_wave_index)
		_check_cleared()

func _spawn(entry: SpawnEntry) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	var path := paths[entry.path_index % paths.size()]
	path.add_child(enemy)
	enemy.setup(entry.enemy_data)
	enemy.progress = PORTAL_OFFSET
	enemy.spawn_in()
	GameState.mark_enemy_seen(entry.enemy_data)
	_alive[enemy] = true
	enemy.reached_end.connect(_on_enemy_reached_end.bind(enemy))
	enemy.died.connect(_on_enemy_died.bind(enemy))

# Abre un portal a la entrada de cada camino que use la oleada.
func _open_portals() -> void:
	for entry in _entries:
		var index := entry.path_index % paths.size()
		if _portals.has(index):
			continue
		var portal := Portal.new()
		var curve := paths[index].curve
		portal.position = curve.sample_baked(PORTAL_OFFSET)
		# La grieta (horizontal en Portal) queda atravesada al camino; girada en múltiplos de 90° para no deformar los píxeles.
		var direction := curve.sample_baked(PORTAL_OFFSET + 1.0) - portal.position
		portal.rotation = snappedf(direction.angle() + PI / 2.0, PI / 2.0)
		paths[index].add_child(portal)
		_portals[index] = portal

func _close_portals() -> void:
	for portal in _portals.values():
		portal.close()
	_portals.clear()

func _on_enemy_died(reward: int, enemy: Enemy) -> void:
	if not _alive.erase(enemy):
		return
	enemy_died.emit(reward)
	_check_cleared()

func _on_enemy_reached_end(damage: int, enemy: Enemy) -> void:
	if not _alive.erase(enemy):
		return
	enemy_reached_end.emit(damage)
	_check_cleared()

func _check_cleared() -> void:
	if _wave_index < 0 or not is_clear():
		return
	wave_cleared.emit(_wave_index)
	if has_waves_left():
		_try_schedule_auto_wave()
	else:
		all_waves_cleared.emit()

func _try_schedule_auto_wave() -> void:
	if auto_waves and is_clear() and has_waves_left() and _auto_countdown < 0.0:
		_auto_countdown = AUTO_WAVE_DELAY
