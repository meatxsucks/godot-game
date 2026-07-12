## SUPER — Tormenta de Meteoros: lluvia de impactos AoE alrededor del punto
## objetivo. Los meteoros (visual + luz + daño) se generan por código.
extends Node3D

@export var meteor_count: int = 8
## Radio alrededor del punto objetivo donde caen los meteoros.
@export var spawn_radius: float = 5.0
## Ventana de tiempo en la que se reparten las caídas.
@export var duration: float = 1.5
@export var impact_radius: float = 1.8
@export var fall_height: float = 12.0
@export var fall_time: float = 0.35
## Tematización: color y tamaño de los proyectiles (meteoro vs flecha).
@export var meteor_color: Color = Color(1.0, 0.35, 0.1)
@export var meteor_size: float = 0.5

var damage: float = 30.0
var source: Node = null

## Impactos encolados: la consulta física debe correr en _physics_process.
var _pending_impacts: Array[Vector3] = []

## Configura la tormenta con el daño por meteoro calculado por el lanzador.
## `_crit` se acepta por uniformidad con el resto de los setup() (NetSpawn
## los llama con 3 argumentos); los meteoros no critean.
func setup(p_damage: float, p_source: Node = null, _crit: bool = false) -> void:
	damage = p_damage
	source = p_source

func _ready() -> void:
	for i in meteor_count:
		var delay := (float(i) / meteor_count) * duration + randf() * 0.1
		var angle := randf() * TAU
		var dist := sqrt(randf()) * spawn_radius
		var target := global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		get_tree().create_timer(delay).timeout.connect(_drop_meteor.bind(target))
	# Liberar la tormenta cuando ya cayeron todos los meteoros.
	get_tree().create_timer(duration + fall_time + 1.0).timeout.connect(queue_free)

func _physics_process(_delta: float) -> void:
	for target in _pending_impacts:
		_do_impact(target)
	_pending_impacts.clear()

func _drop_meteor(target: Vector3) -> void:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = meteor_size
	sphere.height = meteor_size * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = meteor_color
	mat.emission_enabled = true
	mat.emission = meteor_color
	mat.emission_energy_multiplier = 2.0
	sphere.material = mat
	ball.mesh = sphere
	add_child(ball)
	ball.global_position = target + Vector3(0, fall_height, 0)

	var tween := create_tween()
	tween.tween_property(ball, "global_position", target, fall_time)
	tween.tween_callback(func() -> void: _pending_impacts.append(target))
	tween.tween_callback(_flash.bind(target))
	tween.tween_callback(ball.queue_free)

## Daño AoE del impacto vía consulta directa al espacio físico.
func _do_impact(target: Vector3) -> void:
	var shape := SphereShape3D.new()
	shape.radius = impact_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), target)
	var hits := get_world_3d().direct_space_state.intersect_shape(params, 16)
	for hit in hits:
		var body = hit.get("collider")
		if body == null or body == source:
			continue
		if body is Node3D and body.is_in_group("player"):
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _flash(target: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = meteor_color
	light.light_energy = 4.0
	light.omni_range = impact_radius * 2.0
	add_child(light)
	light.global_position = target + Vector3.UP
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.3)
	tween.tween_callback(light.queue_free)
