extends Node
class_name Level

signal lost
signal won

# Centro del área de juego: en horizontal, barra izquierda de 128 px más la mitad de 704;
# en vertical, la mitad de los 540 px de alto.
const GAME_AREA_CENTER := Vector2(480.0, 270.0)
# Área de juego completa: entre las dos barras de 128 px.
# El premio de oleada se queda en pantalla más que el +X€ de un enemigo.
const AWARD_TEXT_DURATION := 4.0
# Temblor al llegar una nave: 2 px (más con más daño) durante 0,15 s.
const SHAKE_AMPLITUDE := 2.0
const SHAKE_TIME := 0.15
const SHAKE_REFERENCE_DAMAGE := 40.0
const GAME_AREA_RECT := Rect2(128.0, 0.0, 704.0, 540.0)

var map: Map
var turrets: Array[TurretData]
var base: Base
var _shake_tween: Tween
var _map_origin: Vector2
# Un nivel acaba una sola vez: tras emitir lost o won no se emite ninguna de las dos.
var _finished: bool = false
# Enemigos que han llegado a la estación en la oleada actual (para el bonus de oleada perfecta).
var _leaks_this_wave := 0

@onready var grid: Grid = $Grid
@onready var spawner: Spawner = $Spawner
@onready var build_manager: BuildManager = $BuildManager
@onready var game_state: LevelState = $LevelState

func _ready() -> void:
	build_manager.state = game_state
	game_state.upgrade_requested.connect(build_manager.upgrade_selected)
	spawner.enemy_died.connect(game_state.register_enemy_destroyed)
	spawner.all_waves_cleared.connect(_win)
	spawner.wave_started.connect(func(_index: int, _total: int) -> void:
		_leaks_this_wave = 0
		game_state.wave_in_progress = true)
	spawner.wave_cleared.connect(func(_index: int) -> void: game_state.wave_in_progress = false)
	spawner.enemy_reached_end.connect(func(_damage: int) -> void: _leaks_this_wave += 1)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.enemy_died.connect(func(_reward: int) -> void: GameState.add_stat("kills"))
	game_state.turret_placed.connect(func() -> void: GameState.add_stat("turrets"))
	$Powers.power_used.connect(func(_power: Powers.Power) -> void: GameState.add_stat("powers"))

func _process(delta: float) -> void:
	# En tiempo real: delta ya viene multiplicado por la velocidad del juego.
	GameState.add_play_time(delta / maxf(Engine.time_scale, 0.01))

func setup(data: LevelData) -> void:
	map = data.map.instantiate()
	map.name = "Map"
	turrets = data.turrets
	add_child(map)
	move_child(map, 0)
	_center_map()
	grid.setup(map.logic_map)
	spawner.setup(map.get_paths(), data.waves)
	base = map.get_node("SpaceStation")
	spawner.enemy_reached_end.connect(base.take_damage)
	spawner.enemy_reached_end.connect(shake_map)
	_map_origin = map.position
	base.destroyed.connect(_lose)

## Resumen de la partida hasta ahora: oleada alcanzada, total, enemigos destruidos y dinero gastado.
func get_run_stats() -> RunStats:
	var stats := RunStats.new(spawner.get_wave_index() + 1, spawner.waves.size(),
			game_state.enemies_destroyed, game_state.money_spent)
	stats.top_turret_name = game_state.retired_top_name
	stats.top_turret_kills = game_state.retired_top_kills
	for node: Node in get_tree().get_nodes_in_group(&"turrets"):
		var turret := node as Turret
		if turret != null and not turret.is_queued_for_deletion() and turret.kills > stats.top_turret_kills:
			stats.top_turret_kills = turret.kills
			stats.top_turret_name = turret.data.name
	return stats

# Desplaza el mapa para que su rectángulo útil quede centrado en el área de juego en los dos ejes.
func _center_map() -> void:
	var used_center := map.position + map.get_used_rect().get_center()
	map.position += (GAME_AREA_CENTER - used_center).round()
	map.place_background(GAME_AREA_RECT)

# Sacude el mapa (no la UI) con un temblor que decae, en píxeles enteros.
# Los tweens siguen Engine.time_scale, así que respeta la velocidad del juego.
func shake_map(damage: int) -> void:
	if _finished:
		return
	if _shake_tween:
		_shake_tween.kill()
	var amplitude := SHAKE_AMPLITUDE * (1.0 + damage / SHAKE_REFERENCE_DAMAGE)
	_shake_tween = create_tween()
	_shake_tween.tween_method(func(t: float) -> void:
		var wave := sin(t * TAU * 3.0) * (1.0 - t) * amplitude
		map.position = _map_origin + Vector2(wave, wave * 0.5).round(), 0.0, 1.0, SHAKE_TIME)
	_shake_tween.finished.connect(func() -> void: map.position = _map_origin)

# Al limpiar una oleada (menos la última) sin que entre nadie, da el bonus de oleada perfecta.
func _on_wave_cleared(_index: int) -> void:
	GameState.flush()
	if _finished or not spawner.has_waves_left():
		return
	if _leaks_this_wave == 0:
		GameState.add_stat("perfect_waves")
		_award("PERFECTA", LevelState.PERFECT_WAVE_BONUS)

# Suma el premio y lo enseña sobre la estación.
func _award(label: String, amount: int) -> void:
	game_state.add_money(amount)
	var pos := base.global_position + Vector2(0.0, -20.0)
	FloatingText.spawn(base.get_parent(), pos, "%s +%s" % [label, UiFormat.money(amount)], AWARD_TEXT_DURATION)

func _lose() -> void:
	if _finished:
		return
	_finished = true
	# Durante la cámara lenta de la derrota el juego sigue corriendo: el nivel deja de construir ya.
	build_manager.stop_building()
	# Se pierde al acabar la explosión de la base: el game over pausa el juego y la cortaría
	await base.animation_finished
	lost.emit()

func _win() -> void:
	if _finished:
		return
	_finished = true
	# Durante el respiro de la victoria el juego sigue corriendo: el nivel deja de construir ya.
	build_manager.stop_building()
	won.emit()
