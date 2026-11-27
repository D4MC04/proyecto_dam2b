class_name CombatScoreboard
extends OfficeObject

# Pantalla de stats de la pared izquierda: al pulsarla, MainMenu se acerca a ella y aparece de cerca
# (StatsCloseUp). El monitor es parte de left_static.png; aquí se pinta la pantalla, que enseña lo mismo
# que la de cerca (StatsPainter) a escala 1 / StatsCloseUp.BODY_SCALE, para que el zoom encaje. Cada vez
# que la pantalla entra en la vista los datos se vuelven a leer y los gráficos suben desde cero.

var _screen: Rect2i
## Lo que se pinta en la pantalla; StatsCloseUp pinta este mismo (mismos datos y momento de la animación).
var painter: StatsPainter = StatsPainter.new()

func _ready() -> void:
	super()
	var s: Array = OfficeLayout.LEFT.stats.screen
	_screen = Rect2i(Vector2i(to_local_point(Vector2(s[0], s[1]))), Vector2i(s[2], s[3]))

func _process(delta: float) -> void:
	super(delta)
	painter.time += delta
	# Mientras no se ve, se van releyendo los datos y la subida vuelve a empezar.
	if not get_viewport_rect().intersects(get_global_rect()):
		painter.refresh()

func _draw_object() -> void:
	for y: int in range(_screen.position.y + 1, _screen.end.y, 2):
		OfficePaint.rect(self, Rect2i(_screen.position.x, y, _screen.size.x, 1), OfficePaint.SCREEN_DARK)
	draw_set_transform(Vector2(_screen.position), 0.0, Vector2.ONE / StatsCloseUp.BODY_SCALE)
	painter.draw(self)
	draw_set_transform(Vector2.ZERO)
