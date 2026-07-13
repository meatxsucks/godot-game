## Tajo de Espada del Guerrero: una hoja visible barre un arco frontal
## (tween) y daña una sola vez a los enemigos alcanzados vía query física.
extends Node3D

@export var reach: float = 1.9
@export var arc_degrees: float = 130.0
@export var swing_time: float = 0.18
@export var hit_radius: float = 1.4

var damage: float = 10.0
var source: Node = null
var is_crit: bool = false
## Tags de estado (E3) que este golpe aplica/detona (llegan por props).
var applies: Array = []
var detonates: Array = []

var _did_hit := false

## Configura el tajo con el daño calculado por el lanzador.
func setup(p_damage: float, p_source: Node = null, p_crit: bool = false) -> void:
	damage = p_damage
	source = p_source
	is_crit = p_crit

func _ready() -> void:
	# Hoja bajo un pivote que barre el arco y se desvanece al terminar.
	var pivot := Node3D.new()
	add_child(pivot)

	var blade := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.05, reach)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 0.92, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 0.85, 1)
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	blade.mesh = mesh
	blade.position = Vector3(0, 0.7, -reach * 0.5)
	pivot.add_child(blade)

	pivot.rotation.y = deg_to_rad(arc_degrees * 0.5)
	var tween := create_tween()
	tween.tween_property(pivot, "rotation:y", deg_to_rad(-arc_degrees * 0.5), swing_time)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, swing_time)
	tween.tween_callback(queue_free)

func _physics_process(_delta: float) -> void:
	# El daño se resuelve una sola vez, en el primer frame de física.
	if _did_hit:
		return
	_did_hit = true
	var center := global_position - global_transform.basis.z * (reach * 0.6) + Vector3(0, 0.5, 0)
	var shape := SphereShape3D.new()
	shape.radius = hit_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), center)
	var hits := get_world_3d().direct_space_state.intersect_shape(params, 12)
	for hit in hits:
		var body = hit.get("collider")
		if body == null or body == source:
			continue
		if body is Node3D and body.is_in_group("player"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage, is_crit)
			# Tags (E3): detonar primero, aplicar después — solo con autoridad.
			if is_multiplayer_authority() and body.has_method("apply_status"):
				var peer: int = source.get_multiplayer_authority() if source else 0
				if not detonates.is_empty():
					body.detonate_status(detonates, peer)
				for tag: StringName in applies:
					body.apply_status(tag, damage, peer)
			# Solo la copia con autoridad acredita el super (réplicas = visual).
			if is_multiplayer_authority() and source and source.has_method("add_super_charge"):
				source.add_super_charge(4.0)
