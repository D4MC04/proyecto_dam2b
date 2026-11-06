extends Resource
class_name LevelData

# Nivel de amenaza que enseña la ficha del radar. EXTREME es solo para el jefe.
enum Threat { LOW, MEDIUM, HIGH, EXTREME }
# Nave del icono del contacto en el radar (sprites de scripts/tools/make_radar_ships.gd).
enum RadarShip { RAIDER, FANG, CRUSHER, SPECTER }

@export var map: PackedScene
## Dinero con el que empieza el jugador el nivel.
@export var starting_money: int = 500
@export var turrets: Array[TurretData]
@export var waves: Array[WaveData]

@export_group("Radar")
## Clave del nombre del sector (SECTOR_<n>_NAME en translations/textos.csv).
@export var sector_name: String = ""
## Distancia al centro del radar, como fracción del radio (0 = estación, 1 = borde).
@export_range(0.0, 1.0, 0.01) var radar_distance: float = 0.5
## Rumbo en grados: 0 = arriba, en el sentido de las agujas del reloj.
@export_range(0.0, 360.0, 1.0) var radar_bearing: float = 0.0
@export var threat: Threat = Threat.LOW
## Nave del icono: la de su enemigo más peligroso.
@export var radar_ship: RadarShip = RadarShip.RAIDER
