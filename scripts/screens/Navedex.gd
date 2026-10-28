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
	"turret", "minigun", "rocket_launcher", "cryo", "disintegrator", "rail", "tesla", "amplifier", "miner",
]
const TAB_ENEMIES := 0
const TAB_ACHIEVEMENTS := 2
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT := "???"
# Lado de las celdas cuadradas de la cuadrícula.
const CELL_SIZE := 64
const ACHIEVEMENT_ICON_DIR := "res://assets/ui/achievements/"
# Icono de logro (16x16 ×3), ancho de cada fila (dos por línea) y color del logro sin conseguir.
const ACHIEVEMENT_ICON_SIZE := 48
const ACHIEVEMENT_ROW_WIDTH := 350
const LOCKED_COLOR := Color(0.3, 0.3, 0.35)
# Lado de las flechas de torreta.
const ARROW_SIZE := 28

@onready var grid: GridContainer = %Grid
@onready var tabs: TabBar = %Tabs
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var turret_icon: Sprite2D = %TurretIcon
@onready var fusion_label: Label = %FusionLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: VBoxContainer = %StatRows
@onready var detail: VBoxContainer = %Detail
@onready var achievements_list: GridContainer = %AchievementsList
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
	_style_arrow(prev_button)
	_style_arrow(next_button)
	prev_button.pressed.connect(_change_version.bind(-1))
	next_button.pressed.connect(_change_version.bind(1))
	tabs.tab_changed.connect(_build_grid)
	_build_grid(TAB_ENEMIES)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

# Flecha pequeña con el mismo borde cian fino y relleno tenue que las celdas.
func _style_arrow(button: Button) -> void:
	button.custom_minimum_size = Vector2(ARROW_SIZE, ARROW_SIZE)
	var normal := ClippedBoxStyle.create(TurretButton.BG_COLOR, TurretButton.BORDER_COLOR)
	var hover := ClippedBoxStyle.create(TurretButton.HOVER_BG_COLOR, TurretButton.HOVER_BORDER_COLOR)
	var disabled := ClippedBoxStyle.create(TurretButton.BG_COLOR, TurretButton.BORDER_COLOR.darkened(0.6))
	for style: ClippedBoxStyle in [normal, hover, disabled]:
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

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
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		cell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	for child in achievements_list.get_children():
		child.free()
	for id: String in GameState.ACHIEVEMENTS:
		var info: Array = GameState.ACHIEVEMENTS[id]
		var done: bool = id in GameState.unlocked
		achievements_list.add_child(_make_achievement_row(id, info[0], info[1], done))

# Fila de un logro: icono a la izquierda y nombre y descripción a la derecha; apagada si falta por conseguir.
func _make_achievement_row(id: String, title: String, description: String, done: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(ACHIEVEMENT_ROW_WIDTH, 0)
	row.add_theme_constant_override("separation", 10)
	row.modulate = Color.WHITE if done else LOCKED_COLOR
	var icon := TextureRect.new()
	icon.texture = load(ACHIEVEMENT_ICON_DIR + id + ".png")
	icon.custom_minimum_size = Vector2.ONE * ACHIEVEMENT_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	var name_text := Label.new()
	name_text.text = title
	name_text.add_theme_font_size_override("font_size", 24)
	var description_text := Label.new()
	description_text.text = description
	description_text.add_theme_font_size_override("font_size", 18)
	description_text.modulate = Color(1, 1, 1, 0.7)
	texts.add_child(name_text)
	texts.add_child(description_text)
	row.add_child(texts)
	return row

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
