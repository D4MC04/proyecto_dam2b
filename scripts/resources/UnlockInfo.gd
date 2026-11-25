extends RefCounted
class_name UnlockInfo
## Datos de un desbloqueo que enseña la pantalla de victoria: la pantalla solo conoce esto, no sabe qué se
## desbloquea. `GameState.complete_level` los crea con `from_turret` y `from_sector`; para otro tipo de
## desbloqueo (un poder, por ejemplo) basta con otro constructor o con crear el `UnlockInfo` a mano.

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
var accent: Color = TurretData.ACCENT_COLOR

## Datos de una torreta nueva: nombre, icono y frase de su ficha.
static func from_turret(data: TurretData) -> UnlockInfo:
	var info: UnlockInfo = UnlockInfo.new()
	info.kind_key = "UNLOCK_TURRET"
	info.title = data.get_inspect_name()
	info.text = data.get_inspect_description()
	info.icon = data.get_inspect_icon()
	info.accent = data.get_inspect_accent()
	return info

## Datos del sector número `number` (desde 1); null si no existe.
static func from_sector(number: int) -> UnlockInfo:
	if number < 1 or number > GameData.levels.size():
		return null
	var level: LevelData = GameData.levels[number - 1]
	var info: UnlockInfo = UnlockInfo.new()
	info.kind_key = "UNLOCK_SECTOR"
	info.title = TranslationServer.translate(level.sector_name)
	info.text = TranslationServer.translate("UNLOCK_SECTOR_TEXT")
	var path: String = SectorRadar.SHIP_DIR + "radar_%s.png" % SectorRadar.SHIP_FILES[level.radar_ship]
	if ResourceLoader.exists(path):
		info.icon = load(path) as Texture2D
	info.accent = SECTOR_COLOR
	info.icon_tint = SECTOR_COLOR
	return info
