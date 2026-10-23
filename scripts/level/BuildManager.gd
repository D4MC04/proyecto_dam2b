extends Node
class_name BuildManager

@export var grid: Grid
@export var tower_scene: PackedScene
# Mientras se apunta el meteorito no se coloca ni se selecciona nada.
@export var powers: Powers

const RANGE_COLOR := Color(1, 1, 1, 0.15)

var state: LevelState

var _preview: Node2D
var _range: Node2D
var _sprite: Sprite2D
var _last_cell: Vector2i = Vector2i(-9999, -9999)
var _last_data: TowerData
# A false cuando el nivel ha acabado: no se coloca nada ni se enseña la vista previa.
var _building := true

## Deja de colocar torres y oculta la vista previa para el resto de la partida.
func stop_building() -> void:
	_building = false
	_hide_preview()

func _ready() -> void:

	_preview = Node2D.new()
	add_child(_preview)
	_preview.visible = false

	_range = Node2D.new()
	_preview.add_child(_range)
	_range.draw.connect(_draw_range)

	_sprite = Sprite2D.new()
	_sprite.modulate = Color(1, 1, 1, 0.6)
	_preview.add_child(_sprite)

func _unhandled_input(event: InputEvent) -> void:

	if state == null or not _building or powers.is_aiming():
		return

	if event is InputEventMouseMotion:
		_update_preview(get_viewport().get_mouse_position())

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place(get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			state.selected_tower = null
			_hide_preview()

func _try_place(mouse_pos: Vector2) -> void:

	var cell := grid.cell(mouse_pos)
	var data := state.selected_tower
	if grid.towers.has(cell):
		# Clic en una torre ya colocada: se selecciona (ficha, vender y mejorar).
		state.inspect_placed(grid.towers[cell])
		return

	# Clic donde no se puede construir (el espacio, o cualquier sitio sin torre de la tienda elegida):
	# se suelta todo, la torre de la tienda y la colocada (ficha, botones y alcance).
	if data == null or not grid.can_build(cell):
		_deselect_all()
		return

	if not state.spend_money(data.cost):
		return

	var tower := tower_scene.instantiate()
	tower.data = data
	add_child(tower)
	tower.global_position = grid.center(cell)
	tower.invested = data.cost
	tower.play_build()

	grid.register_tower(cell, tower)
	state.tower_placed.emit()
	GameState.add_stat("built_" + data.resource_path.get_file().get_basename())

	_hide_preview()

func _deselect_all() -> void:
	state.selected_tower = null
	state.inspected = null
	_hide_preview()

## Mejora la torre colocada seleccionada: la sustituye por su versión mejorada en la misma casilla.
## Sin torre seleccionada, sin mejora o sin dinero no hace nada.
func upgrade_selected() -> void:
	var old := state.sellable_tower
	if not _building or not is_instance_valid(old) or old.data.fusion == null:
		return
	var fused := old.data.fusion
	if not state.spend_money(fused.cost):
		return
	var cell := grid.cell(old.global_position)
	var tower: Tower = tower_scene.instantiate()
	tower.data = fused
	tower.invested = old.invested + fused.cost
	tower.kills = old.kills
	tower.damage_dealt = old.damage_dealt
	# Se saca del árbol ya (tree_exiting libera la casilla) para que no borre el registro de la nueva.
	remove_child(old)
	old.queue_free()
	add_child(tower)
	tower.global_position = grid.center(cell)
	tower.play_build(true)
	GameState.register_fusion(fused)
	grid.register_tower(cell, tower)
	state.inspect_placed(tower)
	_update_preview(get_viewport().get_mouse_position())

func _update_preview(mouse_pos: Vector2) -> void:

	var data := state.selected_tower
	if data == null:
		_hide_preview()
		return
	var cell := grid.cell(mouse_pos)
	# La vista previa solo se enseña en casillas libres.
	if not grid.can_build(cell):
		_hide_preview()
		return

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
