extends Button
class_name EnemyCell

## Petición de enseñar este enemigo en la ficha (clic izquierdo o derecho); no guarda qué está inspeccionado.
signal inspect_requested(data: EnemyData)

@onready var icon_rect: TextureRect = %IconRect
@onready var count_label: Label = %CountLabel

var data: EnemyData

func _ready() -> void:
	pressed.connect(_on_pressed)
	add_theme_stylebox_override("normal", _make_style(TowerButton.BG_COLOR, TowerButton.BORDER_COLOR))
	var hover := _make_style(TowerButton.HOVER_BG_COLOR, TowerButton.HOVER_BORDER_COLOR)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func setup(enemy_data: EnemyData, count: int) -> void:
	data = enemy_data
	tooltip_text = data.name
	count_label.text = "×%s" % UiFormat.abbreviate(count)
	icon_rect.texture = data.get_inspect_icon()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(data)
		accept_event()

func _on_pressed() -> void:
	inspect_requested.emit(data)

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style
