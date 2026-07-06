extends SceneTree

func _init():
	print("TESTING ASYNC VIRTUAL CALL...")
	var test: BaseClass = SubClass.new(self)
	print("Direct call:")
	var res = test.my_func()
	print("Done! (Expected error before this if Godot strict)")
	quit(0)

class BaseClass extends RefCounted:
	var tree
	func _init(t):
		tree = t
	func my_func() -> Variant:
		return false

class SubClass extends BaseClass:
	func my_func() -> Variant:
		print("Async start")
		await tree.create_timer(0.01).timeout
		print("Async end")
		return true
