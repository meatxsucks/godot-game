## Slot 5 — SUPER: Tormenta de Meteoros. No usa cooldown ni maná: requiere
## la barra de stamina llena (se carga golpeando/matando enemigos) y la
## consume entera. Cae sobre el punto apuntado con el mouse.
class_name MeteorStormAbility
extends Ability

const SCENE := preload("res://scenes/magic/MeteorStorm.tscn")

func _init() -> void:
	id = &"meteor_storm"
	display_name = "Tormenta de Meteoros"
	key_label = "R"
	color = Color(1.0, 0.25, 0.15)
	cooldown = 1.0
	mana_cost = 0.0

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> bool:
	if not player.consume_super_charge():
		return false
	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 1.5)
	var storm = SCENE.instantiate()
	player.get_parent().add_child(storm)
	storm.global_position = player.get_aim_point()
	if storm.has_method("setup"):
		storm.setup(result[0], player)
	return true
