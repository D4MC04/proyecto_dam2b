class_name Navedex
extends Control
## Archivo del menú con pestañas Naves y Torretas: cuadrícula con todos y detalle del elegido.
## Los que aún no han salido en una partida se ven en silueta y con "???".

signal back_pressed

const ENEMY_DIR := "res://resources/enemy_data/"
const ENEMY_FILES: Array[String] = [
	"dart_verde", "dart_rojo", "dart_morado", "dart_hielo", "wasp", "nave_normal",
	"nave_agresiva", "ariete", "acorazado", "nodriza", "reparadora",
	"espectro", "divisora", "fragmento_divisora_central",
	"saboteadora",
]
const TURRET_DIR := "res://resources/turret_data/"
# Solo las torretas base; sus mejoras se ven con las flechas del detalle.
const TURRET_FILES: Array[String] = [
	"turret", "laser", "rocket_launcher", "cryo", "disintegrator", "rail", "tesla",
]
const TAB_ENEMIES := 0
const TAB_ACHIEVEMENTS := 2
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT := "???"
# Lado de las celdas cuadradas de la cuadrícula.
const CELL_SIZE := 64

@onready var grid: GridContainer = %Grid
@onready var tabs: TabBar = %Tabs
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var turret_icon: Sprite2D = %TurretIcon
@onready var fusion_label: Label = %FusionLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: VBoxContainer = %StatRows
@onready var detail: VBoxContainer = %Detail
@onready var achievements_list: Label = %AchievementsList
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var _cells: Dictionary[InspectableData, EnemyCell] = {}
# Cadena de versiones de la torreta mostrada (base, mejora...) y cuál se ve.
var _versions: Array[TurretData] = []
var _version_index := 0

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	tabs.add_tab("NAVES")
	tabs.add_tab("TORRETAS")
	tabs.add_tab("LOGROS")
	prev_button.pressed.connect(_change_version.bind(-1))
	next_button.pressed.connect(_change_version.bind(1))
	tabs.tab_changed.connect(_build_grid)
	_build_grid(TAB_ENEMIES)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

# Rellena la cuadrícula con las naves o las torretas según la pestaña.
func _build_grid(tab: int) -> void:
	var achievements := tab == TAB_ACHIEVEMENTS
	grid.visible = not achievements
	detail.visible = not achievements
	achievements_list.visible = achievements
	if achievements:
		_show_achievements()
		return
	for cell in _cells.values():
		grid.remove_child(cell)
		cell.queue_free()
	_cells.clear()
	var enemies := tab == TAB_ENEMIES
	for file in (ENEMY_FILES if enemies else TURRET_FILES):
		var data := load((ENEMY_DIR if enemies else TURRET_DIR) + file + ".tres") as InspectableData
		var cell: EnemyCell = CELL_SCENE.instantiate()
		grid.add_child(cell)
		cell.setup(data, 0)
		cell.count_label.hide()
		cell.inspect_requested.connect(_show_detail)
		_cells[data] = cell
	_on_visibility_changed()

# Al abrirse se refresca lo visto, por si se jugó una partida desde la última vez.
func _on_visibility_changed() -> void:
	if not visible:
		return
	if tabs.current_tab == TAB_ACHIEVEMENTS:
		_show_achievements()
		return
	if _cells.is_empty():
		return
	for data in _cells:
		_cells[data].icon_rect.modulate = Color.WHITE if _is_known(data) else Color.BLACK
	_show_detail(_cells.keys()[0])

# Las torretas siempre se conocen; las naves, solo si ya han salido en una partida.
func _is_known(data: InspectableData) -> bool:
	var enemy := data as EnemyData
	return enemy == null or GameState.has_seen_enemy(enemy)

func _show_achievements() -> void:
	var lines: Array[String] = []
	for id: String in GameState.ACHIEVEMENTS:
		var info: Array = GameState.ACHIEVEMENTS[id]
		var done: bool = id in GameState.unlocked
		lines.append("[%s] %s - %s" % ["X" if done else " ", info[0], info[1]])
	achievements_list.text = "\n".join(lines)

func _show_detail(data: InspectableData) -> void:
	_versions.clear()
	_version_index = 0
	var base := data as TurretData
	if base != null:
		# Base y mejoras encadenadas.
		var turret: TurretData = base
		while turret != null:
			_versions.append(turret)
			turret = turret.fusion
	_show_entry(data)

# Pasa a la versión anterior (-1) o siguiente (+1) de la torreta.
func _change_version(step: int) -> void:
	_version_index = clampi(_version_index + step, 0, _versions.size() - 1)
	_show_entry(_versions[_version_index])

func _show_entry(data: InspectableData) -> void:
	var seen := _is_known(data)
	var turret := data as TurretData
	sprite.visible = turret == null
	turret_icon.visible = turret != null
	prev_button.disabled = _version_index <= 0
	next_button.disabled = _version_index >= _versions.size() - 1
	# Invisibles (no ocultos) en las naves para que la imagen no se mueva.
	prev_button.modulate.a = 1.0 if turret != null else 0.0
	next_button.modulate.a = 1.0 if turret != null else 0.0
	if turret == null:
		prev_button.disabled = true
		next_button.disabled = true
	fusion_label.visible = turret != null and turret.fusion != null
	if turret != null:
		turret_icon.texture = turret.icon
		if turret.fusion != null:
			fusion_label.text = "MEJORA: " + turret.fusion.name.to_upper()
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
