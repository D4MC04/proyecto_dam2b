extends Node
class_name Level

signal lost
signal won

# Centro del área de juego: en horizontal, barra izquierda de 128 px más la mitad de 704;
# en vertical, la mitad de los 540 px de alto.
const GAME_AREA_CENTER := Vector2(480.0, 270.0)
# Área de juego completa: entre las dos barras de 128 px.
const GAME_AREA_RECT := Rect2(128.0, 0.0, 704.0, 540.0)

var map: Map
var towers: Array[TowerData]
# Un nivel acaba una sola vez: tras emitir lost o won no se emite ninguna de las dos.
var _finished: bool = false

@onready var grid: Grid = $Grid
@onready var spawner: Spawner = $Spawner
@onready var build_manager: BuildManager = $BuildManager
@onready var game_state: LevelState = $LevelState

func _ready() -> void:
	build_manager.state = game_state
	spawner.enemy_died.connect(game_state.register_enemy_destroyed)
	spawner.enemy_reached_end.connect(_lose)
	spawner.all_waves_cleared.connect(_win)

func setup(data: LevelData) -> void:
	map = data.map.instantiate()
	map.name = "Map"
	towers = data.towers
	add_child(map)
	move_child(map, 0)
	_center_map()
	grid.setup(map.logic_map)
	spawner.setup(map.get_paths(), data.waves)

## Resumen de la partida hasta ahora: oleada alcanzada, total, enemigos destruidos y dinero gastado.
func get_run_stats() -> RunStats:
	return RunStats.new(spawner.get_wave_index() + 1, spawner.waves.size(),
			game_state.enemies_destroyed, game_state.money_spent)

# Desplaza el mapa para que su rectángulo útil quede centrado en el área de juego en los dos ejes.
func _center_map() -> void:
	var used_center := map.position + map.get_used_rect().get_center()
	map.position += (GAME_AREA_CENTER - used_center).round()
	map.place_background(GAME_AREA_RECT)

func _lose() -> void:
	if _finished:
		return
	_finished = true
	# Durante la cámara lenta de la derrota el juego sigue corriendo: el nivel deja de construir ya.
	build_manager.stop_building()
	lost.emit()

func _win() -> void:
	if _finished:
		return
	_finished = true
	# Durante el respiro de la victoria el juego sigue corriendo: el nivel deja de construir ya.
	build_manager.stop_building()
	won.emit()
