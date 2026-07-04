extends CharacterBody3D

@export var max_health: float = 30.0
@export var speed: float = 3.0
@export var loot_drop_scene: PackedScene = preload("res://scenes/loot/LootDrop.tscn")
## Nivel del botín que dropea (lo setea el spawner según la oleada).
@export var loot_level: int = 1
## Probabilidad [0..1] de dropear equipo al morir.
@export var drop_chance: float = 0.5
## Probabilidad [0..1] de botar además una poción de maná (vida NUNCA dropea
## de enemigos: solo sale de cofres).
@export var mana_drop_chance: float = 0.35
## Color del cuerpo (las variantes del spawner lo cambian).
@export var body_color: Color = Color(0.2, 0.8, 0.2)
## Escala de la variante (rápido chico, tanque grande). Ajusta visual y colisión.
@export var size_scale: float = 1.0

var current_health: float
var _health_bar: HealthBar3D
var _material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health

	# Material propio de la instancia, tintado por variante.
	var mesh: MeshInstance3D = $Visual/Mesh
	_material = mesh.mesh.surface_get_material(0).duplicate()
	_material.albedo_color = body_color
	mesh.set_surface_override_material(0, _material)

	# Escala de la variante: visual + forma de colisión propia.
	if not is_equal_approx(size_scale, 1.0):
		$Visual.scale = Vector3.ONE * size_scale
		var collision: CollisionShape3D = $CollisionShape3D
		collision.shape = collision.shape.duplicate()
		collision.shape.radius *= size_scale
		collision.position.y = collision.shape.radius
		$Visual.position.y = collision.shape.radius

	# Barra de vida flotante para que se vea cómo van perdiendo.
	_health_bar = HealthBar3D.new()
	add_child(_health_bar)
	_health_bar.position.y = 1.25 * size_scale

func _physics_process(delta: float) -> void:
	# Búsqueda simple del jugador
	var player = get_tree().get_first_node_in_group("player")

	if player:
		# Mover hacia el jugador en el plano XZ
		var direction = global_position.direction_to(player.global_position)
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Girar suavemente hacia el jugador
		if direction != Vector3.ZERO:
			var target_look = global_position + direction
			# Evitar errores de look_at cuando target == global_position
			if global_position.distance_squared_to(target_look) > 0.01:
				look_at(target_look, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Gravedad
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()

func take_damage(amount: float) -> void:
	current_health -= amount
	_health_bar.set_ratio(current_health / max_health)

	# Parpadeo blanco al recibir daño; vuelve al color de la variante
	# (no al color leído, que podría ser el blanco de un flash anterior).
	_material.albedo_color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(_material, "albedo_color", body_color, 0.2)

	if current_health <= 0:
		die()

func die() -> void:
	# El kill carga la stamina del super del jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_super_charge"):
		player.add_super_charge(12.0)

	if loot_drop_scene and randf() <= drop_chance:
		_spawn_drop(Loot.generate_random_item(loot_level), Vector3.ZERO)

	# Algunos enemigos botan maná (vida nunca: solo en cofres).
	if loot_drop_scene and randf() <= mana_drop_chance:
		_spawn_drop(Loot.make_potion(&"potion_mana"), Vector3(0.7, 0, 0.2))

	queue_free()

func _spawn_drop(item: LootItem, offset: Vector3) -> void:
	if item == null:
		return
	var drop = loot_drop_scene.instantiate()
	drop.item = item
	get_parent().add_child(drop)
	drop.global_position = global_position + offset
