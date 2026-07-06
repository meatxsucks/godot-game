## Slot 2 — Temblor Lineal (Mazo RMB).
## Envía 3 explosiones en línea recta hacia donde miras.
class_name ShockwaveAbility
extends Ability

const SCENE := preload("res://scenes/magic/FrostNova.tscn")

func _init() -> void:
	id = &"shockwave"
	display_name = "Temblor Lineal"
	key_label = "RMB"
	color = Color(0.8, 0.4, 0.2)
	cooldown = 2.0
	mana_cost = 14.0
	element = &"melee"

func _cast(player) -> Variant:
	var dir: Vector3 = -player.visual.global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()
	
	var tree = player.get_tree()
	_spawn_sequence(player, tree, dir, 0)
	return true

func _spawn_sequence(player: Node, tree: SceneTree, dir: Vector3, i: int) -> void:
	if i >= 3 or not is_instance_valid(player) or not player.is_inside_tree() or player.get("_dead"):
		return
	
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 0.4)
	var nova = SCENE.instantiate()
	nova.position = player.global_position + dir * (2.0 + i * 2.5)
	player.get_parent().add_child(nova)
	if nova.has_method("setup"):
		nova.setup(result[0], player, result[1])
		
	var fx = player.get_node_or_null("/root/FX")
	if fx:
		fx.shake(0.2)
	
	tree.create_timer(0.2).timeout.connect(_spawn_sequence.bind(player, tree, dir, i + 1))
