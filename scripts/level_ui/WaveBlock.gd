extends VBoxContainer
class_name WaveBlock

## Reenvía la petición de inspeccionar de cada celda.
signal inspect_requested(data: EnemyData)

enum State { PAST, CURRENT, NEXT, FUTURE }

const ENEMY_CELL: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")

## Alto de la celda en la barra: el mismo que el de TowerButton (el Navedex mantiene el mínimo de la escena).
const CELL_HEIGHT := 56.0

const TITLE_BG_COLOR := Color("#0e1626")
const TITLE_BORDER_COLOR := Color("#1c4a60")
const TITLE_TEXT_COLOR := Color("#7fa6b8")
const CURRENT_BG_COLOR := Color("#14304a")
const CURRENT_BORDER_COLOR := Color("#40e0f0")
const CURRENT_TEXT_COLOR := Color("#40e0f0")
const NEXT_BORDER_COLOR := Color("#96641e")
const NEXT_TEXT_COLOR := Color("#ecb23c")
const PAST_COLOR := Color(1, 1, 1, 0.4)

@onready var cells: GridContainer = %Cells

## Rellena el bloque con una celda por tipo de enemigo, en orden de primera aparición.
func setup(wave: WaveData) -> void:
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
		cell.custom_minimum_size.y = CELL_HEIGHT
		cells.add_child(cell)
		cell.inspect_requested.connect(inspect_requested.emit)
		cell.setup(enemy_data, counts[enemy_data])

## Una pasada se atenúa entera.
func set_state(state: State) -> void:
	modulate = PAST_COLOR if state == State.PAST else Color.WHITE

## Pinta el título de la oleada (panel y texto) con los colores del estado.
static func apply_title_style(panel: PanelContainer, label: Label, state: State) -> void:
	var bg := TITLE_BG_COLOR
	var border := TITLE_BORDER_COLOR
	var text_color := TITLE_TEXT_COLOR
	match state:
		State.CURRENT:
			bg = CURRENT_BG_COLOR
			border = CURRENT_BORDER_COLOR
			text_color = CURRENT_TEXT_COLOR
		State.NEXT:
			border = NEXT_BORDER_COLOR
			text_color = NEXT_TEXT_COLOR
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	style.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", style)
	label.add_theme_color_override("font_color", text_color)
	panel.modulate = PAST_COLOR if state == State.PAST else Color.WHITE
