class_name OfficePaint
extends RefCounted

# Pinceles de la oficina del menú: rectángulos, cajas con bisel, pantallas, líneas, círculos, rayas
# de aviso y texto, todo en píxeles enteros y sin antialiasing. Los colores son los de art.md.

const FONT: Font = preload("res://assets/fonts/Monogram.ttf")
const TEXT_SIZE := 16
# Alto de una línea de Monogram a 16 px.
const TEXT_HEIGHT := 13

const OUTLINE := Color("#0c0e16")
# Rampa del metal gris azulado de torretas y tablets.
const METAL_DARK := Color("#343a4a")
const METAL := Color("#606a7c")
const METAL_LIGHT := Color("#96a2b6")
const METAL_SHINE := Color("#d2dceb")
# Metal oscuro de paredes y muebles, más apagado que el de los objetos para que estos destaquen.
const WALL_DARK := Color("#0e1118")
const WALL := Color("#151923")
const WALL_LIGHT := Color("#1d2230")
const WALL_EDGE := Color("#2a3142")
const SCREEN := Color("#08111f")
const SCREEN_DARK := Color("#060d18")
const SCREEN_LINE := Color("#14304a")
const CYAN_DARK := Color("#1c7496")
const CYAN := Color("#40e0f0")
const CYAN_LIGHT := Color("#befaff")
const AMBER_DARK := Color("#96641e")
const AMBER := Color("#ecb23c")
const AMBER_LIGHT := Color("#ffe082")
const RED_DARK := Color("#961432")
const RED := Color("#ff3c5a")
const RED_LIGHT := Color("#ffaabe")
const GREEN_DARK := Color("#1c7440")
const GREEN := Color("#3cb860")
const GREEN_LIGHT := Color("#7ee89a")
# Placa de las letras de ámbar (como la cabecera de créditos de la barra derecha).
const PLATE := Color("#221e19")
const PLATE_DARK := Color("#120f0c")

static func rect(item: CanvasItem, r: Rect2i, color: Color) -> void:
	if r.size.x > 0 and r.size.y > 0:
		item.draw_rect(Rect2(r), color)

## Caja con contorno de 1 px y bisel de 1 px: luz arriba y a la izquierda, sombra abajo y a la derecha.
static func bevel_box(item: CanvasItem, r: Rect2i, body: Color, light: Color, shadow: Color,
		outline: Color = OUTLINE) -> void:
	rect(item, r, outline)
	var inner := r.grow(-1)
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
	var inner := r.grow(-1)
	rect(item, inner, light)
	for y in range(inner.position.y + 1, inner.end.y, 2):
		rect(item, Rect2i(inner.position.x, y, inner.size.x, 1), dark)

## Tornillo de 3x3: cruz con luz arriba a la izquierda.
static func screw(item: CanvasItem, at: Vector2i) -> void:
	rect(item, Rect2i(at, Vector2i(3, 3)), METAL_DARK)
	rect(item, Rect2i(at + Vector2i(1, 0), Vector2i(1, 2)), METAL_LIGHT)
	rect(item, Rect2i(at + Vector2i(0, 1), Vector2i(2, 1)), METAL_LIGHT)

## Línea de 1 px (Bresenham).
static func line(item: CanvasItem, from: Vector2i, to: Vector2i, color: Color) -> void:
	var d := (to - from).abs()
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var err := d.x - d.y
	var p := from
	while true:
		item.draw_rect(Rect2(p, Vector2.ONE), color)
		if p == to:
			break
		var e2 := err * 2
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
	for dy in range(-radius, radius + 1):
		var half := _half_width(radius, dy)
		rect(item, Rect2i(center.x - half, center.y + dy, half * 2 + 1, 1), color)

## Anillo de 1 px: el borde del círculo relleno del mismo radio.
static func ring(item: CanvasItem, center: Vector2i, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		var half := _half_width(radius, dy)
		var inner := _half_width(radius - 1, dy) if absi(dy) < radius else -1
		# Lo que sobresale esta fila del círculo de radio menor, a cada lado.
		var width := maxi(half - inner, 1)
		rect(item, Rect2i(center.x - half, center.y + dy, width, 1), color)
		rect(item, Rect2i(center.x + half - width + 1, center.y + dy, width, 1), color)

## Rayas de aviso en diagonal (ámbar y negro), de `stripe` px de ancho.
static func hazard(item: CanvasItem, r: Rect2i, stripe: int = 4) -> void:
	# Fila a fila, en tramos del mismo color.
	for y in range(r.position.y, r.end.y):
		var x := r.position.x
		while x < r.end.x:
			var phase := posmod(x + y, stripe * 2)
			var band := phase < stripe
			var run := mini((stripe if band else stripe * 2) - phase, r.end.x - x)
			item.draw_rect(Rect2(x, y, run, 1), AMBER if band else OUTLINE)
			x += run

## Texto en Monogram con la esquina de arriba a la izquierda en `at`.
static func text(item: CanvasItem, at: Vector2i, value: String, color: Color, size: int = TEXT_SIZE) -> void:
	var baseline := at.y + int(FONT.get_ascent(size))
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
	var outer := r.grow(gap + 1)
	var left := outer.position.x
	var top := outer.position.y
	var right := outer.end.x - 1
	var bottom := outer.end.y - 1
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		var x_dir := 1 if corner.x == left else -1
		var y_dir := 1 if corner.y == top else -1
		var h_start := corner.x if x_dir > 0 else corner.x - length + 1
		var v_start := corner.y if y_dir > 0 else corner.y - length + 1
		rect(item, Rect2i(h_start, corner.y, length, 1), color)
		rect(item, Rect2i(corner.x, v_start, 1, length), color)
