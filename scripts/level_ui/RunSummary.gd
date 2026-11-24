extends PanelContainer
class_name RunSummary
## Resumen de una derrota: oleada alcanzada y último enemigo que llegó a la estación, con las filas
## de la ficha. No sabe en qué pantalla está: el acento lo pone quien lo usa.

const BG_COLOR: Color = Color("#0a0f1a")
# Las filas son más anchas que en la ficha: algo más de aire alrededor del icono y el valor.
const ROW_H_MARGIN: int = 6
const ROW_V_MARGIN: int = 3
const ROW_FONT_SIZE: int = 24
const ROW_ICON_BOX: int = 12
const ROW_ICON_TOP: int = 5
# Hueco entre icono, nombre y valor: el de la ficha (StatRow.SEPARATION) a ×1,5.
const ROW_SEPARATION: int = 6

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

## Pinta las filas (la causa solo si consta) a partir de `stats`; sustituye las anteriores.
func show_stats(stats: RunStats) -> void:
	for row: Node in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	var entries: Array[StatEntry] = [
		StatEntry.new("wave", "STAT_WAVE", "%d/%d" % [stats.wave_reached, stats.wave_total]),
	]
	if not stats.killer_name.is_empty():
		entries.append(StatEntry.new("station", "STAT_CAUSE", tr(stats.killer_name).to_upper()))
	for i: int in entries.size():
		rows.add_child(StatRow.create(entries[i], i, ROW_H_MARGIN, ROW_V_MARGIN, ROW_FONT_SIZE, ROW_ICON_BOX, ROW_ICON_TOP, ROW_SEPARATION))

func _refresh_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BG_COLOR.lerp(accent_color, 0.5)
	style.anti_aliasing = false
	style.set_content_margin_all(3)
	add_theme_stylebox_override("panel", style)
	caption.add_theme_color_override("font_color", accent_color)
