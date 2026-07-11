## Slot 2 — Parpadeo Eléctrico (Varita RMB): teletransporte corto + rayo en cadena.
class_name ChainBoltAbility
extends Ability

const SCENE := preload("res://scenes/magic/ArcBolt.tscn")

func _init() -> void:
	id = &"chain_bolt"
	display_name = "Parpadeo Eléctrico"
	key_label = "RMB"
	color = Color(0.3, 0.7, 1.0)
	cooldown = 2.5
	mana_cost = 15.0
	element = &"lightning"

func _cast(player) -> Variant:
	var target = player.get_aim_point()
	target.y = player.global_position.y
	
	var dist = player.global_position.distance_to(target)
	if dist > 4.0:
		target = player.global_position + (target - player.global_position).normalized() * 4.0
	
	# Efecto al desaparecer
	var fx = player.get_node_or_null("/root/FX")
	if fx:
		fx.burst(player.global_position + Vector3(0, 1, 0), Color(0.3, 0.7, 1.0), 12, 0.05)
	
	player.global_position = target
	
	# Efecto al aparecer
	if fx:
		fx.burst(player.global_position + Vector3(0, 1, 0), Color(0.3, 0.7, 1.0), 12, 0.05)
	
	# Suelta rayo en cadena
	var result: Array = player.stats.roll_spell_damage(&"lightning_damage", 0.65)
	var xform: Transform3D = player.wand.global_transform
	xform.origin.y = PROJECTILE_HEIGHT
	var projectile := NetSpawn.projectile(SCENE,
		{"transform": xform, "chains_left": 2}, player.get_parent())
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])
	return true
