class_name HealthBar
extends Node2D

# Barra de vida pixel art encima de un enemigo; oculta con la vida llena.

const BACKGROUND := Color("#14060a")
const GREEN := Color("#3cc850")
const AMBER := Color("#ecb23c")
const RED := Color("#f0323c")
const HEIGHT := 2.0

var _width: float
var _ratio := 1.0

func setup(width: float, top: float) -> void:
	_width = maxf(roundf(width), 4.0)
	position = Vector2(-_width / 2.0, top - HEIGHT - 3.0)
	visible = false

func update(hp: float, max_hp: float) -> void:
	_ratio = clampf(hp / max_hp, 0.0, 1.0)
	visible = _ratio < 1.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-1, -1, _width + 2, HEIGHT + 2), Color.BLACK, true)
	draw_rect(Rect2(0, 0, _width, HEIGHT), BACKGROUND, true)
	var color := GREEN if _ratio > 0.5 else (AMBER if _ratio > 0.25 else RED)
	draw_rect(Rect2(0, 0, roundf(_width * _ratio), HEIGHT), color, true)
