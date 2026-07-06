## Slot 1 — Tiro de Tensión (Arco LMB).
## Dispara una flecha de alto daño y penetrante, pero reduce tu velocidad.
class_name ArrowAbility
extends Ability

const SCENE := preload("res://scenes/magic/Arrow.tscn")

func _init() -> void:
	id = &"arrow"
	display_name = "Tiro de Tensión"
	key_label = "LMB"
	color = Color(1.0, 0.7, 0.35)
	cooldown = 1.0
	mana_cost = 0.0
	hold_to_cast = true
	element = &"ranged"

func _cast(player) -> Variant:
	# Ralentiza al jugador como si estuviera tensando el arco
	player.apply_speed_modifier(0.4, 0.6)
	
	var result: Array = player.stats.roll_spell_damage(&"ranged_damage", 1.5)
	var arrow = SCENE.instantiate()
	player.get_parent().add_child(arrow)
	arrow.global_transform = player.wand.global_transform
	arrow.global_position.y = PROJECTILE_HEIGHT
	# Hacerla perforante y rápida
	if "pierces_left" in arrow:
		arrow.pierces_left = 3
	arrow.scale = Vector3(1.2, 1.2, 1.2)
	
	if arrow.has_method("setup"):
		arrow.setup(result[0], player, result[1])
	return true
