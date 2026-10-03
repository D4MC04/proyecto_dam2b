extends Node2D

@onready var spawner: Node = $Spawner
@onready var game_over_screen: CanvasLayer = $UI/GameOverScreen

var finished := false

# En _enter_tree porque Grid y Spawner leen el mapa en su _ready, anterior al del nivel.
func _enter_tree():
	GameState.reset()
	var old := $Map
	remove_child(old)
	old.free()
	var map: Map = load(Map.selected).instantiate()
	map.name = "Map"
	add_child(map)
	move_child(map, 0)
	$Spawner.map = map

func _ready():
	spawner.enemy_reached_end.connect(_on_enemy_reached_end)

func _on_enemy_reached_end():
	# Al perder, el escudo de la base se queda débil.
	get_tree().call_group("base", "hit", true)
	_lose()

func _lose():
	if finished:
		return
	finished = true
	game_over_screen.mostrar()
