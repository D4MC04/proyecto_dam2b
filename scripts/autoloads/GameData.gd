extends Node

@export var levels: Array[LevelData]
## Simulacro: el nivel de prueba del tutorial. No es un sector: no está en `levels`, no sale en el radar
## y no da estrellas ni logros.
@export var simulation_level: LevelData
## Las 10 torretas principales en el orden en que se desbloquean: la N sale en el nivel N.
@export var turret_order: Array[TurretData]
