extends Node
class_name LevelState

signal money_changed(amount: int)
signal selected_turret_changed(data: TurretData)
signal inspected_changed(data: Resource)
signal sellable_turret_changed(turret: Turret)
## BuildManager la emite al colocar una torreta nueva en una casilla libre (no al mejorar).
signal turret_placed
## El jugador pide mejorar la torreta colocada seleccionada; la atiende BuildManager.
signal upgrade_requested
## Ha empezado o ha acabado una oleada (ver wave_in_progress).
signal wave_in_progress_changed(active: bool)

# Premio al limpiar una oleada (menos la última) sin que llegue ningún enemigo a la estación.
const PERFECT_WAVE_BONUS := 25

# Lo fija Level.setup con LevelData.starting_money.
var money := 0
# Recuento de la partida para el resumen. Al reiniciar se crea un LevelState nuevo, así que vuelven a 0.
var enemies_destroyed := 0
var money_spent := 0
## Hay una oleada lanzada que aún no se ha limpiado. La pone Level con las señales del Spawner.
var wave_in_progress := false:
	set(value):
		if wave_in_progress == value:
			return
		wave_in_progress = value
		wave_in_progress_changed.emit(value)
var selected_turret: TurretData:
	set(value):
		if selected_turret == value:
			return
		selected_turret = value
		selected_turret_changed.emit(value)
## Lo que enseña la ficha (de momento TurretData). null = aún no se ha inspeccionado nada.
var inspected: Resource:
	set(value):
		# Inspeccionar cualquier cosa suelta la torreta colocada que se pudiera vender.
		sellable_turret = null
		if inspected == value:
			return
		inspected = value
		inspected_changed.emit(value)

## Torreta colocada seleccionada en el mapa, la que enseña el botón de vender. null = ninguna.
var sellable_turret: Turret:
	set(value):
		if sellable_turret == value:
			return
		if is_instance_valid(sellable_turret):
			sellable_turret.selected = false
		sellable_turret = value
		if value != null:
			value.selected = true
		sellable_turret_changed.emit(value)

## Selecciona una torreta colocada: enseña su ficha y habilita venderla.
func inspect_placed(turret: Turret) -> void:
	inspected = turret.data
	sellable_turret = turret

## Vende la torreta colocada seleccionada: devuelve la mitad de lo invertido y la quita del mapa
## (al salir del árbol, Grid libera su casilla).
func sell_selected_turret() -> void:
	if not is_instance_valid(sellable_turret):
		return
	var value := sellable_turret.get_sell_value()
	add_money(value)
	FloatingText.spawn(sellable_turret.get_parent(), sellable_turret.global_position, "+" + UiFormat.money(value))
	_note_retired(sellable_turret)
	sellable_turret.play_sell()
	sellable_turret.queue_free()
	sellable_turret = null

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_spent += amount
	GameState.add_stat("spent", amount)
	money_changed.emit(money)
	return true

## Mejor torreta vendida (se guarda al venderla para que cuente en el resumen).
var retired_top_name := ""
var retired_top_kills := 0

func _note_retired(turret: Turret) -> void:
	if turret.kills > retired_top_kills:
		retired_top_kills = turret.kills
		retired_top_name = turret.data.name

## Un enemigo destruido: suma su recompensa y lo cuenta.
func register_enemy_destroyed(reward: int) -> void:
	enemies_destroyed += 1
	add_money(reward)
