## Guerrero slot 4 — Grito de Guerra: onda AoE que golpea alrededor y, como
## grito de combate, CURA al Guerrero (25% de su vida máxima). Su sustain.
class_name WarCryAbility
extends Ability

const SCENE := preload("res://scenes/magic/WarCry.tscn")
## Fracción de la vida máxima que recupera al gritar.
const HEAL_FRACTION := 0.25

func _init() -> void:
	id = &"war_cry"
	display_name = "Grito de Guerra"
	key_label = "Q"
	color = Color(0.3, 0.9, 0.4)
	cooldown = 8.0
	mana_cost = 20.0
	element = &"melee"

func _cast(player) -> Variant:
	# Cura al Guerrero (número verde) además del golpe en área.
	var heal_amount: float = player.stats.get_stat(&"max_health") * HEAL_FRACTION
	player.heal(heal_amount)
	FX.damage_number(player.global_position, heal_amount, false, Color(0.3, 1.0, 0.4))
	FX.burst(player.global_position + Vector3.UP, Color(0.3, 1.0, 0.4), 16, 0.09)
	# Base LEVE a propósito (E10.4, era 1.2): el árbol de talentos lo potencia.
	return _spawn_nova(player, SCENE, &"melee_damage", 0.8)
