extends Area3D

@export var speed: float = 15.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

## Quién lanzó el proyectil (para evitar fuego amigo / auto-impacto).
var source: Node = null
var is_crit: bool = false

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

	# Muere al impactar contra cualquier cuerpo físico (enemigo o pared).
	queue_free()
