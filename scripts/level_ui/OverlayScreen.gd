extends Control
class_name OverlayScreen

# Pantalla superpuesta al área de juego (pausa, game over...). Las escenas heredadas
# cambian el título y añaden sus OverlayOptionButton a Options; la base conecta todos.
# Quién la muestra lo decide LevelUI.set_state(): esta escena no toca su visibilidad.

enum Option { RESUME, RESTART, QUIT, SETTINGS }

signal option_chosen(option: Option)

## Color del panel holograma y de las opciones.
@export var accent_color: Color = Color("#40e0f0")
## Tono claro del acento: corchetes del panel y texto de las opciones con el ratón encima.
@export var accent_light_color: Color = Color("#befaff")
## Color que oscurece el área de juego (negro salvo que la pantalla quiera un tinte).
@export var dim_color: Color = Color.BLACK
## Opacidad del oscurecido.
@export_range(0.0, 1.0) var dim_opacity: float = 0.5882353

@onready var background: ColorRect = %Background
@onready var frame: OverlayFrame = %Frame
@onready var title_label: Label = %Title
@onready var options: VBoxContainer = %Options

func _ready() -> void:
	background.color = Color(dim_color, dim_opacity)
	frame.accent_color = accent_color
	frame.accent_light_color = accent_light_color
	for child: Node in options.get_children():
		var button: OverlayOptionButton = child as OverlayOptionButton
		if button:
			button.accent_color = accent_color
			button.accent_light_color = accent_light_color
			button.pressed.connect(_on_option_pressed.bind(button.option))

# Pulsar una opción la elige. Una pantalla heredada puede quedarse el clic (p. ej. para pasar de página).
func _on_option_pressed(option: Option) -> void:
	option_chosen.emit(option)

# Cambia el texto (clave de traducción) del botón de una opción (p. ej. "Salir" pasa a "Saltar" en el
# nivel de emergencia).
func set_option_text(option: Option, text_key: String) -> void:
	for child: Node in options.get_children():
		var button: OverlayOptionButton = child as OverlayOptionButton
		if button and button.option == option:
			button.text = text_key

