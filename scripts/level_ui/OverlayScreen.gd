extends Control
class_name OverlayScreen

# Pantalla superpuesta al área de juego (pausa, game over...). Las escenas heredadas
# cambian el título y añaden sus OverlayOptionButton a Options; la base conecta todos.
# Quién la muestra lo decide LevelUI.set_state(): esta escena no toca su visibilidad.

enum Option { RESUME, RESTART, QUIT, NEXT_LEVEL }

signal option_chosen(option: Option)

@onready var title_label: Label = %Title
@onready var options: VBoxContainer = %Options

func _ready() -> void:
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button:
			button.pressed.connect(option_chosen.emit.bind(button.option))

# Muestra u oculta el botón de una opción (p. ej. "Siguiente nivel" en el último nivel).
func set_option_visible(option: Option, option_visible: bool) -> void:
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button and button.option == option:
			button.visible = option_visible
