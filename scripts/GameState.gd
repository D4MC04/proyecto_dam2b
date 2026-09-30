extends Node

signal money_changed(value)

@export var available_towers: Array[TowerData] = []
@export var money: int:
	set(v):
		money = v
		money_changed.emit(money)
