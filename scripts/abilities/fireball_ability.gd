## Slot 1 — Bola de Fuego: el proyectil principal, pega fuerte cada 2s.
class_name FireballAbility
extends Ability

const SCENE := preload("res://scenes/magic/Fireball.tscn")

func _init() -> void:
	id = &"fireball"
	display_name = "Bola de Fuego"
	key_label = "LMB"
	color = Color(1.0, 0.45, 0.1)
	cooldown = 2.0
	mana_cost = 15.0
	hold_to_cast = true
	element = &"fire"

func _cast(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(&"fire_damage", 1.0)
	var projectile = SCENE.instantiate()
	player.get_parent().add_child(projectile)
	projectile.global_transform = player.wand.global_transform
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])

	# Poder legendario "Cascada Crítica": cada crítico recorta el cooldown.
	if result[1] and player.stats.has_legendary(&"crit_cdr"):
		_cooldown_refund = 0.5
	return true
