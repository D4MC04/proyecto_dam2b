@tool
extends StyleBox
class_name ClippedBoxStyle
## Caja con las esquinas de arriba a la izquierda y de abajo a la derecha recortadas en diagonal:
## fondo y borde de 1 px. Es la forma de todos los botones del juego (el tema y las barras) y
## la base del panel holograma de OverlayFrame. Se dibuja en píxeles enteros, sin antialiasing:
## cada diagonal es una escalera de 1 px por fila.

## Recorte de los botones, en píxeles.
const BUTTON_CLIP := 3
# Márgenes de contenido por defecto (texto o icono del botón).
const DEFAULT_H_MARGIN := 4
const DEFAULT_V_MARGIN := 1

@export var bg_color := Color("#081626"):
	set(value):
		bg_color = value
		emit_changed()
@export var border_color := Color("#1c7496"):
	set(value):
		border_color = value
		emit_changed()
## Píxeles que se recortan en diagonal en las dos esquinas.
@export_range(0, 16) var clip := BUTTON_CLIP:
	set(value):
		clip = value
		emit_changed()

func _init() -> void:
	content_margin_left = DEFAULT_H_MARGIN
	content_margin_right = DEFAULT_H_MARGIN
	content_margin_top = DEFAULT_V_MARGIN
	content_margin_bottom = DEFAULT_V_MARGIN

## Crea una caja con estos colores y el recorte de los botones.
static func create(bg: Color, border: Color, clip_px: int = BUTTON_CLIP) -> ClippedBoxStyle:
	var style := ClippedBoxStyle.new()
	style.bg_color = bg
	style.border_color = border
	style.clip = clip_px
	return style

## Copia de esta caja (forma y márgenes) con otros colores.
func recolored(bg: Color, border: Color) -> ClippedBoxStyle:
	var style := duplicate() as ClippedBoxStyle
	style.bg_color = bg
	style.border_color = border
	return style

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var r := Rect2i(rect)
	fill_inside(to_canvas_item, r, clip, bg_color)
	draw_outline(to_canvas_item, r, clip, border_color)

# Primer y último píxel (sin incluir) de la fila `y` de una caja recortada.
static func row_span(r: Rect2i, clip_px: int, y: int) -> Vector2i:
	var left := r.position.x + maxi(clip_px - (y - r.position.y), 0)
	var right := r.end.x - maxi(clip_px - (r.end.y - 1 - y), 0)
	return Vector2i(left, right)

## Pinta el contorno de 1 px de una caja recortada: los bordes rectos y las dos diagonales.
static func draw_outline(ci: RID, r: Rect2i, clip_px: int, color: Color) -> void:
	if r.size.x <= 0 or r.size.y <= 0 or color.a <= 0.0:
		return
	var top := r.position.y
	var bottom := r.end.y - 1
	var top_span := row_span(r, clip_px, top)
	_fill(ci, Rect2i(top_span.x, top, top_span.y - top_span.x, 1), color)
	if bottom == top:
		return
	var bottom_span := row_span(r, clip_px, bottom)
	_fill(ci, Rect2i(bottom_span.x, bottom, bottom_span.y - bottom_span.x, 1), color)
	# Entre la fila de arriba y la de abajo, un píxel a cada lado. En el tramo recto son dos
	# columnas; en los recortes la columna cambia en cada fila y forma la diagonal.
	var straight_top := maxi(top + 1, top + clip_px)
	var straight_bottom := mini(bottom, bottom - clip_px + 1)
	if straight_bottom > straight_top:
		_fill(ci, Rect2i(r.position.x, straight_top, 1, straight_bottom - straight_top), color)
		_fill(ci, Rect2i(r.end.x - 1, straight_top, 1, straight_bottom - straight_top), color)
	for y in range(top + 1, bottom):
		if y >= straight_top and y < straight_bottom:
			continue
		var span := row_span(r, clip_px, y)
		_fill(ci, Rect2i(span.x, y, 1, 1), color)
		_fill(ci, Rect2i(span.y - 1, y, 1, 1), color)

## Rellena el interior de una caja recortada (sin el contorno de 1 px).
static func fill_inside(ci: RID, r: Rect2i, clip_px: int, color: Color) -> void:
	if color.a <= 0.0:
		return
	var inner := r.grow(-1)
	if inner.size.x <= 0 or inner.size.y <= 0:
		return
	# El interior es otra caja recortada, con un píxel menos de recorte, que toca al contorno.
	var inner_clip := maxi(clip_px - 1, 0)
	var straight_top := inner.position.y + inner_clip
	var straight_bottom := inner.end.y - inner_clip
	for y in range(inner.position.y, inner.end.y):
		if y == straight_top and straight_bottom > straight_top:
			_fill(ci, Rect2i(inner.position.x, y, inner.size.x, straight_bottom - straight_top), color)
			continue
		if y > straight_top and y < straight_bottom:
			continue
		var span := row_span(inner, inner_clip, y)
		_fill(ci, Rect2i(span.x, y, span.y - span.x, 1), color)

static func _fill(ci: RID, r: Rect2i, color: Color) -> void:
	if r.size.x > 0 and r.size.y > 0:
		RenderingServer.canvas_item_add_rect(ci, Rect2(r), color)
