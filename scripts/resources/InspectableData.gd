extends Resource
class_name InspectableData
## Contrato común de lo que se puede enseñar en la ficha de la barra izquierda.
## Lo cumplen TurretData y EnemyData; la ficha solo usa estos métodos.

## Icono grande (hasta 34x34, se enseña a escala 1).
func get_inspect_icon() -> Texture2D:
	return null

## Nombre que sale bajo el icono.
func get_inspect_name() -> String:
	return ""

## Etiqueta corta del tipo (9 caracteres como máximo).
func get_inspect_tag() -> String:
	return ""

## Color de acento de las esquinas del marco y de la etiqueta.
func get_inspect_accent() -> Color:
	return Color.WHITE

## Filas de stat de la ficha.
func get_stats() -> Array[StatEntry]:
	return []

## Frase corta que sale al final de la ficha; vacía si no hay.
func get_inspect_description() -> String:
	return ""
