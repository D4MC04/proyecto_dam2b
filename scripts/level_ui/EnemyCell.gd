extends Button
class_name EnemyCell

## Petición de enseñar este enemigo o torreta en la ficha (clic izquierdo o derecho); no guarda qué está inspeccionado.
signal inspect_requested(data: InspectableData)

@onready var icon_rect: TextureRect = %IconRect
@onready var count_label: Label = %CountLabel

var data: InspectableData

func _ready() -> void:
	pressed.connect(_on_pressed)
	add_theme_stylebox_override("normal", ClippedBoxStyle.create(TurretButton.BG_COLOR, TurretButton.BORDER_COLOR))
	var hover := ClippedBoxStyle.create(TurretButton.HOVER_BG_COLOR, TurretButton.HOVER_BORDER_COLOR)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func setup(enemy_data: InspectableData, count: int) -> void:
	data = enemy_data
	count_label.text = "×%s" % UiFormat.abbreviate(count)
	icon_rect.texture = data.get_inspect_icon()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(data)
		accept_event()

func _on_pressed() -> void:
	inspect_requested.emit(data)
