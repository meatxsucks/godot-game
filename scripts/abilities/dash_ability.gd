## Slot 3 — Dash Arcano: impulso corto de movimiento estilo Wizard of Legend.
## La física del dash vive en el player (start_dash); aquí solo se dispara.
class_name DashAbility
extends Ability

func _init() -> void:
	id = &"dash"
	display_name = "Dash Arcano"
	key_label = "SPC"
	color = Color(0.85, 0.9, 1.0)
	cooldown = 1.5
	mana_cost = 0.0

func _cast(player) -> bool:
	return player.start_dash()
