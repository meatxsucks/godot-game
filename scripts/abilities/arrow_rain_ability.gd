## Explorador slot 5 — SUPER: Lluvia de Flechas sobre el punto del cursor.
## Requiere la stamina llena y la consume entera.
class_name ArrowRainAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArrowRain.tscn")

func _init() -> void:
	id = &"arrow_rain"
	display_name = "Lluvia de Flechas"
	key_label = "R"
	color = Color(0.45, 0.9, 0.4)
	cooldown = 1.0
	mana_cost = 0.0
	element = &"ranged"
	is_super = true

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> bool:
	if not player.consume_super_charge():
		return false
	FX.shake(0.4)
	var result: Array = player.stats.roll_spell_damage(&"ranged_damage", 1.2)
	# Posición ANTES de add_child (los objetivos se calculan en _ready).
	var rain = SCENE.instantiate()
	rain.position = player.get_front_point()
	player.get_parent().add_child(rain)
	if rain.has_method("setup"):
		rain.setup(result[0], player)
	return true
