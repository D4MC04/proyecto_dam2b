extends Node2D
class_name BuildManager

@export var grid: Grid
@export var tower_scene: PackedScene

var _preview: Sprite2D

func _ready() -> void:
	_preview = Sprite2D.new()
	add_child(_preview)
	_preview.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_preview(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_place(event.position)

func _update_preview(mouse_pos: Vector2) -> void:
	var data := GameState.selected_tower
	if data == null:
		_preview.visible = false
		return
	var cell := grid.cell(mouse_pos)
	_preview.texture = data.icon
	_preview.global_position = grid.center(cell)
	_preview.visible = true
	_preview.modulate = Color(1, 1, 1, 0.5) if grid.can_build(cell) else Color(1, 0.3, 0.3, 0.5)

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
