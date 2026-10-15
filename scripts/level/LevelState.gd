extends Node
class_name LevelState

signal money_changed(amount: int)
signal selected_tower_changed(data: TowerData)
signal inspected_changed(data: Resource)

var money := 5000
# Recuento de la partida para el resumen. Al reiniciar se crea un LevelState nuevo, así que vuelven a 0.
var enemies_destroyed := 0
var money_spent := 0
var selected_tower: TowerData:
	set(value):
		if selected_tower == value:
			return
		selected_tower = value
		selected_tower_changed.emit(value)
## Lo que enseña la ficha (de momento TowerData). null = aún no se ha inspeccionado nada.
var inspected: Resource:
	set(value):
		if inspected == value:
			return
		inspected = value
		inspected_changed.emit(value)

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_spent += amount
	money_changed.emit(money)
	return true

## Un enemigo destruido: suma su recompensa y lo cuenta.
func register_enemy_destroyed(reward: int) -> void:
	enemies_destroyed += 1
	add_money(reward)
