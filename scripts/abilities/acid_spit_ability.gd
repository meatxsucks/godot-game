## Alquimista — básico desarmado: Escupitajo Ácido. Un proyectil verde,
## rápido y spameable, que hace Sangrar. Reemplaza el golpe de mago cuando
## el Alquimista no tiene arma (ClassDef.unarmed_power). Con arma equipada
## manda el arma, como cualquier clase.
class_name AcidSpitAbility
extends Ability

const SCENE := preload("res://scenes/magic/AcidSpit.tscn")

func _init() -> void:
	id = &"acid_spit"
	display_name = "Escupitajo Ácido"
	key_label = "LMB"
	color = Color(0.55, 0.9, 0.25)
	cooldown = 0.35
	mana_cost = 0.0
	power = 0.4
	hold_to_cast = true
	element = &"magic"
	applies = [&"bleed"]

func _cast(player) -> Variant:
	return _spawn_projectile(player, SCENE, &"magic", power)
