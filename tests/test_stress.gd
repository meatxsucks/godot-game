extends Node3D

func _ready():
	print("STRESS TESTING...")
	var player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	
	var spin = load("res://scripts/abilities/spin_slash_ability.gd").new()
	var multi = load("res://scripts/abilities/multi_bolt_ability.gd").new()
	var shock = load("res://scripts/abilities/shockwave_ability.gd").new()
	
	for i in range(10):
		spin._cast(player)
		multi._cast(player)
		shock._cast(player)
	
	print("Stress test spawned all timers!")
	get_tree().create_timer(3.0).timeout.connect(func():
		print("All timers executed!")
		get_tree().quit(0)
	)
