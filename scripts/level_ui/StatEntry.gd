extends RefCounted
class_name StatEntry
## Una fila de la ficha: icono de 8x8, nombre corto del stat en mayúsculas y valor ya formateado.
## El nombre se pasa como clave de traducción (STAT_...) y se traduce aquí.

const ICON_DIR: String = "res://assets/ui/stat_icons/"
## Caracteres de 6 px que caben en el nombre ("OBJETIVOS", "VEL. BALA").
const MAX_LABEL_CHARS: int = 9
## Caracteres de 6 px que caben en el valor. La fila de la ficha mide 104 px (los 110 px útiles de
## la pantalla de la barra menos 3 px de margen a cada lado): icono de 8 y dos huecos de 4, así que
## quedan 88 px (14 caracteres) entre nombre y valor. Un valor de 7 cabe con un nombre de hasta 7;
## con el nombre más largo (9) caben 5.
const MAX_VALUE_CHARS: int = 7

var icon: Texture2D
var label: String
var value: String

## `icon_name` es el nombre del PNG en assets/ui/stat_icons/, sin extensión.
func _init(icon_name: String, stat_label: String, stat_value: String) -> void:
	icon = load(ICON_DIR + icon_name + ".png")
	label = tr(stat_label)
	value = stat_value
