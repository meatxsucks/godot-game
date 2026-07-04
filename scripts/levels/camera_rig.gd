extends Node3D

@export var target_path: NodePath
@export var smooth_speed: float = 8.0
# Desplazamiento base de la cámara isométrica clásica
@export var offset: Vector3 = Vector3(12, 12, 12)

var target: Node3D = null
## Fuerza restante del screen shake (decae sola).
var _shake: float = 0.0

func _ready() -> void:
	add_to_group("camera_rig")
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

## Sacudida breve de cámara (golpes fuertes, sísmico del boss, supers).
func shake(strength: float = 0.3) -> void:
	_shake = maxf(_shake, strength)

func _process(delta: float) -> void:
	if target:
		var goal := target.global_position
		if _shake > 0.005:
			_shake = lerpf(_shake, 0.0, 8.0 * delta)
			goal += Vector3(
				randf_range(-_shake, _shake),
				0.0,
				randf_range(-_shake, _shake))
		global_position = global_position.lerp(goal, smooth_speed * delta)
