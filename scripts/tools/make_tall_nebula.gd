extends SceneTree
## Genera fondo_nebulosa_tall.png (640x544): la nebulosa original arriba y la misma
## imagen volteada en vertical debajo, para que case consigo misma por arriba y por abajo.
##
## Uso: godot --headless --path . -s scripts/tools/make_tall_nebula.gd
##
## Herramienta de un solo uso: la textura original no se modifica.

const SOURCE := "res://assets/sprites/backgrounds/espacio/fondo_nebulosa.png"
const TARGET := "res://assets/sprites/backgrounds/espacio/fondo_nebulosa_tall.png"


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null:
		push_error("No se pudo cargar " + SOURCE)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var size := source.get_size()
	var flipped := source.duplicate() as Image
	flipped.flip_y()
	var result := Image.create(size.x, size.y * 2, false, Image.FORMAT_RGBA8)
	result.blit_rect(source, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	result.blit_rect(flipped, Rect2i(Vector2i.ZERO, size), Vector2i(0, size.y))
	var error := result.save_png(ProjectSettings.globalize_path(TARGET))
	print("Guardado ", TARGET, " ", result.get_size(), " (error ", error, ")")
	quit(error)
