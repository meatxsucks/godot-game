extends Node3D

@export var target_path: NodePath
@export var smooth_speed: float = 8.0
# Desplazamiento base de la cámara isométrica clásica.
@export var offset: Vector3 = Vector3(12, 12, 12)
# Pose de inspección (inventario abierto): más baja y cerca, casi de frente
# al personaje para apreciar el equipo puesto.
@export var inspect_offset: Vector3 = Vector3(4.5, 3.0, 6.0)

var target: Node3D = null
## Fuerza restante del screen shake (decae sola).
var _shake: float = 0.0
## Inspección: al abrir el inventario la cámara pasa a la pose de inspección
## (frontal y cercana) y desplaza el encuadre para dejar al personaje a la
## izquierda del panel.
var _inspect: bool = false

func _ready() -> void:
	add_to_group("camera_rig")
	if not target_path.is_empty():
		target = get_node(target_path)
	else:
		# El player LOCAL se spawnea unos frames después de la cámara (E1.5);
		# _process reintenta hasta encontrarlo.
		target = Players.local(get_tree())
		
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

## Entra/sale del modo inspección. Lo usa el HUD al abrir el inventario.
func set_zoomed(on: bool) -> void:
	_inspect = on

func _process(delta: float) -> void:
	if not target:
		target = Players.local(get_tree())
		if not target:
			return
		global_position = target.global_position
	var cam: Camera3D = $Camera3D

	# Seguir al jugador (con shake).
	var goal := target.global_position
	if _shake > 0.005:
		_shake = lerpf(_shake, 0.0, 8.0 * delta)
		goal += Vector3(
			randf_range(-_shake, _shake),
			0.0,
			randf_range(-_shake, _shake))
	global_position = global_position.lerp(goal, smooth_speed * delta)

	if cam == null:
		return
	# Interpola entre la pose de juego y la de inspección.
	var want_pos := inspect_offset if _inspect else offset
	cam.position = cam.position.lerp(want_pos, 6.0 * delta)
	# h_offset desplaza el encuadre (sin rotar la vista) para dejar al
	# personaje a la izquierda del panel del inventario.
	cam.h_offset = lerpf(cam.h_offset, 1.6 if _inspect else 0.0, 6.0 * delta)
	# Apuntar al centro del jugador (al pecho en inspección).
	var look_h := 1.0 if _inspect else 0.0
	cam.look_at(global_position + Vector3(0, look_h, 0), Vector3.UP)
