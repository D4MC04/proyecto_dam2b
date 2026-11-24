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
	# Igual que window/size/mode=3 de project.godot: el juego arranca en pantalla completa.
	&"fullscreen": true,
	&"vsync": true,
	&"show_fps": false,
	&"show_turret_range": false,
	&"show_damage_numbers": false,
	&"screen_shake": true,
	# Código del idioma de los textos (uno de LANGUAGES).
	&"language": "es",
	&"pause_on_focus_loss": true,
}

# Topes de FPS para gastar menos (ver flujo.md › "Rendimiento"). El tope normal es la frecuencia de
# la pantalla dividida entre el entero que la deja más cerca de 60 sin bajar de 60 (144 Hz -> 72):
# así cada fotograma dura un número exacto de refrescos y no hay tirones con VSync.
const MIN_FPS: float = 60.0
const IDLE_FPS: int = 30  # árbol en pausa o ventana sin foco
const ASLEEP_FPS: int = 10  # en pausa y sin foco

var _base_fps: int = 60
var _focused: bool = true

func _ready() -> void:
	# Sigue con el árbol en pausa para bajar los FPS.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Se mira una vez: si se lleva la ventana a otro monitor con otra frecuencia no se recalcula.
	var refresh: float = DisplayServer.screen_get_refresh_rate()
	if refresh >= MIN_FPS:
		_base_fps = roundi(refresh / floorf(refresh / MIN_FPS))
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true

# La pausa no avisa con una señal: se mira cada fotograma, que es una comparación.
func _process(_delta: float) -> void:
	var paused: bool = get_tree().paused
	var target: int = _base_fps
	if paused and not _focused:
		target = ASLEEP_FPS
	elif paused or not _focused:
		target = IDLE_FPS
	if Engine.max_fps != target:
		Engine.max_fps = target

# Dentro del editor (F5 incrustado en Godot 4.7) la ventana no se puede cambiar.
func fullscreen_supported() -> bool:
	return not Engine.is_embedded_in_editor()

func get_value(key: StringName) -> Variant:
	# Lo que se enseña coincide con la ventana real: incrustado, siempre ventana.
	if key == &"fullscreen" and not fullscreen_supported():
		return false
	return _values[key]

func set_value(key: StringName, value: Variant) -> void:
	if key == &"fullscreen" and not fullscreen_supported():
		return
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
			if fullscreen_supported():
				# OFF = ventana maximizada: ocupa la pantalla menos la barra de tareas.
				# Al restaurarla usa window_*_override de project.godot, que es menor que el monitor porque
				# Windows convierte una ventana del tamaño exacto de la pantalla en pantalla completa exclusiva.
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_MAXIMIZED)
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
