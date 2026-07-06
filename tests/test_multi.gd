extends SceneTree

func _init():
	print("TESTING MULTI BOLT CALL...")
	var player = MockPlayer.new()
	var root = Node3D.new()
	root.add_child(player)
	self.root.add_child(root)
	
	var ability = load("res://scripts/abilities/multi_bolt_ability.gd").new()
	print("Instantiated ability")
	
	var res = ability._cast(player)
	print("Cast returned: ", res)
	quit(0)

class MockPlayer extends Node3D:
	var stats = MockStats.new()
	func get_aim_point() -> Vector3:
		return Vector3.FORWARD

class MockStats:
	func roll_spell_damage(a, b):
		return [10, false]
