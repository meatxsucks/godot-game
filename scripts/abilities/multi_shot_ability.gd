## Explorador slot 2 — Disparo Múltiple: 3 flechas en abanico.
class_name MultiShotAbility
extends Ability

const SCENE := preload("res://scenes/magic/Arrow.tscn")
## Apertura del abanico en radianes (~14° por flecha lateral).
const SPREAD := 0.24

func _init() -> void:
	id = &"multi_shot"
	display_name = "Disparo Múltiple"
	key_label = "RMB"
	color = Color(1.0, 0.7, 0.35)
	cooldown = 1.3
	mana_cost = 12.0
	hold_to_cast = true
	element = &"ranged"

func _cast(player) -> bool:
	for offset in [-SPREAD, 0.0, SPREAD]:
		var result: Array = player.stats.roll_spell_damage(&"ranged_damage", 0.8)
		var arrow = SCENE.instantiate()
		player.get_parent().add_child(arrow)
		arrow.global_transform = player.wand.global_transform
		arrow.rotate_y(offset)
		if arrow.has_method("setup"):
			arrow.setup(result[0], player, result[1])
	return true
