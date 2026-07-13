## Alquimista Q — Frasco Vivificante: lanzas un frasco al punto apuntado
## (rango limitado) que CURA a los aliados en el área y hace SANGRAR a los
## enemigos. Dual en una tecla: posicionarlo bien es el juego.
class_name AlchemistFlaskAbility
extends Ability

const SCENE := preload("res://scenes/magic/Flask.tscn")
const MAX_RANGE := 8.0

func _init() -> void:
	id = &"alchemist_flask"
	display_name = "Frasco Vivificante"
	key_label = "Q"
	color = Color(0.5, 1.0, 0.6)
	cooldown = 5.0
	mana_cost = 22.0
	element = &"magic"
	applies = [&"bleed"]

func _cast(player) -> Variant:
	var target: Vector3 = player.get_aim_point()
	target.y = 0.0
	var to_target: Vector3 = target - player.global_position
	to_target.y = 0.0
	if to_target.length() > MAX_RANGE:
		target = player.global_position + to_target.normalized() * MAX_RANGE
	# La cura ES el daño rolleado (escala con spell_damage/afijos/skills).
	var result: Array = player.stats.roll_spell_damage(&"magic", 0.9)
	NetSpawn.projectile(SCENE, _tag_props({"position": target}), player.get_parent(),
		result[0], player, result[1])
	return true
