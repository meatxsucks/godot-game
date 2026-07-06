extends SceneTree

func _init():
	print("Starting simulation test...")
	var player_scene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	var root = Node3D.new()
	root.add_child(player)
	
	print("Testing SlashAbility (Sword LMB)")
	var slash = preload("res://scripts/abilities/slash_ability.gd").new()
	slash.execute(player)
	print("Slash completed.")
	
	print("Testing MaceSmashAbility (Mace LMB)")
	var mace = preload("res://scripts/abilities/mace_smash_ability.gd").new()
	mace.execute(player)
	print("Mace completed.")
	
	quit()
