extends SceneTree
## Genera la decoración de los mapas de espacio a partir de cuadrículas de texto.
##
## Uso: godot --headless --path . -s scripts/tools/space_decoration.gd
##
## Herramienta de un solo uso: la fuente de verdad es el .tscn. Volver a ejecutarla
## sobrescribe el tile_map_data de las capas que aparecen en cada .txt, así que se
## pierden los retoques hechos a mano en el editor sobre esas capas.
##
## Formato del .txt:
##   [NombreDeCapa]      capa TileMapLayer del mapa a sobrescribir
##   a = 0 6 0           leyenda: símbolo = source atlas_x atlas_y
##   ..a..b..            filas de la cuadrícula; "." es casilla vacía
## La primera columna y la primera fila corresponden a la casilla GRID_ORIGIN.
## Un tile de varias casillas se escribe solo en su casilla superior izquierda.

const GRID_ORIGIN: Vector2i = Vector2i(-2, -1)
const EMPTY_CELL: String = "."
const DATA_PREFIX: String = "tile_map_data = PackedByteArray(\""
const JOBS: Dictionary[String, String] = {
	"res://resources/map_data/level_5_decor.txt": "res://scenes/maps/espacio/Level5_espacio.tscn",
	"res://resources/map_data/level_6_decor.txt": "res://scenes/maps/espacio/Level6_espacio.tscn",
}


func _initialize() -> void:
	for data_path: String in JOBS:
		_apply(data_path, JOBS[data_path])
	quit()


func _apply(data_path: String, scene_path: String) -> void:
	var data_text: String = FileAccess.get_file_as_string(data_path)
	var scene_text: String = FileAccess.get_file_as_string(scene_path)
	if data_text.is_empty() or scene_text.is_empty():
		push_error("No se puede leer %s o %s" % [data_path, scene_path])
		return
	var layers: Dictionary[String, TileMapLayer] = _parse(data_text)
	for layer_name: String in layers:
		scene_text = _replace_layer_data(scene_text, layer_name, layers[layer_name])
		layers[layer_name].free()
	var file: FileAccess = FileAccess.open(scene_path, FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()
	print("%s -> %s (%s)" % [data_path, scene_path, ", ".join(layers.keys())])


## Devuelve una TileMapLayer rellena por cada sección [Capa] del texto.
func _parse(data_text: String) -> Dictionary[String, TileMapLayer]:
	var layers: Dictionary[String, TileMapLayer] = {}
	var legend: Dictionary[String, PackedInt32Array] = {}
	var layer: TileMapLayer = null
	var row: int = 0
	for raw_line: String in data_text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("["):
			layer = TileMapLayer.new()
			layers[line.trim_prefix("[").trim_suffix("]")] = layer
			legend = {}
			row = 0
		elif layer == null:
			push_error("Línea fuera de una sección [Capa]: %s" % line)
		elif line.contains(" = "):
			var parts: PackedStringArray = line.split(" = ")
			var values: PackedInt32Array = []
			for value: String in parts[1].split(" ", false):
				values.append(value.to_int())
			legend[parts[0]] = values
		else:
			for column: int in line.length():
				var symbol: String = line[column]
				if symbol == EMPTY_CELL:
					continue
				if not legend.has(symbol):
					push_error("Símbolo sin leyenda: %s" % symbol)
					continue
				var tile: PackedInt32Array = legend[symbol]
				layer.set_cell(GRID_ORIGIN + Vector2i(column, row), tile[0], Vector2i(tile[1], tile[2]))
			row += 1
	return layers


## Sustituye solo el contenido de tile_map_data del nodo indicado; el resto del .tscn no cambia.
func _replace_layer_data(scene_text: String, layer_name: String, layer: TileMapLayer) -> String:
	var node_at: int = scene_text.find("[node name=\"%s\" type=\"TileMapLayer\"" % layer_name)
	var prefix_at: int = scene_text.find(DATA_PREFIX, node_at)
	if node_at == -1 or prefix_at == -1:
		push_error("No hay capa TileMapLayer con datos llamada %s" % layer_name)
		return scene_text
	var start: int = prefix_at + DATA_PREFIX.length()
	var end: int = scene_text.find("\")", start)
	return scene_text.substr(0, start) + Marshalls.raw_to_base64(layer.tile_map_data) + scene_text.substr(end)
