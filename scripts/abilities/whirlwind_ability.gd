## Guerrero slot 5 — SUPER: Torbellino. Requiere la stamina llena y la
## consume entera: nova gigante con daño masivo alrededor.
class_name WhirlwindAbility
extends Ability

const SCENE := preload("res://scenes/magic/Whirlwind.tscn")

func _init() -> void:
	id = &"whirlwind"
	display_name = "Torbellino"
	key_label = "R"
	color = Color(0.9, 0.2, 0.15)
	cooldown = 1.0
	mana_cost = 0.0
	element = &"melee"
	is_super = true

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> bool:
	if not player.consume_super_charge():
		return false
	return _spawn_nova(player, SCENE, &"melee_damage", 2.0)
