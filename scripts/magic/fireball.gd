extends Area3D

@export var speed: float = 15.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
## Stamina de super que gana el lanzador por cada impacto conectado.
@export var super_charge_on_hit: float = 4.0
## true = atraviesa enemigos (Flecha Perforante); contra muros siempre muere.
@export var pierces: bool = false

## Quién lanzó el proyectil (para evitar fuego amigo / auto-impacto).
var source: Node = null
var is_crit: bool = false
## Rebotes restantes (legendario "Pira en Cadena"): al impactar salta al
## enemigo más cercano con el 60% del daño.
var chains_left: int = 0

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
	global_position -= global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	# Ignorar al propio lanzador y al jugador (sin fuego amigo).
	if body == source or body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		if source and source.has_method("add_super_charge"):
			source.add_super_charge(super_charge_on_hit)
		if chains_left > 0:
			_chain_from(body)
		if pierces:
			return # sigue de largo a través del enemigo

	# Muere al impactar contra cualquier cuerpo físico (enemigo o pared).
	queue_free()

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
