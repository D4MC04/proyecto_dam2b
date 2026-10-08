extends Sprite2D
## Cometa decorativo del fondo: cruza la pantalla de vez en cuando.

@export var velocidad := Vector2(150, 22)
@export var espera_min := 6.0
@export var espera_max := 15.0
@export var ancho := 620.0
@export var alto := 160.0

var _volando := false


func _ready() -> void:
	hide()
	rotation = velocidad.angle()
	_esperar()


func _esperar() -> void:
	await get_tree().create_timer(randf_range(espera_min, espera_max), false).timeout
	position = Vector2(-30, randf_range(0, alto))
	show()
	_volando = true


func _process(delta: float) -> void:
	if not _volando:
		return
	position += velocidad * delta
	if position.x > ancho:
		_volando = false
		hide()
		_esperar()
