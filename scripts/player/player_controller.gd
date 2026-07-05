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

## Cooldown del legendario "Corazón de Escarcha" (nova al recibir un golpe).
const FROST_GUARD_SCENE := preload("res://scenes/magic/FrostNova.tscn")
var _frost_guard_timer: float = 0.0

var _dash_timer: float = 0.0
var _dash_dir := Vector3.ZERO
## Daño del dash (Embestida del Guerrero; 0 = dash sin daño) y ya golpeados.
var _dash_damage: float = 0.0
var _dash_hit := {}
var _dead: bool = false
var _body_material: StandardMaterial3D
var _body_color: Color

## Modelo KayKit de la clase (si cargó) y sus animaciones.
var _model_anim: AnimationPlayer = null
var _anims: Dictionary = {}
var _attack_lock: float = 0.0

## Apuntado con el stick derecho del mando (fallback: mouse).
var _pad_aim := Vector3.FORWARD
var _use_pad_aim := false

## Arma actual del slot básico (el LMB cambia según el arma equipada).
var _last_weapon_id: StringName = &"__init__"

## UI / HUD puede conectarse a estas señales.
signal stats_changed
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal item_equipped(item: LootItem, previous: LootItem)
signal super_charge_changed(current: float, maximum: float)
signal inventory_changed
signal skills_changed
signal xp_changed(current: float, needed: float, level: int)
signal leveled_up(new_level: int)
signal kit_changed
signal died

@onready var visual: Node3D = $Visual
@onready var wand: MeshInstance3D = $Visual/Wand

func _ready() -> void:
	add_to_group("player")
	abilities = Game.build_kit()
	cooldowns.resize(abilities.size())
	cooldowns.fill(0.0)

	# Material propio del cuerpo para el flash de daño recibido.
	var body_mesh: MeshInstance3D = $Visual/Body
	_body_material = body_mesh.mesh.surface_get_material(0).duplicate()
	_body_color = _body_material.albedo_color
	body_mesh.set_surface_override_material(0, _body_material)

	_setup_model()
	# El ataque básico depende del arma equipada (arranca desarmado).
	stats_changed.connect(_refresh_basic)
	_refresh_basic()
	_emit_resource_signals()
	stats_changed.emit()

func _input(event: InputEvent) -> void:
	# Mover el mouse devuelve el apuntado al cursor.
	if event is InputEventMouseMotion:
		_use_pad_aim = false

## Modelo KayKit animado de la clase. Si no carga, queda la cápsula placeholder.
func _setup_model() -> void:
	var def: Dictionary = Game.class_def(Game.selected_class)
	var path: String = def.get("model", "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene = load(path)
	if scene == null:
		return
	var model: Node3D = scene.instantiate()
	visual.add_child(model)
	model.rotation.y = PI # KayKit mira +Z; nuestro Visual apunta -Z al cursor
	_model_anim = model.find_child("AnimationPlayer", true, false)
	_anims = def.get("anims", {})
	# Placeholders fuera (el Wand queda invisible como marcador de spawn).
	$Visual/Body.visible = false
	wand.visible = false
	if _model_anim and _anims.has("idle"):
		_model_anim.play(_anims["idle"])

	# Paper-doll: el equipo se ve puesto (arranca con las manos vacías).
	var equipment_visuals := EquipmentVisuals.new()
	add_child(equipment_visuals)
	equipment_visuals.setup(self, model)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_frost_guard_timer = maxf(0.0, _frost_guard_timer - delta)
	_move(delta)
	_aim_at_mouse()
	_update_abilities(delta)
	_update_animation(delta)

## Idle/correr según la velocidad; el ataque tiene prioridad breve.
func _update_animation(delta: float) -> void:
	if _model_anim == null or _dead:
		return
	if _attack_lock > 0.0:
		_attack_lock -= delta
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.5
	var target: String = _anims.get("run", "") if moving else _anims.get("idle", "")
	if target != "" and _model_anim.current_animation != target:
		_model_anim.play(target, 0.15)
	# Sin patinar: la anim de correr acompaña la velocidad REAL medida.
	_model_anim.speed_scale = clampf(horizontal_speed / 2.2, 0.8, 3.0) if moving else 1.0

func _play_attack_animation() -> void:
	if _model_anim == null:
		return
	var attack: String = _anims.get("attack", "")
	if attack == "":
		return
	_model_anim.speed_scale = 1.0
	_model_anim.play(attack, 0.1)
	_attack_lock = minf(_model_anim.current_animation_length, 0.45)

## El ataque básico (slot 0) depende del ARMA equipada: espada = corte,
## bastón = Bola de Fuego, varita = Descarga, sin arma = Golpe débil.
func _refresh_basic() -> void:
	var weapon: LootItem = stats.equipment.get(&"weapon", null)
	var weapon_id: StringName = weapon.base.id if (weapon and weapon.base) else &""
	if weapon_id == _last_weapon_id:
		return
	_last_weapon_id = weapon_id

	var basic: Ability
	if weapon == null or weapon.base == null:
		basic = UnarmedAbility.new()
	else:
		match weapon.base.type:
			&"sword":
				basic = SlashAbility.new()
			&"wand":
				basic = ArcBoltAbility.new()
			_:
				basic = FireballAbility.new()
	abilities[0] = basic
	cooldowns[0] = 0.0
	kit_changed.emit()

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
		# Embestida: daña una vez a cada cuerpo que atraviesa.
		if _dash_damage > 0.0:
			for i in get_slide_collision_count():
				var collider: Object = get_slide_collision(i).get_collider()
				if collider and collider.has_method("take_damage") and not _dash_hit.has(collider):
					_dash_hit[collider] = true
					collider.take_damage(_dash_damage)
					add_super_charge(4.0)
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

## Dirección del input WASD/stick izquierdo alineada a la cámara.
func _camera_aligned_input() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return _camera_align(Vector3(input_dir.x, 0, input_dir.y))

## Alinea un vector plano (x, z) a la orientación de la cámara: "arriba"
## del input siempre es "arriba" en pantalla.
func _camera_align(direction: Vector3) -> Vector3:
	if direction == Vector3.ZERO:
		return Vector3.ZERO
	direction = direction.normalized()
	var camera := get_viewport().get_camera_3d()
	if camera:
		var cam_forward := -camera.global_transform.basis.z
		var cam_right := camera.global_transform.basis.x
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		direction = (cam_right * direction.x + cam_forward * -direction.z).normalized()
	return direction

## Impulso del dash: SIEMPRE hacia donde mira el personaje (cursor/stick).
## `damage` > 0 = Embestida (daña lo que atraviesa).
func start_dash(damage: float = 0.0) -> bool:
	var dir := -visual.global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	_dash_dir = dir.normalized()
	_dash_timer = DASH_TIME
	_dash_damage = damage
	_dash_hit.clear()
	FX.burst(global_position + Vector3(0, 0.3, 0), Color(0.85, 0.9, 1.0), 8, 0.05)
	return true

# --- Apuntado -------------------------------------------------------------

## Punto del suelo (plano Y=0) al que se apunta: cursor del mouse, o el
## stick derecho del mando si fue lo último usado.
func get_aim_point() -> Vector3:
	if _use_pad_aim:
		return global_position + _pad_aim * 6.0
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

## Punto FRENTE al personaje (los supers dirigidos caen ahí).
func get_front_point(distance: float = 5.5) -> Vector3:
	var forward := -visual.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	return global_position + forward.normalized() * distance

func _aim_at_mouse() -> void:
	# Stick derecho del mando: apuntado directo alineado a cámara.
	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() > 0.35:
		_use_pad_aim = true
		_pad_aim = _camera_align(Vector3(stick.x, 0, stick.y))

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
	_play_attack_animation()
	# Entrenamiento estilo Tibia: cada casteo da XP a su elemento y a Magia.
	if ability.element != &"":
		stats.skills.add_xp(ability.element, 2.0)
		stats.skills.add_xp(&"magic", 1.0)
		skills_changed.emit()
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
# Vida y maná NO se regeneran solos: son recursos limitados. Se recuperan con
# pociones (vida solo de cofres) y con el maná por kill del stat mana_regen.

## Recompensa por matar un enemigo: stamina del super + maná por kill + XP.
func on_enemy_killed(xp_reward: float = 10.0) -> void:
	add_super_charge(12.0)
	restore_mana(stats.get_stat(&"mana_regen"))

	var level_ups := stats.add_xp(xp_reward)
	xp_changed.emit(stats.xp, stats.xp_needed(), stats.level)
	if level_ups > 0:
		FX.burst(global_position + Vector3.UP, Color(1.0, 0.9, 0.3), 22, 0.1)
		_emit_resource_signals()
		stats_changed.emit()
		leveled_up.emit(stats.level)

## Cura instantánea (pociones). No supera el máximo.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	stats.health = minf(stats.get_stat(&"max_health"), stats.health + amount)
	health_changed.emit(stats.health, stats.get_stat(&"max_health"))

## Restaura maná instantáneo (pociones). No supera el máximo.
func restore_mana(amount: float) -> void:
	if amount <= 0.0:
		return
	stats.mana = minf(stats.get_stat(&"max_mana"), stats.mana + amount)
	mana_changed.emit(stats.mana, stats.get_stat(&"max_mana"))

func take_damage(amount: float, _is_crit: bool = false) -> void:
	# Durante el dash eres intangible (i-frames estilo Wizard of Legend).
	if _dead or _dash_timer > 0.0:
		return

	# Legendario "Desborde Arcano": el maná es tu escudo — la mitad del daño
	# se absorbe con maná (1:1) mientras tengas.
	if stats.has_legendary(&"mana_to_shield") and stats.mana > 0.0:
		var absorbed := minf(amount * 0.5, stats.mana)
		stats.mana -= absorbed
		amount -= absorbed
		mana_changed.emit(stats.mana, stats.get_stat(&"max_mana"))

	stats.health = maxf(0.0, stats.health - amount)
	health_changed.emit(stats.health, stats.get_stat(&"max_health"))

	# Feedback: número rojo + sacudida si el golpe fue fuerte.
	FX.damage_number(global_position, amount, false, Color(1.0, 0.25, 0.25))
	if amount >= 15.0:
		FX.shake(0.35)

	# Legendario "Corazón de Escarcha": nova de hielo defensiva (cd 6s).
	if _frost_guard_timer <= 0.0 and stats.has_legendary(&"on_hit_frost_nova"):
		_frost_guard_timer = 6.0
		var result := stats.roll_spell_damage(&"cold_damage", 1.0)
		var nova := FROST_GUARD_SCENE.instantiate()
		get_parent().add_child(nova)
		nova.global_position = global_position
		if nova.has_method("setup"):
			nova.setup(result[0], self, result[1])

	# Flash rojo al recibir daño.
	_body_material.albedo_color = Color(1.0, 0.25, 0.25)
	var tween := create_tween()
	tween.tween_property(_body_material, "albedo_color", _body_color, 0.25)

	if stats.health <= 0.0:
		_die()

func _die() -> void:
	_dead = true
	# Animación de muerte del modelo; caída con tween como fallback.
	if _model_anim and _anims.has("death"):
		_model_anim.play(_anims["death"], 0.1)
	else:
		var tween := create_tween()
		tween.tween_property(visual, "rotation:x", -PI / 2.0, 0.5) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	died.emit()

# --- Loteo / inventario -----------------------------------------------------

## Recoge un ítem del suelo al inventario. false = inventario lleno.
func pick_up(item: LootItem) -> bool:
	if item == null or inventory.size() >= INVENTORY_SIZE:
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

## Usa el ítem en `index` del inventario: las pociones se consumen (un solo
## uso), el equipo se equipa. Los desplazados (slot ocupado, conflicto a dos
## manos) vuelven al inventario.
func equip_from_inventory(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item := inventory[index]
	if item.is_consumable():
		heal(item.effective(&"restore_health"))
		restore_mana(item.effective(&"restore_mana"))
		inventory.remove_at(index)
		inventory_changed.emit()
		return
	inventory.remove_at(index)
	var displaced := stats.equip(item)
	inventory.append_array(displaced)
	inventory_changed.emit()
	_emit_resource_signals()
	stats_changed.emit()
	item_equipped.emit(item, displaced[0] if not displaced.is_empty() else null)

## Reordena el inventario (drag & drop). Si `to` es una celda vacía (fuera
## del rango actual), mueve el ítem al final.
func swap_inventory(from: int, to: int) -> void:
	if from < 0 or from >= inventory.size() or from == to:
		return
	if to < 0 or to >= inventory.size():
		var item := inventory[from]
		inventory.remove_at(from)
		inventory.append(item)
	else:
		var tmp := inventory[from]
		inventory[from] = inventory[to]
		inventory[to] = tmp
	inventory_changed.emit()

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
