extends Resource
class_name LevelData

@export var map: PackedScene
## Dinero con el que empieza el jugador el nivel.
@export var starting_money: int = 500
@export var turrets: Array[TurretData]
@export var waves: Array[WaveData]
