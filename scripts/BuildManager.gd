extends Node2D
class_name BuildManager

@export var grid: Grid
@export var tower_scene: PackedScene
@export var selected_tower_data: TowerData

var _preview: Node2D

func _ready() -> void:
	_preview = _make_preview()
	add_child(_preview)
	_preview.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_preview(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place(event.position)

func _update_preview(mouse_pos: Vector2) -> void:
	if selected_tower_data == null:
		_preview.visible = false
		return
	var cell := grid.cell(mouse_pos)
	_preview.global_position = grid.center(cell)
	_preview.visible = true
	_preview.modulate = Color.WHITE if grid.can_build(cell) else Color.RED

func _try_place(mouse_pos: Vector2) -> void:
	if selected_tower_data == null:
		return
	var cell := grid.cell(mouse_pos)
	if not grid.can_build(cell):
		return
	var tower: Tower = tower_scene.instantiate()
	tower.data = selected_tower_data
	add_child(tower)
	tower.global_position = grid.center(cell)
	grid.register_tower(cell, tower)

func _make_preview() -> Node2D:
	var s := Sprite2D.new()
	s.modulate.a = 0.5
	return s
