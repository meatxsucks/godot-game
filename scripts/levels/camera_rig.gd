extends Node3D

@export var target_path: NodePath
@export var smooth_speed: float = 8.0
# Desplazamiento base de la cámara isométrica clásica
@export var offset: Vector3 = Vector3(12, 12, 12)

var target: Node3D = null

func _ready() -> void:
	if not target_path.is_empty():
		target = get_node(target_path)
	else:
		target = get_parent().get_node_or_null("Player")
		
	# Setup initial camera relative position correctly
	var cam = $Camera3D
	if cam:
		cam.position = offset
		cam.look_at(Vector3.ZERO, Vector3.UP)
		# Inicializamos la posición del rig en el target inmediatamente
		if target:
			global_position = target.global_position

func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, smooth_speed * delta)
