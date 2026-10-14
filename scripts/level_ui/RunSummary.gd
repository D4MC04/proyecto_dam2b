extends PanelContainer
class_name RunSummary
## Resumen de una partida (oleada alcanzada, enemigos destruidos y dinero gastado) con las filas
## de la ficha. No sabe en qué pantalla está: lo usa la derrota y lo usará la victoria con su acento.

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

func _ready() -> void:
	_refresh_style()

## Pinta las tres filas a partir de `stats`; sustituye las anteriores.
func show_stats(stats: RunStats) -> void:
	for row in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	var entries: Array[StatEntry] = [
		StatEntry.new("wave", "Oleada", "%d/%d" % [stats.wave_reached, stats.wave_total]),
		StatEntry.new("kills", "Enemigos destruidos", UiFormat.abbreviate(stats.enemies_destroyed)),
		StatEntry.new("cost", "Dinero gastado", UiFormat.abbreviate(stats.money_spent) + "€"),
	]
	for i in entries.size():
		rows.add_child(StatRow.create(entries[i], i, ROW_H_MARGIN, ROW_V_MARGIN))

func _refresh_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BG_COLOR.lerp(accent_color, 0.5)
	style.anti_aliasing = false
	style.set_content_margin_all(2)
	add_theme_stylebox_override("panel", style)
	caption.add_theme_color_override("font_color", accent_color)
