extends RefCounted
class_name DevLaunch

# Argumentos de arranque de prueba, solo en depuración (los usa el comando /test). Van tras `--`:
#   Godot.exe --path <carpeta> -- --level=3 --wave=5 --money=9999
# Argumentos:
#   --office-tutorial  oficina con su tutorial (como tras ganar el nivel de emergencia).
#   --office           oficina sin tutoriales.
#   --level=N          nivel N (1 = primer sector) ya empezado; --level=emergency, el nivel de emergencia.
#   --wave=N           con --level: las oleadas anteriores a la N se dan por jugadas (la siguiente es la N).
#   --money=N          con --level: dinero inicial N.
#   --progress=N       nivel más alto desbloqueado (current_level de GameState).
# No se carga ninguna ranura, así que no se guarda nada.

const EMERGENCY: String = "emergency"

## Hay algún argumento de prueba y es una build de depuración.
static func is_active() -> bool:
	if not OS.is_debug_build():
		return false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--office") or arg.begins_with("--level=") or arg.begins_with("--progress="):
			return true
	return false

## Valor de `--key=valor`, o "" si no está. `--key` sin valor devuelve "true".
static func get_arg(key: String) -> String:
	if not OS.is_debug_build():
		return ""
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--" + key:
			return "true"
		if arg.begins_with("--%s=" % key):
			return arg.get_slice("=", 1)
	return ""

## Ajusta GameState según los argumentos y devuelve la escena a la que ir (Game o MainMenu), sin añadir.
static func make_start_scene(main_menu: PackedScene, game_scene: PackedScene) -> Node:
	var progress: String = get_arg("progress")
	if progress.is_valid_int():
		GameState.current_level = clampi(progress.to_int(), 1, GameData.levels.size())
	var level: LevelData = get_level()
	var emergency: bool = level != null and level == GameData.emergency_level
	var office_tutorial: bool = get_arg("office-tutorial") != ""
	# El nivel de emergencia vuelve a la oficina con su tutorial, como en una partida nueva.
	GameState.tutorial_done = not emergency
	GameState.tutorial_won = true
	GameState.office_tutorial_done = not (office_tutorial or emergency)
	if level == null:
		return main_menu.instantiate()
	var game: Game = game_scene.instantiate()
	game.level_data = level
	return game

## Nivel pedido con --level, o null si no hay o no existe.
static func get_level() -> LevelData:
	var value: String = get_arg("level")
	if value == EMERGENCY:
		return GameData.emergency_level
	if value.is_valid_int():
		var index: int = value.to_int() - 1
		if index >= 0 and index < GameData.levels.size():
			return GameData.levels[index]
	return null

## Aplica --wave y --money al nivel recién preparado, solo si es el pedido con --level.
static func apply_to_level(level: Level, data: LevelData) -> void:
	if data == null or data != get_level():
		return
	var money: String = get_arg("money")
	if money.is_valid_int():
		level.game_state.money = money.to_int()
	var wave: String = get_arg("wave")
	if wave.is_valid_int():
		level.spawner.skip_waves(wave.to_int() - 1)
