## Guerrero slot 2 — Hacha Arrojadiza: proyectil para tocar a distancia.
class_name AxeThrowAbility
extends Ability

const SCENE := preload("res://scenes/magic/ThrowingAxe.tscn")

func _init() -> void:
	id = &"axe_throw"
	display_name = "Hacha Arrojadiza"
	key_label = "RMB"
	color = Color(0.72, 0.74, 0.8)
	cooldown = 1.0
	mana_cost = 5.0
	power = 0.7
	hold_to_cast = true
	element = &"melee"
	applies = [&"bleed"]

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"melee_damage", power)
