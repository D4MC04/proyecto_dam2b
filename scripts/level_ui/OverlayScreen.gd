extends Control
class_name OverlayScreen

# Pantalla superpuesta al área de juego (pausa, game over...). Las escenas heredadas
# cambian el título y añaden sus OverlayOptionButton a Options; la base conecta todos.
# Quién la muestra lo decide LevelUI.set_state(): esta escena no toca su visibilidad.

enum Option { RESUME, RESTART, QUIT, NEXT_LEVEL, SETTINGS }

signal option_chosen(option: Option)

# Mezcla del acento con el fondo oscuro del panel para el pie.
const FOOTER_ACCENT_MIX := 0.6

## Color del panel holograma y de las opciones.
@export var accent_color: Color = Color("#40e0f0")
## Tono claro del acento: corchetes del panel y texto de las opciones con el ratón encima.
@export var accent_light_color: Color = Color("#befaff")
## Color que oscurece el área de juego (negro salvo que la pantalla quiera un tinte).
@export var dim_color: Color = Color.BLACK
## Opacidad del oscurecido.
@export_range(0.0, 1.0) var dim_opacity: float = 0.5882353
## Texto tenue abajo a la izquierda del panel ("SISTEMA EN ESPERA"...).
@export var footer_text := ""

@onready var background: ColorRect = %Background
@onready var frame: OverlayFrame = %Frame
@onready var title_label: Label = %Title
@onready var options: VBoxContainer = %Options
@onready var footer_label: Label = %Footer

func _ready() -> void:
	background.color = Color(dim_color, dim_opacity)
	frame.accent_color = accent_color
	frame.accent_light_color = accent_light_color
	footer_label.text = footer_text
	footer_label.visible = not footer_text.is_empty()
	footer_label.add_theme_color_override("font_color", OverlayFrame.BG_COLOR.lerp(accent_color, FOOTER_ACCENT_MIX))
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button:
			button.accent_color = accent_color
			button.accent_light_color = accent_light_color
			button.pressed.connect(option_chosen.emit.bind(button.option))

# Muestra u oculta el botón de una opción (p. ej. "Siguiente nivel" en el último nivel).
func set_option_visible(option: Option, option_visible: bool) -> void:
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button and button.option == option:
			button.visible = option_visible

