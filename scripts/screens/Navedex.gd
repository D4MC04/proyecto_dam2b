class_name Navedex
extends Control
## Archivo del menú, dentro de la tablet de la oficina (MainMenu se acerca a ella y esto aparece encima):
## el terminal de frente con sus botones físicos NAVES / TORRETAS / Volver. En la pantalla, lo elegido
## manda: arriba la vitrina con su escena en vivo (NavedexShowcase), debajo nombre, descripción y stats
## con barra, y abajo un carrusel para elegir. Los que aún no han salido en una partida se ven en
## silueta y con "???".

signal back_pressed

const ENEMY_DIR: String = "res://resources/enemy_data/"
const ENEMY_FILES: Array[String] = [
	"dart_verde", "dart_rojo", "dart_morado", "dart_hielo", "wasp", "nave_normal",
	"nave_agresiva", "ariete", "acorazado", "nodriza", "reparadora",
	"espectro", "divisora", "fragmento_divisora_central",
	"saboteadora",
]
const TURRET_DIR: String = "res://resources/turret_data/"
# Solo las torretas base; sus mejoras se ven con las flechas junto al nombre.
const TURRET_FILES: Array[String] = [
	"turret", "minigun", "rocket_launcher", "cryo", "disintegrator", "rail", "tesla", "amplifier", "orbiter", "miner",
]
const TAB_ENEMIES: int = 0
const TAB_TURRETS: int = 1
const CELL_SCENE: PackedScene = preload("res://scenes/level_ui/EnemyCell.tscn")
const UNKNOWN_TEXT: String = "???"
# Carrusel: celdas a la vista (la del medio es la elegida) y su lado.
const CAROUSEL_CELLS: int = 5
const CELL_SIZE: int = 40
const ARROW_SIZE: int = 28
# Aumento del terminal dibujado y sus piezas en píxeles del terminal (como tablet.png, de frente).
# MainMenu acerca la oficina hasta ese aumento, así que queda encima de la tablet de la oficina.
const SCALE: int = 3
# Alto de la vitrina: mínimo en las naves y fijo en las torretas (cabe con la que más texto lleva).
const SHIP_SHOWCASE_MIN_HEIGHT: float = 112.0
const TURRET_SHOWCASE_HEIGHT: float = 112.0
const FRAME_SIZE: Vector2i = Vector2i(147, 178)
# Carcasa (con las esquinas de arriba a la izquierda y abajo a la derecha cortadas), asas y pantalla.
const BODY_RECT: Rect2i = Rect2i(8, 0, 131, 178)
const BODY_CUT: int = 8
const BODY_COLOR: Color = Color("#3a4256")
const HANDLES: Array[Rect2i] = [Rect2i(0, 54, 11, 70), Rect2i(136, 54, 11, 70)]
const SCREEN_RECT: Rect2i = Rect2i(15, 17, 117, 132)
# Pilotos encima de los botones físicos (centro en x) y fila de la tira de luz bajo la pantalla.
const BUTTON_LEDS: Array[int] = [32, 74, 115]
const LIGHT_STRIP_Y: int = 153
const BAR_HEIGHT: int = 3

@onready var tablet: Control = %Tablet
@onready var showcase: NavedexShowcase = %Showcase
@onready var spacer: Control = %Spacer
@onready var ships_button: Button = %ShipsButton
@onready var turrets_button: Button = %TurretsButton
@onready var fusion_label: Label = %FusionLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var stat_rows: GridContainer = %StatRows
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var carousel: HBoxContainer = %Carousel
@onready var carousel_prev: Button = %CarouselPrev
@onready var carousel_next: Button = %CarouselNext

# Lo de la pestaña abierta y cuál está elegido.
var _entries: Array[InspectableData] = []
var _selected: int = 0
var _cells: Array[EnemyCell] = []
# Cadena de versiones de la torreta mostrada (base, mejora...) y cuál se ve.
var _versions: Array[TurretData] = []
var _version_index: int = 0
# Valor más alto de cada stat entre los de la pestaña, para escalar las barras.
var _stat_max: Dictionary[String, float] = {}

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	var group: ButtonGroup = ButtonGroup.new()
	ships_button.button_group = group
	turrets_button.button_group = group
	ships_button.pressed.connect(_open_tab.bind(TAB_ENEMIES))
	turrets_button.pressed.connect(_open_tab.bind(TAB_TURRETS))
	tablet.resized.connect(queue_redraw)
	for button: Button in [ships_button, turrets_button, %VolverButton]:
		_style_physical(button)
	for button: Button in [prev_button, next_button, carousel_prev, carousel_next]:
		_style_arrow(button)
	prev_button.pressed.connect(_change_version.bind(-1))
	next_button.pressed.connect(_change_version.bind(1))
	carousel_prev.pressed.connect(_step.bind(-1))
	carousel_next.pressed.connect(_step.bind(1))
	# Las celdas del carrusel se crean una vez; al moverse solo cambia lo que enseñan.
	for i: int in CAROUSEL_CELLS:
		var cell: EnemyCell = CELL_SCENE.instantiate()
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.toggle_mode = true
		carousel.add_child(cell)
		carousel.move_child(cell, carousel_next.get_index())
		cell.count_label.hide()
		@warning_ignore("integer_division")
		cell.pressed.connect(_step.bind(i - CAROUSEL_CELLS / 2))
		_cells.append(cell)
	_open_tab(TAB_ENEMIES)
	visibility_changed.connect(_on_visibility_changed)

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		# Los pilotos de los botones siguen a la pestaña.
		queue_redraw()

# El terminal de frente, como tablet.png: asas, carcasa de metal con las esquinas cortadas y tornillos,
# pantalla con su aro, tira de luz y el piloto de cada botón (encendido el de la pestaña elegida).
# Los botones son ShipsButton, TurretsButton y VolverButton.
func _draw() -> void:
	draw_set_transform(tablet.position, 0.0, Vector2(SCALE, SCALE))
	for handle: Rect2i in HANDLES:
		OfficePaint.metal_box(self, handle)
		OfficePaint.rect(self, Rect2i(handle.position.x + (3 if handle.position.x == 0 else 5), handle.position.y + 4, 3, handle.size.y - 8), OfficePaint.OUTLINE)
	_cut_box(BODY_RECT, BODY_CUT, OfficePaint.OUTLINE)
	_cut_box(BODY_RECT.grow(-1), BODY_CUT - 1, OfficePaint.METAL)
	_cut_box(Rect2i(BODY_RECT.position + Vector2i(2, 2), BODY_RECT.size - Vector2i(3, 3)), BODY_CUT - 1, BODY_COLOR)
	for x: int in [BODY_RECT.position.x + 7, BODY_RECT.end.x - 10]:
		OfficePaint.screw(self, Vector2i(x, BODY_RECT.position.y + 6))
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

# Carga las naves o las torretas y elige la primera.
func _open_tab(tab: int) -> void:
	_entries.clear()
	_stat_max.clear()
	var enemies: bool = tab == TAB_ENEMIES
	# Naves: la vitrina crece con el hueco. Torretas: alto fijo y el hueco va entre los stats y el carrusel.
	showcase.custom_minimum_size.y = SHIP_SHOWCASE_MIN_HEIGHT if enemies else TURRET_SHOWCASE_HEIGHT
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL if enemies else Control.SIZE_FILL
	spacer.size_flags_vertical = Control.SIZE_FILL if enemies else Control.SIZE_EXPAND_FILL
	for file: String in (ENEMY_FILES if enemies else TURRET_FILES):
		var data: InspectableData = load((ENEMY_DIR if enemies else TURRET_DIR) + file + ".tres") as InspectableData
		_entries.append(data)
		_collect_stat_max(data)
	_select(0)

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
	if visible:
		_select(_selected)

# Mueve el carrusel `step` puestos (da la vuelta en los extremos).
func _step(step: int) -> void:
	_select(posmod(_selected + step, _entries.size()))

# Elige la entrada `index`: el carrusel la pone en medio y se enseña.
func _select(index: int) -> void:
	_selected = index
	for i: int in _cells.size():
		@warning_ignore("integer_division")
		var data: InspectableData = _entries[posmod(index + i - CAROUSEL_CELLS / 2, _entries.size())]
		var cell: EnemyCell = _cells[i]
		cell.setup(data, 0)
		cell.icon_rect.modulate = Color.WHITE if _is_known(data) else Color.BLACK
		@warning_ignore("integer_division")
		cell.set_pressed_no_signal(i == CAROUSEL_CELLS / 2)
	_versions.clear()
	_version_index = 0
	var turret: TurretData = _entries[index] as TurretData
	while turret != null:
		_versions.append(turret)
		turret = turret.fusion
	_show_entry(_entries[index])

# Las torretas siempre se conocen; las naves, solo si ya han salido en una partida.
func _is_known(data: InspectableData) -> bool:
	var enemy: EnemyData = data as EnemyData
	return enemy == null or GameState.has_seen_enemy(enemy)

# Pasa a la versión anterior (-1) o siguiente (+1) de la torreta.
func _change_version(step: int) -> void:
	_version_index = clampi(_version_index + step, 0, _versions.size() - 1)
	_show_entry(_versions[_version_index])

func _show_entry(data: InspectableData) -> void:
	var seen: bool = _is_known(data)
	var turret: TurretData = data as TurretData
	prev_button.disabled = turret == null or _version_index <= 0
	next_button.disabled = turret == null or _version_index >= _versions.size() - 1
	# Invisibles (no ocultas) en las naves para que el nombre no se mueva.
	prev_button.modulate.a = 1.0 if turret != null else 0.0
	next_button.modulate.a = 1.0 if turret != null else 0.0
	fusion_label.visible = turret != null and turret.fusion != null
	if fusion_label.visible:
		fusion_label.text = tr("NAVEDEX_UPGRADE") % turret.fusion.get_inspect_name().to_upper()
	showcase.show_data(data, seen)
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
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	# Dos columnas: el fondo alterno va por filas, no por stat.
	@warning_ignore("integer_division")
	box.add_child(StatRow.create(entry, index / 2))
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
