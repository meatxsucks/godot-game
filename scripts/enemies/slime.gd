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
## Daño por contacto al jugador y cadencia entre golpes.
@export var attack_damage: float = 8.0
@export var attack_interval: float = 1.0

var current_health: float
var _health_bar: HealthBar3D
var _material: StandardMaterial3D
var _safe_zone: SafeZone
var _attack_timer: float = 0.0
var _repath_timer: float = 0.0

@onready var _nav_agent: NavigationAgent3D = $NavAgent

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_safe_zone = get_tree().get_first_node_in_group("safe_zone")

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
	var direction := _pick_direction(delta)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Girar suavemente hacia donde se mueve
		var target_look := global_position + direction
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

	_attack_timer -= delta
	_try_attack()

## Golpe por contacto: si el jugador está al alcance, le pega y espera
## `attack_interval` antes del próximo golpe.
func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("take_damage"):
		return
	var reach := 0.6 + 0.6 * size_scale
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	if to_player.length_squared() <= reach * reach:
		player.take_damage(attack_damage)
		_attack_timer = attack_interval

## Decide hacia dónde moverse respetando la zona segura: si el slime está
## dentro sale por el camino más corto; si el jugador está a salvo, espera
## afuera; si la zona queda en el camino, la rodea por la tangente.
func _pick_direction(delta: float) -> Vector3:
	# Nunca dentro de la zona segura: salir.
	if _safe_zone and _safe_zone.contains(global_position):
		var out := global_position - _safe_zone.global_position
		out.y = 0
		return out.normalized() if out.length_squared() > 0.001 else Vector3.RIGHT

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return Vector3.ZERO
	# Jugador a salvo: esperar afuera de la zona.
	if _safe_zone and _safe_zone.contains(player.global_position):
		return Vector3.ZERO

	var direction = global_position.direction_to(player.global_position)
	direction.y = 0
	direction = direction.normalized()

	# Navegación con navmesh: rodea muros hacia la puerta (repath throttled).
	# Si el path aún no existe (bake en curso), queda el beeline directo.
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = 0.25
		_nav_agent.target_position = player.global_position
	var next_point := _nav_agent.get_next_path_position()
	var nav_dir := next_point - global_position
	nav_dir.y = 0
	if nav_dir.length_squared() > 0.01:
		direction = nav_dir.normalized()

	# Si el próximo paso entraría a la zona, rodearla por la tangente.
	if _safe_zone and _safe_zone.contains(global_position + direction * speed * delta):
		var to_center := _safe_zone.global_position - global_position
		to_center.y = 0
		var tangent := Vector3(-to_center.z, 0, to_center.x).normalized()
		direction = tangent if tangent.dot(direction) >= 0.0 else -tangent

	return direction

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
	# Recompensa del kill: stamina del super + maná por kill.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed()

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
