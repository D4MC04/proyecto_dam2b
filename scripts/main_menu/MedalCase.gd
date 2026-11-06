class_name MedalCase
extends OfficeObject

# Vitrina de condecoraciones de la pared derecha: abre la lista de logros. La vitrina y su peana son
# parte de right_static.png. Aquí se ponen las medallas (una por logro de GameState.ACHIEVEMENTS, en
# filas de 5, 4 y 3 centradas y escalonadas medio paso), los reflejos del cristal encima y un
# destello de vez en cuando en las conseguidas. Las que faltan dejan el alfiler y una marca tenue. Con
# el ratón encima de una medalla, los corchetes la marcan a ella; si no, a toda la vitrina.

const MEDAL_DIR: String = "res://assets/sprites/office/medal_"
const GLASS: Texture2D = preload("res://assets/sprites/office/case_glass.png")
const EMPTY: Texture2D = preload("res://assets/sprites/office/medal_empty.png")
# Cada cuánto (en segundos) destella una medalla y cuánto dura el destello.
const SPARKLE_PERIOD: float = 3.0
const SPARKLE_TIME: float = 0.36

var _medals: Array[Texture2D] = []
var _hovered_medal: int = -1

func _ready() -> void:
	super()
	for id: String in GameState.ACHIEVEMENTS:
		_medals.append(load(MEDAL_DIR + id + ".png"))

func _process(delta: float) -> void:
	super(delta)
	_hovered_medal = _medal_at(get_local_mouse_position()) if hovered else -1

func _draw_object() -> void:
	var ids: Array = GameState.ACHIEVEMENTS.keys()
	var positions: Array = OfficeLayout.RIGHT.medals
	for i: int in ids.size():
		var texture: Texture2D = _medals[i] if ids[i] in GameState.unlocked else EMPTY
		draw_texture(texture, _medal_rect(positions[i]).position)
	draw_texture(GLASS, Vector2i(-position))
	for i: int in ids.size():
		if not ids[i] in GameState.unlocked:
			continue
		var phase: float = fmod(time * 0.7 + i * 0.37, SPARKLE_PERIOD)
		if phase < SPARKLE_TIME:
			var r: Rect2i = _medal_rect(positions[i])
			var disc_y: int = OfficeLayout.RIGHT.medal.disc_cy
			_sparkle(r.position + Vector2i((r.size.x >> 1) - 13, disc_y - 13), phase / SPARKLE_TIME)

func hover_rect() -> Rect2i:
	if _hovered_medal >= 0:
		return _medal_rect(OfficeLayout.RIGHT.medals[_hovered_medal])
	return super()

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
