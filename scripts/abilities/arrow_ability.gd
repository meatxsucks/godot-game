## Explorador slot 1 — Flecha: proyectil rápido, barato y preciso.
class_name ArrowAbility
extends Ability

const SCENE := preload("res://scenes/magic/Arrow.tscn")

func _init() -> void:
	id = &"arrow"
	display_name = "Flecha"
	key_label = "LMB"
	color = Color(0.95, 0.85, 0.45)
	cooldown = 0.45
	mana_cost = 4.0
	hold_to_cast = true
	element = &"ranged"

func _cast(player) -> bool:
	return _spawn_projectile(player, SCENE, &"ranged_damage", 0.8)
