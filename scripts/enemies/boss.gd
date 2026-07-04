## Rey Slime: el boss de la oleada final. Hereda todo del slime (navegación,
## barra de vida, tint, zona segura, ataque por contacto) y suma: golpe
## sísmico telegrafiado, invocación de secuaces, corona, y botín con
## legendario garantizado.
extends "res://scripts/enemies/slime.gd"

const SLIME_SCENE := preload("res://scenes/enemies/Slime.tscn")

@export var slam_interval: float = 6.0
@export var slam_radius: float = 4.0
@export var slam_damage: float = 30.0
@export var summon_interval: float = 12.0
## Tope de enemigos vivos al invocar (para no inundar la arena).
@export var summon_cap: int = 7

var _slam_timer: float = 3.0
var _summon_timer: float = 8.0

func _ready() -> void:
	super()
	_make_crown()

func _physics_process(delta: float) -> void:
	super(delta)
	_slam_timer -= delta
	if _slam_timer <= 0.0:
		_slam_timer = slam_interval
		_telegraph_slam()
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_interval
		_summon_minions()

# --- Golpe sísmico -------------------------------------------------------------

## Telegrafia un disco rojo 1s y luego daña a quien siga dentro del radio.
func _telegraph_slam() -> void:
	var center := global_position
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = slam_radius
	mesh.bottom_radius = slam_radius
	mesh.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.15, 0.1, 0.3)
	mesh.material = mat
	disc.mesh = mesh
	get_parent().add_child(disc)
	disc.global_position = Vector3(center.x, 0.04, center.z)

	# El callback vive en el disco (no en el boss): si el boss muere durante
	# el telegraph, el golpe igual se resuelve sin tocar un objeto liberado.
	var radius := slam_radius
	var damage_amount := slam_damage
	var tree := get_tree()
	var tween := disc.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.65, 1.0)
	tween.tween_callback(func() -> void:
		FX.burst(center + Vector3(0, 0.3, 0), Color(1.0, 0.25, 0.1), 20, 0.1)
		FX.shake(0.5)
		var player = tree.get_first_node_in_group("player")
		if player and player.has_method("take_damage"):
			var delta: Vector3 = player.global_position - center
			delta.y = 0.0
			if delta.length() <= radius:
				player.take_damage(damage_amount)
		disc.queue_free()
	)

# --- Secuaces ------------------------------------------------------------------

func _summon_minions() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= summon_cap:
		return
	for i in 2:
		var minion := SLIME_SCENE.instantiate()
		minion.loot_level = loot_level
		minion.drop_chance = 0.25
		get_parent().add_child(minion)
		var angle := randf() * TAU
		minion.global_position = global_position + Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)

# --- Corona y botín ------------------------------------------------------------

func _make_crown() -> void:
	var crown := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.35
	cone.height = 0.6
	var mat := StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.metallic = 0.7
	cone.material = mat
	crown.mesh = cone
	crown.position.y = 0.75
	$Visual.add_child(crown)

## Botín real de boss: legendario garantizado + ítem de la oleada + vida.
func die() -> void:
	_spawn_drop(Loot.generate_random_item(loot_level, &"", Rarity.Tier.LEGENDARY), Vector3.ZERO)
	_spawn_drop(Loot.generate_random_item(loot_level), Vector3(1.3, 0, 0.4))
	_spawn_drop(Loot.make_potion(&"potion_health"), Vector3(-1.3, 0, 0.4))
	_spawn_drop(Loot.make_potion(&"potion_health"), Vector3(0, 0, -1.4))

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(xp_reward)
	FX.burst(global_position + Vector3(0, 1, 0), Color(1.0, 0.85, 0.2), 30, 0.12)
	queue_free()
