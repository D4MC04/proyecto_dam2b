extends RefCounted
class_name UnlockInfo
## Datos de un desbloqueo que enseña `UnlockNotice`: la pantalla solo conoce esto, no sabe qué se desbloquea
## ni de dónde viene. `from_id` los saca de los ids que guarda `GameState.pending_unlocks`; para otro tipo de
## desbloqueo (un poder, por ejemplo) basta con un id nuevo allí o con crear el `UnlockInfo` a mano.

const TURRET_PREFIX: String = "turret:"
const SECTOR_PREFIX: String = "sector:"
const SHIP_DIR: String = "res://assets/sprites/enemies/radar/"
# Nombre del sprite por LevelData.RadarShip (igual que en SectorRadar).
const SHIP_FILES: Array[String] = ["raider", "fang", "crusher", "specter"]
const TURRET_COLOR: Color = Color("#40e0f0")
const SECTOR_COLOR: Color = Color("#ecb23c")

## Clave de traducción del tipo ("TORRETA NUEVA", "SECTOR NUEVO"...).
var kind_key: String = ""
## Nombre ya traducido.
var title: String = ""
## Frase ya traducida.
var text: String = ""
var icon: Texture2D
## Tinte del icono (los sprites del radar son monocromos y se tiñen).
var icon_tint: Color = Color.WHITE
## Color del marco y de la etiqueta de tipo.
var accent: Color = TURRET_COLOR

## Id de la torreta de `GameData.turret_order` (su archivo, sin depender del orden de la lista).
static func turret_id(data: TurretData) -> String:
	return TURRET_PREFIX + data.resource_path.get_file()

## Id del sector número `number` (desde 1).
static func sector_id(number: int) -> String:
	return SECTOR_PREFIX + str(number)

## Datos del desbloqueo con ese id; null si el id no existe (por ejemplo, un archivo de guardado viejo o editado).
static func from_id(id: String) -> UnlockInfo:
	if id.begins_with(TURRET_PREFIX):
		return _from_turret(id.trim_prefix(TURRET_PREFIX))
	if id.begins_with(SECTOR_PREFIX):
		var number: String = id.trim_prefix(SECTOR_PREFIX)
		return _from_sector(int(number)) if number.is_valid_int() else null
	return null

static func _from_turret(file: String) -> UnlockInfo:
	for data: TurretData in GameData.turret_order:
		if data.resource_path.get_file() != file:
			continue
		var info: UnlockInfo = UnlockInfo.new()
		info.kind_key = "UNLOCK_TURRET"
		info.title = data.get_inspect_name()
		info.text = data.get_inspect_description()
		info.icon = data.get_inspect_icon()
		info.accent = TURRET_COLOR
		return info
	return null

static func _from_sector(number: int) -> UnlockInfo:
	if number < 1 or number > GameData.levels.size():
		return null
	var level: LevelData = GameData.levels[number - 1]
	var info: UnlockInfo = UnlockInfo.new()
	info.kind_key = "UNLOCK_SECTOR"
	info.title = TranslationServer.translate(level.sector_name)
	info.text = TranslationServer.translate("UNLOCK_SECTOR_TEXT")
	var path: String = SHIP_DIR + "radar_%s.png" % SHIP_FILES[level.radar_ship]
	if ResourceLoader.exists(path):
		info.icon = load(path) as Texture2D
	info.accent = SECTOR_COLOR
	info.icon_tint = SECTOR_COLOR
	return info
