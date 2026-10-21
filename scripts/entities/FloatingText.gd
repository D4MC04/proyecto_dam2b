class_name FloatingText

const FONT := preload("res://assets/fonts/Monogram.ttf")
const COLOR := Color("#ffe082")
const RISE := 12.0
const DURATION := 0.6

## Texto que sale de `position`, sube y se desvanece. Cuelga de `parent` y se libera solo.
static func spawn(parent: Node, position: Vector2, text: String, duration: float = DURATION, color: Color = COLOR) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.z_index = 10
	label.reset_size()
	parent.add_child(label)
	# Centrado sobre el punto; en global porque el padre (el camino) se mueve con el mapa centrado.
	label.global_position = position - label.size / 2.0
	var tween := label.create_tween().set_parallel()
	# Sube a velocidad constante (más distancia si dura más, para que el movimiento no vaya a saltos de píxel)
	# y solo se desvanece en la segunda mitad.
	tween.tween_property(label, "position:y", label.position.y - RISE * maxf(1.0, duration), duration)
	tween.tween_property(label, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.chain().tween_callback(label.queue_free)
