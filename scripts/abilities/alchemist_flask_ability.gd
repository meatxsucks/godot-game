## Alquimista Q — Frasco Vivificante: lanzas un frasco de ácido al punto
## apuntado (rango limitado). En la misma área: DAÑA y hace SANGRAR a los
## enemigos, y CURA a los aliados. Dual en una tecla: posicionarlo bien es
## el juego — y en solo es tu arma principal.
class_name AlchemistFlaskAbility
extends Ability

const SCENE := preload("res://scenes/magic/Flask.tscn")
const MAX_RANGE := 8.0

func _init() -> void:
	id = &"alchemist_flask"
	display_name = "Frasco Vivificante"
	key_label = "Q"
	color = Color(0.55, 0.9, 0.25)
	cooldown = 3.5
	mana_cost = 16.0
	element = &"magic"
	applies = [&"bleed"]

func _cast(player) -> Variant:
	var target: Vector3 = player.get_aim_point()
	target.y = 0.0
	var to_target: Vector3 = target - player.global_position
	to_target.y = 0.0
	if to_target.length() > MAX_RANGE:
		target = player.global_position + to_target.normalized() * MAX_RANGE
	# El roll es cura (100% a aliados) Y daño de ácido (60% a enemigos).
	var result: Array = player.stats.roll_spell_damage(&"magic", 1.0)
	NetSpawn.projectile(SCENE, _tag_props({"position": target}), player.get_parent(),
		result[0], player, result[1])
	return true
