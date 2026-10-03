extends Node

signal money_changed(value)

@export var available_towers: Array[TowerData] = []
@export var selected_tower: TowerData
@export var money: int:
	set(v):
		money = v
		money_changed.emit(money)

# Dinero con el que empieza cada nivel: el valor puesto en GameState.tscn.
@onready var _initial_money := money

func reset() -> void:
	money = _initial_money
