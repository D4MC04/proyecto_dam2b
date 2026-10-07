@tool
extends AnimatedSprite2D

## Genera un SpriteFrames en bucle a partir de un spritesheet de una sola fila
## con frames cuadrados (ancho del frame = alto de la imagen).

@export var sheet: Texture2D:
	set(value):
		sheet = value
		_actualizar()

@export var fps := 30.0:
	set(value):
		fps = value
		_actualizar()

# sprite_frames se regenera desde `sheet` en _actualizar(): no guardarlo en el .tscn
func _validate_property(property: Dictionary):
	if property.name == "sprite_frames":
		property.usage &= ~PROPERTY_USAGE_STORAGE

func _ready():
	texture_filter = TEXTURE_FILTER_NEAREST
	_actualizar()

func _actualizar():
	if sheet == null:
		return
	var frame_size = sheet.get_height()
	if frame_size <= 0 or int(sheet.get_width()) % frame_size != 0:
		return
	@warning_ignore("integer_division")
	var frame_count = sheet.get_width() / frame_size

	var sf = SpriteFrames.new()
	if not sf.has_animation("default"):
		sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.set_animation_speed("default", fps)
	for i in frame_count:
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		sf.add_frame("default", atlas)

	sprite_frames = sf
	animation = "default"
	play("default")
