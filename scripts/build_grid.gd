extends Node2D

@export var torre: PackedScene = preload("res://scenes/tower.tscn")

var tilemap: TileMapLayer
var camino = {}   # casilla -> true
var torres = {}   # casilla -> torre

func _ready():
	var nivel = get_parent()
	tilemap = nivel.find_children("*", "TileMapLayer", true, false)[0]
	var path: Path2D = nivel.find_children("*", "Path2D", true, false)[0]
	var largo = path.curve.get_baked_length()
	var paso = tilemap.tile_set.tile_size.x / 4.0
	var d = 0.0
	while d < largo:
		camino[_casilla(path.to_global(path.curve.sample_baked(d)))] = true
		d += paso
	camino[_casilla(path.to_global(path.curve.sample_baked(largo)))] = true
	for t in get_tree().get_nodes_in_group("torres"):
		_registrar(t)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		colocar(get_global_mouse_position())

func puede_construir(c: Vector2i) -> bool:
	return tilemap.get_used_rect().has_point(c) and not camino.has(c) and not torres.has(c)

func colocar(pos: Vector2) -> bool:
	var c = _casilla(pos)
	if not puede_construir(c):
		return false
	var t = torre.instantiate()
	get_parent().add_child(t)
	t.global_position = _centro(c)
	_registrar(t)
	return true

func _registrar(t):
	var c = _casilla(t.global_position)
	if not puede_construir(c):
		push_warning("Torre en casilla no valida: %s" % c)
		return
	torres[c] = t
	t.global_position = _centro(c)
	t.ajustar_a_casilla(Vector2(tilemap.tile_set.tile_size))
	t.tree_exiting.connect(func(): torres.erase(c))

func _casilla(p: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(p))

func _centro(c: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(c))
