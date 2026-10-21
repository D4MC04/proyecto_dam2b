class_name Navedex
extends Control
## Archivo de enemigos del menú: cuadrícula con los 12 y detalle del elegido.
## Los que aún no han salido en una partida se ven en silueta y con "???".

signal back_pressed

const ENEMY_DIR := "res://resources/enemy_data/"
const ENEMY_FILES: Array[String] = [
	"dart_verde", "dart_rojo", "dart_morado", "dart_hielo", "wasp", "nave_normal",
	"nave_agresiva", "spiked_ship", "ufo", "ariete", "acorazado", "nodriza", "reparadora",
]
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT := "???"

@onready var grid: GridContainer = %Grid
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: VBoxContainer = %StatRows

var _cells: Dictionary[EnemyData, EnemyCell] = {}

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	for file in ENEMY_FILES:
		var data := load(ENEMY_DIR + file + ".tres") as EnemyData
		var cell: EnemyCell = CELL_SCENE.instantiate()
		grid.add_child(cell)
		cell.setup(data, 0)
		cell.count_label.hide()
		cell.inspect_requested.connect(_show_detail)
		_cells[data] = cell
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

# Al abrirse se refresca lo visto, por si se jugó una partida desde la última vez.
func _on_visibility_changed() -> void:
	if not visible:
		return
	for data in _cells:
		_cells[data].icon_rect.modulate = Color.WHITE if GameState.has_seen_enemy(data) else Color.BLACK
	_show_detail(_cells.keys()[0])

func _show_detail(data: EnemyData) -> void:
	var seen: bool = GameState.has_seen_enemy(data)
	sprite.sprite_frames = data.sprite_frames
	sprite.modulate = Color.WHITE if seen else Color.BLACK
	sprite.play(&"up")
	name_label.text = data.name.to_upper() if seen else UNKNOWN_TEXT
	description_label.text = data.description if seen else UNKNOWN_TEXT
	for row in stat_rows.get_children():
		stat_rows.remove_child(row)
		row.queue_free()
	if seen:
		var stats := data.get_stats()
		for i in stats.size():
			stat_rows.add_child(StatRow.create(stats[i], i, 3, 1, 24, 8, 3, 6))
