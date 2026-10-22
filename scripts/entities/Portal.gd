class_name Portal
extends Node2D

const OPEN_TIME := 0.3
const CLOSE_TIME := 0.3
# Media longitud y media altura de la raja abierta: 30x10 px.
const HALF_LENGTH := 15
const HALF_HEIGHT := 4
const PULSE_SPEED := 6.0
const SHAKE_TIME := 0.25
const BOSS_SHAKE := 3
const FLASH := Color(2.5, 2.5, 2.5)
const FLOW_COUNT := 6
const FLOW_SPEED := 0.9
const INSIDE := Color("#1a0614")
const HALO := Color("#be30a0")
const EDGE_DARK := Color("#be30a0")
const EDGE_LIGHT := Color("#ff5ad2")
const TIP := Color("#f0323c")
const FLOW := Color("#ff5ad2")
const SPIRAL_COUNT := 8
const SPIRAL_SPEED := 0.5
const EXIT_FLASH_TIME := 0.15

# Cuánto está abierta la grieta, de 0 a 1: a lo largo y a lo alto.
# Amplitud del temblor al abrirse, en píxeles.
var shake_strength: int = 1
var _length_ratio: float = 0.0
var _height_ratio: float = 0.0
var _time: float = 0.0
var _shake_left: float = 0.0
var _shake_offset := Vector2.ZERO
var _exit_flash_left: float = 0.0

# Primero una línea que se alarga, luego se abre en alto y tiembla con un destello.
func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_length_ratio", 1.0, OPEN_TIME * 0.5)
	tween.tween_property(self, "_height_ratio", 1.0, OPEN_TIME * 0.5)
	tween.tween_callback(_shake)

func _process(delta: float) -> void:
	_time += delta
	_shake_left -= delta
	_exit_flash_left -= delta
	_shake_offset = Vector2(randi_range(-shake_strength, shake_strength), randi_range(-shake_strength, shake_strength)) if _shake_left > 0.0 else Vector2.ZERO
	queue_redraw()

## Destello en la salida de una nave por este portal.
func flash_exit() -> void:
	_exit_flash_left = EXIT_FLASH_TIME

## Cierra la grieta hasta una línea y la libera.
func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_height_ratio", 0.0, CLOSE_TIME * 0.6)
	tween.tween_property(self, "_length_ratio", 0.0, CLOSE_TIME * 0.4)
	tween.tween_callback(queue_free)

func _shake() -> void:
	_shake_left = SHAKE_TIME
	create_tween().tween_property(self, "modulate", Color.WHITE, SHAKE_TIME).from(FLASH)

# Media altura del interior en la columna `x`: lente que acaba en punta.
func _half_height_at(x: int, half_length: int) -> int:
	var t := (x + 0.5) / half_length
	return roundi(HALF_HEIGHT * _height_ratio * (1.0 - t * t))

# Raja horizontal en forma de ojo, columna a columna en píxeles enteros:
# interior oscuro, borde de 1 px que late, halo por fuera y puntas rojas.
func _draw() -> void:
	draw_set_transform(_shake_offset)
	var half_length := roundi(HALF_LENGTH * _length_ratio)
	if half_length < 1:
		return
	var edge := EDGE_DARK.lerp(EDGE_LIGHT, 0.5 + 0.5 * sin(_time * PULSE_SPEED))
	for x in range(-half_length, half_length):
		var h := _half_height_at(x, half_length)
		var is_tip := x == -half_length or x == half_length - 1
		draw_rect(Rect2(x, -h - 2, 1, 1), HALO)
		draw_rect(Rect2(x, h + 1, 1, 1), HALO)
		draw_rect(Rect2(x, -h - 1, 1, 1), TIP if is_tip else edge)
		draw_rect(Rect2(x, h, 1, 1), TIP if is_tip else edge)
		if h > 0:
			draw_rect(Rect2(x, -h, 1, h * 2), INSIDE)
	# Partículas que giran hacia dentro, como espiral, dentro de la grieta.
	for i in SPIRAL_COUNT:
		var phase := fmod(_time * SPIRAL_SPEED + float(i) / SPIRAL_COUNT, 1.0)
		var angle := TAU * (float(i) / SPIRAL_COUNT + phase * 2.0)
		var pos := Vector2(cos(angle) * half_length, sin(angle) * HALF_HEIGHT * _height_ratio) * (1.0 - phase)
		draw_rect(Rect2(roundi(pos.x), roundi(pos.y), 1, 1), FLOW)
	# Píxeles que van de los bordes hacia el centro.
	for i in FLOW_COUNT:
		var phase := fmod(_time * FLOW_SPEED + float(i) / FLOW_COUNT, 1.0)
		var side := 1 if i % 2 == 0 else -1
		var x := roundi(side * (half_length - 2) * (1.0 - phase))
		var y := roundi(((i % 3) - 1) * (1.0 - phase) * 2.0)
		if absi(y) < _half_height_at(x, half_length):
			draw_rect(Rect2(x, y, 1, 1), FLOW)
	# Destello en cruz al salir una nave.
	if _exit_flash_left > 0.0:
		var flash := Color(1, 1, 1, _exit_flash_left / EXIT_FLASH_TIME)
		draw_rect(Rect2(-2, -1, 4, 2), flash)
		draw_rect(Rect2(-1, -2, 2, 4), flash)
