extends OverlayScreen
class_name PauseScreen

# Pantalla de pausa: título con cursor parpadeante y modo plegado, que deja solo una etiqueta
# en la esquina para ver el mapa limpio. Plegar no cambia el estado de LevelUI (sigue en PAUSED).

const CURSOR := "_"
const CURSOR_BLINK_TIME := 0.5

@onready var fold_button: Button = %FoldButton
@onready var folded_tag: OverlayFrame = %FoldedTag

var _folded := false
var _cursor_timer := 0.0
var _cursor_label: Label

func _ready() -> void:
	super()
	_add_cursor()
	title_label.add_theme_color_override("font_color", accent_color)
	folded_tag.accent_color = accent_color
	fold_button.pressed.connect(_set_folded.bind(true))
	folded_tag.gui_input.connect(_on_folded_tag_gui_input)
	visibility_changed.connect(_on_visibility_changed)
	_set_folded(false)

# El cursor es una etiqueta aparte que parpadea con la opacidad, así el panel nunca cambia de tamaño.
func _add_cursor() -> void:
	var box := title_label.get_parent()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	box.add_child(row)
	box.move_child(row, title_label.get_index())
	title_label.reparent(row, false)
	_cursor_label = title_label.duplicate() as Label
	_cursor_label.unique_name_in_owner = false
	_cursor_label.text = CURSOR
	row.add_child(_cursor_label)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_cursor_timer = fmod(_cursor_timer + delta, CURSOR_BLINK_TIME * 2.0)
	_cursor_label.modulate.a = 1.0 if _cursor_timer < CURSOR_BLINK_TIME else 0.0

func _on_visibility_changed() -> void:
	# Al pausar, la pausa sale siempre desplegada y con el cursor encendido.
	if is_visible_in_tree():
		_cursor_timer = 0.0
		_set_folded(false)

func _set_folded(folded: bool) -> void:
	_folded = folded
	background.visible = not folded
	frame.visible = not folded
	folded_tag.visible = folded

func _on_folded_tag_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if _folded and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_set_folded(false)
		accept_event()
