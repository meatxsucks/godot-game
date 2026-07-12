## Nova de Escarcha: anillo AoE que crece desde el mago y daña una sola vez
## a cada enemigo que toca.
extends Area3D

@export var max_radius: float = 4.0
@export var expand_time: float = 0.4
## Ralentización aplicada a los golpeados (hielo). 1.0 = sin efecto.
@export var slow_factor: float = 1.0
@export var slow_time: float = 0.0

var damage: float = 10.0
var source: Node = null
var is_crit: bool = false

## Cuerpos ya golpeados por esta nova (un solo golpe por enemigo).
var _already_hit := {}

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

## Configura la nova con el daño calculado por el lanzador.
func setup(p_damage: float, p_source: Node = null, p_crit: bool = false) -> void:
	damage = p_damage
	source = p_source
	is_crit = p_crit

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Forma única por instancia para poder animar el radio sin afectar otras novas.
	collision.shape = collision.shape.duplicate()
	var tween := create_tween()
	tween.tween_method(_set_radius, 0.3, max_radius, expand_time)
	tween.tween_interval(0.1)
	tween.tween_callback(queue_free)

func _set_radius(radius: float) -> void:
	collision.shape.radius = radius
	mesh.scale = Vector3.ONE * radius

func _on_body_entered(body: Node3D) -> void:
	if body == source or body.is_in_group("player") or _already_hit.has(body):
		return
	_already_hit[body] = true
	if body.has_method("take_damage"):
		body.take_damage(damage, is_crit)
		if slow_factor < 1.0 and body.has_method("apply_slow"):
			body.apply_slow(slow_factor, slow_time)
		# Solo la copia con autoridad acredita el super (réplicas = visual).
		if is_multiplayer_authority() and source and source.has_method("add_super_charge"):
			source.add_super_charge(4.0)
