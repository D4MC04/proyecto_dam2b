extends VBoxContainer
class_name WaveBlock

enum State { PAST, CURRENT, FUTURE }

const ENEMY_CELL: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")

const TITLE_BG_COLOR := Color("#0e1626")
const TITLE_BORDER_COLOR := Color("#1c4a60")
const TITLE_TEXT_COLOR := Color("#7fa6b8")
const CURRENT_BG_COLOR := Color("#14304a")
const CURRENT_BORDER_COLOR := Color("#40e0f0")
const CURRENT_TEXT_COLOR := Color("#40e0f0")
const PAST_COLOR := Color(1, 1, 1, 0.4)

@onready var title_panel: PanelContainer = %TitlePanel
@onready var title_label: Label = %TitleLabel
@onready var cells: GridContainer = %Cells

## Rellena el bloque con una celda por tipo de enemigo, en orden de primera aparición.
func setup(wave: WaveData, wave_number: int) -> void:
	title_label.text = "OLEADA %d" % wave_number
	var entries: Array[SpawnEntry] = wave.entries.duplicate()
	entries.sort_custom(func(a: SpawnEntry, b: SpawnEntry) -> bool: return a.time < b.time)
	# Un Dictionary conserva el orden de inserción: la primera aparición manda.
	var counts: Dictionary = {}
	for entry in entries:
		if entry.enemy_data == null:
			continue
		counts[entry.enemy_data] = int(counts.get(entry.enemy_data, 0)) + 1
	for enemy_data: EnemyData in counts:
		var cell: EnemyCell = ENEMY_CELL.instantiate()
		cells.add_child(cell)
		cell.setup(enemy_data, counts[enemy_data])
	set_state(State.FUTURE)

func set_state(state: State) -> void:
	var current := state == State.CURRENT
	var bg := CURRENT_BG_COLOR if current else TITLE_BG_COLOR
	var border := CURRENT_BORDER_COLOR if current else TITLE_BORDER_COLOR
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.anti_aliasing = false
	title_panel.add_theme_stylebox_override("panel", style)
	title_label.add_theme_color_override("font_color", CURRENT_TEXT_COLOR if current else TITLE_TEXT_COLOR)
	modulate = PAST_COLOR if state == State.PAST else Color.WHITE
