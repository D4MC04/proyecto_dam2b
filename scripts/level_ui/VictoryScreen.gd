extends OverlayScreen
class_name VictoryScreen

# Pantalla de victoria ("sector asegurado"): el marco entra deslizando desde arriba mientras se
# funde el oscurecido; al llegar, los números del resumen cuentan hacia arriba. Un clic en el área
# de juego (fuera de los botones) salta la entrada y el conteo. Junto al título, destellos ámbar.
# Corre con el árbol en pausa (hereda process_mode ALWAYS de LevelUI), así que va en tiempo real.

# Duración del fundido del oscurecido, a la vez que la entrada.
const DIM_FADE_TIME := 0.2
# Duración total de la entrada: el marco baja hasta pasarse SLIDE_OVERSHOOT_PX px de su sitio
# y en los últimos SLIDE_SETTLE_TIME s vuelve a él.
const SLIDE_TIME := 0.35
const SLIDE_SETTLE_TIME := 0.08
const SLIDE_OVERSHOOT_PX := 2.0
# Duración del conteo de los números, que empieza al llegar el marco.
const COUNT_TIME := 0.8

# Destellos de cuatro puntas alrededor del título, en la rampa ámbar de art.md.
const SPARKLE_ARM_COLOR := Color("#ecb23c")
const SPARKLE_CORE_COLOR := Color("#ffe082")
const SPARKLE_DIAGONAL_COLOR := Color("#96641e")
# Cada destello: línea del título a la que se arrima, lado (-1 izquierda, 1 derecha), desplazamiento
# en px desde la esquina de esa línea, largo máximo de las puntas, ritmo y fase propios.
const SPARKLES: Array[Dictionary] = [
	{"line": 0, "side": -1, "offset": Vector2i(-8, -2), "max_arm": 5, "rate": 2.1, "phase": 0.0},
	{"line": 0, "side": 1, "offset": Vector2i(5, -8), "max_arm": 3, "rate": 3.0, "phase": 2.2},
	{"line": -1, "side": 1, "offset": Vector2i(7, 2), "max_arm": 4, "rate": 2.5, "phase": 4.1},
]

@onready var run_summary: RunSummary = %RunSummary
@onready var center: CenterContainer = $Center

# Entrada en curso (deslizamiento y fundido); null si no hay.
var _intro: Tween
var _time := 0.0

func _ready() -> void:
	super()
	title_label.add_theme_color_override("font_color", accent_color)
	run_summary.accent_color = accent_color
	title_label.draw.connect(_draw_sparkles)
	# El oscurecido cubre el área de juego; el marco y el resumen paran los clics que caen encima.
	for area: Control in [background, frame, run_summary]:
		area.gui_input.connect(_on_area_gui_input)
	visibility_changed.connect(_on_visibility_changed)

## Enseña el resumen de la partida. Se llama antes de mostrar la pantalla.
func show_run_stats(stats: RunStats) -> void:
	run_summary.show_stats(stats)

func _on_visibility_changed() -> void:
	# Cada vez que se abre, la entrada y el conteo empiezan de cero; al cerrarse se deja en su sitio.
	if is_visible_in_tree():
		_start_intro()
	else:
		_finish_intro()

func _start_intro() -> void:
	if _intro != null:
		_intro.kill()
	_time = 0.0
	# Desde donde el borde de abajo del marco (centrado) queda justo encima del área de juego.
	var area_height := size.y if size.y > 0.0 else get_viewport_rect().size.y
	var start_y := -roundf((area_height + frame.get_combined_minimum_size().y) / 2.0)
	_set_slide(start_y)
	background.modulate.a = 0.0
	_intro = create_tween().set_ignore_time_scale()
	_intro.tween_property(background, "modulate:a", 1.0, DIM_FADE_TIME)
	_intro.parallel().tween_method(_set_slide, start_y, SLIDE_OVERSHOOT_PX, SLIDE_TIME - SLIDE_SETTLE_TIME) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro.tween_method(_set_slide, SLIDE_OVERSHOOT_PX, 0.0, SLIDE_SETTLE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_intro.tween_callback(func() -> void: _intro = null)
	run_summary.count_up(COUNT_TIME, SLIDE_TIME)

# Corta la entrada y el conteo y deja el panel en su estado final.
func _finish_intro() -> void:
	if _intro != null:
		_intro.kill()
		_intro = null
	background.modulate.a = 1.0
	_set_slide(0.0)
	run_summary.finish_count()

# Desplazamiento vertical del marco respecto a su sitio, en píxeles enteros para que no tiemble.
func _set_slide(offset_y: float) -> void:
	center.position.y = roundf(offset_y)

func _on_area_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if _intro != null or run_summary.is_counting():
		_finish_intro()
		accept_event()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	title_label.queue_redraw()

# Pinta los destellos sobre el título, alrededor de la primera y la última línea del texto.
func _draw_sparkles() -> void:
	var font := title_label.get_theme_font("font")
	var font_size := title_label.get_theme_font_size("font_size")
	var line_height := font.get_height(font_size) + title_label.get_theme_constant("line_spacing")
	var lines := title_label.text.split("\n")
	for sparkle: Dictionary in SPARKLES:
		var line_index: int = posmod(sparkle["line"], lines.size())
		var line_width := font.get_string_size(lines[line_index], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var side: int = sparkle["side"]
		# Esquina de arriba de la línea por el lado del destello (el texto va centrado).
		var corner := Vector2(title_label.size.x / 2.0 + side * line_width / 2.0, line_index * line_height)
		var anchor := Vector2i(corner.round()) + (sparkle["offset"] as Vector2i) + Vector2i(0, roundi(line_height / 2.0))
		# Crece y mengua en pasos de 1 px, cada uno a su ritmo.
		var wave := 0.5 + 0.5 * sin(_time * float(sparkle["rate"]) + float(sparkle["phase"]))
		_draw_sparkle(anchor, roundi(wave * float(sparkle["max_arm"])))

# Destello de cuatro puntas en píxeles enteros: cruz de 1 px con el centro claro y, al máximo
# tamaño, cuatro píxeles en diagonal.
func _draw_sparkle(center_px: Vector2i, arm: int) -> void:
	if arm <= 0:
		return
	var c := Vector2(center_px)
	title_label.draw_rect(Rect2(c.x, c.y - arm, 1, arm * 2 + 1), SPARKLE_ARM_COLOR)
	title_label.draw_rect(Rect2(c.x - arm, c.y, arm * 2 + 1, 1), SPARKLE_ARM_COLOR)
	if arm >= 2:
		title_label.draw_rect(Rect2(c.x, c.y - 1, 1, 3), SPARKLE_CORE_COLOR)
		title_label.draw_rect(Rect2(c.x - 1, c.y, 3, 1), SPARKLE_CORE_COLOR)
	else:
		title_label.draw_rect(Rect2(c, Vector2.ONE), SPARKLE_CORE_COLOR)
	if arm >= 4:
		for diagonal: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			title_label.draw_rect(Rect2(c + diagonal, Vector2.ONE), SPARKLE_DIAGONAL_COLOR)
