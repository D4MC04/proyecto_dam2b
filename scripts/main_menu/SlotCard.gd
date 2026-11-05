extends Button
class_name SlotCard

# Tarjeta de una ranura de guardado en la pantalla de inicio. Es un botón sin estilos del tema:
# todo se pinta en _draw en píxeles enteros, con la forma de los botones (esquinas recortadas,
# ver ClippedBoxStyle) y las líneas de barrido del panel holograma (OverlayFrame). A la izquierda,
# una pestaña con el número de la ranura; a la derecha, el resumen de la partida o "NUEVA PARTIDA".

const CARD_SIZE: Vector2 = Vector2(432, 72)
const CLIP: int = 6
# Ancho de la pestaña del número, con su línea divisoria.
const TAB_WIDTH: int = 56
const TEXT_LEFT: int = TAB_WIDTH + 18
const TEXT_RIGHT: int = 22
# Fila de arriba de cada línea de texto.
const LINE_1_TOP: int = 15
const LINE_2_TOP: int = 43
const NUMBER_SIZE: int = 48
const LINE_1_SIZE: int = 24
const LINE_2_SIZE: int = 16
# Medidas de Monogram en píxeles de la fuente (1 = font_size / 16): alto de mayúsculas y
# números, ancho de un número (sin el hueco de 1 px que deja a la derecha) y su tamaño nativo.
const GLYPH_CAP: int = 7
const DIGIT_WIDTH: int = 5
const FONT_BASE_SIZE: int = 16
const ICON_GAP: int = 4

const BG: Color = Color("#081626")
const BG_ALPHA: float = 0.92
const ACCENT: Color = Color("#40e0f0")
const ACCENT_LIGHT: Color = Color("#befaff")
const BORDER: Color = Color("#1c7496")
const BORDER_EMPTY: Color = Color("#1c4a60")
const TEXT: Color = Color("#cce6ff")
const TEXT_DIM: Color = Color("#5a7a96")
const AMBER: Color = Color("#ecb23c")
# Mezcla del fondo con el acento según el estado (como los botones del tema, algo más suave).
const HOVER_MIX: float = 0.18
const PRESSED_MIX: float = 0.26
const TAB_MIX: float = 0.12
const TAB_HOVER_MIX: float = 0.32
const SCANLINE_DARKEN: float = 0.25
# Línea de barrido que recorre la tarjeta con el ratón encima.
const SWEEP_PERIOD: float = 1.4
const SWEEP_MIX: float = 0.12
const STAR_ICON: Texture2D = preload("res://assets/ui/slot_achievements.png")

## Ranura que representa (1..GameState.SLOT_COUNT).
var slot: int = 1
## Filas visibles de arriba abajo (0..1): la entrada animada la va descubriendo con una línea clara.
var reveal: float = 1.0:
	set(value):
		reveal = value
		queue_redraw()
## Opacidad de los textos (aparecen al acabar la entrada).
var content_alpha: float = 1.0:
	set(value):
		content_alpha = value
		queue_redraw()
## Destello al elegirla (0..1): la tarjeta se rellena con el tono claro del acento.
var flash: float = 0.0:
	set(value):
		flash = value
		queue_redraw()

var _summary: Dictionary = {}
var _sweep_time: float = 0.0

func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	focus_mode = Control.FOCUS_NONE
	# El fondo y el borde los pinta _draw; los estilos del tema no dibujan nada.
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(style_name, empty)
	mouse_entered.connect(func() -> void:
		_sweep_time = 0.0
		set_process(true))
	mouse_exited.connect(func() -> void:
		set_process(false)
		queue_redraw())
	set_process(false)

## Resumen de GameState.get_slot_summary (vacío = ranura libre).
func set_summary(summary: Dictionary) -> void:
	_summary = summary
	queue_redraw()

func has_save() -> bool:
	return not _summary.is_empty()

func _process(delta: float) -> void:
	_sweep_time += delta
	queue_redraw()

func _draw() -> void:
	var r: Rect2i = Rect2i(Vector2i.ZERO, Vector2i(size))
	var mode: BaseButton.DrawMode = get_draw_mode()
	var hovered: bool = mode == DRAW_HOVER or mode == DRAW_HOVER_PRESSED
	var pressed: bool = mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	var mix: float = PRESSED_MIX if pressed else (HOVER_MIX if hovered else 0.0)
	var bg: Color = Color(BG.lerp(ACCENT, mix).lerp(ACCENT_LIGHT, flash * 0.6), BG_ALPHA)
	var bg_dark: Color = Color(bg.darkened(SCANLINE_DARKEN), bg.a)
	var border: Color = ACCENT if hovered or pressed else (BORDER if has_save() else BORDER_EMPTY)
	border = border.lerp(ACCENT_LIGHT, flash)
	var tab: Color = Color(BG.lerp(border, TAB_HOVER_MIX if hovered else TAB_MIX), BG_ALPHA)
	var sweep_row: int = -1
	if hovered and reveal >= 1.0:
		sweep_row = int(fmod(_sweep_time, SWEEP_PERIOD) / SWEEP_PERIOD * r.size.y)
	# Se pinta fila a fila: borde en los extremos, pestaña, divisoria y fondo con barrido.
	var rows: int = int(ceilf(r.size.y * reveal))
	for y: int in rows:
		var span: Vector2i = ClippedBoxStyle.row_span(r, CLIP, y)
		if y == 0 or y == r.size.y - 1:
			draw_rect(Rect2(span.x, y, span.y - span.x, 1), border)
			continue
		var fill: Color = bg if y % 2 == 0 else bg_dark
		if y == sweep_row:
			fill = Color(fill.lerp(ACCENT_LIGHT, SWEEP_MIX), fill.a)
		draw_rect(Rect2(span.x + 1, y, TAB_WIDTH - span.x - 1, 1), tab)
		draw_rect(Rect2(TAB_WIDTH + 1, y, span.y - 1 - TAB_WIDTH - 1, 1), fill)
		draw_rect(Rect2(TAB_WIDTH, y, 1, 1), border)
		draw_rect(Rect2(span.x, y, 1, 1), border)
		draw_rect(Rect2(span.y - 1, y, 1, 1), border)
	if reveal < 1.0:
		# Línea de escaneo clara en el borde de lo descubierto (no antes de empezar).
		if reveal > 0.0 and rows < r.size.y:
			var span: Vector2i = ClippedBoxStyle.row_span(r, CLIP, rows)
			draw_rect(Rect2(span.x, rows, span.y - span.x, 1), ACCENT_LIGHT)
		return
	if content_alpha > 0.0:
		_draw_content(hovered)

func _draw_content(hovered: bool) -> void:
	var font: Font = get_theme_font(&"font")
	var number_color: Color = ACCENT_LIGHT if hovered else (ACCENT if has_save() else BORDER)
	# El número se centra por su tinta (no por la caja de la línea, que tiene hueco abajo y a la derecha).
	var font_px: float = float(NUMBER_SIZE) / FONT_BASE_SIZE
	var number_ink: Vector2 = Vector2(DIGIT_WIDTH, GLYPH_CAP) * font_px
	var baseline: Vector2 = Vector2(roundf((TAB_WIDTH - number_ink.x) / 2.0), roundf((size.y + number_ink.y) / 2.0))
	draw_string(font, baseline, str(slot), HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE,
			Color(number_color, content_alpha))
	var width: int = int(size.x) - TEXT_LEFT - TEXT_RIGHT
	if not has_save():
		_text(font, Vector2(TEXT_LEFT, LINE_1_TOP), tr("SLOT_NEW"), LINE_1_SIZE,
				ACCENT_LIGHT if hovered else ACCENT)
		_text(font, Vector2(TEXT_LEFT, LINE_2_TOP), tr("SLOT_EMPTY"), LINE_2_SIZE, TEXT_DIM)
		return
	var sector: int = mini(_summary.sector, GameData.levels.size())
	_text(font, Vector2(TEXT_LEFT, LINE_1_TOP), tr("SLOT_SECTOR") % sector, LINE_1_SIZE, TEXT)
	# Logros a la derecha de la primera línea: estrella y "X/12" en ámbar.
	var achievements: String = "%d/%d" % [_summary.achievements, _summary.achievements_total]
	var achievements_width: int = int(font.get_string_size(achievements, HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_1_SIZE).x)
	var right: int = TEXT_LEFT + width
	_text(font, Vector2(right - achievements_width, LINE_1_TOP), achievements, LINE_1_SIZE, AMBER)
	# Icono centrado en el alto de los números, no en el de la línea.
	var cap: float = GLYPH_CAP * float(LINE_1_SIZE) / FONT_BASE_SIZE
	var line_1_baseline: float = LINE_1_TOP + roundf(font.get_ascent(LINE_1_SIZE))
	var icon_top: float = roundf(line_1_baseline - (cap + STAR_ICON.get_height()) / 2.0)
	draw_texture(STAR_ICON, Vector2(right - achievements_width - ICON_GAP - STAR_ICON.get_width(), icon_top),
			Color(1, 1, 1, content_alpha))
	# Segunda línea: fecha del último guardado a la izquierda y tiempo jugado a la derecha.
	var saved: String = _format_date(_summary.saved_at)
	var played: String = _format_time(_summary.play_time)
	var x: int = _text(font, Vector2(TEXT_LEFT, LINE_2_TOP), tr("SLOT_SAVED") + " ", LINE_2_SIZE, TEXT_DIM)
	_text(font, Vector2(x, LINE_2_TOP), saved, LINE_2_SIZE, TEXT)
	var played_width: int = int(font.get_string_size(played, HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_2_SIZE).x)
	var played_label: String = tr("SLOT_PLAYED") + " "
	var label_width: int = int(font.get_string_size(played_label, HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_2_SIZE).x)
	_text(font, Vector2(right - played_width - label_width, LINE_2_TOP), played_label, LINE_2_SIZE, TEXT_DIM)
	_text(font, Vector2(right - played_width, LINE_2_TOP), played, LINE_2_SIZE, TEXT)

# Pinta `text` con su fila de arriba en `top_left` y devuelve la x donde acaba.
func _text(font: Font, top_left: Vector2, text: String, font_size: int, color: Color,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> int:
	var baseline: Vector2 = Vector2(top_left.x, top_left.y + roundf(font.get_ascent(font_size)))
	draw_string(font, baseline, text, alignment, width, font_size, Color(color, color.a * content_alpha))
	return int(top_left.x + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

# Fecha y hora locales, "03/11/2026 18:42"; "-" si la ranura no la guardó.
static func _format_date(unix_time: int) -> String:
	if unix_time <= 0:
		return "-"
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return "%02d/%02d/%d %02d:%02d" % [date.day, date.month, date.year, date.hour, date.minute]

@warning_ignore("integer_division")
static func _format_time(seconds_played: float) -> String:
	var seconds: int = int(seconds_played)
	return "%dh %02dm" % [seconds / 3600, seconds % 3600 / 60]
