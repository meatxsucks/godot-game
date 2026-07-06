## Slot 2 — Salto Evasivo (Arco RMB).
## Salta hacia atrás dejando una trampa/explosión en tu posición original.
class_name MultiShotAbility
extends Ability

const SCENE := preload("res://scenes/magic/FrostNova.tscn")

func _init() -> void:
	id = &"multi_shot"
	display_name = "Salto Evasivo"
	key_label = "RMB"
	color = Color(0.8, 0.9, 1.0)
	cooldown = 3.0
	mana_cost = 15.0
	element = &"ranged"

func _cast(player) -> Variant:
	# z positivo es hacia atrás relativo al visual (que mira al mouse)
	var dir: Vector3 = player.visual.global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		# dash hacia atrás rápido con invulnerabilidad
		player.force_move(dir.normalized(), 3.5, 0.25, true, 0.0)
	
	# Deja una trampa que explota
	FX.burst(player.global_position + Vector3.UP, Color(0.8, 0.9, 1.0), 12, 0.05)
	return _spawn_nova(player, SCENE, &"ranged_damage", 0.6)
