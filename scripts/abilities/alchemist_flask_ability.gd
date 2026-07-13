## Alquimista Q — Frasco Corrosivo: lanzas un frasco al punto apuntado que
## deja un CHARCO de ácido persistente. Los enemigos que lo pisan se derriten
## (daño por tick + Sangrado que se apila), los aliados dentro se curan. No
## es un pop instantáneo: es una zona que colocas y controla el espacio.
class_name AlchemistFlaskAbility
extends Ability

const PUDDLE := preload("res://scenes/magic/AcidPuddle.tscn")
const MAX_RANGE := 9.0

func _init() -> void:
	id = &"alchemist_flask"
	display_name = "Frasco Corrosivo"
	key_label = "Q"
	color = Color(0.55, 0.9, 0.25)
	cooldown = 6.0
	mana_cost = 20.0
	element = &"magic"
	applies = [&"bleed"]

func _cast(player) -> Variant:
	var target: Vector3 = player.get_aim_point()
	target.y = 0.0
	var to_target: Vector3 = target - player.global_position
	to_target.y = 0.0
	if to_target.length() > MAX_RANGE:
		target = player.global_position + to_target.normalized() * MAX_RANGE
	# El daño rolleado escala el charco (ticks y cura salen de acá).
	var result: Array = player.stats.roll_spell_damage(&"magic", 1.0)
	NetSpawn.projectile(PUDDLE, _tag_props({"position": target}), player.get_parent(),
		result[0], player, result[1])
	FX.burst(target + Vector3.UP, color, 16, 0.09)
	return true
