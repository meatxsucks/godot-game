## Guerrero slot 1 — Tajo Deslizante (Lunge Slash).
## Da un salto rápido hacia adelante al atacar.
class_name SlashAbility
extends Ability

const SCENE := preload("res://scenes/magic/SwordSlash.tscn")

func _init() -> void:
	id = &"slash"
	display_name = "Corte Deslizante"
	key_label = "LMB"
	color = Color(0.95, 0.95, 0.88)
	cooldown = 0.5
	mana_cost = 0.0
	hold_to_cast = true
	element = &"melee"

func _cast(player) -> Variant:
	var result: Array = player.stats.roll_spell_damage(&"melee_damage", 0.55)
	# Orientado como el Visual del player
	var xform := Transform3D(player.visual.global_transform.basis, player.global_position)
	var slash := NetSpawn.projectile(SCENE, {"transform": xform}, player.get_parent())
	if slash.has_method("setup"):
		slash.setup(result[0], player, result[1])
	
	# Lunge forward (micro-dash sin i-frames)
	var dir: Vector3 = -player.visual.global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		player.force_move(dir, 3.0, 0.15, false, 0.0)
	
	return true
