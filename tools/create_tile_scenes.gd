@tool
extends EditorScript

func _run():
	var src_dir = "res://assets/tiles/"
	var dst_dir = "res://scenes/tiles/"
	DirAccess.make_dir_recursive_absolute(dst_dir)

	var dir = DirAccess.open(src_dir)
	if dir == null:
		print("No se pudo abrir ", src_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var tile_name = file_name.get_basename()
			_create_scene(src_dir, dst_dir, tile_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("Escenas generadas en ", dst_dir)

func _create_scene(src_dir, dst_dir, tile_name):
	var texture = load(src_dir + tile_name + ".png")
	if texture == null:
		print("No se pudo cargar textura de ", tile_name)
		return

	var sprite = Sprite2D.new()
	sprite.name = tile_name
	sprite.texture = texture

	var scene = PackedScene.new()
	scene.pack(sprite)

	var scene_path = dst_dir + tile_name + ".tscn"
	var err = ResourceSaver.save(scene, scene_path)
	if err == OK:
		print("Guardada: ", scene_path)
	else:
		print("Error guardando ", scene_path, ": ", err)

	sprite.queue_free()
