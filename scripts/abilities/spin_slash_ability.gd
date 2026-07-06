## Slot 2 — Tajo Giratorio (Espada RMB): ataque circular mientras te mueves lento.
class_name SpinSlashAbility
extends Ability

const SCENE := preload("res://scenes/magic/Whirlwind.tscn")

func _init() -> void:
	id = &"spin_slash"
	display_name = "Giro Movible"
	key_label = "RMB"
	color = Color(0.85, 0.85, 0.78)
	cooldown = 2.0
	mana_cost = 15.0
	element = &"melee"

func _cast(player) -> Variant:
	# Ralentiza al jugador mientras gira
	player.apply_speed_modifier(0.4, 1.2)
	
	# Ejecuta 3 cortes en área durante 1.2s sin usar await
	var tree = player.get_tree()
	_spawn_sequence(player, tree, 0)
	return true

func _spawn_sequence(player: Node, tree: SceneTree, i: int) -> void:
	if i >= 3 or not is_instance_valid(player) or not player.is_inside_tree() or player.get("_dead"):
		return
	
	_spawn_nova(player, SCENE, &"melee_damage", 0.6)
	tree.create_timer(0.4).timeout.connect(_spawn_sequence.bind(player, tree, i + 1))
