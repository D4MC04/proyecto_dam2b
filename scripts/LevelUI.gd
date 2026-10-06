extends CanvasLayer
class_name GameUI

@onready var sidebar: Sidebar = %Sidebar

func setup(state: GameState, towers: Array[TowerData]) -> void:

	sidebar.tower_selected.connect(func(data): state.selected_tower = data)
	state.money_changed.connect(sidebar.set_money)
	sidebar.build_buttons(towers)
	sidebar.set_money(state.money)
