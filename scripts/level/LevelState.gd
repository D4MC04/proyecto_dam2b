extends Node
class_name LevelState

signal money_changed(amount: int)
signal selected_tower_changed(data: TowerData)

var money := 1000
var selected_tower: TowerData:
	set(value):
		if selected_tower == value:
			return
		selected_tower = value
		selected_tower_changed.emit(value)

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true
