extends SceneTree

func _init():
	print("Checking all abilities...")
	var dir = DirAccess.open("res://scripts/abilities")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".gd"):
				var res = load("res://scripts/abilities/" + file)
				if res == null:
					print("FAILED TO LOAD: ", file)
				else:
					var inst = res.new()
					if not inst:
						print("FAILED TO INSTANTIATE: ", file)
					else:
						print("OK: ", file)
			file = dir.get_next()
	print("Done checking.")
	quit(0)
