@tool
extends EditorScript

func _run():
	var size = 64
	var dir = "res://assets/tiles/"
	DirAccess.make_dir_recursive_absolute(dir)

	var tiles = [
		["grass",    Color(0.75, 0.88, 0.75)],
		["dirt",     Color(0.85, 0.78, 0.68)],
		["path",     Color(0.87, 0.82, 0.70)],
		["water",    Color(0.72, 0.85, 0.90)],
		["sand",     Color(0.92, 0.88, 0.75)],
		["stone",    Color(0.80, 0.80, 0.82)],
		["forest",   Color(0.68, 0.80, 0.68)],
		["swamp",    Color(0.78, 0.82, 0.72)],
		["snow",     Color(0.93, 0.94, 0.96)],
		["lava",     Color(0.90, 0.75, 0.72)],
	]

	for tile in tiles:
		var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(tile[1])
		img.save_png(dir + "%s.png" % tile[0])

	print("Tiles generados en ", dir)
