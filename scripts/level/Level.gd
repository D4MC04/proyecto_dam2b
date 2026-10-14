extends Node
class_name Level

signal lost

const ENEMY_BASE_DAMAGE := 10  # vida que quita a la base cada enemigo que llega al final

var map: Map
var towers: Array[TowerData]
var base: Base

@onready var grid: Grid = $Grid
@onready var spawner: Spawner = $Spawner
@onready var build_manager: BuildManager = $BuildManager
@onready var game_state: LevelState = $LevelState

func _ready() -> void:
	build_manager.state = game_state
	spawner.enemy_died.connect(game_state.add_money)

func setup(data: LevelData) -> void:
	map = data.map.instantiate()
	map.name = "Map"
	towers = data.towers
	add_child(map)
	move_child(map, 0)
	grid.setup(map.logic_map)
	spawner.setup(map.get_paths(), data.waves)
	base = map.get_node("SpaceStation")
	spawner.enemy_reached_end.connect(base.take_damage.bind(ENEMY_BASE_DAMAGE))
	base.destroyed.connect(_lose)

func on_tower_selected(data: TowerData) -> void:
	game_state.selected_tower = data

# Se pierde al acabar la explosión de la base: el game over pausa el juego y la cortaría
func _lose() -> void:
	await base.animation_finished
	lost.emit()
