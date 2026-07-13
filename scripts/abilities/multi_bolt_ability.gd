## Slot 2 — Muro de Llamas (Bastón RMB).
## Invoca pilares de fuego en una línea perpendicular a tu mirada.
class_name MultiBoltAbility
extends Ability

const SCENE := preload("res://scenes/magic/Whirlwind.tscn")

func _init() -> void:
	id = &"multi_bolt"
	display_name = "Muro de Llamas"
	key_label = "RMB"
	color = Color(1.0, 0.45, 0.1)
	cooldown = 4.0
	mana_cost = 20.0
	element = &"fire"
	applies = [&"burn"]

func _cast(player) -> Variant:
	var target = player.get_aim_point()
	var dir_to_target = (target - player.global_position).normalized()
	dir_to_target.y = 0.0
	# Vector perpendicular para armar el muro
	var right = Vector3(-dir_to_target.z, 0, dir_to_target.x)
	
	var tree = player.get_tree()
	_spawn_sequence(player, tree, target, right, 0)
	return true

func _spawn_sequence(player: Node, tree: SceneTree, target: Vector3, right: Vector3, i: int) -> void:
	if i >= 3 or not is_instance_valid(player) or not player.is_inside_tree() or player.get("_dead"):
		return

	var offset = right * (i - 1) * 1.5 # -1.5, 0, 1.5
	var spawn_pos = target + offset

	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 0.5)
	NetSpawn.projectile(SCENE, _tag_props({"position": spawn_pos}), player.get_parent(),
		result[0], player, result[1])
	
	var fx = player.get_node_or_null("/root/FX")
	if fx:
		fx.burst(spawn_pos + Vector3.UP, Color(1.0, 0.5, 0.1), 8, 0.05)
		
	tree.create_timer(0.15).timeout.connect(_spawn_sequence.bind(player, tree, target, right, i + 1))
