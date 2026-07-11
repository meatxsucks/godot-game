## Sistema de oleadas de la Arena: rondas anunciadas con descanso entre medio,
## cuota de enemigos por oleada y escalado de vida/daño/loot. Cada N oleadas
## superadas reabastece los cofres (la vida solo sale de ahí).
extends Node3D

signal wave_started(n: int)
signal wave_cleared(n: int)
signal intermission_tick(next_n: int, seconds_left: int)
signal boss_defeated

const BOSS_SCENE := preload("res://scenes/enemies/Boss.tscn")

const PORTAL_SCENE := preload("res://scenes/world/SpawnPortal.tscn")

@export var slime_scene: PackedScene = preload("res://scenes/enemies/Slime.tscn")
## Rectángulo del campo donde pueden aparecer los portales de oleada.
@export var field_min := Vector2(-28, -28)
@export var field_max := Vector2(28, 12)
## Máximo de enemigos vivos a la vez.
@export var max_alive: int = 10
## Descanso entre oleadas: tiempo para volver a la base y equiparse.
@export var intermission_time: float = 10.0
@export var spawn_interval: float = 0.8
## Anillo alrededor del spawner donde aparecen.
@export var spawn_radius_min: float = 8.0
@export var spawn_radius_max: float = 12.0
## Cada cuántas oleadas superadas se reabastecen los cofres.
@export var chest_restock_every: int = 3
## Oleada del boss: aparece el Rey Slime; superarla = nivel completado
## (después el modo sigue endless).
@export var boss_wave: int = 5

## Animaciones KayKit Skeletons por rol.
const ANIMS_MELEE := {"idle": "Idle", "run": "Running_A", "attack": "Unarmed_Melee_Attack_Punch_A", "hit": "Hit_A", "death": "Death_A", "spawn": "Spawn_Ground"}
const ANIMS_WARRIOR := {"idle": "Idle", "run": "Running_A", "attack": "2H_Melee_Attack_Slice", "hit": "Hit_A", "death": "Death_A", "spawn": "Spawn_Ground"}
const ANIMS_CASTER := {"idle": "Idle", "run": "Running_A", "attack": "Spellcast_Shoot", "hit": "Hit_A", "death": "Death_A", "spawn": "Spawn_Ground"}

const ENEMY_ARROW := preload("res://scenes/magic/EnemyArrow.tscn")

## Variantes base (escalan por oleada): vida, velocidad, escala, daño, XP,
## modelo KayKit + anims, y si es tirador a distancia.
const VARIANTS := {
	&"normal": {"hp": 30.0, "speed": 3.0, "scale": 1.0, "dmg": 8.0, "xp": 10.0,
		"color": Color(0.2, 0.8, 0.2), "model": "res://assets/kaykit/Skeleton_Minion.glb",
		"anims": ANIMS_MELEE, "ranged": false},
	&"fast": {"hp": 16.0, "speed": 4.6, "scale": 0.85, "dmg": 5.0, "xp": 8.0,
		"color": Color(0.4, 0.9, 0.75), "model": "res://assets/kaykit/Skeleton_Rogue.glb",
		"anims": ANIMS_MELEE, "ranged": false},
	&"tank": {"hp": 75.0, "speed": 1.9, "scale": 1.25, "dmg": 15.0, "xp": 25.0,
		"color": Color(0.1, 0.45, 0.15), "model": "res://assets/kaykit/Skeleton_Warrior.glb",
		"anims": ANIMS_WARRIOR, "ranged": false},
	&"archer": {"hp": 20.0, "speed": 2.6, "scale": 1.0, "dmg": 10.0, "xp": 15.0,
		"color": Color(0.6, 0.25, 0.8), "model": "res://assets/kaykit/Skeleton_Mage.glb",
		"anims": ANIMS_CASTER, "ranged": true},
}

enum State { INTERMISSION, SPAWNING, FIGHTING }

var wave: int = 0
var _state: State = State.INTERMISSION
var _timer: float = 0.0
## Cuota de enemigos que faltan por spawnear en la oleada actual.
var _to_spawn: int = 0
var _last_tick: int = -1
var _safe_zone: SafeZone
## Portales activos: la oleada emerge de ellos (telegrafiados en el descanso).
var _portals: Array[Node3D] = []

func _ready() -> void:
	add_to_group("wave_manager")
	_safe_zone = get_tree().get_first_node_in_group("safe_zone")
	_timer = intermission_time
	_make_portals.call_deferred(1)

func current_wave() -> int:
	return wave

## Enemigos restantes de la oleada (por spawnear + vivos). Para el HUD.
func enemies_left() -> int:
	return _to_spawn + get_tree().get_nodes_in_group("enemies").size()

func _physics_process(delta: float) -> void:
	match _state:
		State.INTERMISSION:
			_timer -= delta
			var seconds := ceili(_timer)
			if seconds != _last_tick:
				_last_tick = seconds
				intermission_tick.emit(wave + 1, maxi(0, seconds))
			if _timer <= 0.0:
				_start_wave()
		State.SPAWNING:
			_timer -= delta
			if _timer <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < max_alive:
				_timer = spawn_interval
				_spawn_one()
				if _to_spawn <= 0:
					_state = State.FIGHTING
		State.FIGHTING:
			if get_tree().get_nodes_in_group("enemies").is_empty():
				print("[Waves] oleada %d superada" % wave)
				wave_cleared.emit(wave)
				_spawn_rewards()
				if wave == boss_wave:
					print("[Waves] ¡NIVEL SUPERADO!")
					boss_defeated.emit()
				if chest_restock_every > 0 and wave % chest_restock_every == 0:
					_restock_chests()
				_state = State.INTERMISSION
				_timer = intermission_time
				_last_tick = -1
				# Telegrafiar la siguiente oleada: portales nuevos ya visibles.
				_clear_portals()
				_make_portals(wave + 1)

func _start_wave() -> void:
	wave += 1
	_state = State.SPAWNING
	_timer = 0.0
	if wave == boss_wave:
		# Oleada final: el Rey Slime + una escolta reducida.
		_to_spawn = 4
		_spawn_boss()
		print("[Waves] ¡OLEADA FINAL %d: EL REY SLIME!" % wave)
	else:
		_to_spawn = 3 + 2 * wave
		print("[Waves] oleada %d: %d enemigos" % [wave, _to_spawn])
	wave_started.emit(wave)

func _spawn_boss() -> void:
	var pos: Vector3
	if _portals.is_empty():
		pos = _random_spawn_pos()
	else:
		pos = (_portals.pick_random() as Node3D).global_position
	var boss := NetSpawn.enemy(BOSS_SCENE,
		{"loot_level": _loot_level() + 2, "position": pos}, self)
	# Escalar también al boss si la oleada final se configura más tarde.
	# Post-spawn (su _ready ya corrió): hay que reponer current_health.
	if wave > boss_wave:
		boss.max_health *= 1.0 + 0.05 * (wave - boss_wave)
		boss.current_health = boss.max_health

## Nivel del botín de la oleada actual (sube cada 2 rondas).
func _loot_level() -> int:
	return 1 + int(wave / 2.0)

## Mezcla de variantes por progresión: temprano casi todo normal; arqueros
## desde la oleada 2, más rápidos desde la 3 y tanques desde la 4.
func _pick_variant() -> Dictionary:
	var archer_weight := maxi(0, wave - 1) * 18
	var fast_weight := 10 + maxi(0, wave - 2) * 20
	var tank_weight := maxi(0, wave - 3) * 15
	var total := 100 + archer_weight + fast_weight + tank_weight
	var roll := randi() % total
	if roll < 100:
		return VARIANTS[&"normal"]
	roll -= 100
	if roll < archer_weight:
		return VARIANTS[&"archer"]
	roll -= archer_weight
	if roll < fast_weight:
		return VARIANTS[&"fast"]
	return VARIANTS[&"tank"]

func _spawn_one() -> void:
	var variant := _pick_variant()
	var hp_mult := 1.0 + 0.15 * (wave - 1)
	var dmg_mult := 1.0 + 0.10 * (wave - 1)

	# La oleada emerge de los portales (con jitter); anillo como fallback.
	var pos: Vector3
	if _portals.is_empty():
		pos = _random_spawn_pos()
	else:
		var portal: Node3D = _portals.pick_random()
		pos = portal.global_position + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
	# Nunca spawnear dentro de la zona segura (la base es sagrada).
	if _safe_zone and _safe_zone.contains(pos):
		return

	# Los "poderes" de los enemigos escalan con la oleada: atacan más rápido
	# y los arqueros disparan abanicos de más flechas.
	var atk_speed := 1.0 + 0.06 * (wave - 1)

	var props := {
		"max_health": variant["hp"] * hp_mult,
		"speed": variant["speed"],
		"size_scale": variant["scale"],
		"attack_damage": variant["dmg"] * dmg_mult,
		"attack_interval": maxf(0.45, 1.0 / atk_speed),
		"body_color": variant["color"],
		"loot_level": _loot_level(),
		"xp_reward": variant["xp"] * (1.0 + 0.1 * (wave - 1)),
		"model_path": variant["model"],
		"anims": variant["anims"],
		"is_ranged": variant["ranged"],
		"position": pos,
	}
	var scene_props := {}
	if variant["ranged"]:
		scene_props["projectile_scene"] = ENEMY_ARROW.resource_path
		props["ranged_interval"] = maxf(1.0, 2.5 / atk_speed)
		# +1 flecha cada 3 oleadas (1 → 2 en la 4, 3 en la 7...).
		props["projectile_count"] = 1 + int(wave / 3.0)
	NetSpawn.enemy(slime_scene, props, self, scene_props)
	_to_spawn -= 1

func _random_spawn_pos() -> Vector3:
	var angle := randf() * TAU
	var dist := randf_range(spawn_radius_min, spawn_radius_max)
	return global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

# --- Portales (distribución procedural de la oleada) --------------------------

## Elige 1 + N/2 posiciones (máx 4) repartidas por el campo, evitando la zona
## segura, al jugador y otros portales (intentos con rechazo).
func _make_portals(for_wave: int) -> void:
	var count := clampi(1 + int(for_wave / 2.0), 1, 4)
	var players := Players.alive(get_tree())
	for i in count:
		for attempt in 20:
			var pos := Vector3(
				randf_range(field_min.x, field_max.x),
				0.0,
				randf_range(field_min.y, field_max.y))
			if _safe_zone and _safe_zone.contains(pos):
				continue
			# Lejos de TODOS los jugadores, no solo del primero.
			if players.any(func(p: Node3D) -> bool: return pos.distance_to(p.global_position) < 8.0):
				continue
			if _portals.any(func(p: Node3D) -> bool: return p.global_position.distance_to(pos) < 8.0):
				continue
			var portal := PORTAL_SCENE.instantiate()
			add_child(portal)
			portal.global_position = pos
			_portals.append(portal)
			break

func _clear_portals() -> void:
	for portal in _portals:
		portal.queue_free()
	_portals.clear()

const REWARD_DROP := preload("res://scenes/loot/LootDrop.tscn")

## Recompensa por superar la oleada: el equipo cae AL FINAL, cerca del
## jugador (los enemigos ya no dropean equipo a mitad de ronda).
func _spawn_rewards() -> void:
	var player := Players.nearest(get_tree(), global_position)
	var center: Vector3 = player.global_position if player else global_position
	var count := 1 + int(wave / 3.0)
	for i in count:
		var angle := TAU * float(i) / count + randf() * 0.5
		var pos := center + Vector3(cos(angle) * 1.8, 0.0, sin(angle) * 1.8)
		NetSpawn.drop(REWARD_DROP, Loot.generate_random_item(_loot_level()), pos, self)
	print("[Waves] recompensa: %d ítems" % count)

func _restock_chests() -> void:
	for chest in get_tree().get_nodes_in_group("chest"):
		if chest.has_method("restock"):
			chest.restock(_loot_level())
	print("[Waves] cofres reabastecidos")
