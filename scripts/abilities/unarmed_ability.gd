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
	power = 0.5
	hold_to_cast = true
	element = &"melee"

func _cast(player) -> Variant:
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", power)
	var xform := Transform3D(player.visual.global_transform.basis, player.global_position)
	NetSpawn.projectile(SCENE,
		{"transform": xform, "reach": 1.2, "hit_radius": 1.0}, player.get_parent(),
		result[0], player, result[1])
	return true
