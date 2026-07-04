extends CharacterBody3D

@export var speed: float = 6.0
@export var acceleration: float = 10.0

## Dash Arcano: multiplicador de velocidad y duración del impulso.
const DASH_SPEED_MULT := 4.0
const DASH_TIME := 0.15

## Carga máxima de stamina del super.
const SUPER_MAX := 100.0

## Acción de input de cada slot de la barra (mismo orden que `abilities`).
const ABILITY_ACTIONS: Array[StringName] = [
	&"attack_primary",
	&"attack_secondary",
	&"ability_dash",
	&"ability_nova",
	&"ability_super",
]

## Capacidad del inventario (loot recogido, aún no equipado).
const INVENTORY_SIZE := 20

## Stats del mago (base + loot equipado). Fuente de verdad del combate.
var stats := PlayerStats.new()

## Barra de poderes (5 slots) y el cooldown restante de cada uno.
var abilities: Array[Ability] = []
var cooldowns: Array[float] = []

## Loot recogido. Se equipa a mano desde el panel de inventario.
var inventory: Array[LootItem] = []

## false mientras el inventario está abierto: no se castean poderes
## (los cooldowns siguen corriendo).
var combat_input_enabled: bool = true

## Stamina del super (0..SUPER_MAX). Se gana dañando y matando enemigos.
var super_charge: float = 0.0

var _dash_timer: float = 0.0
var _dash_dir := Vector3.ZERO

## UI / HUD puede conectarse a estas señales.
signal stats_changed
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal item_equipped(item: LootItem, previous: LootItem)
signal super_charge_changed(current: float, maximum: float)
signal inventory_changed

@onready var visual: Node3D = $Visual
@onready var wand: MeshInstance3D = $Visual/Wand

func _ready() -> void:
	add_to_group("player")
	abilities = [
		FireballAbility.new(),
		ArcBoltAbility.new(),
		DashAbility.new(),
		FrostNovaAbility.new(),
		MeteorStormAbility.new(),
	]
	cooldowns.resize(abilities.size())
	cooldowns.fill(0.0)
	_emit_resource_signals()
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	_move(delta)
	_aim_at_mouse()
	_regen_mana(delta)
	_update_abilities(delta)

# --- Movimiento -----------------------------------------------------------

## Velocidad de caminata real: base + move_speed (%) de las botas/loot.
func current_speed() -> float:
	return speed * (1.0 + stats.get_stat(&"move_speed") / 100.0)

func _move(delta: float) -> void:
	# Durante el dash la velocidad está bloqueada al impulso.
	if _dash_timer > 0.0:
		_dash_timer -= delta
		velocity.x = _dash_dir.x * current_speed() * DASH_SPEED_MULT
		velocity.z = _dash_dir.z * current_speed() * DASH_SPEED_MULT
		# Al terminar el impulso se corta en seco a velocidad de caminata:
		# sin esto el mago "resbala" mientras desacelera desde x4.
		if _dash_timer <= 0.0:
			velocity.x = _dash_dir.x * current_speed()
			velocity.z = _dash_dir.z * current_speed()
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	var direction := _camera_aligned_input()

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed(), acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed(), acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()

## Dirección del input WASD alineada a la cámara: "W" siempre mueve hacia
## "arriba" en pantalla.
func _camera_aligned_input() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	var camera := get_viewport().get_camera_3d()
	if camera and direction != Vector3.ZERO:
		var cam_forward := -camera.global_transform.basis.z
		var cam_right := camera.global_transform.basis.x
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		direction = (cam_right * direction.x + cam_forward * -direction.z).normalized()

	return direction

## Impulso del Dash Arcano: hacia el input de movimiento, o hacia el cursor
## si el mago está quieto. Devuelve false si no hay dirección válida.
func start_dash() -> bool:
	var dir := _camera_aligned_input()
	if dir == Vector3.ZERO:
		dir = get_aim_point() - global_position
		dir.y = 0.0
		dir = dir.normalized()
	if dir == Vector3.ZERO:
		return false
	_dash_dir = dir
	_dash_timer = DASH_TIME
	return true

# --- Apuntado -------------------------------------------------------------

## Punto del suelo (plano Y=0) bajo el cursor. Lo usan el apuntado del mago
## y las habilidades dirigidas (super).
func get_aim_point() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return global_position
	var mouse_pos := get_viewport().get_mouse_position()
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(
		camera.project_ray_origin(mouse_pos),
		camera.project_ray_normal(mouse_pos))
	if hit == null:
		return global_position
	return hit

func _aim_at_mouse() -> void:
	var hit := get_aim_point()
	hit.y = visual.global_position.y
	if hit.distance_squared_to(visual.global_position) > 0.1:
		visual.look_at(hit, Vector3.UP)

# --- Barra de poderes -------------------------------------------------------

func _update_abilities(delta: float) -> void:
	for i in abilities.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
		if not combat_input_enabled:
			continue
		var action := ABILITY_ACTIONS[i]
		var pressed := Input.is_action_pressed(action) if abilities[i].hold_to_cast \
				else Input.is_action_just_pressed(action)
		if pressed and cooldowns[i] <= 0.0:
			_try_cast(i)

func _try_cast(slot: int) -> void:
	var ability := abilities[slot]
	if not ability.execute(self):
		return
	_emit_resource_signals()
	cooldowns[slot] = maxf(0.0, effective_cooldown(ability.cooldown) - ability.consume_cooldown_refund())

## Cooldown real tras aplicar cast_speed y reducción de enfriamiento del loot.
func effective_cooldown(base: float) -> float:
	var cast_speed := stats.get_stat(&"cast_speed")
	var cdr := stats.get_stat(&"cooldown_reduction")
	var cd := base * (1.0 - cdr / 100.0) / (1.0 + cast_speed / 100.0)
	return maxf(0.05, cd)

## Helpers para el HUD.
func get_ability(slot: int) -> Ability:
	return abilities[slot]

func get_cooldown_left(slot: int) -> float:
	return cooldowns[slot]

func get_cooldown_total(slot: int) -> float:
	return effective_cooldown(abilities[slot].cooldown)

# --- Super (stamina) --------------------------------------------------------

## Acredita stamina del super (impactos de habilidades, kills).
func add_super_charge(amount: float) -> void:
	super_charge = clampf(super_charge + amount, 0.0, SUPER_MAX)
	super_charge_changed.emit(super_charge, SUPER_MAX)

## Gasta la barra entera para lanzar el super; false si aún no está llena.
func consume_super_charge() -> bool:
	if super_charge < SUPER_MAX:
		return false
	super_charge = 0.0
	super_charge_changed.emit(super_charge, SUPER_MAX)
	return true

# --- Recursos ---------------------------------------------------------------

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

# --- Loteo / inventario -----------------------------------------------------

## Recoge un ítem del suelo al inventario. false = inventario lleno.
func pick_up(item: LootItem) -> bool:
	if item == null or inventory.size() >= INVENTORY_SIZE:
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

## Equipa el ítem en `index` del inventario. Los desplazados (slot ocupado,
## conflicto a dos manos) vuelven al inventario.
func equip_from_inventory(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item := inventory[index]
	inventory.remove_at(index)
	var displaced := stats.equip(item)
	inventory.append_array(displaced)
	inventory_changed.emit()
	_emit_resource_signals()
	stats_changed.emit()
	item_equipped.emit(item, displaced[0] if not displaced.is_empty() else null)

## Desequipa un slot hacia el inventario (si hay espacio).
func unequip_slot(slot: StringName) -> void:
	if inventory.size() >= INVENTORY_SIZE:
		return
	var item := stats.unequip(slot)
	if item == null:
		return
	inventory.append(item)
	inventory_changed.emit()
	_emit_resource_signals()
	stats_changed.emit()

## Equipa un ítem directamente (sin pasar por el inventario); los desplazados
## sí van al inventario. Devuelve el primero desplazado (o null).
func equip(item: LootItem) -> LootItem:
	var displaced := stats.equip(item)
	inventory.append_array(displaced)
	if not displaced.is_empty():
		inventory_changed.emit()
	_emit_resource_signals()
	stats_changed.emit()
	var previous: LootItem = displaced[0] if not displaced.is_empty() else null
	item_equipped.emit(item, previous)
	return previous

func _emit_resource_signals() -> void:
	health_changed.emit(stats.health, stats.get_stat(&"max_health"))
	mana_changed.emit(stats.mana, stats.get_stat(&"max_mana"))
