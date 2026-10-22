class_name Navedex
extends Control
## Archivo del menú con pestañas Naves y Torres: cuadrícula con todos y detalle del elegido.
## Los que aún no han salido en una partida se ven en silueta y con "???".

signal back_pressed

const ENEMY_DIR := "res://resources/enemy_data/"
const ENEMY_FILES: Array[String] = [
	"dart_verde", "dart_rojo", "dart_morado", "dart_hielo", "wasp", "nave_normal",
	"nave_agresiva", "spiked_ship", "ufo", "ariete", "acorazado", "nodriza", "reparadora",
	"espectro", "divisora", "fragmento_divisora_central",
	"saboteadora",
]
const TOWER_DIR := "res://resources/turret_data/"
# Cada torre base va seguida de su fusión.
const TOWER_FILES: Array[String] = [
	"turret", "turret_fusion", "laser", "laser_fusion", "rocket_launcher", "rocket_launcher_fusion",
	"cryo", "cryo_fusion", "disintegrator", "disintegrator_fusion", "rail", "rail_fusion",
	"tesla", "tesla_fusion",
]
const TAB_ENEMIES := 0
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT := "???"

@onready var grid: GridContainer = %Grid
@onready var tabs: TabBar = %Tabs
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var tower_icon: Sprite2D = %TowerIcon
@onready var fusion_label: Label = %FusionLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: VBoxContainer = %StatRows

var _cells: Dictionary[InspectableData, EnemyCell] = {}

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	tabs.add_tab("NAVES")
	tabs.add_tab("TORRES")
	tabs.tab_changed.connect(_build_grid)
	_build_grid(TAB_ENEMIES)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

# Rellena la cuadrícula con las naves o las torres según la pestaña.
func _build_grid(tab: int) -> void:
	for cell in _cells.values():
		grid.remove_child(cell)
		cell.queue_free()
	_cells.clear()
	var enemies := tab == TAB_ENEMIES
	for file in (ENEMY_FILES if enemies else TOWER_FILES):
		var data := load((ENEMY_DIR if enemies else TOWER_DIR) + file + ".tres") as InspectableData
		var cell: EnemyCell = CELL_SCENE.instantiate()
		grid.add_child(cell)
		cell.setup(data, 0)
		cell.count_label.hide()
		cell.inspect_requested.connect(_show_detail)
		_cells[data] = cell
	_on_visibility_changed()

# Al abrirse se refresca lo visto, por si se jugó una partida desde la última vez.
func _on_visibility_changed() -> void:
	if not visible or _cells.is_empty():
		return
	for data in _cells:
		_cells[data].icon_rect.modulate = Color.WHITE if _is_known(data) else Color.BLACK
	_show_detail(_cells.keys()[0])

# Las torres siempre se conocen; las naves, solo si ya han salido en una partida.
func _is_known(data: InspectableData) -> bool:
	var enemy := data as EnemyData
	return enemy == null or GameState.has_seen_enemy(enemy)

func _show_detail(data: InspectableData) -> void:
	var seen := _is_known(data)
	var tower := data as TowerData
	sprite.visible = tower == null
	tower_icon.visible = tower != null
	fusion_label.visible = tower != null and tower.fusion != null
	if tower != null:
		tower_icon.texture = tower.icon
		if tower.fusion != null:
			fusion_label.text = "FUSIÓN: " + tower.fusion.name.to_upper()
	else:
		var enemy := data as EnemyData
		sprite.sprite_frames = enemy.sprite_frames
		sprite.modulate = Color.WHITE if seen else Color.BLACK
		sprite.play(&"up")
	name_label.text = data.get_inspect_name().to_upper() if seen else UNKNOWN_TEXT
	description_label.text = data.get_inspect_description() if seen else UNKNOWN_TEXT
	for row in stat_rows.get_children():
		stat_rows.remove_child(row)
		row.queue_free()
	if seen:
		var stats := data.get_stats()
		for i in stats.size():
			stat_rows.add_child(StatRow.create(stats[i], i, 3, 1, 24, 8, 3, 6))
