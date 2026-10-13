extends Button
class_name EnemyCell

## Clic en la celda. De momento nadie lo escucha (la ficha de enemigos lo usará).
signal enemy_clicked(data: EnemyData)

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
	if data.sprite_frames != null and data.sprite_frames.has_animation("up"):
		icon_rect.texture = data.sprite_frames.get_frame_texture("up", 0)

func _on_pressed() -> void:
	enemy_clicked.emit(data)

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(1)
	style.border_color = border
	style.anti_aliasing = false
	return style
