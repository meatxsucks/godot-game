extends CharacterBody3D

@export var max_health: float = 30.0
@export var speed: float = 3.0
@export var loot_drop_scene: PackedScene = preload("res://scenes/loot/LootDrop.tscn")
## Nivel del botín que dropea (lo setea el spawner según la oleada).
@export var loot_level: int = 1
## Probabilidad [0..1] de dropear equipo al morir. 0 por diseño: el equipo
## cae como RECOMPENSA al superar la oleada (menos ruido en el suelo).
@export var drop_chance: float = 0.0
## Probabilidad [0..1] de botar además una poción de maná (vida NUNCA dropea
## de enemigos: solo sale de cofres).
@export var mana_drop_chance: float = 0.35
## Probabilidad de soltar oro POR JUGADOR al morir (E5.1).
@export var gold_drop_chance: float = 0.35
## Color del cuerpo (esfera fallback + burst de muerte).
@export var body_color: Color = Color(0.2, 0.8, 0.2)
## Escala de la variante. Ajusta visual y colisión.
@export var size_scale: float = 1.0
## Daño por golpe (contacto o proyectil) y cadencia.
@export var attack_damage: float = 8.0
@export var attack_interval: float = 1.0
## XP que entrega al morir (el spawner la escala por oleada).
@export var xp_reward: float = 10.0

## Modelo KayKit opcional (lo setea el spawner por variante) + sus anims
## (keys: idle/run/attack/hit/death/spawn). Sin modelo = esfera tintada.
@export var model_path: String = ""
@export var anims: Dictionary = {}

## Enemigo a distancia: mantiene el rango y dispara proyectiles.
@export var is_ranged: bool = false
@export var preferred_range: float = 8.0
@export var ranged_interval: float = 2.5
@export var projectile_scene: PackedScene
## Proyectiles por disparo (el spawner lo sube en oleadas altas = abanico).
@export var projectile_count: int = 1

var current_health: float
var _health_bar: HealthBar3D
var _material: StandardMaterial3D
var _safe_zone: SafeZone
var _attack_timer: float = 0.0
var _ranged_timer: float = 1.5
var _repath_timer: float = 0.0
var _slow_mult: float = 1.0
var _slow_timer: float = 0.0
var _dying: bool = false

var _model_anim: AnimationPlayer = null
var _anim_lock: float = 0.0
## Última posición vista por la réplica (deriva la anim de correr/idle).
var _last_client_pos: Vector3 = Vector3.ZERO

@onready var _nav_agent: NavigationAgent3D = $NavAgent

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	_safe_zone = get_tree().get_first_node_in_group("safe_zone")
	_tags = StatusTags.new(self)

	# Material propio de la instancia (esfera fallback, tintada por variante).
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

	_setup_model()

	# Barra de vida flotante (más alta si hay modelo humanoide).
	_health_bar = HealthBar3D.new()
	add_child(_health_bar)
	_health_bar.position.y = (2.2 if _model_anim else 1.25) * size_scale

## Modelo KayKit animado (esqueletos). Fallback total a la esfera tintada.
func _setup_model() -> void:
	if model_path == "" or not ResourceLoader.exists(model_path):
		return
	var scene = load(model_path)
	if scene == null:
		return
	var model: Node3D = scene.instantiate()
	$Visual.add_child(model)
	model.rotation.y = PI # KayKit mira +Z; look_at apunta -Z
	_model_anim = model.find_child("AnimationPlayer", true, false)
	$Visual/Mesh.visible = false
	if _model_anim and anims.has("spawn"):
		_model_anim.play(anims["spawn"])
		_anim_lock = minf(_model_anim.current_animation_length, 1.0)

## Ralentización de hielo. factor 0.65 = 35% más lento durante `duration`.
## Solo el host: en clientes los proyectiles réplica no afectan el estado.
func apply_slow(factor: float, duration: float) -> void:
	if not is_multiplayer_authority():
		return
	_slow_mult = minf(_slow_mult, factor)
	_slow_timer = maxf(_slow_timer, duration)

func _physics_process(delta: float) -> void:
	# Réplica en cliente (E1.4): el host simula la IA; acá solo se refresca
	# lo visual desde el estado sincronizado (posición/rotación/vida).
	if not is_multiplayer_authority():
		_client_update(delta)
		return
	if _dying:
		return
	# Tags de estado (E3): ticks de Quemado/Sangrado y expiraciones.
	_tags.update(delta)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0

	var direction := _pick_direction(delta)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed * _slow_mult
		velocity.z = direction.z * speed * _slow_mult
		# Girar suavemente hacia donde se mueve
		var target_look := global_position + direction
		# Evitar errores de look_at cuando target == global_position
		if global_position.distance_squared_to(target_look) > 0.01:
			look_at(target_look, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		# Los tiradores encaran al jugador más cercano aunque estén quietos.
		if is_ranged:
			var player := Players.nearest(get_tree(), global_position)
			if player:
				var look_target: Vector3 = player.global_position
				look_target.y = global_position.y
				if global_position.distance_squared_to(look_target) > 0.01:
					look_at(look_target, Vector3.UP)

	# Gravedad
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()

	_attack_timer -= delta
	if is_ranged:
		_ranged_timer -= delta
		_try_shoot()
	else:
		_try_attack()

	_update_animation(delta, direction)

## Refresco visual de la réplica (cliente): barra de vida y animación desde
## el estado que sincroniza el host. La muerte se anticipa localmente para
## ver la animación; el despawn real lo manda el MultiplayerSpawner del host.
func _client_update(delta: float) -> void:
	_health_bar.set_ratio(clampf(current_health / max_health, 0.0, 1.0))
	if current_health <= 0.0:
		if not _dying:
			_dying = true
			_health_bar.visible = false
			if _model_anim and anims.has("death"):
				_model_anim.play(anims["death"], 0.1)
		return
	var moved := global_position - _last_client_pos
	_last_client_pos = global_position
	moved.y = 0.0
	# velocity solo alimenta el speed_scale de la anim (acá no hay física).
	velocity = moved / maxf(delta, 0.0001)
	_update_animation(delta, velocity if moved.length_squared() > 0.0001 else Vector3.ZERO)

# --- Animación (con modelo) --------------------------------------------------

func _update_animation(delta: float, direction: Vector3) -> void:
	if _model_anim == null:
		return
	if _anim_lock > 0.0:
		_anim_lock -= delta
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var target: String = anims.get("run", "") if direction != Vector3.ZERO else anims.get("idle", "")
	if target != "" and _model_anim.current_animation != target:
		_model_anim.play(target, 0.15)
	# Sin patinar: la anim acompaña la velocidad REAL medida del enemigo.
	_model_anim.speed_scale = clampf(horizontal_speed / 2.2, 0.7, 3.0) if direction != Vector3.ZERO else 1.0

func _play_locked(key: String, max_lock: float = 0.6) -> void:
	if _model_anim == null or not anims.has(key):
		return
	_model_anim.speed_scale = 1.0
	_model_anim.play(anims[key], 0.1)
	_anim_lock = minf(_model_anim.current_animation_length, max_lock)

# --- Ataques ------------------------------------------------------------------

## Golpe por contacto (melee): si el jugador más cercano está al alcance, le pega.
func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	var player := Players.nearest(get_tree(), global_position)
	if player == null or not player.has_method("take_damage"):
		return
	var reach := 0.6 + 0.6 * size_scale
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	if to_player.length_squared() <= reach * reach:
		player.take_damage(attack_damage)
		_attack_timer = attack_interval
		_play_locked("attack")

## Disparo a distancia (arquero/mago esqueleto).
func _try_shoot() -> void:
	if _ranged_timer > 0.0 or projectile_scene == null:
		return
	# Targetea al más cercano que NO esté a salvo en la base.
	var player := Players.nearest_of(_targetable_players(), global_position)
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0
	if to_player.length() > preferred_range + 4.0:
		return # todavía acercándose

	_ranged_timer = ranged_interval
	var origin := global_position + Vector3(0, 0.9, 0)
	var aim: Vector3 = player.global_position + Vector3(0, 0.5, 0) - origin
	if aim.length_squared() < 0.001:
		return
	# Abanico: en oleadas altas el arquero dispara varios proyectiles.
	var spread := 0.22
	var base_angle := -spread * (projectile_count - 1) * 0.5
	for i in projectile_count:
		# Basis(UP, ang) * looking_at == look_at + rotate_y de antes.
		var bolt_basis := Basis(Vector3.UP, base_angle + spread * i) \
			* Basis.looking_at(aim.normalized(), Vector3.UP)
		var bolt := NetSpawn.projectile(projectile_scene,
			{"transform": Transform3D(bolt_basis, origin)}, get_parent())
		if bolt.has_method("setup"):
			bolt.setup(attack_damage, self)
	_play_locked("attack")

## Jugadores vivos que se pueden atacar (fuera de la zona segura).
func _targetable_players() -> Array[Node3D]:
	var candidates: Array[Node3D] = []
	for player in Players.alive(get_tree()):
		if _safe_zone and _safe_zone.contains(player.global_position):
			continue
		candidates.append(player)
	return candidates

# --- Navegación ----------------------------------------------------------------

## Decide hacia dónde moverse respetando la zona segura y (si es tirador) su
## rango preferido: si el slime está dentro de la zona sale; si el jugador
## está a salvo, espera afuera; si la zona queda en el camino, la rodea.
func _pick_direction(delta: float) -> Vector3:
	# Nunca dentro de la zona segura: salir.
	if _safe_zone and _safe_zone.contains(global_position):
		var out := global_position - _safe_zone.global_position
		out.y = 0
		return out.normalized() if out.length_squared() > 0.001 else Vector3.RIGHT

	# Persigue al jugador más cercano que no esté a salvo; si todos están
	# muertos o en la zona segura, espera afuera.
	var player := Players.nearest_of(_targetable_players(), global_position)
	if player == null:
		return Vector3.ZERO

	var flat_to_player: Vector3 = player.global_position - global_position
	flat_to_player.y = 0

	# Tiradores: mantener el rango (retroceden si el jugador se acerca).
	if is_ranged:
		var dist := flat_to_player.length()
		if dist < preferred_range - 2.0:
			return -flat_to_player.normalized()
		if dist <= preferred_range + 2.0:
			return Vector3.ZERO

	var direction := flat_to_player.normalized()

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

# --- Tags de estado (E3, GDD §4) ------------------------------------------------

## Tags activos de este enemigo (Quemado/Congelado/Marcado/Sangrado).
var _tags: StatusTags

## Pone un tag (lo llaman los proyectiles al golpear). Solo host; el FX de
## aplicación se replica a todos.
func apply_status(tag: StringName, base_damage: float, applier_peer: int = 0) -> void:
	if _dying or not is_multiplayer_authority():
		return
	if _tags.apply(tag, base_damage, applier_peer):
		_tag_fx.rpc(tag, false)

## Detona tags activos: los consume y aplica el daño extra como crítico.
## El combo cruzado de party (aplicó OTRO jugador) ya viene bonificado.
func detonate_status(tags: Array, detonator_peer: int = 0) -> void:
	if _dying or not is_multiplayer_authority():
		return
	var bonus := _tags.detonate(tags, detonator_peer)
	if bonus > 0.0:
		_tag_fx.rpc(tags[0], true)
		take_damage(bonus, true)

## Daño de tick (Quemado/Sangrado): directo, sin animación de hit (el spam
## de "hit" congelaría al enemigo) y con el color del tag.
func _status_tick(tag_def: TagDef, amount: float) -> void:
	if _dying or amount <= 0.0:
		return
	current_health -= amount
	_health_bar.set_ratio(current_health / max_health)
	FX.damage_number(global_position, amount, false, tag_def.color)
	if current_health <= 0:
		die()

## FX del tag en TODAS las máquinas (aplicar = ráfaga chica; detonar = grande).
@rpc("authority", "call_local", "reliable")
func _tag_fx(tag: StringName, detonated: bool) -> void:
	var tag_def := StatusTags.def(tag)
	if tag_def == null:
		return
	var origin := global_position + Vector3(0, 0.6 * size_scale, 0)
	FX.burst(origin, tag_def.color, 18 if detonated else 8, 0.09 if detonated else 0.05)

# --- Daño y muerte --------------------------------------------------------------

func take_damage(amount: float, is_crit: bool = false) -> void:
	# El daño lo resuelve SOLO el host; la vida viaja por el sincronizador.
	if _dying or not is_multiplayer_authority():
		return
	# Marcado (E3): el próximo golpe se amplifica y consume el tag.
	var amplifier := _tags.consume_amplifier()
	if amplifier > 1.0:
		amount *= amplifier
		is_crit = true
	current_health -= amount
	_health_bar.set_ratio(current_health / max_health)
	FX.damage_number(global_position, amount, is_crit)

	if _model_anim:
		_play_locked("hit", 0.3)
	else:
		# Parpadeo blanco (fallback esfera); vuelve al color de la variante.
		_material.albedo_color = Color.WHITE
		var tween = create_tween()
		tween.tween_property(_material, "albedo_color", body_color, 0.2)

	if current_health <= 0:
		die()

func die() -> void:
	if _dying:
		return
	_dying = true
	# Salir del grupo YA: la oleada cuenta vivos por este grupo.
	remove_from_group("enemies")

	# Recompensa del kill (stamina del super + maná + XP): en co-op la
	# reciben TODOS los jugadores vivos, no solo el primero.
	for player in Players.alive(get_tree()):
		if player.has_method("on_enemy_killed"):
			player.on_enemy_killed(xp_reward)

	# Equipo instanciado (E1.7): tirada independiente POR JUGADOR vivo —
	# cada uno ve solo su drop, nadie compite por el botín.
	if loot_drop_scene and drop_chance > 0.0:
		for player in Players.alive(get_tree()):
			if randf() <= drop_chance:
				_spawn_drop(Loot.generate_random_item(loot_level), Vector3.ZERO,
					player.get_multiplayer_authority())

	# Oro (E5.1): tirada POR JUGADOR vivo (como el equipo, nadie compite);
	# la cantidad escala con el nivel del botín.
	if loot_drop_scene:
		for player in Players.alive(get_tree()):
			if randf() <= gold_drop_chance:
				_spawn_drop(Loot.make_gold(randi_range(1, 3) + loot_level),
					Vector3(-0.7, 0, -0.2), player.get_multiplayer_authority())

	# Algunos enemigos botan maná (vida nunca: solo en cofres).
	# Las pociones del mundo son COMPARTIDAS: recurso al que llega primero.
	if loot_drop_scene and randf() <= mana_drop_chance:
		_spawn_drop(Loot.make_potion(&"potion_mana"), Vector3(0.7, 0, 0.2))

	FX.burst(global_position + Vector3(0, 0.5, 0), body_color, 16)

	if _model_anim and anims.has("death"):
		# Cadáver: animación de muerte, sin colisión ni barra, y liberar.
		$CollisionShape3D.set_deferred("disabled", true)
		_health_bar.visible = false
		_model_anim.play(anims["death"], 0.1)
		get_tree().create_timer(1.2).timeout.connect(queue_free)
	else:
		queue_free()

func _spawn_drop(item: LootItem, offset: Vector3, owner_peer: int = 0) -> void:
	if item == null:
		return
	NetSpawn.drop(loot_drop_scene, item, global_position + offset, get_parent(), owner_peer)
