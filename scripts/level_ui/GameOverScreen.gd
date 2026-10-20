extends OverlayScreen
class_name GameOverScreen

# Pantalla de derrota ("señal perdida"): entra con un glitch que corta el área de juego mientras
# el título y el panel parpadean; después el panel queda estable con estática tenue y, cada pocos
# segundos, un parpadeo corto del título. Enseña el resumen de partida que le pasa LevelUI.
# Corre con el árbol en pausa (hereda process_mode ALWAYS de LevelUI), así que delta es tiempo real.

# Duración del corte de entrada.
const INTRO_TIME := 0.5
# Cada cuánto cambia el patrón del glitch: a saltos, como una señal que se pierde.
const GLITCH_STEP_TIME := 0.05
# Intensidad del glitch al principio y al final de la entrada.
const INTRO_START_INTENSITY := 1.0
const INTRO_END_INTENSITY := 0.5
# Estática que queda con el panel estable.
const RESIDUAL_STATIC := 0.12
# Probabilidad de que el panel se vea en cada paso de la entrada; sube hasta 1 al acabar.
const INTRO_FRAME_SHOW_CHANCE := 0.45
# Hueco aleatorio entre parpadeos del título con el panel estable, y lo que dura cada uno.
const TITLE_FLICKER_MIN_GAP := 2.5
const TITLE_FLICKER_MAX_GAP := 5.0
const TITLE_FLICKER_TIME := 0.15
const TITLE_FLICKER_ALPHA := 0.25

@onready var glitch_layer: ColorRect = %GlitchLayer
@onready var run_summary: RunSummary = %RunSummary

var _glitch_material: ShaderMaterial
var _time := 0.0
var _step_timer := 0.0
# Momento (en _time) en que empieza el siguiente parpadeo del título con el panel estable.
var _next_title_flicker := 0.0

func _ready() -> void:
	super()
	title_label.add_theme_color_override("font_color", accent_color)
	run_summary.accent_color = accent_color
	_glitch_material = glitch_layer.material as ShaderMaterial
	_glitch_material.set_shader_parameter("tint_color", accent_color)
	visibility_changed.connect(_on_visibility_changed)

## Enseña el resumen de la partida. Se llama antes de mostrar la pantalla.
func show_run_stats(stats: RunStats) -> void:
	run_summary.show_stats(stats)

func _on_visibility_changed() -> void:
	# Cada vez que se abre, el glitch empieza de cero.
	if is_visible_in_tree():
		_time = 0.0
		_step_timer = 0.0
		_set_options_clickable(false)
		_next_title_flicker = INTRO_TIME + randf_range(TITLE_FLICKER_MIN_GAP, TITLE_FLICKER_MAX_GAP)
		_glitch_material.set_shader_parameter("rect_size", glitch_layer.size)
		_step_glitch()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	# Los botones no reciben clics hasta que acaba el glitch de entrada.
	if _time >= INTRO_TIME and options.get_child(0).mouse_filter != Control.MOUSE_FILTER_STOP:
		_set_options_clickable(true)
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = GLITCH_STEP_TIME
		_step_glitch()

# Los botones ignoran el ratón mientras el marco puede estar invisible (mouse_filter, no disabled,
# para que no se vean con el aspecto de desactivados).
func _set_options_clickable(clickable: bool) -> void:
	for child: Node in options.get_children():
		var button := child as OverlayOptionButton
		if button:
			button.mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE

# Nuevo patrón del glitch y estado del panel y el título para este paso.
func _step_glitch() -> void:
	_glitch_material.set_shader_parameter("seed", randf() * 1000.0)
	if _time < INTRO_TIME:
		var progress := _time / INTRO_TIME
		_glitch_material.set_shader_parameter("intensity",
				lerpf(INTRO_START_INTENSITY, INTRO_END_INTENSITY, progress) * randf_range(0.6, 1.0))
		_glitch_material.set_shader_parameter("residual", 0.0)
		# Cuanto más avanza la entrada, más se ve el panel.
		frame.modulate.a = 1.0 if randf() < lerpf(INTRO_FRAME_SHOW_CHANCE, 1.0, progress) else 0.0
		title_label.modulate.a = 1.0 if randf() < 0.5 else TITLE_FLICKER_ALPHA
		return
	_glitch_material.set_shader_parameter("intensity", 0.0)
	_glitch_material.set_shader_parameter("residual", RESIDUAL_STATIC)
	frame.modulate.a = 1.0
	title_label.modulate.a = 1.0
	if _time >= _next_title_flicker:
		# Dentro del parpadeo, el título alterna entre tenue y visible en cada paso.
		if _time < _next_title_flicker + TITLE_FLICKER_TIME:
			title_label.modulate.a = TITLE_FLICKER_ALPHA if randf() < 0.6 else 1.0
		else:
			_next_title_flicker = _time + randf_range(TITLE_FLICKER_MIN_GAP, TITLE_FLICKER_MAX_GAP)
