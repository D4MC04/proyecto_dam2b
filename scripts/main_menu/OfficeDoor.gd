class_name OfficeDoor
extends OfficeObject

# Puerta automática de la oficina: sale del juego. Dos hojas de metal que encajan por un borde
# dentado y se abren deslizando hacia los lados, con un cartel de SALIDA encima y rayas de aviso
# en el marco. Con el ratón encima se entreabre (el sensor la detecta); al pulsarla se abre del
# todo y emite `opened`.

signal opened

const SIGN := Rect2i(52, 0, 96, 19)
const FRAME := Rect2i(0, 24, 200, 306)
const HAZARD_WIDTH := 8
# Hueco de la puerta, dentro del marco y las rayas.
const OPENING := Rect2i(18, 42, 164, 288)
const LEAF_WIDTH := 82
# Dientes del borde: alto de cada diente y lo que entra en la otra hoja.
const TOOTH_HEIGHT := 12
const TOOTH_DEPTH := 4
const GROOVE_STEP := 36
# Apertura (0 cerrada, 1 abierta): al pasar el ratón y velocidad (por segundo).
const PEEK_OPEN := 0.1
const OPEN_SPEED := 2.4
const CORRIDOR_FAR := Color("#1c5d6d")
const CORRIDOR := Color("#0e2230")
const CORRIDOR_FLOOR := Color("#14304a")

var _open := 0.0
var _leaving := false

func _process(delta: float) -> void:
	var target := 1.0 if _leaving else (PEEK_OPEN if hovered else 0.0)
	_open = move_toward(_open, target, delta * OPEN_SPEED)
	if _leaving and _open >= 1.0:
		_leaving = false
		opened.emit()
	super(delta)

## Abre la puerta del todo; al acabar emite `opened`.
func open_fully() -> void:
	_leaving = true

func _draw_object() -> void:
	OfficePaint.wall_box(self, FRAME)
	var hazard := OPENING.grow_individual(HAZARD_WIDTH, HAZARD_WIDTH, HAZARD_WIDTH, 0)
	OfficePaint.rect(self, hazard.grow_individual(1, 1, 1, 0), OfficePaint.OUTLINE)
	OfficePaint.hazard(self, hazard)
	_draw_corridor()
	var slide := int(round(_open * LEAF_WIDTH))
	_draw_leaf(OPENING.position.x - slide, true)
	_draw_leaf(OPENING.position.x + LEAF_WIDTH + slide, false)
	OfficePaint.rect(self, Rect2i(OPENING.position.x - 1, OPENING.position.y - 1, OPENING.size.x + 2, 1), OfficePaint.OUTLINE)
	# Umbral.
	OfficePaint.metal_box(self, Rect2i(OPENING.position.x - 6, OPENING.end.y - 3, OPENING.size.x + 12, 4))
	_draw_sign()

# Pasillo iluminado que se ve al abrir.
func _draw_corridor() -> void:
	OfficePaint.rect(self, OPENING, CORRIDOR)
	OfficePaint.rect(self, Rect2i(OPENING.position.x, 250, OPENING.size.x, OPENING.end.y - 250), CORRIDOR_FLOOR)
	OfficePaint.rect(self, Rect2i(62, 96, 76, 154), CORRIDOR_FAR)
	OfficePaint.rect(self, Rect2i(62, 96, 76, 2), OfficePaint.CYAN_LIGHT)
	for i in 4:
		OfficePaint.line(self, Vector2i(62 - i * 12, 250 + i * 18), Vector2i(138 + i * 12, 250 + i * 18), OfficePaint.CYAN_DARK)

# Una hoja: `origin_x` es su borde izquierdo con la puerta cerrada en su sitio. Solo se pinta lo
# que queda dentro del hueco.
func _draw_leaf(origin_x: int, left: bool) -> void:
	var top := OPENING.position.y
	var bottom := OPENING.end.y - 3
	# Cuerpo, con los dientes del borde hacia el centro.
	for y in range(top, bottom, TOOTH_HEIGHT):
		var height := mini(TOOTH_HEIGHT, bottom - y)
		var tooth_out := (int(float(y - top) / TOOTH_HEIGHT) % 2 == 0) == left
		var width := LEAF_WIDTH + (TOOTH_DEPTH if tooth_out else -TOOTH_DEPTH)
		var x := origin_x if left else origin_x + LEAF_WIDTH - width
		_clip_rect(Rect2i(x, y, width, height), OfficePaint.METAL_DARK)
		# Luz arriba de cada diente y contorno del borde.
		_clip_rect(Rect2i(x, y, width, 1), OfficePaint.METAL)
		_clip_rect(Rect2i(x + width - 1 if left else x, y, 1, height), OfficePaint.OUTLINE)
	# Ranuras horizontales.
	for y in range(top + GROOVE_STEP, bottom - 10, GROOVE_STEP):
		_clip_rect(Rect2i(origin_x + 6, y, LEAF_WIDTH - 12, 1), OfficePaint.OUTLINE)
		_clip_rect(Rect2i(origin_x + 6, y + 1, LEAF_WIDTH - 12, 1), OfficePaint.METAL)
	# Ventanuco y franja de luz junto al borde.
	var window := Rect2i(origin_x + 22, top + 46, 38, 8)
	_clip_rect(window, OfficePaint.OUTLINE)
	_clip_rect(window.grow(-1), OfficePaint.SCREEN)
	_clip_rect(Rect2i(window.position.x + 2, window.position.y + 2, 10, 1), OfficePaint.CYAN_DARK)
	var strip_x := origin_x + LEAF_WIDTH - 12 if left else origin_x + 10
	var strip_color := OfficePaint.CYAN if hovered or _open > 0.0 else OfficePaint.CYAN_DARK
	_clip_rect(Rect2i(strip_x, top + 70, 2, 150), strip_color)
	# Borde exterior de la hoja.
	_clip_rect(Rect2i(origin_x if left else origin_x + LEAF_WIDTH - 1, top, 1, bottom - top), OfficePaint.OUTLINE)

func _clip_rect(r: Rect2i, color: Color) -> void:
	OfficePaint.rect(self, r.intersection(OPENING), color)

# Cartel luminoso de salida, en verde.
func _draw_sign() -> void:
	OfficePaint.bevel_box(self, SIGN, Color("#0b1f14"), OfficePaint.GREEN_DARK, OfficePaint.OUTLINE)
	var color := OfficePaint.GREEN_LIGHT if hovered or _open > 0.0 else OfficePaint.GREEN
	@warning_ignore("integer_division")
	var center_x := SIGN.position.x + SIGN.size.x / 2
	OfficePaint.text_centered(self, center_x, 3, "SALIDA", color)
	# Soporte hasta el marco.
	OfficePaint.rect(self, Rect2i(center_x - 2, SIGN.end.y, 4, FRAME.position.y - SIGN.end.y), OfficePaint.METAL_DARK)
