extends Node3D

func _ready():
	print("TESTING LMB...")
	var player = $Player
	
	# Test Sword
	player.abilities[0] = load("res://scripts/abilities/slash_ability.gd").new()
	player._try_cast(0)
	print("SWORD OK")
	
	# Test Mace
	player.abilities[0] = load("res://scripts/abilities/mace_smash_ability.gd").new()
	player._try_cast(0)
	print("MACE OK")

	# Test Wand
	player.abilities[0] = load("res://scripts/abilities/arc_bolt_ability.gd").new()
	player._try_cast(0)
	print("WAND OK")
	
	# Test Staff
	player.abilities[0] = load("res://scripts/abilities/fireball_ability.gd").new()
	player._try_cast(0)
	print("STAFF OK")
	
	# Test Bow
	player.abilities[0] = load("res://scripts/abilities/arrow_ability.gd").new()
	player._try_cast(0)
	print("BOW OK")
	
	print("ALL LEFT CLICKS OK")
	get_tree().quit(0)
