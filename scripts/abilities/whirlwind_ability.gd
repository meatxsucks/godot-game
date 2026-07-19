## Guerrero slot 5 — SUPER: Golpe de Titán. Un único golpe masivo en el
## suelo (no un giro repetido como el de la espada): requiere la stamina
## llena y la consume entera. El finisher del tanque.
class_name WhirlwindAbility
extends Ability

const SCENE := preload("res://scenes/magic/TitanSlam.tscn")

func _init() -> void:
	id = &"titan_slam"
	display_name = "Golpe de Titán"
	key_label = "R"
	color = Color(1.0, 0.85, 0.3)
	cooldown = 1.0
	mana_cost = 0.0
	power = 1.6
	element = &"melee"
	detonates = [&"bleed"]
	is_super = true

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.6)
	FX.burst(player.global_position + Vector3.UP * 0.4, Color(1.0, 0.85, 0.3), 36, 0.16)
	# Un solo impacto colosal (2.5x), no una serie de giros repetidos.
	# Base LEVE a propósito (E10.4, era 2.5): el árbol de talentos lo potencia.
	return _spawn_nova(player, SCENE, &"melee_damage", power)
