## Slot 1 — Descarga Arcana (Varita LMB): el básico de la varita, rápido y liviano.
class_name ArcBoltAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArcBolt.tscn")

func _init() -> void:
	id = &"arc_bolt"
	display_name = "Descarga Arcana"
	key_label = "LMB"
	color = Color(0.4, 0.8, 1.0)
	cooldown = 0.3
	mana_cost = 0.0
	hold_to_cast = true
	element = &"lightning"
	applies = [&"marked"]

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"lightning_damage", 0.28)
