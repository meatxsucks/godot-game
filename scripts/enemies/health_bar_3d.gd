## Barra de vida flotante 3D construida por código (dos quads, sin assets).
## El dueño la actualiza con set_ratio(); se orienta a la cámara cada frame.
class_name HealthBar3D
extends Node3D

const WIDTH := 0.9
const HEIGHT := 0.1

var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D

func _ready() -> void:
	_make_quad(Color(0.05, 0.05, 0.08, 0.9), 0.0)
	_fill = _make_quad(Color(0.3, 0.9, 0.3), 0.012)
	_fill_mat = _fill.mesh.material

func _make_quad(color: Color, z_offset: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(WIDTH, HEIGHT)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.no_depth_test = true
	quad.material = mat
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.position.z = z_offset
	add_child(mesh_instance)
	return mesh_instance

## Fracción de vida 0..1. Ancla el relleno a la izquierda y va de verde a rojo.
func set_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.position.x = -WIDTH * 0.5 * (1.0 - ratio)
	_fill_mat.albedo_color = Color(1.0 - ratio * 0.7, ratio * 0.9, 0.15)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# Mirar de frente a la cámara (+Z del quad hacia ella).
	var to_camera := camera.global_position - global_position
	if to_camera.length_squared() > 0.01:
		look_at(camera.global_position, Vector3.UP, true)
