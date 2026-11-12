class_name Navedex
extends Control
## Archivo del menú, dentro de la tablet de la oficina (MainMenu se acerca a ella y esto aparece encima):
## marco de la tablet, botones físicos NAVES / TORRETAS, cuadrícula con todos y detalle del elegido
## (holograma cian, stats con barra). Los que aún no han salido en una partida se ven en silueta y con "???".

signal back_pressed

const ENEMY_DIR: String = "res://resources/enemy_data/"
const ENEMY_FILES: Array[String] = [
	"dart_verde", "dart_rojo", "dart_morado", "dart_hielo", "wasp", "nave_normal",
	"nave_agresiva", "ariete", "acorazado", "nodriza", "reparadora",
	"espectro", "divisora", "fragmento_divisora_central",
	"saboteadora",
]
const TURRET_DIR: String = "res://resources/turret_data/"
# Solo las torretas base; sus mejoras se ven con las flechas del detalle.
const TURRET_FILES: Array[String] = [
	"turret", "minigun", "rocket_launcher", "cryo", "disintegrator", "rail", "tesla", "amplifier", "orbiter", "miner",
]
const TAB_ENEMIES: int = 0
const TAB_TURRETS: int = 1
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT: String = "???"
# Lado de las celdas cuadradas de la cuadrícula.
const CELL_SIZE: int = 40
# Lado de las flechas de torreta.
const ARROW_SIZE: int = 28
# Aumento del terminal dibujado y sus piezas en píxeles del terminal (como tablet.png, de frente).
# MainMenu acerca la oficina hasta ese aumento, así que queda encima de la tablet de la oficina.
const SCALE: int = 3
const FRAME_SIZE: Vector2i = Vector2i(147, 170)
# Carcasa (con las esquinas de arriba a la izquierda y abajo a la derecha cortadas), asas, antena y pantalla.
const BODY_RECT: Rect2i = Rect2i(8, 7, 131, 163)
const BODY_CUT: int = 8
const BODY_COLOR: Color = Color("#3a4256")
const HANDLES: Array[Rect2i] = [Rect2i(0, 46, 11, 64), Rect2i(136, 46, 11, 64)]
# En la misma columna que la antena de tablet.png al final del zoom, para taparla.
const ANTENNA: Rect2i = Rect2i(91, 0, 5, 9)
const BEACON_PERIOD: float = 1.4
const SCREEN_RECT: Rect2i = Rect2i(15, 24, 117, 116)
# Pilotos encima de los botones físicos (centro en x) y fila de la tira de luz bajo la pantalla.
const BUTTON_LEDS: Array[int] = [32, 74, 115]
const LIGHT_STRIP_Y: int = 144
# Holograma: vueltas por segundo y velocidad de la línea de escaneo (px/s).
const SPIN_SPEED: float = 0.75
const SCAN_SPEED: float = 40.0
const SCAN_COLOR: Color = Color(OfficePaint.CYAN_LIGHT, 0.5)
const BAR_HEIGHT: int = 3

@onready var grid: GridContainer = %Grid
@onready var tablet: Control = %Tablet
@onready var holo: Control = %Holo
@onready var ships_button: Button = %ShipsButton
@onready var turrets_button: Button = %TurretsButton
@onready var fusion_label: Label = %FusionLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: VBoxContainer = %StatRows
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var _cells: Dictionary[InspectableData, EnemyCell] = {}
# Cadena de versiones de la torreta mostrada (base, mejora...) y cuál se ve.
var _versions: Array[TurretData] = []
var _version_index: int = 0
# Lo que enseña el holograma, si se ve entero y la copia en cian de cada textura.
var _holo_texture: Texture2D
var _holo_known: bool = true
var _holograms: Dictionary[Texture2D, Texture2D] = {}
# Valor más alto de cada stat entre los de la pestaña, para escalar las barras.
var _stat_max: Dictionary[String, float] = {}
var _time: float = 0.0

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	var group: ButtonGroup = ButtonGroup.new()
	ships_button.button_group = group
	turrets_button.button_group = group
	ships_button.pressed.connect(_build_grid.bind(TAB_ENEMIES))
	turrets_button.pressed.connect(_build_grid.bind(TAB_TURRETS))
	holo.draw.connect(_draw_holo)
	tablet.resized.connect(queue_redraw)
	for button: Button in [ships_button, turrets_button, %VolverButton]:
		_style_physical(button)
	_style_arrow(prev_button)
	_style_arrow(next_button)
	prev_button.pressed.connect(_change_version.bind(-1))
	next_button.pressed.connect(_change_version.bind(1))
	_build_grid(TAB_ENEMIES)
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		holo.queue_redraw()
		# El marco también: la punta de la antena parpadea y los pilotos siguen a la pestaña.
		queue_redraw()

# El terminal de frente, como tablet.png: asas, antena (su punta parpadea), carcasa de metal con las
# esquinas cortadas y tornillos, pantalla con su aro, tira de luz y el piloto de cada botón (encendido
# el de la pestaña elegida). Los botones son ShipsButton, TurretsButton y VolverButton.
func _draw() -> void:
	draw_set_transform(tablet.position, 0.0, Vector2(SCALE, SCALE))
	for handle: Rect2i in HANDLES:
		OfficePaint.metal_box(self, handle)
		OfficePaint.rect(self, Rect2i(handle.position.x + (3 if handle.position.x == 0 else 5), handle.position.y + 4, 3, handle.size.y - 8), OfficePaint.OUTLINE)
	OfficePaint.rect(self, ANTENNA, OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(ANTENNA.position.x + 1, 2, 1, ANTENNA.size.y - 2), OfficePaint.METAL_LIGHT)
	OfficePaint.rect(self, Rect2i(ANTENNA.position.x + 2, 2, 2, ANTENNA.size.y - 2), OfficePaint.METAL_DARK)
	var beacon_on: bool = fmod(_time, BEACON_PERIOD) < BEACON_PERIOD / 2.0
	OfficePaint.rect(self, Rect2i(ANTENNA.position.x + 1, 0, 3, 2), OfficePaint.CYAN_LIGHT if beacon_on else OfficePaint.CYAN_DARK)
	_cut_box(BODY_RECT, BODY_CUT, OfficePaint.OUTLINE)
	_cut_box(BODY_RECT.grow(-1), BODY_CUT - 1, OfficePaint.METAL)
	_cut_box(Rect2i(BODY_RECT.position + Vector2i(2, 2), BODY_RECT.size - Vector2i(3, 3)), BODY_CUT - 1, BODY_COLOR)
	for x: int in [BODY_RECT.position.x + 7, BODY_RECT.end.x - 10]:
		OfficePaint.screw(self, Vector2i(x, BODY_RECT.position.y + 5))
	OfficePaint.rect(self, SCREEN_RECT.grow(2), OfficePaint.WALL_LIGHT)
	OfficePaint.screen(self, SCREEN_RECT.grow(1))
	OfficePaint.rect(self, Rect2i(SCREEN_RECT.position.x + 2, LIGHT_STRIP_Y - 1, SCREEN_RECT.size.x - 4, 3), OfficePaint.OUTLINE)
	OfficePaint.rect(self, Rect2i(SCREEN_RECT.position.x + 3, LIGHT_STRIP_Y, SCREEN_RECT.size.x - 6, 1), OfficePaint.CYAN)
	for i: int in BUTTON_LEDS.size():
		var lit: bool = (ships_button.button_pressed if i == 0 else turrets_button.button_pressed if i == 1 else false)
		OfficePaint.rect(self, Rect2i(BUTTON_LEDS[i] - 4, LIGHT_STRIP_Y + 4, 8, 3), OfficePaint.OUTLINE)
		OfficePaint.rect(self, Rect2i(BUTTON_LEDS[i] - 3, LIGHT_STRIP_Y + 5, 6, 1), OfficePaint.CYAN if lit else OfficePaint.WALL_LIGHT)

# Caja con las esquinas de arriba a la izquierda y abajo a la derecha cortadas `cut` px en escalera, fila a fila.
func _cut_box(r: Rect2i, cut: int, color: Color) -> void:
	for y: int in r.size.y:
		var left: int = maxi(0, cut - y)
		var right: int = maxi(0, cut - (r.size.y - 1 - y))
		OfficePaint.rect(self, Rect2i(r.position.x + left, r.position.y + y, r.size.x - left - right, 1), color)

# Botón físico de la carcasa: metal con contorno grueso; el de la pestaña elegida, cian encendido.
func _style_physical(button: Button) -> void:
	var looks: Dictionary[String, Color] = {
		"normal": OfficePaint.METAL, "hover": OfficePaint.METAL_LIGHT,
		"pressed": OfficePaint.CYAN, "hover_pressed": OfficePaint.CYAN_LIGHT, "disabled": OfficePaint.METAL_DARK,
	}
	for state: String in looks:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = looks[state]
		style.set_border_width_all(SCALE)
		style.border_color = OfficePaint.OUTLINE
		style.anti_aliasing = false
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, OfficePaint.OUTLINE)

# Flecha pequeña con el mismo borde cian fino y relleno tenue que las celdas.
func _style_arrow(button: Button) -> void:
	button.custom_minimum_size = Vector2(ARROW_SIZE, ARROW_SIZE)
	var normal: ClippedBoxStyle = ClippedBoxStyle.create(TurretButton.BG_COLOR, TurretButton.BORDER_COLOR)
	var hover: ClippedBoxStyle = ClippedBoxStyle.create(TurretButton.HOVER_BG_COLOR, TurretButton.HOVER_BORDER_COLOR)
	var disabled: ClippedBoxStyle = ClippedBoxStyle.create(TurretButton.BG_COLOR, TurretButton.BORDER_COLOR.darkened(0.6))
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
	for cell: EnemyCell in _cells.values():
		grid.remove_child(cell)
		cell.queue_free()
	_cells.clear()
	_stat_max.clear()
	var enemies: bool = tab == TAB_ENEMIES
	for file: String in (ENEMY_FILES if enemies else TURRET_FILES):
		var data: InspectableData = load((ENEMY_DIR if enemies else TURRET_DIR) + file + ".tres") as InspectableData
		var cell: EnemyCell = CELL_SCENE.instantiate()
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		cell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		grid.add_child(cell)
		cell.setup(data, 0)
		cell.count_label.hide()
		cell.inspect_requested.connect(_show_detail)
		_cells[data] = cell
		_collect_stat_max(data)
	_on_visibility_changed()

# Anota el valor más alto de cada stat (de la torreta y de sus mejoras) para escalar las barras.
func _collect_stat_max(data: InspectableData) -> void:
	var entry_data: InspectableData = data
	while entry_data != null:
		for entry: StatEntry in entry_data.get_stats():
			_stat_max[entry.label] = maxf(_stat_max.get(entry.label, 0.0), entry.value.to_float())
		var turret: TurretData = entry_data as TurretData
		entry_data = turret.fusion if turret != null else null

# Al abrirse se refresca lo visto, por si se jugó una partida desde la última vez.
func _on_visibility_changed() -> void:
	if not visible or _cells.is_empty():
		return
	for data: InspectableData in _cells:
		_cells[data].icon_rect.modulate = Color.WHITE if _is_known(data) else Color.BLACK
	_show_detail(_cells.keys()[0])

# Las torretas siempre se conocen; las naves, solo si ya han salido en una partida.
func _is_known(data: InspectableData) -> bool:
	var enemy: EnemyData = data as EnemyData
	return enemy == null or GameState.has_seen_enemy(enemy)

func _show_detail(data: InspectableData) -> void:
	_versions.clear()
	_version_index = 0
	var base: TurretData = data as TurretData
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
	var seen: bool = _is_known(data)
	var turret: TurretData = data as TurretData
	prev_button.disabled = _version_index <= 0
	next_button.disabled = _version_index >= _versions.size() - 1
	# Invisibles (no ocultos) en las naves para que el holograma no se mueva.
	prev_button.modulate.a = 1.0 if turret != null else 0.0
	next_button.modulate.a = 1.0 if turret != null else 0.0
	if turret == null:
		prev_button.disabled = true
		next_button.disabled = true
	fusion_label.visible = turret != null and turret.fusion != null
	var source: Texture2D
	if turret != null:
		source = turret.icon
		if turret.fusion != null:
			fusion_label.text = tr("NAVEDEX_UPGRADE") % turret.fusion.get_inspect_name().to_upper()
	else:
		source = (data as EnemyData).sprite_frames.get_frame_texture(&"up", 0)
	if not _holograms.has(source):
		_holograms[source] = ArchiveTablet.make_hologram(source)
	_holo_known = seen
	_holo_texture = _holograms[source] if seen else source
	name_label.text = data.get_inspect_name().to_upper() if seen else UNKNOWN_TEXT
	description_label.text = data.get_inspect_description() if seen else ""
	for row: Node in stat_rows.get_children():
		stat_rows.remove_child(row)
		row.queue_free()
	if seen:
		var stats: Array[StatEntry] = data.get_stats()
		for i: int in stats.size():
			stat_rows.add_child(_make_stat_row(stats[i], i))

# Fila del stat con una barra debajo: su valor frente al más alto de la pestaña (si no es un número, vacía).
func _make_stat_row(entry: StatEntry, index: int) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(StatRow.create(entry, index))
	var bar: ColorRect = ColorRect.new()
	bar.color = OfficePaint.SCREEN_LINE
	bar.custom_minimum_size.y = BAR_HEIGHT
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)
	var top: float = _stat_max.get(entry.label, 0.0)
	if top > 0.0:
		var fill: ColorRect = ColorRect.new()
		fill.color = OfficePaint.CYAN
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.anchor_right = clampf(entry.value.to_float() / top, 0.0, 1.0)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(fill)
	return box

# Holograma: gira sobre sí mismo (se estrecha por los dos lados y se voltea en su sitio) y una línea de
# escaneo le baja por encima. Los no vistos son la silueta negra, quieta.
func _draw_holo() -> void:
	if _holo_texture == null:
		return
	var texture_size: Vector2i = Vector2i(_holo_texture.get_size())
	@warning_ignore("integer_division")
	var zoom: int = maxi(1, mini(int(holo.size.x) / texture_size.x, int(holo.size.y) / texture_size.y))
	var full: Vector2i = texture_size * zoom
	var turn: float = cos(_time * SPIN_SPEED * TAU) if _holo_known else 1.0
	var squeeze: int = floori((1.0 - absf(turn)) * (full.x - zoom) / 2.0)
	var width: int = full.x - 2 * squeeze
	var top_left: Vector2i = (Vector2i(holo.size) - full) / 2
	holo.draw_texture_rect(_holo_texture, Rect2(top_left.x + squeeze, top_left.y, width if turn >= 0.0 else -width, full.y),
			false, Color.WHITE if _holo_known else Color.BLACK)
	if _holo_known:
		var scan_y: int = int(_time * SCAN_SPEED) % (full.y + 8) - 4
		holo.draw_rect(Rect2i(top_left.x + squeeze, top_left.y + scan_y, width, 2).intersection(Rect2i(top_left, full)), SCAN_COLOR)
