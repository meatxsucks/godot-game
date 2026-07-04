## Spawner continuo: mantiene la arena poblada de slimes eligiendo variantes
## al azar (normal, rápido, tanque). Cuenta los vivos por el grupo "enemies".
extends Node3D

@export var slime_scene: PackedScene = preload("res://scenes/enemies/Slime.tscn")
## Máximo de enemigos vivos a la vez.
@export var max_alive: int = 8
@export var spawn_interval: float = 3.0
## Anillo alrededor del spawner donde aparecen (lejos del centro/jugador).
@export var spawn_radius_min: float = 8.0
@export var spawn_radius_max: float = 16.0
## Nivel del loot que dropean los spawneados.
@export var loot_level: int = 1

## Variantes: vida, velocidad, escala, daño por contacto y color del cuerpo.
const VARIANTS := [
	{"hp": 30.0, "speed": 3.0, "scale": 1.0, "dmg": 8.0, "color": Color(0.2, 0.8, 0.2)},    # normal
	{"hp": 16.0, "speed": 4.6, "scale": 0.75, "dmg": 5.0, "color": Color(0.4, 0.9, 0.75)},  # rápido
	{"hp": 75.0, "speed": 1.9, "scale": 1.5, "dmg": 15.0, "color": Color(0.1, 0.45, 0.15)}, # tanque
]

var _timer: float = 1.0
var _safe_zone: SafeZone

func _ready() -> void:
	_safe_zone = get_tree().get_first_node_in_group("safe_zone")

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = spawn_interval
	if get_tree().get_nodes_in_group("enemies").size() >= max_alive:
		return
	_spawn()

func _spawn() -> void:
	var variant: Dictionary = VARIANTS.pick_random()
	var slime := slime_scene.instantiate()
	slime.max_health = variant["hp"]
	slime.speed = variant["speed"]
	slime.size_scale = variant["scale"]
	slime.attack_damage = variant["dmg"]
	slime.body_color = variant["color"]
	slime.loot_level = loot_level
	add_child(slime)

	var angle := randf() * TAU
	var dist := randf_range(spawn_radius_min, spawn_radius_max)
	var pos := global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	# Nunca spawnear dentro de la zona segura (la base es sagrada).
	if _safe_zone and _safe_zone.contains(pos):
		slime.queue_free()
		return
	slime.global_position = pos
