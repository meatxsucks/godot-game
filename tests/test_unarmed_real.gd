extends SceneTree

func _init():
	print("Running full Unarmed test...")
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	var root = Node3D.new()
	root.add_child(player)
	
	player._ready() # Force ready to build abilities
	
	player.abilities[0] = load("res://scripts/abilities/unarmed_ability.gd").new()
	print("Executing UnarmedAbility...")
	player._try_cast(0)
	print("Executed!")
	quit(0)
