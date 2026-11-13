class_name MedalCase
extends OfficeObject

# Vitrina de condecoraciones de la pared derecha: no abre nada. La vitrina y su peana son
# parte de right_static.png. Aquí se ponen las medallas (una por logro de GameState.ACHIEVEMENTS, en
# filas de 3, 4 y 3 centradas y escalonadas medio paso), los reflejos del cristal encima y un
# destello de vez en cuando en las conseguidas. Cada medalla conseguida sale en el metal de su fase
# (AchievementTint): el disco, la anilla, el pasador y el símbolo; la cinta guarda su color. Las que faltan dejan el alfiler y una marca tenue. Solo
# las medallas se pueden mirar: con el ratón encima de una, los corchetes la marcan y una ficha
# junto a ella da su nombre, fase y descripción. En el resto de la vitrina no hay corchetes.

const MEDAL_DIR: String = "res://assets/sprites/office/medal_"
const GLASS: Texture2D = preload("res://assets/sprites/office/case_glass.png")
const EMPTY: Texture2D = preload("res://assets/sprites/office/medal_empty.png")
# Filas de la medalla (de la primera a la anterior a la segunda) con la cinta, que no cambia de color
# con la fase. Salen de build_medal() en gen_right.py.
const RIBBON_ROWS: Vector2i = Vector2i(7, 25)
# Cada cuánto (en segundos) destella una medalla y cuánto dura el destello.
const SPARKLE_PERIOD: float = 3.0
const SPARKLE_TIME: float = 0.36
# Ficha de la medalla señalada: ancho, margen interior, alto de línea y separación con la medalla.
const CARD_WIDTH: int = 230
const CARD_PAD: int = 12
const CARD_LINE: int = 14
const CARD_GAP: int = 4
# Separación extra entre el nombre y la descripción.
const CARD_TITLE_GAP: int = 3
const CARD_NAME_SIZE: int = 16
const CARD_TEXT_SIZE: int = 16
# Gris apagado del "???" de un logro sin conseguir.
const LOCKED_COLOR: Color = Color(0.5, 0.52, 0.58)

var _medals: Array[Texture2D] = []
var _hovered_medal: int = -1

func _ready() -> void:
	super()
	# La vitrina no es un botón: sin corchetes propios (los dibuja cada medalla) ni mano al pasar.
	show_brackets = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	for id: String in GameState.ACHIEVEMENTS:
		_medals.append(load(MEDAL_DIR + id + ".png"))

func _process(delta: float) -> void:
	super(delta)
	_hovered_medal = _medal_at(get_local_mouse_position()) if hovered else -1

func _draw_object() -> void:
	var ids: Array = GameState.ACHIEVEMENTS.keys()
	var positions: Array = OfficeLayout.RIGHT.medals
	for i: int in ids.size():
		var phase: int = GameState.get_phase(ids[i])
		var texture: Texture2D = EMPTY
		if phase != GameState.PHASE_NONE:
			texture = AchievementTint.tint(_medals[i], phase, RIBBON_ROWS)
		draw_texture(texture, _medal_rect(positions[i]).position)
	draw_texture(GLASS, Vector2i(-position))
	for i: int in ids.size():
		if GameState.get_phase(ids[i]) == GameState.PHASE_NONE:
			continue
		var phase: float = fmod(time * 0.7 + i * 0.37, SPARKLE_PERIOD)
		if phase < SPARKLE_TIME:
			var r: Rect2i = _medal_rect(positions[i])
			var disc_y: int = OfficeLayout.RIGHT.medal.disc_cy
			_sparkle(r.position + Vector2i((r.size.x >> 1) - 13, disc_y - 13), phase / SPARKLE_TIME)
	if _hovered_medal >= 0:
		_draw_hover()

# Corchetes de la medalla señalada y su ficha, por encima de todo lo demás.
func _draw_hover() -> void:
	var rect: Rect2i = _medal_rect(OfficeLayout.RIGHT.medals[_hovered_medal])
	OfficePaint.brackets(self, rect, OfficePaint.CYAN_LIGHT)
	_draw_card(rect, GameState.ACHIEVEMENTS.keys()[_hovered_medal])

# Ficha con el nombre, la fase (en su color) y la descripción con la meta que toca. Va debajo de la
# medalla, o encima si abajo no cabe, y se mantiene dentro de la vista.
func _draw_card(medal: Rect2i, id: String) -> void:
	var phase: int = GameState.get_phase(id)
	var lines: PackedStringArray = _wrap(GameState.achievement_description(id), CARD_WIDTH - CARD_PAD * 2)
	var height: int = CARD_PAD * 2 + CARD_TITLE_GAP + CARD_LINE * (1 + lines.size())
	@warning_ignore("integer_division")
	var x: int = clampi(medal.position.x + (medal.size.x - CARD_WIDTH) / 2,
			to_local_point(Vector2.ZERO).x + 8, to_local_point(Vector2(960, 0)).x - CARD_WIDTH - 8)
	var y: int = medal.end.y + CARD_GAP
	if y + height > to_local_point(Vector2(0, 506)).y:
		y = medal.position.y - CARD_GAP - height
	var box: Rect2i = Rect2i(x, y, CARD_WIDTH, height)
	OfficePaint.bevel_box(self, box, OfficePaint.SCREEN, OfficePaint.CYAN_DARK, OfficePaint.SCREEN_LINE)
	var at: Vector2i = box.position + Vector2i(CARD_PAD, CARD_PAD)
	# Nombre y fase en el color de la fase conseguida; sin ninguna, el nombre es "???" en gris apagado
	# y no hay fase. La descripción sale siempre.
	var owned: bool = phase != GameState.PHASE_NONE
	var phase_color: Color = GameState.PHASE_COLORS[phase] if owned else LOCKED_COLOR
	OfficePaint.text(self, at, tr(GameState.ACHIEVEMENTS[id][0]) if owned else "???", phase_color, CARD_NAME_SIZE)
	if owned:
		var phase_text: String = GameState.phase_name(phase).to_upper()
		OfficePaint.text(self, Vector2i(box.end.x - CARD_PAD - OfficePaint.text_width(phase_text, CARD_TEXT_SIZE), at.y),
				phase_text, phase_color, CARD_TEXT_SIZE)
	for i: int in lines.size():
		OfficePaint.text(self, at + Vector2i(0, CARD_TITLE_GAP + CARD_LINE * (i + 1)), lines[i], OfficePaint.METAL_SHINE, CARD_TEXT_SIZE)

# Parte `value` en líneas de como mucho `width` píxeles, por palabras.
func _wrap(value: String, width: int) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var current: String = ""
	for word: String in value.split(" "):
		var candidate: String = word if current.is_empty() else current + " " + word
		if current.is_empty() or OfficePaint.text_width(candidate, CARD_TEXT_SIZE) <= width:
			current = candidate
		else:
			lines.append(current)
			current = word
	lines.append(current)
	return lines

func _medal_rect(at: Array) -> Rect2i:
	var medal: Dictionary = OfficeLayout.RIGHT.medal
	var w: int = medal.w
	@warning_ignore("integer_division")
	return Rect2i(Vector2i(to_local_point(Vector2(at[0] - w / 2, at[1]))), Vector2i(w, medal.h))

# Medalla bajo `point` (local): el disco o la cinta; -1 si ninguna.
func _medal_at(point: Vector2) -> int:
	var medal: Dictionary = OfficeLayout.RIGHT.medal
	var positions: Array = OfficeLayout.RIGHT.medals
	for i: int in positions.size():
		var r: Rect2i = _medal_rect(positions[i])
		var disc: Vector2 = Vector2(r.position.x + r.size.x / 2.0, r.position.y + float(medal.disc_cy))
		var ribbon: Rect2 = Rect2(r.position.x + r.size.x / 2.0 - 12, r.position.y, 24, 28)
		if point.distance_to(disc) <= float(medal.r) or ribbon.has_point(point):
			return i
	return -1

# Destello de cuatro puntas que crece y se apaga (k de 0 a 1).
func _sparkle(at: Vector2i, k: float) -> void:
	var r: int = 1 + roundi((k if k < 0.5 else 1.0 - k) * 4.0)
	OfficePaint.rect(self, Rect2i(at.x - r, at.y, r * 2 + 1, 1), OfficePaint.CYAN_LIGHT)
	OfficePaint.rect(self, Rect2i(at.x, at.y - r, 1, r * 2 + 1), OfficePaint.CYAN_LIGHT)
	OfficePaint.rect(self, Rect2i(at, Vector2i.ONE), Color.WHITE)
