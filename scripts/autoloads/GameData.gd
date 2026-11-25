extends Node

@export var levels: Array[LevelData]
## Nivel de emergencia: el nivel de prueba del tutorial. No es un sector: no está en `levels`, no sale en el radar
## y no da estrellas ni logros.
@export var emergency_level: LevelData
## Las 10 torretas principales en el orden en que se desbloquean: la N + 1 sale en el nivel N (la 1.ª en el de emergencia).
@export var turret_order: Array[TurretData]
