extends Node
class_name GameState

signal money_changed(amount: int)

var money := 100
var selected_tower: TowerData

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true
