class_name StatRow
## Fila de un stat con el estilo de la ficha: icono de 8x8 y nombre a la izquierda, valor a la
## derecha y fondo alterno según su posición. La usan InfoPanel y RunSummary.

const LABEL_COLOR := Color("#5a7a96")
const VALUE_COLOR := Color("#cce6ff")
const BG_COLOR := Color("#0b2132")
const ALT_BG_COLOR := Color("#091d2c")
# Hueco entre icono, nombre y valor.
const SEPARATION := 4
# Distancia del borde de arriba de la línea de texto (13 px) al icono de 8x8.
const ICON_TOP := 3

## `index` decide el fondo alterno. Los márgenes son el hueco entre el borde de la fila y su contenido.
## `font_size`, `icon_box` (lado del hueco del icono, que sigue siendo de 8x8 centrado), `icon_top`
## y `separation` escalan la fila.
static func create(entry: StatEntry, index: int, h_margin: int = 3, v_margin: int = 1, font_size: int = 16, icon_box: int = 8, icon_top: int = ICON_TOP, separation: int = SEPARATION) -> PanelContainer:
	var row := PanelContainer.new()
	# IGNORE: la fila no recoge el ratón, así que la rueda llega directa al ScrollContainer de encima.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR if index % 2 == 0 else ALT_BG_COLOR
	style.anti_aliasing = false
	style.content_margin_left = h_margin
	style.content_margin_right = h_margin
	style.content_margin_top = v_margin
	style.content_margin_bottom = v_margin
	row.add_theme_stylebox_override("panel", style)

	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", separation)
	row.add_child(box)

	# El icono va bajado ICON_TOP px dentro de la línea de texto para que su centro caiga
	# a la altura del centro de las mayúsculas de Monogram.
	var icon_margin := MarginContainer.new()
	icon_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_margin.add_theme_constant_override("margin_top", icon_top)
	box.add_child(icon_margin)
	var icon := TextureRect.new()
	icon.texture = entry.icon
	icon.custom_minimum_size = Vector2(icon_box, icon_box)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_margin.add_child(icon)

	box.add_child(_make_label(entry.label, LABEL_COLOR, font_size))

	var value := _make_label(entry.value, VALUE_COLOR, font_size)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.clip_text = true
	box.add_child(value)
	return row

## Etiqueta del valor de una fila hecha con create(), para cambiar su texto sin rehacerla.
static func get_value_label(row: PanelContainer) -> Label:
	return row.get_child(0).get_child(2) as Label

static func _make_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
