extends AnimatedSprite2D

# Alien decorativo del menú: cruza la pantalla despacio girando sobre sí mismo.
# Cada cruce elige una ruta nueva al azar por una franja lateral (arriba, abajo,
# izquierda o derecha) para no pasar por encima del título ni de los botones.

const SPEED = 22.0       # px/s, lento y constante
const SPIN_SPEED = 0.8   # rad/s, giro continuo
const MARGIN = 12.0      # cuánto sale fuera de pantalla antes de reaparecer
# ponytail: franjas fijas a mano según dónde cae la Caja del menú; si se mueve el título, ajustar aquí
const BAND_TOP = Vector2(10, 80)
const BAND_BOTTOM = Vector2(195, 262)
const BAND_LEFT = Vector2(10, 130)
const BAND_RIGHT = Vector2(350, 470)

var viewport_size: Vector2
var rng = RandomNumberGenerator.new()
var dir: Vector2

func _ready():
	viewport_size = get_viewport_rect().size
	rng.randomize()
	animation = "walk_down"  # frontal, mirando a la pantalla
	frame = 0
	stop()
	_new_route()

func _process(delta):
	position += dir * SPEED * delta
	rotation += SPIN_SPEED * delta
	if position.x < -MARGIN or position.x > viewport_size.x + MARGIN \
			or position.y < -MARGIN or position.y > viewport_size.y + MARGIN:
		_new_route()

func _new_route():
	var start: Vector2
	var end: Vector2
	if rng.randf() < 0.5:
		# Horizontal: entra por un lado y sale por el otro, dentro de la franja de arriba o abajo
		var band = BAND_TOP if rng.randf() < 0.5 else BAND_BOTTOM
		start = Vector2(-MARGIN, rng.randf_range(band.x, band.y))
		end = Vector2(viewport_size.x + MARGIN, rng.randf_range(band.x, band.y))
	else:
		# Vertical: de arriba abajo dentro de la franja izquierda o derecha
		var band = BAND_LEFT if rng.randf() < 0.5 else BAND_RIGHT
		start = Vector2(rng.randf_range(band.x, band.y), -MARGIN)
		end = Vector2(rng.randf_range(band.x, band.y), viewport_size.y + MARGIN)
	if rng.randf() < 0.5:
		var tmp = start
		start = end
		end = tmp
	dir = (end - start).normalized()
	position = start + dir  # un paso dentro para no disparar el reinicio en el primer frame
