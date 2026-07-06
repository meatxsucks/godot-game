## Slot 1 — Bola de Fuego de Artillería (Bastón LMB).
## Gran daño, pero te inmoviliza brevemente al castear.
class_name FireballAbility
extends Ability

const SCENE := preload("res://scenes/magic/Fireball.tscn")

func _init() -> void:
	id = &"fireball"
	display_name = "Artillería Ígnea"
	key_label = "LMB"
	color = Color(1.0, 0.45, 0.1)
	cooldown = 1.0
	mana_cost = 0.0
	hold_to_cast = true
	element = &"fire"

func _cast(player) -> Variant:
	# Te ancla al piso por 0.8s
	player.apply_speed_modifier(0.0, 0.8)
	
	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 1.8)
	var projectile = SCENE.instantiate()
	player.get_parent().add_child(projectile)
	projectile.global_transform = player.wand.global_transform
	projectile.global_position.y = PROJECTILE_HEIGHT
	# Escala el proyectil para que se vea más grande
	projectile.scale = Vector3(1.5, 1.5, 1.5)
	
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])
	return true
