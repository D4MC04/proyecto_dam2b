extends RefCounted
class_name StatEntry
## Una fila de la ficha: icono de 8x8, nombre corto del stat en mayúsculas y valor ya formateado.

const ICON_DIR := "res://assets/ui/stat_icons/"
## Caracteres de 6 px que caben en el nombre ("OBJETIVOS", "VEL. BALA").
const MAX_LABEL_CHARS := 9
## Caracteres de 6 px que caben en el valor. La fila de la ficha mide 108 px (los 110 px útiles de
## la pantalla de la barra menos 1 px de margen a cada lado): icono de 8, hueco de 2, nombre de
## 9 caracteres (54), hueco de 2 y quedan 42 px para el valor.
const MAX_VALUE_CHARS := 7

var icon: Texture2D
var label: String
var value: String

## `icon_name` es el nombre del PNG en assets/ui/stat_icons/, sin extensión.
func _init(icon_name: String, stat_label: String, stat_value: String) -> void:
	icon = load(ICON_DIR + icon_name + ".png")
	label = stat_label
	value = stat_value
