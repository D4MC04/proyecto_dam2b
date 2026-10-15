@tool
extends VBoxContainer
class_name ScreenHeader
## Cabecera de la pantalla de las barras: "// TEXTO" en cian y debajo una regla de marcas
## (línea de 1 px con marcas cortas cada 4 px y largas cada 16), pintada en píxeles enteros.

const TEXT_PREFIX := "// "
const TEXT_COLOR := Color("#40e0f0")
const RULER_COLOR := Color("#1c7496")
const TICK_STEP := 4
const MAJOR_TICK_STEP := 16
# Largo de las marcas por debajo de la línea.
const TICK_LENGTH := 2
const MAJOR_TICK_LENGTH := 3

## Texto de la cabecera, sin el "// ".
@export var title := "":
	set(value):
		title = value
		if is_node_ready():
			title_label.text = TEXT_PREFIX + title

@onready var title_label: Label = %TitleLabel
@onready var ruler: Control = %Ruler

func _ready() -> void:
	title_label.text = TEXT_PREFIX + title
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	ruler.custom_minimum_size.y = 1 + MAJOR_TICK_LENGTH
	ruler.draw.connect(_draw_ruler)

func _draw_ruler() -> void:
	var width := int(ruler.size.x)
	ruler.draw_rect(Rect2(0, 0, width, 1), RULER_COLOR)
	for x in range(0, width, TICK_STEP):
		var length := MAJOR_TICK_LENGTH if x % MAJOR_TICK_STEP == 0 else TICK_LENGTH
		ruler.draw_rect(Rect2(x, 1, 1, length), RULER_COLOR)
