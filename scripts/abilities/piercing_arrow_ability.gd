## Explorador slot 4 — Flecha Perforante: atraviesa a todos los enemigos en
## línea (muere solo contra muros). Ideal contra filas de slimes.
class_name PiercingArrowAbility
extends Ability

const SCENE := preload("res://scenes/magic/PiercingArrow.tscn")

func _init() -> void:
	id = &"piercing_arrow"
	display_name = "Flecha Perforante"
	key_label = "Q"
	color = Color(0.5, 1.0, 0.6)
	cooldown = 4.0
	mana_cost = 15.0
	element = &"ranged"

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"ranged_damage", 1.2)
