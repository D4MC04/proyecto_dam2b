extends Node2D
class_name BuildManager

@export var grid: Grid
@export var tower_scene: PackedScene

const RANGE_COLOR := Color(1, 1, 1, 0.15)

var _preview: Node2D
var _range: Node2D
var _sprite: Sprite2D
var _last_cell: Vector2i = Vector2i(-9999, -9999)
var _last_data: TowerData

func _ready() -> void:
	_preview = Node2D.new()
	add_child(_preview)
	_preview.visible = false

	# El rango se añade primero para que quede por debajo del sprite
	_range = Node2D.new()
	_preview.add_child(_range)
	_range.draw.connect(_draw_range)

	_sprite = Sprite2D.new()
	_sprite.modulate = Color(1, 1, 1, 0.6)
	_preview.add_child(_sprite)

func _unhandled_input(event: InputEvent) -> void:
	# Con la cámara del nivel, la posición del ratón en pantalla no es la del mapa.
	event = make_input_local(event)
	if event is InputEventMouseMotion:
		_update_preview(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place(event.position)

func _update_preview(mouse_pos: Vector2) -> void:
	var data := GameState.selected_tower
	if data == null:
		_hide_preview()
		return
	var cell := grid.cell(mouse_pos)
	if not grid.can_build(cell):
		_hide_preview()
		return
	# Solo redibujamos si cambia la celda o la torre seleccionada
	if cell != _last_cell or data != _last_data:
		_last_cell = cell
		_last_data = data
		_sprite.texture = data.icon
		_preview.global_position = grid.center(cell)
		_range.queue_redraw()
	_preview.visible = true

func _hide_preview() -> void:
	_preview.visible = false
	_last_cell = Vector2i(-9999, -9999)
	_last_data = null

func _draw_range() -> void:
	if _last_data == null or _last_data.attack_range == null:
		return
	_last_data.attack_range.draw(_range.get_canvas_item(), RANGE_COLOR)

func _try_place(mouse_pos: Vector2) -> void:
	var data := GameState.selected_tower
	if data == null:
		return
	var cell := grid.cell(mouse_pos)
	if not grid.can_build(cell):
		return
	var tower: Tower = tower_scene.instantiate()
	tower.data = data
	add_child(tower)
	tower.global_position = grid.center(cell)
	grid.register_tower(cell, tower)
	GameState.money -= data.cost
	_hide_preview()
