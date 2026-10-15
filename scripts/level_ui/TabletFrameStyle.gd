@tool
extends StyleBox
class_name TabletFrameStyle
## Estilo de las dos barras laterales: una tablet física con marco de metal (bisel, tornillos y
## rejilla de altavoz abajo) y dentro una pantalla oscura con líneas de barrido y corchetes cian.
## Se dibuja por código en píxeles enteros, sin antialiasing.

const OUTLINE_COLOR := Color("#0c0e16")
const METAL_LIGHT_COLOR := Color("#96a2b6")
const METAL_COLOR := Color("#606a7c")
const METAL_SHADOW_COLOR := Color("#343a4a")
const SCREEN_COLOR := Color("#08111f")
const SCREEN_ALT_COLOR := Color("#060d18")
const BRACKET_COLOR := Color("#40e0f0")

# Grosor del marco de fuera a dentro: contorno, metal y contorno interior.
const FRAME_SIDE := 6
const FRAME_TOP := 8
const FRAME_BOTTOM := 18
# Hueco entre el borde de la pantalla y el contenido.
const SCREEN_PADDING := 3
# Largo de cada brazo de los corchetes de la pantalla.
const BRACKET_LENGTH := 4
# Tornillo de 3x3 a 2 px del borde exterior (justo dentro del contorno y del bisel).
const SCREW_INSET := 2
# Rejilla de altavoz: dos filas de puntos cada 2 px, centradas en la franja de abajo.
const GRILLE_WIDTH := 24
const GRILLE_STEP := 2
const GRILLE_ROWS := 2

func _init() -> void:
	content_margin_left = FRAME_SIDE + SCREEN_PADDING
	content_margin_right = FRAME_SIDE + SCREEN_PADDING
	content_margin_top = FRAME_TOP + SCREEN_PADDING
	content_margin_bottom = FRAME_BOTTOM + SCREEN_PADDING

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var r := Rect2i(rect)
	_draw_frame(to_canvas_item, r)
	var screen := Rect2i(r.position.x + FRAME_SIDE, r.position.y + FRAME_TOP,
			r.size.x - FRAME_SIDE * 2, r.size.y - FRAME_TOP - FRAME_BOTTOM)
	_draw_screen(to_canvas_item, screen)

@warning_ignore("integer_division")
func _draw_frame(ci: RID, r: Rect2i) -> void:
	# Contorno exterior y, dentro, el metal.
	_fill(ci, r, OUTLINE_COLOR)
	var metal := r.grow(-1)
	_fill(ci, metal, METAL_COLOR)
	# Bisel: luz arriba y a la izquierda, sombra abajo y a la derecha.
	_fill(ci, Rect2i(metal.position, Vector2i(metal.size.x, 1)), METAL_LIGHT_COLOR)
	_fill(ci, Rect2i(metal.position, Vector2i(1, metal.size.y)), METAL_LIGHT_COLOR)
	_fill(ci, Rect2i(metal.position.x, metal.end.y - 1, metal.size.x, 1), METAL_SHADOW_COLOR)
	_fill(ci, Rect2i(metal.end.x - 1, metal.position.y, 1, metal.size.y), METAL_SHADOW_COLOR)
	# Contorno interior que separa el metal de la pantalla (la pantalla lo tapa por dentro).
	_fill(ci, Rect2i(r.position.x + FRAME_SIDE - 1, r.position.y + FRAME_TOP - 1,
			r.size.x - FRAME_SIDE * 2 + 2, r.size.y - FRAME_TOP - FRAME_BOTTOM + 2), OUTLINE_COLOR)

	var left := r.position.x + SCREW_INSET
	var right := r.end.x - SCREW_INSET - 3
	var top := r.position.y + SCREW_INSET
	var bottom := r.end.y - SCREW_INSET - 3
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		_draw_screw(ci, corner)

	# Rejilla centrada en la franja de metal de abajo (entre el contorno interior y el bisel).
	var band_top := r.end.y - FRAME_BOTTOM + 1
	var band_height := FRAME_BOTTOM - 3
	var grille_x := r.position.x + (r.size.x - GRILLE_WIDTH) / 2
	var grille_y := band_top + (band_height - (GRILLE_ROWS - 1) * GRILLE_STEP - 1) / 2
	for row in GRILLE_ROWS:
		for x in range(0, GRILLE_WIDTH, GRILLE_STEP):
			_fill(ci, Rect2i(grille_x + x, grille_y + row * GRILLE_STEP, 1, 1), METAL_SHADOW_COLOR)

# Tornillo redondo de 3x3: cabeza en cruz con el centro hundido y luz arriba a la izquierda.
func _draw_screw(ci: RID, origin: Vector2i) -> void:
	_fill(ci, Rect2i(origin + Vector2i(1, 0), Vector2i.ONE), METAL_LIGHT_COLOR)
	_fill(ci, Rect2i(origin + Vector2i(0, 1), Vector2i.ONE), METAL_LIGHT_COLOR)
	_fill(ci, Rect2i(origin + Vector2i(1, 1), Vector2i.ONE), METAL_SHADOW_COLOR)
	_fill(ci, Rect2i(origin + Vector2i(2, 1), Vector2i.ONE), METAL_SHADOW_COLOR)
	_fill(ci, Rect2i(origin + Vector2i(1, 2), Vector2i.ONE), METAL_SHADOW_COLOR)

func _draw_screen(ci: RID, screen: Rect2i) -> void:
	# Líneas de barrido: fondo en un tono y una fila de cada dos en el otro.
	_fill(ci, screen, SCREEN_COLOR)
	for y in range(1, screen.size.y, 2):
		_fill(ci, Rect2i(screen.position.x, screen.position.y + y, screen.size.x, 1), SCREEN_ALT_COLOR)
	# Corchetes en L en las cuatro esquinas, con los brazos hacia dentro.
	var right := screen.end.x - 1
	var bottom := screen.end.y - 1
	for corner: Vector2i in [screen.position, Vector2i(right, screen.position.y),
			Vector2i(screen.position.x, bottom), Vector2i(right, bottom)]:
		var x_start := corner.x if corner.x == screen.position.x else corner.x - BRACKET_LENGTH + 1
		var y_start := corner.y if corner.y == screen.position.y else corner.y - BRACKET_LENGTH + 1
		_fill(ci, Rect2i(x_start, corner.y, BRACKET_LENGTH, 1), BRACKET_COLOR)
		_fill(ci, Rect2i(corner.x, y_start, 1, BRACKET_LENGTH), BRACKET_COLOR)

func _fill(ci: RID, r: Rect2i, color: Color) -> void:
	RenderingServer.canvas_item_add_rect(ci, Rect2(r), color)
