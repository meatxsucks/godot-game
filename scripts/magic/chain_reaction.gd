## Alquimista R — Reacción en Cadena: los enemigos cercanos EXPLOTAN uno tras
## otro (pop-pop-pop), y cada explosión detona TODOS sus tags y salpica daño
## a los vecinos. Corre en el host (resuelve el daño); el visual de cada pop
## se replica por RPC. El heal/prime de party lo dispara la habilidad aparte.
extends Node3D

@export var reach: float = 9.0
## Radio de salpicadura de cada explosión.
@export var splash_radius: float = 2.6
@export var step_delay: float = 0.14
@export var color: Color = Color(0.55, 0.9, 0.25)

var damage: float = 30.0
var source: Node = null
var is_crit: bool = false

const ALL_TAGS := [&"burn", &"frozen", &"marked", &"bleed"]

## Configura el efecto con el daño rolleado por el lanzador (NetSpawn).
func setup(p_damage: float, p_source: Node = null, p_crit: bool = false) -> void:
	damage = p_damage
	source = p_source
	is_crit = p_crit

func _ready() -> void:
	# Diferido un frame: la posición del spawn ya está aplicada y la consulta
	# física ve el estado del mundo asentado (robusto a cualquier orden de
	# add_child/seteo de posición).
	if is_multiplayer_authority():
		_run_chain.call_deferred()
	# Se libera solo tras la secuencia (margen para los últimos FX).
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _run_chain() -> void:
	var peer: int = source.get_multiplayer_authority() if source else 0
	# Enemigos al alcance, ordenados del más cercano al más lejano = la
	# cadena "avanza" visiblemente hacia afuera.
	var targets: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and global_position.distance_to(enemy.global_position) <= reach:
			targets.append(enemy)
	targets.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	_pop_next(targets, 0, peer)

func _pop_next(targets: Array, i: int, peer: int) -> void:
	if i >= targets.size():
		return
	var enemy = targets[i]
	if is_instance_valid(enemy) and enemy.has_method("detonate_status"):
		var pos: Vector3 = enemy.global_position
		enemy.detonate_status(ALL_TAGS, peer)
		# Salpicadura: daño a todos los enemigos cerca del que explotó.
		var shape := SphereShape3D.new()
		shape.radius = splash_radius
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = Transform3D(Basis(), pos + Vector3(0, 0.5, 0))
		for hit in get_world_3d().direct_space_state.intersect_shape(params, 16):
			var body = hit.get("collider")
			if body and body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(damage, is_crit)
		# El visual va al final: si el nodo aún no tiene ruta de red válida,
		# el .rpc() no debe abortar el daño (que es lo que importa).
		_boom.rpc(pos)
	get_tree().create_timer(step_delay).timeout.connect(_pop_next.bind(targets, i + 1, peer))

## Visual de una explosión en TODAS las máquinas.
@rpc("authority", "call_local", "reliable")
func _boom(pos: Vector3) -> void:
	FX.burst(pos + Vector3(0, 0.6, 0), color, 20, 0.1)
	FX.shake(0.12)
