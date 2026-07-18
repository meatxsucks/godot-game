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

func _cast(player) -> Variant:
	# Base LEVE a propósito (E10.4, era 1.0): el árbol de talentos lo potencia.
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 0.7 * damage_scale)
	return player.start_dash(result[0])
