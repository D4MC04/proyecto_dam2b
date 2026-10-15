extends PanelContainer
class_name RunSummary
## Resumen de una partida (oleada alcanzada, enemigos destruidos y dinero gastado) con las filas
## de la ficha. No sabe en qué pantalla está: lo usan la derrota y la victoria, cada una con su acento.
## show_stats() pinta los valores finales de golpe; count_up() los hace contar desde 0 (la victoria).

const BG_COLOR := Color("#0a0f1a")
# Las filas son más anchas que en la ficha: algo más de aire alrededor del icono y el valor.
const ROW_H_MARGIN := 4
const ROW_V_MARGIN := 2

## Color del rótulo y del borde.
@export var accent_color: Color = Color("#40e0f0"):
	set(value):
		accent_color = value
		if is_node_ready():
			_refresh_style()

@onready var caption: Label = %Caption
@onready var rows: VBoxContainer = %Rows

var _stats: RunStats
# Etiquetas de valor de las filas que cuentan; las rellena show_stats().
var _kills_label: Label
var _cost_label: Label
# Conteo en curso de count_up(); null si no hay.
var _count: Tween

func _ready() -> void:
	_refresh_style()

## Pinta las tres filas a partir de `stats`; sustituye las anteriores.
func show_stats(stats: RunStats) -> void:
	_stop_count()
	_stats = stats
	for row in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	var entries: Array[StatEntry] = [
		StatEntry.new("wave", "Oleada", "%d/%d" % [stats.wave_reached, stats.wave_total]),
		StatEntry.new("kills", "Enemigos destruidos", UiFormat.abbreviate(stats.enemies_destroyed)),
		StatEntry.new("cost", "Dinero gastado", UiFormat.money(stats.money_spent)),
	]
	for i in entries.size():
		rows.add_child(StatRow.create(entries[i], i, ROW_H_MARGIN, ROW_V_MARGIN))
	_kills_label = StatRow.get_value_label(rows.get_child(1) as PanelContainer)
	_cost_label = StatRow.get_value_label(rows.get_child(2) as PanelContainer)

## Pone enemigos destruidos y dinero gastado a 0 y, tras `delay` segundos, los hace contar hasta
## su valor en `duration` segundos, frenando al final. La oleada no cuenta. Va en tiempo real.
## Necesita un show_stats() antes; sin él no hace nada.
func count_up(duration: float, delay: float = 0.0) -> void:
	_stop_count()
	if _stats == null:
		return
	_show_counted(0.0)
	_count = create_tween().set_ignore_time_scale()
	_count.tween_interval(delay)
	_count.tween_method(_show_counted, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_count.tween_callback(func() -> void: _count = null)

## Corta el conteo en curso y deja los valores finales.
func finish_count() -> void:
	_stop_count()
	if _stats != null:
		_show_counted(1.0)

func is_counting() -> bool:
	return _count != null

func _stop_count() -> void:
	if _count != null:
		_count.kill()
		_count = null

# Valores de las filas que cuentan al `progress` (0..1) del conteo. Con UiFormat en cada paso
# el texto tiene el formato del valor final.
func _show_counted(progress: float) -> void:
	_kills_label.text = UiFormat.abbreviate(roundi(_stats.enemies_destroyed * progress))
	_cost_label.text = UiFormat.money(roundi(_stats.money_spent * progress))

func _refresh_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BG_COLOR.lerp(accent_color, 0.5)
	style.anti_aliasing = false
	style.set_content_margin_all(2)
	add_theme_stylebox_override("panel", style)
	caption.add_theme_color_override("font_color", accent_color)
