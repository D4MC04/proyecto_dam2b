extends Button
class_name OverlayOptionButton

# Botón de una OverlayScreen. Dice qué opción representa (la pantalla base lo conecta) y es el
# botón recortado del tema en el acento de su pantalla: saca la forma y los márgenes de los
# estilos del tema y solo cambia los colores.

const IDLE_COLOR := Color("#cce6ff")
# Base oscura de la que salen los fondos y bordes, mezclada con el acento.
const DARK_COLOR := Color("#060b14")
const NORMAL_BG_MIX := 0.07
const NORMAL_BORDER_MIX := 0.45
# Con el ratón encima el botón se rellena con el acento; pulsado, algo más oscuro.
const HOVER_BG_MIX := 0.35
const PRESSED_BG_MIX := 0.22
const DISABLED_BORDER_MIX := 0.25
const DISABLED_TEXT_COLOR := Color("#5a7a96")

@export var option: OverlayScreen.Option = OverlayScreen.Option.RESUME
@export var accent_color: Color = Color("#40e0f0"):
	set(value):
		accent_color = value
		_refresh_look()
## Texto con el ratón encima o pulsado.
@export var accent_light_color: Color = Color("#befaff"):
	set(value):
		accent_light_color = value
		_refresh_look()

func _ready() -> void:
	# Es un juego de ratón: los botones no toman el foco.
	focus_mode = Control.FOCUS_NONE
	_refresh_look()

func _refresh_look() -> void:
	# Sin árbol no hay tema del que sacar la forma; _ready lo vuelve a llamar.
	if not is_inside_tree():
		return
	var normal_bg := DARK_COLOR.lerp(accent_color, NORMAL_BG_MIX)
	var hover := _recolor("hover", normal_bg.lerp(accent_color, HOVER_BG_MIX), accent_color)
	add_theme_stylebox_override("normal", _recolor("normal", normal_bg, DARK_COLOR.lerp(accent_color, NORMAL_BORDER_MIX)))
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", _recolor("pressed", normal_bg.lerp(accent_color, PRESSED_BG_MIX), accent_color))
	add_theme_stylebox_override("hover_pressed", _recolor("hover_pressed", hover.bg_color, accent_color))
	add_theme_stylebox_override("disabled", _recolor("disabled", DARK_COLOR, DARK_COLOR.lerp(accent_color, DISABLED_BORDER_MIX)))
	add_theme_color_override("font_color", IDLE_COLOR)
	add_theme_color_override("font_disabled_color", DISABLED_TEXT_COLOR)
	for color_name: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(color_name, accent_light_color)

# El estilo `style_name` del tema (sin el override de este botón) con otros colores.
func _recolor(style_name: StringName, bg: Color, border: Color) -> ClippedBoxStyle:
	remove_theme_stylebox_override(style_name)
	var base := get_theme_stylebox(style_name) as ClippedBoxStyle
	if base == null:
		return ClippedBoxStyle.create(bg, border)
	return base.recolored(bg, border)
