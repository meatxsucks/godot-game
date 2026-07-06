## Slot 1 — Bola de Fuego (Bastón LMB): el básico del bastón, liviano.
class_name FireballAbility
extends Ability

const SCENE := preload("res://scenes/magic/Fireball.tscn")

func _init() -> void:
	id = &"fireball"
	display_name = "Bola de Fuego"
	key_label = "LMB"
	color = Color(1.0, 0.45, 0.1)
	cooldown = 1.0
	mana_cost = 0.0
	hold_to_cast = true
	element = &"fire"

func _cast(player) -> Variant:
	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 0.55)
	var projectile = SCENE.instantiate()
	player.get_parent().add_child(projectile)
	projectile.global_transform = player.wand.global_transform
	projectile.global_position.y = PROJECTILE_HEIGHT
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])
	return true
