extends SceneTree

func _init():
	print("TESTING BIND...")
	var test = TestClass.new(self)
	test.start()
	
class TestClass extends RefCounted:
	var tree
	func _init(t):
		tree = t
	func start():
		print("Start")
		tree.create_timer(0.1).timeout.connect(_my_func.bind(1, "hello"))
	func _my_func(a, b):
		print("Called with: ", a, " ", b)
		tree.quit(0)
