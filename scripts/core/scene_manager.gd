extends Node

signal transition_finished

@onready var transition_scene = preload("res://scenes/core/SceneTransition.tscn")
var current_transition: CanvasLayer = null

func change_scene(path: String) -> void:
	if current_transition != null:
		return
		
	# Instanciar la transición
	current_transition = transition_scene.instantiate()
	get_tree().root.add_child(current_transition)
	
	var anim: AnimationPlayer = current_transition.get_node("AnimationPlayer")
	anim.play("fade_out")
	await anim.animation_finished
	
	# Cambiar de escena en el momento oscuro
	get_tree().change_scene_to_file(path)
	
	# Transicionar de vuelta
	anim.play("fade_in")
	await anim.animation_finished
	
	current_transition.queue_free()
	current_transition = null
	transition_finished.emit()
