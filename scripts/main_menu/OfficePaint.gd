class_name OfficePaint
extends RefCounted

# Pinceles de la oficina del menú: rectángulos, cajas con bisel, pantallas, líneas, círculos, texto y
# pantallas en trapecio (las de las piezas apoyadas en la consola inclinada), todo en píxeles enteros
# y sin antialiasing. Los colores son los de art.md.

const FONT: Font = preload("res://assets/fonts/Monogram.ttf")
const TEXT_SIZE: int = 16
# Alto de una línea de Monogram a 16 px.
const TEXT_HEIGHT: int = 13

const OUTLINE: Color = Color("#0c0e16")
# Rampa del metal gris azulado de torretas y tablets.
const METAL_DARK: Color = Color("#343a4a")
const METAL: Color = Color("#606a7c")
const METAL_LIGHT: Color = Color("#96a2b6")
const METAL_SHINE: Color = Color("#d2dceb")
# Metal oscuro de paredes y muebles, más apagado que el de los objetos para que estos destaquen.
const WALL_DARK: Color = Color("#0e1118")
const WALL: Color = Color("#151923")
const WALL_LIGHT: Color = Color("#1d2230")
const WALL_EDGE: Color = Color("#2a3142")
const SCREEN: Color = Color("#08111f")
const SCREEN_DARK: Color = Color("#060d18")
const SCREEN_LINE: Color = Color("#14304a")
const CYAN_DARK: Color = Color("#1c7496")
const CYAN: Color = Color("#40e0f0")
const CYAN_LIGHT: Color = Color("#befaff")
const AMBER_DARK: Color = Color("#96641e")
const AMBER: Color = Color("#ecb23c")
const AMBER_LIGHT: Color = Color("#ffe082")
const RED_DARK: Color = Color("#961432")
const RED: Color = Color("#ff3c5a")
const RED_LIGHT: Color = Color("#ffaabe")
const GREEN_DARK: Color = Color("#1c7440")
const GREEN: Color = Color("#3cb860")
const GREEN_LIGHT: Color = Color("#7ee89a")
# Placa de las letras de ámbar (como la cabecera de créditos de la barra derecha).
const PLATE: Color = Color("#221e19")
const PLATE_DARK: Color = Color("#120f0c")

static func rect(item: CanvasItem, r: Rect2i, color: Color) -> void:
	if r.size.x > 0 and r.size.y > 0:
		item.draw_rect(Rect2(r), color)

## Caja con contorno de 1 px y bisel de 1 px: luz arriba y a la izquierda, sombra abajo y a la derecha.
static func bevel_box(item: CanvasItem, r: Rect2i, body: Color, light: Color, shadow: Color,
		outline: Color = OUTLINE) -> void:
	rect(item, r, outline)
	var inner: Rect2i = r.grow(-1)
	rect(item, inner, body)
	rect(item, Rect2i(inner.position, Vector2i(inner.size.x, 1)), light)
	rect(item, Rect2i(inner.position, Vector2i(1, inner.size.y)), light)
	rect(item, Rect2i(inner.position.x + 1, inner.end.y - 1, inner.size.x - 1, 1), shadow)
	rect(item, Rect2i(inner.end.x - 1, inner.position.y + 1, 1, inner.size.y - 1), shadow)

## Caja de metal de objeto (rampa gris azulada).
static func metal_box(item: CanvasItem, r: Rect2i) -> void:
	bevel_box(item, r, METAL, METAL_LIGHT, METAL_DARK)

## Caja de metal oscuro de pared o mueble.
static func wall_box(item: CanvasItem, r: Rect2i) -> void:
	bevel_box(item, r, WALL_LIGHT, WALL_EDGE, WALL_DARK)

## Pantalla con contorno y líneas de barrido alternas, como la de las tablets de las barras.
static func screen(item: CanvasItem, r: Rect2i, light: Color = SCREEN, dark: Color = SCREEN_DARK) -> void:
	rect(item, r, OUTLINE)
	var inner: Rect2i = r.grow(-1)
	rect(item, inner, light)
	for y: int in range(inner.position.y + 1, inner.end.y, 2):
		rect(item, Rect2i(inner.position.x, y, inner.size.x, 1), dark)

## Tornillo de 3x3: cruz con luz arriba a la izquierda.
static func screw(item: CanvasItem, at: Vector2i) -> void:
	rect(item, Rect2i(at, Vector2i(3, 3)), METAL_DARK)
	rect(item, Rect2i(at + Vector2i(1, 0), Vector2i(1, 2)), METAL_LIGHT)
	rect(item, Rect2i(at + Vector2i(0, 1), Vector2i(2, 1)), METAL_LIGHT)

## Línea de 1 px (Bresenham).
static func line(item: CanvasItem, from: Vector2i, to: Vector2i, color: Color) -> void:
	var d: Vector2i = (to - from).abs()
	var step: Vector2i = Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var err: int = d.x - d.y
	var p: Vector2i = from
	while true:
		item.draw_rect(Rect2(p, Vector2.ONE), color)
		if p == to:
			break
		var e2: int = err * 2
		if e2 > -d.y:
			err -= d.y
			p.x += step.x
		if e2 < d.x:
			err += d.x
			p.y += step.y

## Media anchura de la fila `dy` de un círculo de radio `radius`.
static func _half_width(radius: int, dy: int) -> int:
	return int(sqrt(float(radius * radius - dy * dy)) + 0.5)

## Círculo relleno.
static func disc(item: CanvasItem, center: Vector2i, radius: int, color: Color) -> void:
	for dy: int in range(-radius, radius + 1):
		var half: int = _half_width(radius, dy)
		rect(item, Rect2i(center.x - half, center.y + dy, half * 2 + 1, 1), color)

## Anillo de 1 px: el borde del círculo relleno del mismo radio.
static func ring(item: CanvasItem, center: Vector2i, radius: int, color: Color) -> void:
	for dy: int in range(-radius, radius + 1):
		var half: int = _half_width(radius, dy)
		var inner: int = _half_width(radius - 1, dy) if absi(dy) < radius else -1
		# Lo que sobresale esta fila del círculo de radio menor, a cada lado.
		var width: int = maxi(half - inner, 1)
		rect(item, Rect2i(center.x - half, center.y + dy, width, 1), color)
		rect(item, Rect2i(center.x + half - width + 1, center.y + dy, width, 1), color)

## Texto en Monogram con la esquina de arriba a la izquierda en `at`.
static func text(item: CanvasItem, at: Vector2i, value: String, color: Color, size: int = TEXT_SIZE) -> void:
	var baseline: int = at.y + int(FONT.get_ascent(size))
	item.draw_string(FONT, Vector2(at.x, baseline), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

## Texto centrado en horizontal sobre `center_x`.
static func text_centered(item: CanvasItem, center_x: int, y: int, value: String, color: Color,
		size: int = TEXT_SIZE) -> void:
	@warning_ignore("integer_division")
	text(item, Vector2i(center_x - text_width(value, size) / 2, y), value, color, size)

static func text_width(value: String, size: int = TEXT_SIZE) -> int:
	return int(FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)

## Corchetes en L por fuera de las cuatro esquinas de `r`, como los del panel holograma.
static func brackets(item: CanvasItem, r: Rect2i, color: Color, length: int = 6, gap: int = 3) -> void:
	var outer: Rect2i = r.grow(gap + 1)
	var left: int = outer.position.x
	var top: int = outer.position.y
	var right: int = outer.end.x - 1
	var bottom: int = outer.end.y - 1
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		var x_dir: int = 1 if corner.x == left else -1
		var y_dir: int = 1 if corner.y == top else -1
		var h_start: int = corner.x if x_dir > 0 else corner.x - length + 1
		var v_start: int = corner.y if y_dir > 0 else corner.y - length + 1
		rect(item, Rect2i(h_start, corner.y, length, 1), color)
		rect(item, Rect2i(corner.x, v_start, 1, length), color)

## Extremos [izquierda, derecha) de la fila `row` (desde arriba) del trapecio `quad`
## (claves top, bot, tl, tr, bl, br de OfficeLayout).
static func quad_span(quad: Dictionary, row: int) -> Vector2:
	var height: int = quad.bot - quad.top
	var v: float = float(row) / maxf(height, 1.0)
	return Vector2(lerpf(quad.tl, quad.bl, v), lerpf(quad.tr, quad.br, v))

## Rectángulo `r` de una pantalla pintada de frente, de `source_size`, llevado al trapecio `quad`
## fila a fila (cada fila se estira a lo ancho del trapecio). `origin` desplaza el trapecio.
static func quad_rect(item: CanvasItem, quad: Dictionary, source_size: Vector2i, r: Rect2i, color: Color,
		origin: Vector2i = Vector2i.ZERO) -> void:
	var rows: int = quad.bot - quad.top + 1
	for y: int in range(maxi(r.position.y, 0), mini(r.end.y, source_size.y)):
		var row: int = int(float(y) * rows / source_size.y)
		var span: Vector2 = quad_span(quad, row)
		var scale: float = (span.y - span.x) / source_size.x
		var x0: int = roundi(span.x + r.position.x * scale)
		var x1: int = roundi(span.x + r.end.x * scale)
		rect(item, Rect2i(origin.x + x0, origin.y + quad.top + row, x1 - x0, 1), color)

## Tamaño de la pantalla de frente que se pinta en un trapecio: su ancho mayor y su alto.
static func quad_source_size(quad: Dictionary) -> Vector2i:
	return Vector2i(maxi(quad.tr - quad.tl, quad.br - quad.bl), quad.bot - quad.top + 1)

## Corchetes en L por fuera de las cuatro esquinas de un trapecio, para las piezas apoyadas en la
## consola inclinada. `corners`: arriba a la izquierda, arriba a la derecha, abajo a la derecha y abajo
## a la izquierda, con el borde derecho y el de abajo por fuera (como un Rect2i). Los brazos de arriba
## y de abajo van en horizontal; los de los lados siguen la inclinación de su lado.
static func quad_brackets(item: CanvasItem, corners: PackedVector2Array, color: Color, length: int = 8,
		gap: int = 3) -> void:
	var grow: int = gap + 1
	var height: float = maxf(corners[3].y - corners[0].y, 1.0)
	var rows: Array[int] = [roundi(corners[0].y) - grow, roundi(corners[3].y) - 1 + grow]
	for side: int in 2:
		# Línea de fuera del lado: x en cada fila, `grow` px por fuera del borde.
		var top: Vector2 = corners[0] if side == 0 else corners[1] - Vector2(1, 0)
		var bottom: Vector2 = corners[3] if side == 0 else corners[2] - Vector2(1, 0)
		var slope: float = (bottom.x - top.x) / height
		var x_dir: int = 1 if side == 0 else -1
		var offset: float = -grow if side == 0 else grow
		for end: int in 2:
			var y: int = rows[end]
			var y_dir: int = 1 if end == 0 else -1
			var x: int = roundi(top.x + (y - top.y) * slope + offset)
			rect(item, Rect2i(x if x_dir > 0 else x - length + 1, y, length, 1), color)
			for i: int in range(1, length):
				var arm_y: int = y + i * y_dir
				rect(item, Rect2i(roundi(top.x + (arm_y - top.y) * slope + offset), arm_y, 1, 1), color)

## bevel_box de una pantalla pintada de frente (`source_size`) llevada al trapecio `quad`.
static func quad_bevel_box(item: CanvasItem, quad: Dictionary, source_size: Vector2i, r: Rect2i, body: Color,
		light: Color, shadow: Color, origin: Vector2i = Vector2i.ZERO) -> void:
	quad_rect(item, quad, source_size, r, OUTLINE, origin)
	var inner: Rect2i = r.grow(-1)
	quad_rect(item, quad, source_size, inner, body, origin)
	quad_rect(item, quad, source_size, Rect2i(inner.position, Vector2i(inner.size.x, 1)), light, origin)
	quad_rect(item, quad, source_size, Rect2i(inner.position, Vector2i(1, inner.size.y)), light, origin)
	quad_rect(item, quad, source_size, Rect2i(inner.position.x + 1, inner.end.y - 1, inner.size.x - 1, 1), shadow, origin)
	quad_rect(item, quad, source_size, Rect2i(inner.end.x - 1, inner.position.y + 1, 1, inner.size.y - 1), shadow, origin)
