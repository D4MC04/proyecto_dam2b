class_name OfficeRoom
extends Control

# Paredes, suelo y muebles de una vista de la oficina del comandante (960x540), pintados en
# píxeles enteros. La vista central es el ventanal (el cristal se deja transparente para que se
# vea el espacio de detrás) con el escritorio delante; las laterales son pared de paneles de metal
# con suelo de placas. Lo que se pulsa (radar, tablet, mural...) son OfficeObject aparte, encima.

enum View { LEFT, CENTER, RIGHT }

@export var view := View.CENTER:
	set(value):
		view = value
		queue_redraw()

const WIDTH := 960
const HEIGHT := 540
const CEILING_HEIGHT := 14
# Ventanal: alto del marco de arriba, ancho de los pilares, parteluces y alféizar.
const WINDOW_TOP := 14
const WINDOW_FRAME := 8
const PILLAR_WIDTH := 26
const MULLION_X: Array[int] = [316, 636]
const MULLION_WIDTH := 8
const SILL_TOP := 380
const SILL_HEIGHT := 12
# Reflejos del cristal: franjas diagonales casi transparentes.
const REFLECTION := Color(0.75, 0.95, 1.0, 0.05)
# Escritorio: superficie en trapecio (atrás más estrecha) y frente.
const DESK_TOP := 400
const DESK_FRONT := 440
const DESK_BACK_X := Vector2i(64, 896)
const DESK_FRONT_X := Vector2i(40, 920)
const DESK_SURFACE := Color("#1d2230")
const DESK_SURFACE_LIGHT := Color("#262c3c")
# Paredes laterales: bandas de arriba y abajo y suelo.
const WALL_TRIM_TOP := 40
const BASEBOARD_TOP := 440
const FLOOR_TOP := 452
const PANEL_WIDTH := 160

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Las juntas del suelo salen de la vista; sin recorte se pintarían sobre la de al lado.
	clip_contents = true

func _draw() -> void:
	match view:
		View.CENTER:
			_draw_window()
			_draw_desk()
		_:
			_draw_side_wall()
	_draw_ceiling()

# Viga del techo con luces cian cada 80 px.
func _draw_ceiling() -> void:
	OfficePaint.rect(self, Rect2i(0, 0, WIDTH, CEILING_HEIGHT), OfficePaint.WALL_DARK)
	OfficePaint.rect(self, Rect2i(0, CEILING_HEIGHT - 2, WIDTH, 1), OfficePaint.WALL_EDGE)
	OfficePaint.rect(self, Rect2i(0, CEILING_HEIGHT - 1, WIDTH, 1), OfficePaint.OUTLINE)
	for x in range(40, WIDTH, 80):
		OfficePaint.rect(self, Rect2i(x, 5, 12, 3), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(x + 1, 6, 10, 1), OfficePaint.CYAN_DARK)

# --- Vista central -------------------------------------------------------------------------

func _draw_window() -> void:
	_draw_reflections()
	# Pared de debajo del alféizar.
	OfficePaint.rect(self, Rect2i(0, SILL_TOP, WIDTH, HEIGHT - SILL_TOP), OfficePaint.WALL_DARK)
	OfficePaint.wall_box(self, Rect2i(0, WINDOW_TOP, WIDTH, WINDOW_FRAME))
	for x in MULLION_X:
		OfficePaint.wall_box(self, Rect2i(x, WINDOW_TOP + WINDOW_FRAME - 1, MULLION_WIDTH, SILL_TOP - WINDOW_TOP - WINDOW_FRAME + 2))
	for x: int in [0, WIDTH - PILLAR_WIDTH]:
		_draw_pillar(x)
	OfficePaint.wall_box(self, Rect2i(0, SILL_TOP, WIDTH, SILL_HEIGHT))
	OfficePaint.rect(self, Rect2i(1, SILL_TOP + 1, WIDTH - 2, 1), OfficePaint.METAL_DARK)

# Dos franjas diagonales en cada hoja del ventanal, una ancha y una fina.
func _draw_reflections() -> void:
	var panes: Array[Vector2i] = [
		Vector2i(PILLAR_WIDTH, MULLION_X[0]),
		Vector2i(MULLION_X[0] + MULLION_WIDTH, MULLION_X[1]),
		Vector2i(MULLION_X[1] + MULLION_WIDTH, WIDTH - PILLAR_WIDTH),
	]
	var top := WINDOW_TOP + WINDOW_FRAME
	for pane in panes:
		for band: Vector2i in [Vector2i(150, 14), Vector2i(176, 4)]:
			for y in range(top, SILL_TOP):
				var x := pane.x + band.x - (y - top)
				var left := maxi(x, pane.x)
				var right := mini(x + band.y, pane.y)
				if right > left:
					OfficePaint.rect(self, Rect2i(left, y, right - left, 1), REFLECTION)

# Pilar del ventanal con una franja de luz y remaches.
func _draw_pillar(x: int) -> void:
	var r := Rect2i(x, WINDOW_TOP, PILLAR_WIDTH, SILL_TOP - WINDOW_TOP)
	OfficePaint.wall_box(self, r)
	var inner_x := x + PILLAR_WIDTH - 6 if x == 0 else x + 4
	OfficePaint.rect(self, Rect2i(inner_x, WINDOW_TOP + 20, 2, SILL_TOP - WINDOW_TOP - 40), OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(inner_x, WINDOW_TOP + 22, 1, SILL_TOP - WINDOW_TOP - 44), OfficePaint.CYAN_DARK)
	for y in range(WINDOW_TOP + 14, SILL_TOP - 10, 60):
		OfficePaint.screw(self, Vector2i(x + 9, y))

func _draw_desk() -> void:
	# Superficie: cada fila un poco más ancha hacia delante.
	for y in range(DESK_TOP, DESK_FRONT):
		var t := float(y - DESK_TOP) / float(DESK_FRONT - DESK_TOP)
		var left := int(lerpf(DESK_BACK_X.x, DESK_FRONT_X.x, t))
		var right := int(lerpf(DESK_BACK_X.y, DESK_FRONT_X.y, t))
		var color := DESK_SURFACE_LIGHT if y == DESK_TOP + 1 else DESK_SURFACE
		OfficePaint.rect(self, Rect2i(left - 1, y, right - left + 2, 1), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(left, y, right - left, 1), color)
	OfficePaint.rect(self, Rect2i(DESK_BACK_X.x, DESK_TOP, DESK_BACK_X.y - DESK_BACK_X.x, 1), OfficePaint.OUTLINE)
	# Canto delantero con la tira de luz cian.
	var front := Rect2i(DESK_FRONT_X.x - 1, DESK_FRONT, DESK_FRONT_X.y - DESK_FRONT_X.x + 2, HEIGHT - DESK_FRONT)
	OfficePaint.rect(self, Rect2i(front.position.x, DESK_FRONT, front.size.x, 1), OfficePaint.METAL_DARK)
	OfficePaint.rect(self, Rect2i(front.position.x, DESK_FRONT + 1, front.size.x, 1), OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(front.position.x, DESK_FRONT + 2, front.size.x, 2), OfficePaint.CYAN_DARK)
	for x in range(front.position.x + 20, front.end.x - 20, 60):
		OfficePaint.rect(self, Rect2i(x, DESK_FRONT + 2, 24, 1), OfficePaint.CYAN)
	OfficePaint.wall_box(self, Rect2i(front.position.x, DESK_FRONT + 4, front.size.x, HEIGHT - DESK_FRONT - 4 + 1))
	# Paneles del frente, cajones y rejilla central.
	for x: int in [260, 700]:
		OfficePaint.rect(self, Rect2i(x, DESK_FRONT + 6, 1, HEIGHT - DESK_FRONT - 6), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(x + 1, DESK_FRONT + 6, 1, HEIGHT - DESK_FRONT - 6), OfficePaint.WALL_EDGE)
	for x: int in [130, 790]:
		OfficePaint.bevel_box(self, Rect2i(x, 470, 40, 5), OfficePaint.METAL_DARK, OfficePaint.METAL, OfficePaint.OUTLINE)
		OfficePaint.bevel_box(self, Rect2i(x, 506, 40, 5), OfficePaint.METAL_DARK, OfficePaint.METAL, OfficePaint.OUTLINE)
	var vent := Rect2i(400, 462, 160, 54)
	OfficePaint.bevel_box(self, vent, OfficePaint.WALL_DARK, OfficePaint.OUTLINE, OfficePaint.WALL_EDGE)
	for y in range(vent.position.y + 6, vent.end.y - 4, 6):
		OfficePaint.rect(self, Rect2i(vent.position.x + 8, y, vent.size.x - 16, 2), OfficePaint.OUTLINE)
	_draw_keyboard()
	_draw_nameplate()
	_draw_mug()

# Teclado delante del radar.
func _draw_keyboard() -> void:
	var r := Rect2i(424, 429, 112, 9)
	OfficePaint.bevel_box(self, r, OfficePaint.METAL_DARK, OfficePaint.METAL, OfficePaint.OUTLINE)
	for row in 2:
		for i in 13:
			OfficePaint.rect(self, Rect2i(r.position.x + 4 + i * 8, r.position.y + 2 + row * 3, 6, 2), OfficePaint.WALL_EDGE)

# Placa del comandante en ámbar, como la cabecera de créditos.
func _draw_nameplate() -> void:
	var value := "CMDTE."
	var r := Rect2i(140, 412, OfficePaint.text_width(value) + 16, 19)
	OfficePaint.rect(self, Rect2i(r.position.x + 4, r.end.y, r.size.x - 8, 2), OfficePaint.OUTLINE)
	OfficePaint.bevel_box(self, r, OfficePaint.PLATE, OfficePaint.AMBER_DARK, OfficePaint.PLATE_DARK)
	OfficePaint.text(self, r.position + Vector2i(8, 3), value, OfficePaint.AMBER)

# Taza de metal claro con una franja cian.
func _draw_mug() -> void:
	var r := Rect2i(266, 410, 14, 18)
	OfficePaint.rect(self, Rect2i(r.end.x - 1, r.position.y + 4, 6, 9), OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(r.end.x, r.position.y + 6, 3, 5), DESK_SURFACE)
	OfficePaint.bevel_box(self, r, OfficePaint.METAL_LIGHT, OfficePaint.METAL_SHINE, OfficePaint.METAL)
	OfficePaint.rect(self, Rect2i(r.position.x + 1, r.position.y + 7, r.size.x - 2, 3), OfficePaint.CYAN_DARK)
	OfficePaint.rect(self, Rect2i(r.position.x + 2, r.position.y + 1, r.size.x - 4, 2), Color("#2b1d14"))

# --- Vistas laterales ----------------------------------------------------------------------

func _draw_side_wall() -> void:
	OfficePaint.rect(self, Rect2i(0, 0, WIDTH, FLOOR_TOP), OfficePaint.WALL)
	# Paneles: juntas verticales y remaches en las esquinas.
	for x in range(0, WIDTH + 1, PANEL_WIDTH):
		OfficePaint.rect(self, Rect2i(x - 1, CEILING_HEIGHT, 1, BASEBOARD_TOP - CEILING_HEIGHT), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(x, CEILING_HEIGHT, 1, BASEBOARD_TOP - CEILING_HEIGHT), OfficePaint.WALL_LIGHT)
		for y: int in [WALL_TRIM_TOP + 14, BASEBOARD_TOP - 14]:
			OfficePaint.rect(self, Rect2i(x + 6, y, 2, 2), OfficePaint.WALL_EDGE)
			OfficePaint.rect(self, Rect2i(x - 8, y, 2, 2), OfficePaint.WALL_EDGE)
	# Franja horizontal en el centro de cada panel.
	OfficePaint.rect(self, Rect2i(0, 250, WIDTH, 1), OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(0, 251, WIDTH, 1), OfficePaint.WALL_LIGHT)
	OfficePaint.wall_box(self, Rect2i(-1, WALL_TRIM_TOP, WIDTH + 2, 8))
	_draw_pipes()
	# Zócalo con luz cian a tramos.
	OfficePaint.wall_box(self, Rect2i(-1, BASEBOARD_TOP, WIDTH + 2, FLOOR_TOP - BASEBOARD_TOP))
	for x in range(20, WIDTH, 80):
		OfficePaint.rect(self, Rect2i(x, BASEBOARD_TOP + 5, 40, 2), OfficePaint.CYAN_DARK)
	_draw_floor()

# Dos tuberías bajo el techo con abrazaderas.
func _draw_pipes() -> void:
	for pipe: Vector2i in [Vector2i(18, 8), Vector2i(28, 6)]:
		OfficePaint.bevel_box(self, Rect2i(-1, pipe.x, WIDTH + 2, pipe.y), OfficePaint.METAL_DARK, OfficePaint.METAL, OfficePaint.WALL_DARK)
	for x in range(70, WIDTH, 140):
		OfficePaint.bevel_box(self, Rect2i(x, 16, 6, 20), OfficePaint.METAL, OfficePaint.METAL_LIGHT, OfficePaint.METAL_DARK)

# Suelo de placas: líneas horizontales cada vez más separadas y juntas que se abren hacia delante.
func _draw_floor() -> void:
	OfficePaint.rect(self, Rect2i(0, FLOOR_TOP, WIDTH, HEIGHT - FLOOR_TOP), OfficePaint.WALL_DARK)
	for y: int in [458, 468, 484, 508]:
		OfficePaint.rect(self, Rect2i(0, y, WIDTH, 1), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(0, y + 1, WIDTH, 1), OfficePaint.WALL)
	@warning_ignore("integer_division")
	var center := WIDTH / 2
	for x in range(-480, WIDTH + 480, 96):
		var bottom_x := center + int((x - center) * 1.8)
		OfficePaint.line(self, Vector2i(x, FLOOR_TOP), Vector2i(bottom_x, HEIGHT - 1), OfficePaint.OUTLINE)
