## Guerrero slot 3 — Embestida: dash con i-frames que DAÑA a los enemigos
## que atraviesa (la física del golpe vive en el player, _dash_damage).
class_name ChargeAbility
extends Ability

func _init() -> void:
	id = &"charge"
	display_name = "Embestida"
	key_label = "SPC"
	color = Color(1.0, 0.6, 0.3)
	cooldown = 1.5
	mana_cost = 0.0
	element = &"melee"

func _cast(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 1.0)
	return player.start_dash(result[0])
