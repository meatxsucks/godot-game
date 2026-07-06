extends Node3D

@export var target_path: NodePath
@export var smooth_speed: float = 8.0
# Desplazamiento base de la cámara isométrica clásica.
@export var offset: Vector3 = Vector3(12, 12, 12)

var target: Node3D = null
## Fuerza restante del screen shake (decae sola).
var _shake: float = 0.0
## Zoom (1 = normal, <1 = más cerca) y desplazamiento lateral. Al abrir el
## inventario la cámara se acerca y corre al personaje a un lado del panel.
var _zoom: float = 1.0
var _pan: float = 0.0

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

## Acerca (o restaura) la cámara al personaje. Lo usa el HUD al abrir el
## inventario: zoom + corrimiento para que el personaje quede a la vista,
## no detrás del panel de la derecha.
func set_zoomed(on: bool) -> void:
	_zoom = 0.5 if on else 1.0
	_pan = 5.0 if on else 0.0

func _process(delta: float) -> void:
	if not target:
		return
	var cam: Camera3D = $Camera3D
	# Zoom suave: acerca/aleja la cámara sobre su eje.
	if cam:
		cam.position = cam.position.lerp(offset * _zoom, 6.0 * delta)

	var goal := target.global_position
	# Corrimiento lateral (en el eje "derecha" de la cámara) para dejar al
	# personaje a un lado y no detrás del panel del inventario.
	if cam and absf(_pan) > 0.01:
		var cam_right := cam.global_transform.basis.x
		cam_right.y = 0.0
		if cam_right.length_squared() > 0.001:
			goal += cam_right.normalized() * _pan

	if _shake > 0.005:
		_shake = lerpf(_shake, 0.0, 8.0 * delta)
		goal += Vector3(
			randf_range(-_shake, _shake),
			0.0,
			randf_range(-_shake, _shake))
	global_position = global_position.lerp(goal, smooth_speed * delta)
