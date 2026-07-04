## Sistema de oleadas de la Arena: rondas anunciadas con descanso entre medio,
## cuota de enemigos por oleada y escalado de vida/daño/loot. Cada N oleadas
## superadas reabastece los cofres (la vida solo sale de ahí).
extends Node3D

signal wave_started(n: int)
signal wave_cleared(n: int)
signal intermission_tick(next_n: int, seconds_left: int)

@export var slime_scene: PackedScene = preload("res://scenes/enemies/Slime.tscn")
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

## Variantes base (escalan por oleada): vida, velocidad, escala, daño, color.
const VARIANTS := {
	&"normal": {"hp": 30.0, "speed": 3.0, "scale": 1.0, "dmg": 8.0, "color": Color(0.2, 0.8, 0.2)},
	&"fast": {"hp": 16.0, "speed": 4.6, "scale": 0.75, "dmg": 5.0, "color": Color(0.4, 0.9, 0.75)},
	&"tank": {"hp": 75.0, "speed": 1.9, "scale": 1.5, "dmg": 15.0, "color": Color(0.1, 0.45, 0.15)},
}

enum State { INTERMISSION, SPAWNING, FIGHTING }

var wave: int = 0
var _state: State = State.INTERMISSION
var _timer: float = 0.0
## Cuota de enemigos que faltan por spawnear en la oleada actual.
var _to_spawn: int = 0
var _last_tick: int = -1
var _safe_zone: SafeZone

func _ready() -> void:
	add_to_group("wave_manager")
	_safe_zone = get_tree().get_first_node_in_group("safe_zone")
	_timer = intermission_time

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
				if chest_restock_every > 0 and wave % chest_restock_every == 0:
					_restock_chests()
				_state = State.INTERMISSION
				_timer = intermission_time
				_last_tick = -1

func _start_wave() -> void:
	wave += 1
	_to_spawn = 3 + 2 * wave
	_state = State.SPAWNING
	_timer = 0.0
	print("[Waves] oleada %d: %d enemigos" % [wave, _to_spawn])
	wave_started.emit(wave)

## Nivel del botín de la oleada actual (sube cada 2 rondas).
func _loot_level() -> int:
	return 1 + int(wave / 2.0)

## Mezcla de variantes por progresión: temprano casi todo normal, desde la
## oleada 3 entran más rápidos y desde la 5 más tanques.
func _pick_variant() -> Dictionary:
	var fast_weight := 10 + maxi(0, wave - 2) * 20
	var tank_weight := maxi(0, wave - 4) * 15
	var total := 100 + fast_weight + tank_weight
	var roll := randi() % total
	var key: StringName = &"normal"
	if roll >= 100 and roll < 100 + fast_weight:
		key = &"fast"
	elif roll >= 100 + fast_weight:
		key = &"tank"
	return VARIANTS[key]

func _spawn_one() -> void:
	var variant := _pick_variant()
	var hp_mult := 1.0 + 0.15 * (wave - 1)
	var dmg_mult := 1.0 + 0.10 * (wave - 1)

	var pos := _random_spawn_pos()
	# Nunca spawnear dentro de la zona segura (la base es sagrada).
	if _safe_zone and _safe_zone.contains(pos):
		return

	var slime := slime_scene.instantiate()
	slime.max_health = variant["hp"] * hp_mult
	slime.speed = variant["speed"]
	slime.size_scale = variant["scale"]
	slime.attack_damage = variant["dmg"] * dmg_mult
	slime.body_color = variant["color"]
	slime.loot_level = _loot_level()
	add_child(slime)
	slime.global_position = pos
	_to_spawn -= 1

func _random_spawn_pos() -> Vector3:
	var angle := randf() * TAU
	var dist := randf_range(spawn_radius_min, spawn_radius_max)
	return global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

func _restock_chests() -> void:
	for chest in get_tree().get_nodes_in_group("chest"):
		if chest.has_method("restock"):
			chest.restock(_loot_level())
	print("[Waves] cofres reabastecidos")
