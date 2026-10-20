extends Node
class_name LevelState

signal money_changed(amount: int)
signal selected_tower_changed(data: TowerData)
signal inspected_changed(data: Resource)
signal sellable_tower_changed(tower: Tower)

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
		# Inspeccionar cualquier cosa suelta la torre colocada que se pudiera vender.
		sellable_tower = null
		if inspected == value:
			return
		inspected = value
		inspected_changed.emit(value)

## Torre colocada seleccionada en el mapa, la que enseña el botón de vender. null = ninguna.
var sellable_tower: Tower:
	set(value):
		if sellable_tower == value:
			return
		sellable_tower = value
		sellable_tower_changed.emit(value)

## Selecciona una torre colocada: enseña su ficha y habilita venderla.
func inspect_placed(tower: Tower) -> void:
	inspected = tower.data
	sellable_tower = tower

## Vende la torre colocada seleccionada: devuelve la mitad del coste y la quita del mapa
## (al salir del árbol, Grid libera su casilla).
func sell_selected_tower() -> void:
	if not is_instance_valid(sellable_tower):
		return
	add_money(sellable_tower.data.get_sell_value())
	sellable_tower.queue_free()
	sellable_tower = null

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
