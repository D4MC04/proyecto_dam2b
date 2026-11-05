extends MarginContainer
class_name LevelIndicator

const NORMAL_ALPHA: float = 0.7
const HIDDEN_ALPHA: float = 0.15
const FADE_TIME: float = 0.15
const DETECT_MARGIN: float = 4.0

@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel

var _is_hidden: bool = false
var _tween: Tween
# Último nivel y oleada mostrados, para repintarlos al cambiar de idioma.
var _level_number: int = 0
var _wave: Vector2i = Vector2i.ZERO

func _ready() -> void:
	modulate.a = NORMAL_ALPHA

func _notification(what: int) -> void:
	if what != NOTIFICATION_TRANSLATION_CHANGED or not is_node_ready():
		return
	if _level_number > 0:
		set_level_number(_level_number)
	if _wave.y > 0:
		set_wave(_wave.x, _wave.y)

# Si number no es válido (nivel fuera de la lista) no se muestra nada.
func set_level_number(number: int) -> void:
	visible = number > 0
	_level_number = number
	level_label.text = tr("HUD_LEVEL_N") % number if number > 0 else ""

func set_wave(number: int, total: int) -> void:
	_wave = Vector2i(number, total)
	wave_label.text = tr("HUD_WAVE_N_OF") % [number, total]

func _process(_delta: float) -> void:
	if not visible:
		return
	var area: Rect2 = get_global_rect().grow(DETECT_MARGIN)
	var occupied: bool = area.has_point(get_global_mouse_position())
	if not occupied:
		for node: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy: Node2D = node as Node2D
			if enemy != null and area.has_point(enemy.global_position):
				occupied = true
				break
	if occupied != _is_hidden:
		_is_hidden = occupied
		_fade_to(HIDDEN_ALPHA if occupied else NORMAL_ALPHA)

func _fade_to(alpha: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, FADE_TIME)
