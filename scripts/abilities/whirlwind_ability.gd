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

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.5)
	# Estallido de partículas + doble onda de choque (impacto visual).
	FX.burst(player.global_position + Vector3.UP * 0.4, Color(1.0, 0.45, 0.1), 40, 0.14)
	_spawn_nova(player, SCENE, &"melee_damage", 2.0)
	var tree = player.get_tree()
	tree.create_timer(0.18).timeout.connect(func() -> void:
		if is_instance_valid(player) and player.is_inside_tree() and not player.get("_dead"):
			_spawn_nova(player, SCENE, &"melee_damage", 1.0))
	return true
