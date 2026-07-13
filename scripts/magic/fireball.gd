extends Area3D

@export var speed: float = 15.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
## Stamina de super que gana el lanzador por cada impacto conectado.
@export var super_charge_on_hit: float = 4.0
## true = atraviesa enemigos (Flecha Perforante); contra muros siempre muere.
@export var pierces: bool = false
## false = proyectil ENEMIGO: ignora al grupo "enemies" y daña al jugador.
@export var friendly: bool = true
## Color de la ráfaga de partículas al impactar.
@export var impact_color: Color = Color(1.0, 0.55, 0.2)

## Quién lanzó el proyectil (para evitar fuego amigo / auto-impacto).
var source: Node = null
var is_crit: bool = false
## Tags de estado (E3) que este golpe aplica/detona (llegan por props).
var applies: Array = []
var detonates: Array = []
## Rebotes restantes (legendario "Pira en Cadena"): al impactar salta al
## enemigo más cercano con el 60% del daño.
var chains_left: int = 0
## Cuerpos ya procesados (el rayo de barrido y body_entered pueden ver al
## mismo enemigo).
var _hit_bodies := {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)

## Configura el proyectil con el daño calculado por el lanzador.
func setup(p_damage: float, p_source: Node = null, p_crit: bool = false) -> void:
	damage = p_damage
	source = p_source
	is_crit = p_crit

func _physics_process(delta: float) -> void:
	var from := global_position
	global_position -= global_transform.basis.z * speed * delta
	# Barrido anti-túnel: los proyectiles rápidos avanzan ~0.5m por frame y
	# podían saltarse la colisión de enemigos chicos. El rayo entre la
	# posición anterior y la nueva no se salta nada.
	var query := PhysicsRayQueryParameters3D.create(from, global_position)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.get("collider") is Node3D:
		_on_body_entered(hit["collider"])

func _on_body_entered(body: Node3D) -> void:
	# Ignorar al lanzador, a los ya golpeados, y al propio bando.
	if body == source or _hit_bodies.has(body):
		return
	if friendly and body.is_in_group("player"):
		return
	if not friendly and body.is_in_group("enemies"):
		return

	if body.has_method("take_damage"):
		_hit_bodies[body] = true
		# Daño a JUGADORES: lo aplica solo la copia local del peer dueño
		# (su vida es local); en las demás copias el impacto es solo visual.
		# El daño a enemigos se auto-filtra (take_damage ignora réplicas).
		if not body.is_in_group("player") or body.is_multiplayer_authority():
			body.take_damage(damage, is_crit)
		_apply_status_tags(body)
		FX.burst(global_position, impact_color, 8, 0.05)
		# El super lo acredita solo la copia con autoridad (host/offline):
		# las réplicas duplicarían el crédito.
		if is_multiplayer_authority() and source and source.has_method("add_super_charge"):
			source.add_super_charge(super_charge_on_hit)
		if chains_left > 0:
			_chain_from(body)
		if pierces:
			return # sigue de largo a través del enemigo

	# Muere al impactar contra cualquier cuerpo físico (enemigo o pared).
	queue_free()

## Tags de estado (E3): detonar primero (no lo recién puesto), luego aplicar.
## Solo la copia con autoridad (host/offline) — los tags son estado del host.
func _apply_status_tags(body: Node3D) -> void:
	if not is_multiplayer_authority() or not body.has_method("apply_status"):
		return
	var peer: int = source.get_multiplayer_authority() if source else 0
	var to_detonate: Array = detonates
	if source and source.has_method("elixir_primed") and source.elixir_primed():
		to_detonate = ["burn", "frozen", "marked", "bleed"]
	if not to_detonate.is_empty():
		body.detonate_status(to_detonate, peer)
	for tag: StringName in applies:
		body.apply_status(tag, damage, peer)

## Legendario "Pira en Cadena": se duplica apuntando al enemigo más cercano
## (≤8m, distinto al golpeado) con 60% del daño y un rebote menos.
func _chain_from(hit_body: Node3D) -> void:
	var nearest: Node3D = null
	var best := 8.0 * 8.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == hit_body or not (enemy is Node3D):
			continue
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist < best:
			best = dist
			nearest = enemy
	if nearest == null:
		return

	var clone := duplicate()
	clone.damage = damage * 0.6
	clone.source = source
	clone.is_crit = false
	clone.chains_left = chains_left - 1
	clone.transform = global_transform
	var dir := nearest.global_position + Vector3(0, 0.4, 0) - global_position
	if dir.length_squared() > 0.001:
		clone.transform.basis = Basis.looking_at(dir.normalized(), Vector3.UP)
	get_parent().add_child.call_deferred(clone)
