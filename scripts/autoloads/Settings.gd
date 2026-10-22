extends Node

# Autoload: opciones del jugador. Se cargan y aplican al arrancar y se guardan en cada cambio.
# Se emite después de aplicar el cambio, para lo que depende de una opción durante la partida.
signal changed(key: StringName)

const PATH := "user://settings.cfg"
const SECTION := "settings"

# Opción de volumen -> bus de audio que controla.
const VOLUME_BUSES: Dictionary[StringName, StringName] = {
	&"master_volume": &"Master",
	&"music_volume": &"Music",
	&"sfx_volume": &"SFX",
}

# Valores por defecto; los volúmenes son lineales, de 0 a 1.
var _values: Dictionary[StringName, Variant] = {
	&"master_volume": 1.0,
	&"music_volume": 1.0,
	&"sfx_volume": 1.0,
	&"muted": false,
	&"fullscreen": false,
	&"vsync": true,
	&"show_fps": false,
	&"show_tower_range": false,
	&"low_effects": false,
}

func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for key in _values:
			# El archivo lo puede editar cualquiera: solo se aceptan valores del tipo esperado.
			var value: Variant = file.get_value(SECTION, key, _values[key])
			if typeof(value) == typeof(_values[key]):
				_values[key] = value
	for key in _values:
		_apply(key)

func get_value(key: StringName) -> Variant:
	return _values[key]

func set_value(key: StringName, value: Variant) -> void:
	_values[key] = value
	_apply(key)
	_save()
	changed.emit(key)

func _apply(key: StringName) -> void:
	var value: Variant = _values[key]
	if VOLUME_BUSES.has(key):
		var bus := AudioServer.get_bus_index(VOLUME_BUSES[key])
		AudioServer.set_bus_volume_linear(bus, clampf(value, 0.0, 1.0))
		return
	match key:
		&"muted":
			# Silencia el bus Master sin tocar los volúmenes: al quitarlo vuelven como estaban.
			AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), value)
		&"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
		&"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)

func _save() -> void:
	var file := ConfigFile.new()
	for key in _values:
		file.set_value(SECTION, key, _values[key])
	if file.save(PATH) != OK:
		push_warning("Settings: no se pudo guardar " + PATH)
