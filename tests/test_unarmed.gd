extends Node3D

func _ready():
	print("TESTING UNARMED LMB...")
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	
	player.abilities[0] = load("res://scripts/abilities/unarmed_ability.gd").new()
	player._try_cast(0)
	print("UNARMED OK")
	get_tree().quit(0)
