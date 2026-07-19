## Slot 4 — Nova de Escarcha: anillo AoE que crece desde el mago.
## Escala con cold_damage del loot.
class_name FrostNovaAbility
extends Ability

const SCENE := preload("res://scenes/magic/FrostNova.tscn")

func _init() -> void:
	id = &"frost_nova"
	display_name = "Nova de Escarcha"
	key_label = "Q"
	color = Color(0.5, 0.85, 1.0)
	cooldown = 5.0
	mana_cost = 25.0
	power = 0.35
	element = &"cold"
	applies = [&"frozen"]

func _cast(player) -> Variant:
	# Base MUY leve a propósito (E10.4; 2º nerf 2026-07-17: la Q seguía
	# reventando — feedback del dueño): el árbol de talentos lo potencia.
	return _spawn_nova(player, SCENE, &"cold_damage", power)
