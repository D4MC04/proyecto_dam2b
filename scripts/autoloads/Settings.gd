extends Node

# Autoload: opciones del jugador. Se cargan y aplican al arrancar y se guardan en cada cambio.
# Se emite después de aplicar el cambio, para lo que depende de una opción durante la partida.
signal changed(key: StringName)

const PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

# Opción de volumen -> bus de audio que controla.
const VOLUME_BUSES: Dictionary[StringName, StringName] = {
	&"master_volume": &"Master",
	&"music_volume": &"Music",
	&"sfx_volume": &"SFX",
}

# Opción -> nombre que tenía en versiones anteriores del archivo de opciones.
const LEGACY_KEYS: Dictionary[StringName, StringName] = {
	&"show_turret_range": &"show_tower_range",
}

# Idiomas con traducción en translations/textos.csv, en el orden en que los recorre Opciones.
const LANGUAGES: PackedStringArray = ["es", "en"]

# Valores por defecto; los volúmenes son lineales, de 0 a 1.
var _values: Dictionary[StringName, Variant] = {
	&"master_volume": 1.0,
	&"music_volume": 1.0,
	&"sfx_volume": 1.0,
	&"muted": false,
	&"fullscreen": false,
	&"vsync": true,
	&"show_fps": false,
	&"show_turret_range": false,
	&"show_damage_numbers": false,
	# Código del idioma de los textos (uno de LANGUAGES).
	&"language": "es",
	&"pause_on_focus_loss": true,
}

func _ready() -> void:
	var file: ConfigFile = ConfigFile.new()
	if file.load(PATH) == OK:
		for key: StringName in _values:
			# Si el archivo trae la clave con el nombre antiguo, se lee una vez para no perder el valor.
			var fallback: Variant = file.get_value(SECTION, LEGACY_KEYS.get(key, key), _values[key])
			# El archivo lo puede editar cualquiera: solo se aceptan valores del tipo esperado.
			var value: Variant = file.get_value(SECTION, key, fallback)
			if typeof(value) == typeof(_values[key]):
				_values[key] = value
	for key: StringName in _values:
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
		var bus: int = AudioServer.get_bus_index(VOLUME_BUSES[key])
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
		&"language":
			# Un idioma desconocido (archivo editado a mano) vuelve al español.
			TranslationServer.set_locale(value if value in LANGUAGES else LANGUAGES[0])

func _save() -> void:
	var file: ConfigFile = ConfigFile.new()
	for key: StringName in _values:
		file.set_value(SECTION, key, _values[key])
	if file.save(PATH) != OK:
		push_warning("Settings: no se pudo guardar " + PATH)
