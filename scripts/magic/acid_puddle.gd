## Charco de ácido persistente del Alquimista (Q). Queda en el suelo unos
## segundos: DERRITE a los enemigos que lo pisan (ticks de daño + Sangrado
## que se apila) y CURA a los aliados que estén dentro. El daño/curas los
## resuelve el host (o la copia local del aliado); el visual corre en todos.
extends Node3D

@export var radius: float = 3.2
@export var duration: float = 5.0
## Cada cuánto hace efecto (seg).
@export var tick_interval: float = 0.5
@export var color: Color = Color(0.55, 0.9, 0.25)

var damage: float = 10.0
var source: Node = null
var is_crit: bool = false
var applies: Array = []
var detonates: Array = []

var _tick_timer: float = 0.0
var _life: float = 0.0
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D

## Configura el efecto con el daño rolleado por el lanzador (NetSpawn).
func setup(p_damage: float, p_source: Node = null, p_crit: bool = false) -> void:
	damage = p_damage
	source = p_source
	is_crit = p_crit

func _ready() -> void:
	# Disco de ácido burbujeante (visual por código).
	_mesh = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.12
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(color.r, color.g, color.b, 0.55)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.emission_enabled = true
	_mat.emission = color
	_mat.emission_energy_multiplier = 0.8
	mesh.material = _mat
	_mesh.mesh = mesh
	add_child(_mesh)
	_mesh.position.y = 0.06
	# "Aparece" creciendo desde el centro.
	_mesh.scale = Vector3(0.2, 1.0, 0.2)
	create_tween().tween_property(_mesh, "scale", Vector3.ONE, 0.25)

func _physics_process(delta: float) -> void:
	_life += delta
	# Burbujeo: pulso sutil del emissive.
	if _mat:
		_mat.emission_energy_multiplier = 0.6 + 0.4 * absf(sin(_life * 6.0))
	# Desvanecer al final.
	if _life > duration - 0.6 and _mat:
		_mat.albedo_color.a = maxf(0.0, (duration - _life) / 0.6) * 0.55
	if _life >= duration:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer > 0.0:
		return
	_tick_timer = tick_interval
	_do_tick()

## Un pulso del charco: consulta física del área y aplica efecto por bando.
func _do_tick() -> void:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), global_position + Vector3(0, 0.5, 0))
	var peer: int = source.get_multiplayer_authority() if source else 0
	FX.burst(global_position + Vector3(randf_range(-radius, radius) * 0.6, 0.2,
		randf_range(-radius, radius) * 0.6), color, 4, 0.05)
	for hit in get_world_3d().direct_space_state.intersect_shape(params, 24):
		var body = hit.get("collider")
		if body == null:
			continue
		if body.is_in_group("player"):
			# Cura por tick a la copia local del aliado (vida local).
			if body.is_multiplayer_authority() and body.has_method("heal"):
				body.heal(damage * 0.35)
		elif is_multiplayer_authority() and body.has_method("apply_status"):
			# Enemigos: derretir — daño + Sangrado que se apila cada tick.
			if body.has_method("take_damage"):
				body.take_damage(damage * 0.4, false)
			var to_detonate: Array = detonates
			if source and source.has_method("elixir_primed") and source.elixir_primed():
				to_detonate = ["burn", "frozen", "marked", "bleed"]
			if not to_detonate.is_empty():
				body.detonate_status(to_detonate, peer)
			for tag: StringName in applies:
				body.apply_status(tag, damage, peer)
