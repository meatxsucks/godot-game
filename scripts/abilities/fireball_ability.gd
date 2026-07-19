## Slot 1 — Bola de Fuego (Bastón LMB): el básico del bastón, liviano.
class_name FireballAbility
extends Ability

const SCENE := preload("res://scenes/magic/Fireball.tscn")

func _init() -> void:
	id = &"fireball"
	display_name = "Bola de Fuego"
	key_label = "LMB"
	color = Color(1.0, 0.45, 0.1)
	cooldown = 1.0
	mana_cost = 0.0
	power = 0.55
	hold_to_cast = true
	element = &"fire"
	applies = [&"burn"]

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"fire_damage", power)
