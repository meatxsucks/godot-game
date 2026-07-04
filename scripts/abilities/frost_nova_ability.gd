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
	element = &"cold"

func _cast(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(&"cold_damage", 1.0)
	var nova = SCENE.instantiate()
	player.get_parent().add_child(nova)
	nova.global_position = player.global_position
	if nova.has_method("setup"):
		nova.setup(result[0], player, result[1])
	return true
