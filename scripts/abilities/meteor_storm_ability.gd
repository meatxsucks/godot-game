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
	element = &"fire"
	is_super = true
	# El ejemplo del GDD §4: la R de fuego DETONA a los Quemados.
	detonates = [&"burn"]

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.4)
	# Base LEVE a propósito (E10.4, era 1.5): el árbol de talentos lo potencia.
	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 1.0 * damage_scale)
	# La posición viaja en props y se aplica ANTES de entrar al árbol: la
	# tormenta calcula sus objetivos en _ready (asignarla después la hacía
	# caer alrededor del origen).
	NetSpawn.projectile(SCENE,
		_tag_props({"position": player.get_front_point()}), player.get_parent(),
		result[0], player)
	return true
