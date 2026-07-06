## Slot 1 — Ametralladora Arcana (Varita LMB): proyectil muy rápido, pero te ralentiza.
class_name ArcBoltAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArcBolt.tscn")

func _init() -> void:
	id = &"arc_bolt"
	display_name = "Ametralladora Arcana"
	key_label = "LMB"
	color = Color(0.4, 0.8, 1.0)
	cooldown = 0.25 # Fuego rápido
	mana_cost = 0.0
	hold_to_cast = true
	element = &"lightning"

func _cast(player) -> Variant:
	# Ralentiza al jugador mientras ametralla
	player.apply_speed_modifier(0.7, 0.3)
	return _spawn_projectile(player, SCENE, &"lightning_damage", 0.4)
