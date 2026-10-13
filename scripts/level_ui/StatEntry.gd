extends RefCounted
class_name StatEntry
## Una fila de la ficha: icono de 8x8, nombre del stat (sale en el tooltip) y valor ya formateado.

const ICON_DIR := "res://assets/ui/stat_icons/"
## Caracteres de 8 px que caben en el valor: 72 px de barra menos el icono, el hueco y los márgenes.
const MAX_VALUE_CHARS := 7

var icon: Texture2D
var label: String
var value: String

## `icon_name` es el nombre del PNG en assets/ui/stat_icons/, sin extensión.
func _init(icon_name: String, stat_label: String, stat_value: String) -> void:
	icon = load(ICON_DIR + icon_name + ".png")
	label = stat_label
	value = stat_value
