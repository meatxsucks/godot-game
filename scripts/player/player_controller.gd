extends CharacterBody3D

@export var speed: float = 6.0
@export var acceleration: float = 10.0
@export var fireball_scene: PackedScene = preload("res://scenes/magic/Fireball.tscn")
## Cooldown base de la Bola de Fuego (segundos), antes de cast_speed/CDR.
@export var fire_cooldown: float = 0.5
## Coste de maná por lanzamiento.
@export var fireball_mana_cost: float = 15.0

## Stats del mago (base + loot equipado). Fuente de verdad del combate.
var stats := PlayerStats.new()

var fire_timer: float = 0.0

## UI / HUD puede conectarse a estas señales.
signal stats_changed
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal item_equipped(item: LootItem, previous: LootItem)

@onready var visual: Node3D = $Visual
@onready var wand: MeshInstance3D = $Visual/Wand

func _ready() -> void:
	add_to_group("player")
	_emit_resource_signals()
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	_move(delta)
	_aim_at_mouse()
	_regen_mana(delta)

	fire_timer -= delta
	if Input.is_action_pressed("attack_primary") and fire_timer <= 0.0:
		_cast_fireball()

# --- Movimiento -----------------------------------------------------------

func _move(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Alinear con la cámara: "W" siempre mueve hacia "arriba" en pantalla.
	var camera := get_viewport().get_camera_3d()
	if camera and direction != Vector3.ZERO:
		var cam_forward := -camera.global_transform.basis.z
		var cam_right := camera.global_transform.basis.x
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		direction = (cam_right * direction.x + cam_forward * -direction.z).normalized()

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()

# --- Apuntado -------------------------------------------------------------

func _aim_at_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, 0.0)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit:
		hit.y = visual.global_position.y
		if hit.distance_squared_to(visual.global_position) > 0.1:
			visual.look_at(hit, Vector3.UP)

# --- Combate / Magia ------------------------------------------------------

## Cooldown real tras aplicar cast_speed y reducción de enfriamiento.
func _effective_cooldown() -> float:
	var cast_speed := stats.get_stat(&"cast_speed")
	var cdr := stats.get_stat(&"cooldown_reduction")
	var cd := fire_cooldown * (1.0 - cdr / 100.0) / (1.0 + cast_speed / 100.0)
	return maxf(0.05, cd)

func _cast_fireball() -> void:
	if stats.mana < fireball_mana_cost:
		return
	stats.mana -= fireball_mana_cost
	_emit_resource_signals()
	fire_timer = _effective_cooldown()

	if not fireball_scene:
		return
	var fireball := fireball_scene.instantiate()
	get_parent().add_child(fireball)
	fireball.global_transform = wand.global_transform

	var result := stats.roll_spell_damage()
	var dmg: float = result[0]
	var is_crit: bool = result[1]
	if fireball.has_method("setup"):
		fireball.setup(dmg, self, is_crit)

	# Poder legendario "Cascada Crítica": cada crítico recorta el cooldown.
	if is_crit and stats.has_legendary(&"crit_cdr"):
		fire_timer = maxf(0.0, fire_timer - 0.5)

func _regen_mana(delta: float) -> void:
	var max_mana := stats.get_stat(&"max_mana")
	if stats.mana < max_mana:
		stats.mana = minf(max_mana, stats.mana + stats.get_stat(&"mana_regen") * delta)
		mana_changed.emit(stats.mana, max_mana)

func take_damage(amount: float) -> void:
	stats.health = maxf(0.0, stats.health - amount)
	health_changed.emit(stats.health, stats.get_stat(&"max_health"))
	if stats.health <= 0.0:
		_die()

func _die() -> void:
	# Placeholder: aquí iría game over / respawn. Por ahora solo log.
	print("[Player] derrotado")

# --- Loteo ----------------------------------------------------------------

## Equipa un ítem recogido y propaga el cambio de stats. Devuelve el ítem previo.
func equip(item: LootItem) -> LootItem:
	var previous := stats.equip(item)
	_emit_resource_signals()
	stats_changed.emit()
	item_equipped.emit(item, previous)
	return previous

func _emit_resource_signals() -> void:
	health_changed.emit(stats.health, stats.get_stat(&"max_health"))
	mana_changed.emit(stats.mana, stats.get_stat(&"max_mana"))
