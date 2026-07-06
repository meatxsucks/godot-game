extends Node3D

func _ready():
	print("TESTING GAME TREE WITH PRINTS...")
	var player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	
	print("Casting Multi Bolt...")
	var multi = load("res://scripts/abilities/multi_bolt_ability.gd").new()
	multi._cast(player)
	
	print("Waiting for timers...")
	get_tree().create_timer(2.0).timeout.connect(func():
		print("ALL CASTS FINISHED AND TIMERS FIRED!")
		get_tree().quit(0)
	)
