extends Node
class_name Level

signal lost
signal won

# Centro horizontal del área de juego: barra izquierda de 80 px más la mitad de 480.
const GAME_AREA_CENTER_X := 320.0

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

# Desplaza el mapa en horizontal para que su rectángulo útil quede centrado en el área de juego.
func _center_map() -> void:
	var used_center_x := map.position.x + map.get_used_rect().get_center().x
	map.position.x += roundf(GAME_AREA_CENTER_X - used_center_x)

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
	won.emit()
