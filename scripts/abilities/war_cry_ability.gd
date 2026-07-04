## Guerrero slot 4 — Grito de Guerra: onda AoE grande alrededor.
class_name WarCryAbility
extends Ability

const SCENE := preload("res://scenes/magic/WarCry.tscn")

func _init() -> void:
	id = &"war_cry"
	display_name = "Grito de Guerra"
	key_label = "Q"
	color = Color(1.0, 0.35, 0.2)
	cooldown = 6.0
	mana_cost = 15.0
	element = &"melee"

func _cast(player) -> bool:
	return _spawn_nova(player, SCENE, &"melee_damage", 1.2)
