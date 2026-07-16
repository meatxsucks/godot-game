## Slot 1 — Esquirla Helada (Cetro de escarcha LMB): el básico del cetro,
## proyectil de hielo que aplica Congelado (E7.2, cubre el tag huérfano).
## Visual placeholder: reusa el proyectil de ArcBolt hasta el arte de E8.
class_name FrostShardAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArcBolt.tscn")

func _init() -> void:
	id = &"frost_shard"
	display_name = "Esquirla Helada"
	key_label = "LMB"
	color = Color(0.45, 0.8, 1.0)
	cooldown = 0.9
	mana_cost = 0.0
	hold_to_cast = true
	element = &"cold"
	applies = [&"frozen"]

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"cold_damage", 0.5)
