## Slot 1 — Flecha (Arco LMB): el básico del arco, liviano.
class_name ArrowAbility
extends Ability

const SCENE := preload("res://scenes/magic/Arrow.tscn")

func _init() -> void:
	id = &"arrow"
	display_name = "Flecha"
	key_label = "LMB"
	color = Color(1.0, 0.7, 0.35)
	cooldown = 0.9
	mana_cost = 0.0
	hold_to_cast = true
	element = &"ranged"

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"ranged_damage", 0.55)
