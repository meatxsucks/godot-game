## Guerrero slot 1 — Tajo Circular: el "espadazo" básico, AoE instantáneo
## alrededor del guerrero. Gratis y spameable.
class_name SlashAbility
extends Ability

const SCENE := preload("res://scenes/magic/SlashWave.tscn")

func _init() -> void:
	id = &"slash"
	display_name = "Tajo Circular"
	key_label = "LMB"
	color = Color(0.95, 0.95, 0.88)
	cooldown = 0.6
	mana_cost = 0.0
	hold_to_cast = true
	element = &"melee"

func _cast(player) -> bool:
	return _spawn_nova(player, SCENE, &"melee_damage", 1.0)
