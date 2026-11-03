class_name AchievementsScreen
extends Control

# Logros del menú principal, que abre el mural de condecoraciones de la oficina: panel holograma
# con una cuadrícula de 2 columnas, una fila por logro (icono, nombre y descripción); los que
# faltan por conseguir se ven apagados.

signal back_pressed

const ICON_DIR := "res://assets/ui/achievements/"
# Icono de logro (16x16 ×3), ancho de cada fila (dos por línea) y color del logro sin conseguir.
const ICON_SIZE := 48
const ROW_WIDTH := 350
const LOCKED_COLOR := Color(0.3, 0.3, 0.35)

@onready var list: GridContainer = %AchievementsList

func _ready() -> void:
	%VolverButton.pressed.connect(back_pressed.emit)
	visibility_changed.connect(_on_visibility_changed)

# Al abrirse se rehace la lista, por si se consiguió alguno desde la última vez.
func _on_visibility_changed() -> void:
	if not visible:
		return
	for child in list.get_children():
		child.free()
	for id: String in GameState.ACHIEVEMENTS:
		var info: Array = GameState.ACHIEVEMENTS[id]
		list.add_child(_make_row(id, info[0], info[1], id in GameState.unlocked))

# Fila de un logro: icono a la izquierda y nombre y descripción a la derecha; apagada si falta por conseguir.
func _make_row(id: String, title: String, description: String, done: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0)
	row.add_theme_constant_override("separation", 10)
	row.modulate = Color.WHITE if done else LOCKED_COLOR
	var icon := TextureRect.new()
	icon.texture = load(ICON_DIR + id + ".png")
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	var name_text := Label.new()
	name_text.text = title
	name_text.add_theme_font_size_override("font_size", 24)
	var description_text := Label.new()
	description_text.text = description
	description_text.add_theme_font_size_override("font_size", 18)
	description_text.modulate = Color(1, 1, 1, 0.7)
	texts.add_child(name_text)
	texts.add_child(description_text)
	row.add_child(texts)
	return row
