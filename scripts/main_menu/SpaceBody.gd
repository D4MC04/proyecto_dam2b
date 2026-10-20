@tool
class_name SpaceBody
extends AnimatedSprite2D

## Genera un SpriteFrames en bucle a partir de un spritesheet de una sola fila
## con frames cuadrados (ancho del frame = alto de la imagen).

@export var sheet: Texture2D:
	set(value):
		sheet = value
		_rebuild_frames()

@export var fps: float = 30.0:
	set(value):
		fps = value
		_rebuild_frames()

# sprite_frames se regenera desde `sheet` en _rebuild_frames(): no guardarlo en el .tscn
func _validate_property(property: Dictionary) -> void:
	if property.name == "sprite_frames":
		property.usage &= ~PROPERTY_USAGE_STORAGE

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	_rebuild_frames()

func _rebuild_frames() -> void:
	if sheet == null:
		return
	var frame_size: int = sheet.get_height()
	if frame_size <= 0 or int(sheet.get_width()) % frame_size != 0:
		return
	@warning_ignore("integer_division")
	var frame_count: int = sheet.get_width() / frame_size

	var sf: SpriteFrames = SpriteFrames.new()
	if not sf.has_animation("default"):
		sf.add_animation("default")
	sf.set_animation_loop("default", true)
	sf.set_animation_speed("default", fps)
	for i in frame_count:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		sf.add_frame("default", atlas)

	sprite_frames = sf
	animation = "default"
	play("default")
