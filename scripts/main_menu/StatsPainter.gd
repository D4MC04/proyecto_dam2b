class_name StatsPainter
extends RefCounted

# Lo que enseña la pantalla del monitor de stats, igual de lejos (CombatScoreboard, a escala 1 / 1,5)
# que de cerca (StatsCloseUp, a escala 1): así el zoom pasa de uno a otro sin que cambie nada. Se pinta
# en un lienzo de SIZE (la pantalla de cerca) con los datos reales de GameState: la cabecera con una
# regla, ocho cifras en dos columnas, las barras de todas las torretas base de más a menos construidas
# (su número encima y debajo la torreta en reposo, animada), el anillo con el reparto por tipo de ataque,
# su total y su leyenda, y "Volver". Tras refresh() todo sube desde cero en GROW_TIME y se queda quieto.

const SIZE: Vector2i = Vector2i(504, 399)
const CHART_BG: Color = Color("#0a1828")
## Colores del anillo y su leyenda, en orden.
const RING_COLORS: Array[Color] = [OfficePaint.CYAN, OfficePaint.AMBER, OfficePaint.RED, OfficePaint.GREEN]
## Tipos de ataque con su porción en el anillo; el resto se junta en "otros".
const RING_TYPES: int = 3
## Segundos que tardan los gráficos en subir hasta su valor.
const GROW_TIME: float = 1.2
const PAD: int = 12
const LINE_HEIGHT: int = 16
const COLUMN_WIDTH: int = 240
# Gráfico de barras: caja, hueco de cada torreta, ancho y alto máximo de barra.
const BARS_RECT: Rect2i = Rect2i(PAD, 110, 320, 237)
const BAR_STEP: int = 31
const BAR_WIDTH: int = 14
const BAR_MAX: int = 160
## Alto de la fila de torretas bajo las barras.
const TURRET_ROW: int = 32
# Anillo y su leyenda, a la derecha de las barras.
const RING_RECT: Rect2i = Rect2i(344, 110, 148, 237)
const RING_INNER: int = 26
const RING_OUTER: int = 40
# Botón "Volver".
const BACK_SIZE: Vector2i = Vector2i(160, 28)
@warning_ignore("integer_division")
const BACK_RECT: Rect2i = Rect2i((SIZE.x - BACK_SIZE.x) / 2, SIZE.y - PAD - BACK_SIZE.y, BACK_SIZE.x, BACK_SIZE.y)

## Segundos desde el último refresh().
var time: float = 0.0
## Torreta de las barras bajo el ratón (-1 ninguna) y si está encima de "Volver" (solo de cerca).
var hovered_bar: int = -1
var back_hovered: bool = false
var turrets: Array[Dictionary] = []
var _types: Array[Dictionary] = []
var _lines: Array[String] = []

func _init() -> void:
	refresh()

## Torretas base con las veces que se han construido (stats.built_<torreta>), de más a menos:
## [{data: TurretData, count: int}].
static func built_turrets() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i: int in Navedex.TURRET_FILES.size():
		var file: String = Navedex.TURRET_FILES[i]
		list.append({"data": load(Navedex.TURRET_DIR + file + ".tres"), "count": GameState.stats.get("built_" + file, 0), "order": i})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.count > b.count or (a.count == b.count and a.order < b.order))
	return list

## Reparto de lo construido por tipo de ataque, de más a menos: los RING_TYPES primeros y el resto en
## "otros" (STATS_OTHER). [{label: clave de traducción, count: int}], sin los tipos que no tienen ninguna.
static func built_by_type(list: Array[Dictionary]) -> Array[Dictionary]:
	var counts: Dictionary[String, int] = {}
	for turret: Dictionary in list:
		var label: String = (turret.data as TurretData).get_attack_label()
		counts[label] = counts.get(label, 0) + turret.count
	var types: Array[Dictionary] = []
	for label: String in counts:
		if counts[label] > 0:
			types.append({"label": label, "count": counts[label]})
	types.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.count > b.count)
	if types.size() > RING_TYPES + 1:
		var rest: int = 0
		for type: Dictionary in types.slice(RING_TYPES):
			rest += type.count
		types = types.slice(0, RING_TYPES)
		types.append({"label": "STATS_OTHER", "count": rest})
	return types

## Vuelve a leer GameState y los gráficos suben otra vez desde cero.
@warning_ignore("integer_division")
func refresh() -> void:
	time = 0.0
	turrets = built_turrets()
	_types = built_by_type(turrets)
	var stats: Dictionary = GameState.stats
	var seconds: int = int(GameState.play_time)
	var favorite: String = GameState.favorite_turret()
	var turret_name: String = "-"
	if favorite != "":
		turret_name = (load(Navedex.TURRET_DIR + favorite + ".tres") as TurretData).get_inspect_name()
	# Dos columnas: primero la de la izquierda, de arriba abajo.
	_lines = [
		TranslationServer.translate("STATS_KILLS") % stats.get("kills", 0),
		TranslationServer.translate("STATS_WINS") % stats.get("wins", 0),
		TranslationServer.translate("STATS_TURRETS") % stats.get("turrets", 0),
		TranslationServer.translate("STATS_PERFECT_WAVES") % stats.get("perfect_waves", 0),
		TranslationServer.translate("STATS_SPENT") % UiFormat.money(stats.get("spent", 0)),
		TranslationServer.translate("STATS_TIME") % [seconds / 3600, seconds % 3600 / 60],
		TranslationServer.translate("STATS_FAVORITE") % turret_name,
		TranslationServer.translate("STATS_POWERS") % stats.get("powers", 0),
	]

## Torreta de las barras en el punto `point` del lienzo; -1 si ninguna.
func bar_at(point: Vector2i) -> int:
	var bars: Rect2i = BARS_RECT.grow(-4)
	if not bars.has_point(point):
		return -1
	@warning_ignore("integer_division")
	return mini((point.x - bars.position.x) / BAR_STEP, turrets.size() - 1)

## Pinta el contenido en `item`, que ya tiene puesta la transformación del lienzo.
func draw(item: CanvasItem) -> void:
	var grow: float = 1.0 - pow(1.0 - clampf(time / GROW_TIME, 0.0, 1.0), 3.0)
	OfficePaint.text(item, Vector2i(PAD, 8), "// " + TranslationServer.translate("HEADER_STATS"), OfficePaint.CYAN)
	var width: int = SIZE.x - PAD * 2
	OfficePaint.rect(item, Rect2i(PAD, 24, width, 2), OfficePaint.CYAN_DARK)
	for x: int in range(0, width, 8):
		OfficePaint.rect(item, Rect2i(PAD + x, 26, 2, 4 if x % 32 == 0 else 2), OfficePaint.CYAN_DARK)
	for i: int in _lines.size():
		@warning_ignore("integer_division")
		OfficePaint.text(item, Vector2i(PAD + (i / 4) * COLUMN_WIDTH, 38 + (i % 4) * LINE_HEIGHT), _lines[i], OfficePaint.CYAN_LIGHT)
	_draw_bars(item, grow)
	_draw_ring(item, grow)
	_draw_back(item)

# Barras normalizadas a la más alta. Arriba el título, o el nombre y las construidas de la que está bajo el ratón.
func _draw_bars(item: CanvasItem, grow: float) -> void:
	var box: Rect2i = BARS_RECT
	OfficePaint.rect(item, box, CHART_BG)
	var base: int = box.end.y - TURRET_ROW - 6
	OfficePaint.rect(item, Rect2i(box.position.x, base, box.size.x, 2), OfficePaint.CYAN_DARK)
	var title: String = TranslationServer.translate("STATS_BUILT")
	if hovered_bar >= 0:
		var hovered: Dictionary = turrets[hovered_bar]
		title = "%s: %d" % [(hovered.data as TurretData).get_inspect_name(), hovered.count]
	OfficePaint.text(item, Vector2i(box.position.x + 6, box.position.y + 4), title, OfficePaint.CYAN)
	var best: int = maxi(turrets[0].count, 1)
	for i: int in turrets.size():
		var x: int = box.position.x + 4 + i * BAR_STEP
		@warning_ignore("integer_division")
		var center: int = x + BAR_STEP / 2
		var count: int = turrets[i].count
		var height: int = roundi(float(count) / best * BAR_MAX * grow)
		var lit: bool = i == hovered_bar
		if height > 0:
			@warning_ignore("integer_division")
			var bar: Rect2i = Rect2i(center - BAR_WIDTH / 2, base - height, BAR_WIDTH, height)
			OfficePaint.rect(item, bar, OfficePaint.CYAN if lit else OfficePaint.CYAN_DARK)
			OfficePaint.rect(item, Rect2i(bar.position, Vector2i(BAR_WIDTH, 2)), OfficePaint.CYAN_LIGHT if lit else OfficePaint.CYAN)
		OfficePaint.text_centered(item, center, base - height - 14, UiFormat.abbreviate(roundi(count * grow)),
				OfficePaint.CYAN_LIGHT if lit else OfficePaint.CYAN)
		var data: TurretData = turrets[i].data
		var tint: Color = Color.WHITE if count > 0 or lit else Color(1, 1, 1, 0.35)
		@warning_ignore("integer_division")
		var at: Vector2 = Vector2(center, base + 4 + TURRET_ROW / 2)
		for frames: SpriteFrames in [data.sprite_frames, data.cannon]:
			var texture: Texture2D = _idle_frame(frames)
			if texture:
				item.draw_texture(texture, (at - texture.get_size() / 2.0).floor(), tint)

# Anillo que gira despacio con el reparto por tipo, el total en medio y la leyenda con nombre y número.
func _draw_ring(item: CanvasItem, grow: float) -> void:
	var box: Rect2i = RING_RECT
	OfficePaint.rect(item, box, CHART_BG)
	var cx: int = box.get_center().x
	OfficePaint.text_centered(item, cx, box.position.y + 4, TranslationServer.translate("STATS_BY_TYPE"), OfficePaint.CYAN)
	var center: Vector2i = Vector2i(cx, box.position.y + 88)
	var total: int = 0
	for type: Dictionary in _types:
		total += type.count
	# Sin datos, un anillo apagado entero.
	var parts: Array[float] = [1.0]
	var colors: Array[Color] = [OfficePaint.SCREEN_LINE]
	if total > 0:
		parts.clear()
		colors.clear()
		for i: int in _types.size():
			parts.append(float(_types[i].count) / total * grow)
			colors.append(RING_COLORS[i])
	var gap: float = 0.08 if parts.size() > 1 else 0.0
	var step: float = 0.5 / RING_OUTER
	var start: float = time * 0.3
	for i: int in parts.size():
		var end: float = start + parts[i] * TAU
		var a: float = start
		while a < end - gap:
			for r: int in range(RING_INNER, RING_OUTER):
				OfficePaint.rect(item, Rect2i(center.x + roundi(cos(a) * r), center.y + roundi(sin(a) * r), 1, 1), colors[i])
			a += step
		start = end
	OfficePaint.text_centered(item, cx, center.y - 7, UiFormat.abbreviate(roundi(total * grow)), OfficePaint.CYAN_LIGHT)
	var right: int = box.end.x - 8
	for i: int in _types.size():
		var y: int = box.position.y + 156 + i * 16
		OfficePaint.rect(item, Rect2i(box.position.x + 8, y + 3, 7, 7), RING_COLORS[i])
		OfficePaint.text(item, Vector2i(box.position.x + 20, y), TranslationServer.translate(_types[i].label), OfficePaint.CYAN_LIGHT)
		var count: String = UiFormat.abbreviate(roundi(_types[i].count * grow))
		OfficePaint.text(item, Vector2i(right - OfficePaint.text_width(count), y), count, RING_COLORS[i])

# Frame de la animación "default" (la de reposo, como en el mapa) que toca ahora; null si no hay.
func _idle_frame(frames: SpriteFrames) -> Texture2D:
	if frames == null or not frames.has_animation(&"default"):
		return null
	var count: int = frames.get_frame_count(&"default")
	var speed: float = frames.get_animation_speed(&"default")
	return frames.get_frame_texture(&"default", int(time * speed) % count if speed > 0.0 else 0)

# "Volver" como ScreenButton: solo el contorno, con un relleno tenue al pasar el ratón.
func _draw_back(item: CanvasItem) -> void:
	var r: Rect2i = BACK_RECT
	if back_hovered:
		OfficePaint.rect(item, r, Color(OfficePaint.CYAN, 0.15))
	item.draw_rect(Rect2(r).grow(-0.5), OfficePaint.CYAN if back_hovered else OfficePaint.CYAN_DARK, false, 1.0)
	@warning_ignore("integer_division")
	OfficePaint.text_centered(item, r.get_center().x, r.position.y + (r.size.y - OfficePaint.TEXT_HEIGHT) / 2,
			TranslationServer.translate("BTN_BACK"), OfficePaint.CYAN_LIGHT if back_hovered else OfficePaint.CYAN)
