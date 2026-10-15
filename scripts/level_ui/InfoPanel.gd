extends PanelContainer
class_name InfoPanel
## Ficha de la barra izquierda. Enseña lo inspeccionado en LevelState (lo recibe por
## show_inspected) y pinta las filas que le dan, sin saber qué stats existen.

# Fuente a 8 px en 72 px de ancho: 9 caracteres por línea.
const NAME_MAX_CHARS := 9
const NAME_MAX_LINES := 2
# Frames que dura el parpadeo de escáner al cambiar de contenido.
const FLASH_FRAMES := 2

const NAME_COLOR := Color("#f0faff")
const TAG_BG_COLOR := Color("#0e1626")
const PAD_BG_COLOR := Color("#060b14")
const PAD_GRID_COLOR := Color("#14304a")
# Largo de cada brazo de las esquinas del marco del icono.
const PAD_CORNER := 4
const PAD_GRID_STEP := 4
const PAD_GRID_OFFSET := 2

@onready var idle_view: Control = %IdleView
@onready var detail_view: Control = %DetailView
@onready var icon_pad: Control = %IconPad
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var type_tag: PanelContainer = %TypeTag
@onready var type_label: Label = %TypeLabel
@onready var stat_scroll: ScrollContainer = %StatScroll
@onready var stat_rows: VBoxContainer = %StatRows
@onready var description_divider: Control = %DescriptionDivider
@onready var description_label: Label = %DescriptionLabel
@onready var scan_flash: Control = %ScanFlash

var _accent := Color.WHITE
var _flash_id := 0

func _ready() -> void:
	icon_pad.draw.connect(_draw_icon_pad)
	# Alto fijo de dos líneas para que la cabecera no cambie de tamaño entre fichas.
	name_label.text = "A\nA"
	name_label.custom_minimum_size.y = name_label.get_combined_minimum_size().y
	_show_idle()

## Enseña `data` en la ficha; con null vuelve al estado de reposo.
func show_inspected(data: Resource) -> void:
	var info := data as InspectableData
	if info != null:
		_show_detail(info.get_inspect_icon(), info.get_inspect_name(), info.get_inspect_tag(),
				info.get_inspect_accent(), info.get_stats(), info.get_inspect_description())
	else:
		_show_idle()
	_flash()

func _show_idle() -> void:
	detail_view.hide()
	idle_view.show()

func _show_detail(icon: Texture2D, title: String, tag: String, accent: Color,
		stats: Array[StatEntry], description: String) -> void:
	idle_view.hide()
	detail_view.show()
	_accent = accent
	icon_rect.texture = icon
	icon_pad.queue_redraw()
	# Sin pasar a mayúsculas: PressStart2P dibuja mal las mayúsculas con tilde (Ó, Á).
	name_label.text = _wrap_name(title)
	type_label.text = tag
	type_label.add_theme_color_override("font_color", accent)
	type_tag.add_theme_stylebox_override("panel", _make_tag_style(accent))

	for row in stat_rows.get_children():
		stat_rows.remove_child(row)
		row.queue_free()
	for i in stats.size():
		stat_rows.add_child(StatRow.create(stats[i], i))
	description_label.text = description
	description_label.visible = description != ""
	description_divider.visible = description != ""
	stat_scroll.scroll_vertical = 0

func _make_tag_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TAG_BG_COLOR.lerp(accent, 0.2)
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = accent.darkened(0.4)
	style.anti_aliasing = false
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

# Marco del icono: fondo oscuro con rejilla de puntos y esquinas en el color de acento.
func _draw_icon_pad() -> void:
	var size_i := Vector2i(icon_pad.size)
	icon_pad.draw_rect(Rect2(Vector2.ZERO, Vector2(size_i)), PAD_BG_COLOR)
	for x in range(PAD_GRID_OFFSET, size_i.x, PAD_GRID_STEP):
		for y in range(PAD_GRID_OFFSET, size_i.y, PAD_GRID_STEP):
			icon_pad.draw_rect(Rect2(x, y, 1, 1), PAD_GRID_COLOR)
	var right := size_i.x - 1
	var bottom := size_i.y - 1
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(right, 0), Vector2i(0, bottom), Vector2i(right, bottom)]:
		# Los brazos salen de la esquina hacia dentro.
		var x_start := corner.x if corner.x == 0 else corner.x - PAD_CORNER + 1
		var y_start := corner.y if corner.y == 0 else corner.y - PAD_CORNER + 1
		icon_pad.draw_rect(Rect2(x_start, corner.y, PAD_CORNER, 1), _accent)
		icon_pad.draw_rect(Rect2(corner.x, y_start, 1, PAD_CORNER), _accent)

# Parte el nombre por palabras en líneas de NAME_MAX_CHARS. Una palabra que no cabe
# en una línea se corta con guion. Si sobran líneas, se quedan las primeras.
func _wrap_name(text: String) -> String:
	var words := PackedStringArray()
	for word in text.split(" ", false):
		while word.length() > NAME_MAX_CHARS:
			words.append(word.left(NAME_MAX_CHARS - 1) + "-")
			word = word.substr(NAME_MAX_CHARS - 1)
		words.append(word)
	var lines := PackedStringArray()
	var line := ""
	for word in words:
		if line == "":
			line = word
		elif not line.ends_with("-") and line.length() + 1 + word.length() <= NAME_MAX_CHARS:
			line += " " + word
		else:
			lines.append(line)
			line = word
	if line != "":
		lines.append(line)
	return "\n".join(lines.slice(0, NAME_MAX_LINES))

# Parpadeo de escáner de unos frames sobre el contenido; el marco no se mueve.
func _flash() -> void:
	_flash_id += 1
	var id := _flash_id
	scan_flash.show()
	for i in FLASH_FRAMES:
		await get_tree().process_frame
	if id == _flash_id:
		scan_flash.hide()
