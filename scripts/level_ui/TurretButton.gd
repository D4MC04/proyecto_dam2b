extends Button
class_name TurretButton

## Petición de cambio de selección: on = seleccionar esta torreta, !on = soltarla.
signal selection_changed(data: TurretData, on: bool)
## Petición de enseñar esta torreta en la ficha (clic derecho o izquierdo, se pueda pagar o no).
signal inspect_requested(data: TurretData)

const BORDER_COLOR := Color("#1c7496")
const HOVER_BORDER_COLOR := Color("#40e0f0")
const BG_COLOR := Color("#0e1626")
const HOVER_BG_COLOR := Color("#16243c")
const SELECTED_COLOR := Color("#ecb23c")
const SELECTED_HOVER_BORDER_COLOR := Color("#ffe082")
const UNAFFORDABLE_COST_COLOR := Color("#ff3c5a")
const AFFORDABLE_COST_COLOR := Color("#ecb23c")
const UNAFFORDABLE_ICON_COLOR := Color(1, 1, 1, 0.35)
# Torreta aún sin desbloquear: plano oculto, sin icono ni coste. Caja más apagada que la normal,
# rejilla de puntos, silueta rayada de una torreta (octógono, igual en todas) con contorno
# punteado, centrada en el botón, y un candado en su centro.
const LOCKED_BG_COLOR := Color("#0a1220")
const LOCKED_BORDER_COLOR := Color("#1c4a60")
const LOCKED_GRID_COLOR := Color("#16283c")
const LOCKED_GRID_STEP := 4
# Misma forma que la base de las torretas (30x30, 9 px recortados en cada esquina). Tamaño par
# como el botón, para que la silueta y el candado queden centrados al píxel.
const LOCKED_SILHOUETTE_SIZE := Vector2i(30, 30)
const LOCKED_SILHOUETTE_CUT := 9
# Filas pares e impares de la silueta.
const LOCKED_SILHOUETTE_COLORS: Array[Color] = [Color("#122a40"), Color("#0e2034")]
const LOCKED_OUTLINE_COLOR := Color("#2a6a88")
# Candado en píxeles: 1 = contorno, 2 = cuerpo, 3 = brillo, 4 = ojo de cerradura, 5 = sombra.
const LOCK_PIXELS: PackedStringArray = [
	"..111111..",
	".1......1.",
	".1......1.",
	".1......1.",
	"1111111111",
	"1333333331",
	"1224444221",
	"1222442221",
	"1222442221",
	"1222222221",
	"1555555551",
	"1111111111",
]
const LOCK_COLORS := {
	"1": HOVER_BORDER_COLOR,
	"2": Color("#1c5d6d"),
	"3": Color("#befaff"),
	"4": Color("#0a1018"),
	"5": Color("#144252"),
}
# Largo de cada brazo de los corchetes que rodean la torreta seleccionada por fuera.
const BRACKET_LENGTH := 4

@onready var icon_rect: Control = %IconRect
@onready var base_sprite: AnimatedSprite2D = %BaseSprite
@onready var cannon_sprite: AnimatedSprite2D = %CannonSprite
@onready var cost_label: Label = %CostLabel

var data: TurretData
var _money := 0
var _selected := false
var _affordable := true
# Con una pantalla abierta el clic izquierdo solo enseña la ficha: no selecciona ni suelta.
var _selection_locked := false
# Torreta sin desbloquear en este nivel: no se compra, no se selecciona y no enseña ficha.
var _locked := false

# Plano oculto ya pintado, por tamaño de botón: es el mismo en todas las bloqueadas.
static var _locked_textures: Dictionary[Vector2i, ImageTexture] = {}

func _ready() -> void:
	pressed.connect(_on_pressed)
	icon_rect.resized.connect(_center_sprites)
	_center_sprites()

func setup(turret_data: TurretData, money: int, locked := false) -> void:
	data = turret_data
	_locked = locked
	_setup_sprites()
	cost_label.text = "" if locked else UiFormat.money(data.cost)
	set_money(money)

# Torreta en reposo mirando hacia arriba, como en el mapa: base y cañón en bucle.
# Sin cañón o sin animación se queda en el primer frame.
func _setup_sprites() -> void:
	base_sprite.sprite_frames = data.sprite_frames
	cannon_sprite.sprite_frames = data.cannon
	_play_idle(base_sprite)
	_play_idle(cannon_sprite)

# IconRect ocupa todo el ancho del botón: los sprites van en su centro.
func _center_sprites() -> void:
	base_sprite.position = (icon_rect.size / 2.0).floor()
	cannon_sprite.position = base_sprite.position

func _play_idle(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames == null:
		return
	for animation: StringName in [&"default", &"spin"]:
		if sprite.sprite_frames.has_animation(animation):
			sprite.play(animation)
			return

func set_money(amount: int) -> void:
	_money = amount
	if data == null:
		return
	if _locked:
		_refresh()
		return
	_affordable = _money >= data.cost
	if not _affordable and _selected and not _selection_locked:
		# Ya no te llega: se pide soltarla. LevelState confirma con show_selected.
		selection_changed.emit(data, false)
	_refresh()

## Bloquea o desbloquea la selección con el clic izquierdo; la ficha sigue funcionando.
func set_selection_locked(locked: bool) -> void:
	_selection_locked = locked
	if not locked and _selected and not _affordable:
		# Se quedó sin dinero mientras estaba bloqueada: se pide soltarla.
		selection_changed.emit(data, false)

## Refleja la selección de LevelState; no emite nada.
func set_selected(on: bool) -> void:
	_selected = on
	_refresh()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if _locked:
		accept_event()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(data)
		accept_event()

func _on_pressed() -> void:
	if _locked:
		return
	# Solo el clic izquierdo llega aquí; el derecho se recoge en _gui_input.
	inspect_requested.emit(data)
	if _selection_locked or not _affordable:
		return
	selection_changed.emit(data, not _selected)

# Corchetes en L en ámbar justo por fuera de las cuatro esquinas de la torreta seleccionada.
func _draw() -> void:
	if _locked:
		draw_texture(_get_locked_texture(Vector2i(size)), Vector2.ZERO)
		return
	if not _selected:
		return
	var left := -1
	var top := -1
	var right := int(size.x)
	var bottom := int(size.y)
	for corner: Vector2i in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		# Los brazos salen de la esquina hacia el centro del botón.
		var x_start := corner.x if corner.x == left else corner.x - BRACKET_LENGTH + 1
		var y_start := corner.y if corner.y == top else corner.y - BRACKET_LENGTH + 1
		draw_rect(Rect2(x_start, corner.y, BRACKET_LENGTH, 1), SELECTED_COLOR)
		draw_rect(Rect2(corner.x, y_start, 1, BRACKET_LENGTH), SELECTED_COLOR)

static func _get_locked_texture(box_size: Vector2i) -> ImageTexture:
	if not _locked_textures.has(box_size):
		_locked_textures[box_size] = ImageTexture.create_from_image(_build_locked_image(box_size))
	return _locked_textures[box_size]

# Rejilla, silueta, contorno y candado en una imagen transparente que se pinta sobre la caja;
# todo dentro de la caja recortada.
static func _build_locked_image(box_size: Vector2i) -> Image:
	var image := Image.create_empty(box_size.x, box_size.y, false, Image.FORMAT_RGBA8)
	var bounds := Rect2i(Vector2i.ZERO, box_size)
	var silhouette := Rect2i((box_size - LOCKED_SILHOUETTE_SIZE) / 2, LOCKED_SILHOUETTE_SIZE)
	for y in box_size.y:
		for x in box_size.x:
			if not _inside_box(bounds, x, y):
				continue
			if _in_silhouette(silhouette, x, y):
				image.set_pixel(x, y, LOCKED_SILHOUETTE_COLORS[y % 2])
			elif _touches_silhouette(silhouette, x, y) and _is_outline_dot(silhouette, box_size, x, y):
				image.set_pixel(x, y, LOCKED_OUTLINE_COLOR)
			elif x % LOCKED_GRID_STEP == 1 and y % LOCKED_GRID_STEP == 1:
				image.set_pixel(x, y, LOCKED_GRID_COLOR)
	_draw_lock_pixels(image, box_size)
	return image

# Octógono: el rectángulo con las cuatro esquinas recortadas en diagonal.
static func _in_silhouette(rect: Rect2i, x: int, y: int) -> bool:
	if not rect.has_point(Vector2i(x, y)):
		return false
	var from_side := mini(x - rect.position.x, rect.end.x - 1 - x)
	var from_top := mini(y - rect.position.y, rect.end.y - 1 - y)
	return from_side + from_top >= LOCKED_SILHOUETTE_CUT

# Píxel fuera de la silueta pegado a ella por un lado (no en diagonal): forma el contorno.
static func _touches_silhouette(rect: Rect2i, x: int, y: int) -> bool:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _in_silhouette(rect, x + step.x, y + step.y):
			return true
	return false

# Punteado del contorno, simétrico en los dos ejes. En los tramos rectos, un píxel sí y otro no,
# contando desde el borde más cercano del botón; en las diagonales, todos (la escalera de
# píxeles que solo se tocan por la esquina ya se ve punteada).
static func _is_outline_dot(rect: Rect2i, box_size: Vector2i, x: int, y: int) -> bool:
	var on_side := x < rect.position.x or x >= rect.end.x
	var on_top_or_bottom := y < rect.position.y or y >= rect.end.y
	if not on_side and not on_top_or_bottom:
		return true
	var count := mini(y, box_size.y - 1 - y) if on_side else mini(x, box_size.x - 1 - x)
	return count % 2 == 0

# Dentro del interior de la caja recortada (sin el borde de 1 px).
static func _inside_box(bounds: Rect2i, x: int, y: int) -> bool:
	if y < 1 or y >= bounds.end.y - 1:
		return false
	var span := ClippedBoxStyle.row_span(bounds, ClippedBoxStyle.BUTTON_CLIP, y)
	return x > span.x and x < span.y - 1

# Candado en el centro de la caja, con un halo de 1 px del color de fondo para que se lea
# sobre la silueta.
static func _draw_lock_pixels(image: Image, box_size: Vector2i) -> void:
	var lock_size := Vector2i(LOCK_PIXELS[0].length(), LOCK_PIXELS.size())
	var origin := (box_size - lock_size) / 2
	for y in lock_size.y:
		for x in lock_size.x:
			if LOCK_PIXELS[y][x] == ".":
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					image.set_pixelv(origin + Vector2i(x + dx, y + dy), LOCKED_BG_COLOR)
	for y in lock_size.y:
		for x in lock_size.x:
			var key := LOCK_PIXELS[y][x]
			if key != ".":
				image.set_pixelv(origin + Vector2i(x, y), LOCK_COLORS[key])

func _refresh() -> void:
	if data == null:
		return
	if _locked:
		var locked_style := ClippedBoxStyle.create(LOCKED_BG_COLOR, LOCKED_BORDER_COLOR)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(state, locked_style)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		icon_rect.modulate = Color.TRANSPARENT   # oculto sin quitarle el hueco al layout
		queue_redraw()
		return
	var normal := ClippedBoxStyle.create(BG_COLOR, BORDER_COLOR)
	var hover := ClippedBoxStyle.create(HOVER_BG_COLOR, HOVER_BORDER_COLOR)
	var selected := ClippedBoxStyle.create(BG_COLOR.lerp(SELECTED_COLOR, 0.25), SELECTED_COLOR)
	var selected_hover := ClippedBoxStyle.create(BG_COLOR.lerp(SELECTED_COLOR, 0.4), SELECTED_HOVER_BORDER_COLOR)
	var empty := StyleBoxEmpty.new()
	if _selected:
		normal = selected
		hover = selected_hover
	elif not _affordable:
		hover = normal   # sin resalte: no se puede comprar
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("disabled", normal)
	add_theme_stylebox_override("focus", empty)
	icon_rect.modulate = Color.WHITE if _affordable else UNAFFORDABLE_ICON_COLOR
	var cost_color := AFFORDABLE_COST_COLOR if _affordable else UNAFFORDABLE_COST_COLOR
	cost_label.add_theme_color_override("font_color", cost_color)
