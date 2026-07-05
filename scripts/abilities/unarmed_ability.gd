## Golpe desarmado: el ataque básico cuando NO hay arma equipada.
## Débil a propósito — equipa algo del cofre.
class_name UnarmedAbility
extends Ability

const SCENE := preload("res://scenes/magic/SwordSlash.tscn")

func _init() -> void:
	id = &"unarmed"
	display_name = "Golpe"
	key_label = "LMB"
	color = Color(0.7, 0.7, 0.7)
	cooldown = 0.7
	mana_cost = 0.0
	hold_to_cast = true
	element = &"melee"

func _cast(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 0.5)
	var punch = SCENE.instantiate()
	punch.reach = 1.2
	punch.hit_radius = 1.0
	player.get_parent().add_child(punch)
	punch.global_position = player.global_position
	punch.global_transform.basis = player.visual.global_transform.basis
	if punch.has_method("setup"):
		punch.setup(result[0], player, result[1])
	return true
