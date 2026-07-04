## Slot 2 — Descarga Arcana: proyectil rápido y débil para spamear.
## Escala con lightning_damage del loot.
class_name ArcBoltAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArcBolt.tscn")

func _init() -> void:
	id = &"arc_bolt"
	display_name = "Descarga Arcana"
	key_label = "RMB"
	color = Color(0.4, 0.8, 1.0)
	cooldown = 0.6
	mana_cost = 6.0
	hold_to_cast = true
	element = &"lightning"

func _cast(player) -> bool:
	return _spawn_projectile(player, SCENE, &"lightning_damage", 0.4)
