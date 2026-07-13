## Frasco de ácido del Alquimista (E7.1): estalla en el punto apuntado y
## afecta a AMBOS bandos en la misma área — CURA a los aliados (la cura es
## el daño rolleado: escala con stats/afijos), y a los enemigos les hace
## DAÑO de ácido además de aplicar/detonar sus tags. Co-op: cada peer cura
## a SU player local; daño y tags los resuelve la copia del host.
extends Node3D

@export var radius: float = 3.0
@export var splash_color: Color = Color(0.5, 1.0, 0.6)
## Daño a enemigos como fracción del roll (la cura a aliados es el 100%).
@export var enemy_damage_ratio: float = 0.6

var damage: float = 10.0
var source: Node = null
var is_crit: bool = false
var applies: Array = []
var detonates: Array = []

var _did_effect := false

func _ready() -> void:
	# Anillo que crece y se desvanece (visual por código, estilo nova).
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.7
	mesh.outer_radius = 0.9
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = splash_color
	mat.emission_enabled = true
	mat.emission = splash_color
	mesh.material = mat
	ring.mesh = mesh
	add_child(ring)
	ring.position.y = 0.15

	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3.ONE * radius, 0.35)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tween.tween_callback(queue_free)
	FX.burst(global_position + Vector3(0, 0.5, 0), splash_color, 14, 0.08)

func _physics_process(_delta: float) -> void:
	# La consulta física corre una sola vez, en el primer frame de física.
	if _did_effect:
		return
	_did_effect = true
	var shape := SphereShape3D.new()
	shape.radius = radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), global_position + Vector3(0, 0.5, 0))
	var peer: int = source.get_multiplayer_authority() if source else 0
	for hit in get_world_3d().direct_space_state.intersect_shape(params, 16):
		var body = hit.get("collider")
		if body == null:
			continue
		if body.is_in_group("player"):
			# Cura al player LOCAL de esta máquina (su vida es local).
			if body.is_multiplayer_authority() and body.has_method("heal"):
				body.heal(damage)
				FX.burst(body.global_position + Vector3.UP, splash_color, 10, 0.06)
		elif is_multiplayer_authority() and body.has_method("apply_status"):
			# Enemigos: daño de ácido + tags (solo la copia con autoridad).
			if enemy_damage_ratio > 0.0 and body.has_method("take_damage"):
				body.take_damage(damage * enemy_damage_ratio, is_crit)
			var to_detonate: Array = detonates
			if source and source.has_method("elixir_primed") and source.elixir_primed():
				to_detonate = ["burn", "frozen", "marked", "bleed"]
			if not to_detonate.is_empty():
				body.detonate_status(to_detonate, peer)
			for tag: StringName in applies:
				body.apply_status(tag, damage, peer)
