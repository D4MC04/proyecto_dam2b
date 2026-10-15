extends PanelContainer
class_name OverlayFrame

# Panel holograma de las pantallas superpuestas (pausa, derrota y victoria) y de la etiqueta plegada
# de la pausa. Todo sale del color de acento y se pinta en _draw en píxeles enteros, de fuera hacia
# dentro: brillo de 1 px, borde exterior, 1 px de hueco, borde interior y fondo translúcido con
# líneas de barrido. Las esquinas de arriba a la izquierda y de abajo a la derecha van recortadas
# en diagonal (como los botones, ver ClippedBoxStyle). Con `decorated`, además, una regla de marcas
# arriba por dentro y corchetes en L por fuera de las cuatro esquinas.

const BG_COLOR := Color("#0a0f1a")
# Fondo: el oscuro mezclado con el acento y translúcido, para que se intuya el mapa detrás.
const BG_ACCENT_MIX := 0.15
const BG_ALPHA := 0.85
# Las líneas de barrido alternan el fondo con una versión algo más oscura.
const SCANLINE_DARKEN := 0.25
# Mezclas del acento con el fondo oscuro para cada parte.
const GLOW_MIX := 0.25
const INNER_BORDER_MIX := 0.35
const RULER_MIX := 0.5
# Grosor del marco: brillo, borde exterior, hueco y borde interior.
const FRAME_THICKNESS := 4
# Regla de marcas: distancia desde el borde de arriba y desde los lados.
const RULER_TOP := 7
const RULER_SIDE := 8
# Corchetes de fuera: largo de cada brazo y hueco hasta el panel.
const BRACKET_LENGTH := 6
const BRACKET_GAP := 3
## Lo que sobresalen los corchetes por fuera del panel.
const OUTSIDE_MARGIN := BRACKET_GAP + 1

@export var accent_color: Color = Color("#40e0f0"):
	set(value):
		accent_color = value
		queue_redraw()
## Tono claro del acento, para los corchetes de fuera.
@export var accent_light_color: Color = Color("#befaff"):
	set(value):
		accent_light_color = value
		queue_redraw()
## Píxeles recortados en diagonal en las esquinas del borde exterior.
@export_range(1, 12) var corner_clip := 6:
	set(value):
		corner_clip = value
		queue_redraw()
## Con la regla de arriba y los corchetes de fuera (la etiqueta plegada no los lleva).
@export var decorated := true:
	set(value):
		decorated = value
		queue_redraw()

func _ready() -> void:
	# El marco lo pinta _draw; el estilo solo deja el hueco del marco alrededor del contenido.
	var style := StyleBoxEmpty.new()
	style.set_content_margin_all(FRAME_THICKNESS)
	add_theme_stylebox_override("panel", style)

## Color del fondo del panel con este acento (sin las líneas de barrido).
static func background_color(accent: Color) -> Color:
	return Color(BG_COLOR.lerp(accent, BG_ACCENT_MIX), BG_ALPHA)

func _draw() -> void:
	var ci := get_canvas_item()
	var r := Rect2i(Vector2i.ZERO, Vector2i(size))
	var bg := background_color(accent_color)
	# Cada anillo está 1 px más adentro y con 1 px menos de recorte, así las diagonales se tocan.
	var outer_clip := corner_clip + 1
	ClippedBoxStyle.draw_outline(ci, r, outer_clip, BG_COLOR.lerp(accent_color, GLOW_MIX))
	ClippedBoxStyle.draw_outline(ci, r.grow(-1), outer_clip - 1, accent_color)
	ClippedBoxStyle.draw_outline(ci, r.grow(-2), maxi(outer_clip - 2, 0), bg)
	ClippedBoxStyle.draw_outline(ci, r.grow(-3), maxi(outer_clip - 3, 0), BG_COLOR.lerp(accent_color, INNER_BORDER_MIX))
	_draw_scanlines(r.grow(-FRAME_THICKNESS), maxi(outer_clip - FRAME_THICKNESS, 0), bg)
	if decorated:
		ScreenHeader.draw_ruler(self, Vector2i(RULER_SIDE, RULER_TOP), r.size.x - RULER_SIDE * 2,
				BG_COLOR.lerp(accent_color, RULER_MIX))
		_draw_brackets(r)

# Fondo de dentro con líneas de barrido: filas alternas en el fondo y en su versión más oscura.
func _draw_scanlines(r: Rect2i, clip_px: int, bg: Color) -> void:
	var dark := Color(bg.darkened(SCANLINE_DARKEN), bg.a)
	for y in range(r.position.y, r.end.y):
		var span := ClippedBoxStyle.row_span(r, clip_px, y)
		var color := bg if (y - r.position.y) % 2 == 0 else dark
		draw_rect(Rect2(span.x, y, span.y - span.x, 1), color)

# Corchetes en L por fuera de las cuatro esquinas, con los brazos a lo largo de los bordes.
func _draw_brackets(r: Rect2i) -> void:
	var left := r.position.x - 1 - BRACKET_GAP
	var top := r.position.y - 1 - BRACKET_GAP
	var right := r.end.x + BRACKET_GAP
	var bottom := r.end.y + BRACKET_GAP
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		var x_start := corner.x if corner.x == left else corner.x - BRACKET_LENGTH + 1
		var y_start := corner.y if corner.y == top else corner.y - BRACKET_LENGTH + 1
		draw_rect(Rect2(x_start, corner.y, BRACKET_LENGTH, 1), accent_light_color)
		draw_rect(Rect2(corner.x, y_start, 1, BRACKET_LENGTH), accent_light_color)
