extends CharacterBody3D

@export var max_health: float = 30.0
@export var speed: float = 3.0
@export var loot_drop_scene: PackedScene = preload("res://scenes/loot/LootDrop.tscn")
## Nivel del botín que dropea (lo setea el spawner según la oleada).
@export var loot_level: int = 1
## Probabilidad [0..1] de dropear algo al morir.
@export var drop_chance: float = 1.0

var current_health: float

func _ready() -> void:
	current_health = max_health

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
	
	# Efecto visual de daño temporal (parpadeo blanco)
	var mesh = $Visual/Mesh
	var mat = mesh.get_surface_override_material(0)
	if mat == null:
		mat = mesh.mesh.surface_get_material(0).duplicate()
		mesh.set_surface_override_material(0, mat)
		
	var orig_color = mat.albedo_color
	mat.albedo_color = Color.WHITE
	
	var tween = create_tween()
	tween.tween_property(mat, "albedo_color", orig_color, 0.2)
	
	if current_health <= 0:
		die()

func die() -> void:
	# El kill carga la stamina del super del jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_super_charge"):
		player.add_super_charge(12.0)

	if loot_drop_scene and randf() <= drop_chance:
		var drop = loot_drop_scene.instantiate()
		drop.item = Loot.generate_random_item(loot_level)
		get_parent().add_child(drop)
		drop.global_position = global_position

	queue_free()
