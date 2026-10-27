extends Node2D
class_name AmpMark
# Marca de torreta amplificada (va como hija suya): un chevrón ámbar de 5x4 px con contorno, en la
# esquina de arriba a la derecha, que la base octogonal deja libre.

const OUTLINE := Color("#0c0e16")
const AMBER: PackedColorArray = [Color("#96641e"), Color("#ecb23c"), Color("#ffe082")]
# Esquina de arriba a la izquierda del dibujo (con el contorno) respecto al centro de la torreta.
const ORIGIN := Vector2i(9, -16)
# "." vacío y "a" a "c" ámbar de oscuro a claro; el contorno se añade alrededor.
const SHAPE: Array[String] = [
	"..c..",
	".cbc.",
	"cb.bc",
	"a...a",
]

func _ready() -> void:
	# Por encima de las torretas vecinas.
	z_index = 1

func _draw() -> void:
	var filled := {}
	for y in SHAPE.size():
		for x in SHAPE[y].length():
			var symbol := SHAPE[y][x]
			if symbol != ".":
				filled[Vector2i(x, y)] = AMBER["abc".find(symbol)]
	# Contorno de 1 px en cruz alrededor del relleno.
	for pixel: Vector2i in filled:
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor := pixel + offset
			if not filled.has(neighbor):
				draw_rect(Rect2(Vector2(ORIGIN + neighbor + Vector2i.ONE), Vector2.ONE), OUTLINE)
	for pixel: Vector2i in filled:
		draw_rect(Rect2(Vector2(ORIGIN + pixel + Vector2i.ONE), Vector2.ONE), filled[pixel])
