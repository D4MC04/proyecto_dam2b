extends Control
class_name OverlayScreen

# Pantalla superpuesta al área de juego (pausa, game over...). Las escenas heredadas
# cambian el título y añaden sus OverlayOptionButton a Options; la base conecta todos.
# Quién la muestra lo decide LevelUI.set_state(): esta escena no toca su visibilidad.

enum Option { RESUME, RESTART, QUIT }

signal option_chosen(option: Option)

@onready var title_label: Label = %Title
@onready var options: VBoxContainer = %Options

func _ready() -> void:
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button:
			button.pressed.connect(option_chosen.emit.bind(button.option))
