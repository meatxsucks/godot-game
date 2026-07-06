extends Node

func _ready():
	print("Starting test...")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player found! Clicking left click...")
		player._try_cast(0)
		print("Left click finished.")
	else:
		print("No player.")
	get_tree().quit()
