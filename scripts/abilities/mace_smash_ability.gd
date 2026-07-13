## Slot 1 — Salto Sísmico (Mazo LMB).
## Salta hacia el cursor y golpea en área al aterrizar.
class_name MaceSmashAbility
extends Ability

const SCENE := preload("res://scenes/magic/WarCry.tscn")

func _init() -> void:
	id = &"mace_smash"
	display_name = "Salto Sísmico"
	key_label = "LMB"
	color = Color(0.7, 0.6, 0.5)
	cooldown = 1.1
	mana_cost = 0.0
	hold_to_cast = true
	element = &"melee"
	applies = [&"marked"]

func _cast(player) -> Variant:
	var target = player.get_aim_point()
	var dist = player.global_position.distance_to(target)
	# Limitar el alcance a 4.5 metros
	if dist > 4.5:
		target = player.global_position + (target - player.global_position).normalized() * 4.5
	
	# El tiempo depende de la distancia, con un mínimo y máximo
	var leap_time = clampf(dist / 12.0, 0.25, 0.45)
	
	player.leap_to(target, leap_time, 1.8, func():
		if not player.is_inside_tree() or player._dead:
			return
		FX.shake(0.4)
		_spawn_nova(player, SCENE, &"melee_damage", 0.5)
	)
	return true
