class_name StatRow
## Fila de un stat con el estilo de la ficha: icono de 8x8 a la izquierda, valor a la derecha,
## fondo alterno según su posición y el nombre del stat en el tooltip. La usan InfoPanel y RunSummary.

const VALUE_COLOR := Color("#befaff")
const BG_COLOR := Color("#0e1626")
const ALT_BG_COLOR := Color("#0a0f1a")

## `index` decide el fondo alterno. Los márgenes son el hueco entre el borde de la fila y su contenido.
static func create(entry: StatEntry, index: int, h_margin: int = 1, v_margin: int = 1) -> PanelContainer:
	var row := PanelContainer.new()
	row.tooltip_text = entry.label
	# PASS: enseña el tooltip pero deja pasar la rueda a un ScrollContainer de encima.
	row.mouse_filter = Control.MOUSE_FILTER_PASS
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
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)

	var icon := TextureRect.new()
	icon.texture = entry.icon
	icon.custom_minimum_size = Vector2(8, 8)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var value := Label.new()
	value.text = entry.value
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.clip_text = true
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size", 8)
	value.add_theme_color_override("font_color", VALUE_COLOR)
	box.add_child(value)
	return row

## Etiqueta del valor de una fila hecha con create(), para cambiar su texto sin rehacerla.
static func get_value_label(row: PanelContainer) -> Label:
	return row.get_child(0).get_child(1) as Label
