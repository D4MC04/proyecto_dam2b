class_name AchievementsScreen
extends Control

# Logros del menú principal, que abre el mural de condecoraciones de la oficina: panel holograma
# con una cuadrícula de 2 columnas, una fila por logro (icono en el metal de su fase, nombre, fase y
# descripción con la siguiente meta); los que no tienen ninguna fase se ven apagados.

signal back_pressed

const ICON_DIR: String = "res://assets/ui/achievements/"
# Icono de logro (16x16 ×3), ancho de cada fila (dos por línea) y color del logro sin conseguir.
const ICON_SIZE: int = 48
const ROW_WIDTH: int = 350
const LOCKED_COLOR: Color = Color(0.3, 0.3, 0.35)

@onready var list: GridContainer = %AchievementsList

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	visibility_changed.connect(_on_visibility_changed)

# Al abrirse se rehace la lista, por si se consiguió alguno desde la última vez.
func _on_visibility_changed() -> void:
	if not visible:
		return
	for child: Node in list.get_children():
		child.free()
	for id: String in GameState.ACHIEVEMENTS:
		list.add_child(_make_row(id))

# Fila de un logro: icono en el metal de su fase a la izquierda; a la derecha, nombre con la fase
# conseguida y descripción con la meta de la siguiente fase. Apagada si no tiene ninguna fase.
func _make_row(id: String) -> HBoxContainer:
	var phase: int = GameState.get_phase(id)
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0)
	row.add_theme_constant_override("separation", 10)
	row.modulate = Color.WHITE if phase != GameState.PHASE_NONE else LOCKED_COLOR
	var icon: TextureRect = TextureRect.new()
	icon.texture = AchievementTint.tint(load(ICON_DIR + id + ".png"), maxi(phase, GameState.PHASE_BRONZE))
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var texts: VBoxContainer = VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	var title: HBoxContainer = HBoxContainer.new()
	title.add_theme_constant_override("separation", 8)
	var name_text: Label = Label.new()
	name_text.text = tr(GameState.ACHIEVEMENTS[id][0])
	name_text.add_theme_font_size_override("font_size", 24)
	title.add_child(name_text)
	if phase != GameState.PHASE_NONE:
		var phase_text: Label = Label.new()
		phase_text.text = GameState.phase_name(phase).to_upper()
		phase_text.add_theme_font_size_override("font_size", 18)
		phase_text.add_theme_color_override("font_color", GameState.PHASE_COLORS[phase])
		phase_text.size_flags_vertical = Control.SIZE_SHRINK_END
		title.add_child(phase_text)
	var description_text: Label = Label.new()
	description_text.text = GameState.achievement_description(id)
	description_text.add_theme_font_size_override("font_size", 18)
	description_text.modulate = Color(1, 1, 1, 0.7)
	texts.add_child(title)
	texts.add_child(description_text)
	row.add_child(texts)
	return row
