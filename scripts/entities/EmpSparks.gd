extends Node2D
class_name EmpSparks
# Lo que se ve sobre una torreta apagada por un pulso EMP: chispas azules en zigzag que saltan sin
# parar, todo en píxeles sin antialiasing.

const SPARK_COLORS: Array[Color] = [Color("#2a6ae6"), Color("#78bcff"), Color("#e6f6ff")]
const SPARK_COUNT: int = 4
# Las chispas caen dentro de la torreta (32x32, centrada) y asoman un poco por los bordes.
const HALF_SIZE: int = 14
# Largo de cada zigzag (px), que baja desde donde empieza.
const SPARK_LENGTH_MIN: int = 4
const SPARK_LENGTH_MAX: int = 7

func _ready() -> void:
	z_index = 1

func _process(_delta: float) -> void:
	# Cada frame las chispas cambian de sitio.
	queue_redraw()

func _draw() -> void:
	for i: int in SPARK_COUNT:
		var length: int = randi_range(SPARK_LENGTH_MIN, SPARK_LENGTH_MAX)
		# El zigzag baja: empieza más arriba cuanto más largo, para que todo quede centrado en la torreta.
		var point: Vector2 = Vector2(randi_range(-HALF_SIZE, HALF_SIZE - 1), randi_range(-HALF_SIZE, HALF_SIZE - length))
		var side: int = 1 if randi() % 2 else -1
		var color: Color = SPARK_COLORS.pick_random()
		for step: int in length:
			draw_rect(Rect2(point, Vector2.ONE), color)
			point += Vector2(side if step % 2 else -side, 1)
