## Guerrero slot 1 — Tajo de Espada: el ataque básico, un barrido frontal
## con la hoja visible. Gratis y spameable; apunta hacia el mouse.
class_name SlashAbility
extends Ability

const SCENE := preload("res://scenes/magic/SwordSlash.tscn")

func _init() -> void:
	id = &"slash"
	display_name = "Tajo de Espada"
	key_label = "LMB"
	color = Color(0.95, 0.95, 0.88)
	cooldown = 0.5
	mana_cost = 0.0
	hold_to_cast = true
	element = &"melee"

func _cast(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 1.0)
	var slash = SCENE.instantiate()
	player.get_parent().add_child(slash)
	slash.global_position = player.global_position
	# Orientado como el Visual del player (que mira al cursor).
	slash.global_transform.basis = player.visual.global_transform.basis
	if slash.has_method("setup"):
		slash.setup(result[0], player, result[1])
	return true
