## Habilidad del mago: definición (nombre, cooldown, coste) + casteo.
##
## Cada slot de la barra de poderes tiene una instancia. El player gestiona
## los timers de cooldown; la habilidad solo valida recursos y ejecuta.
class_name Ability
extends RefCounted

var id: StringName = &""
var display_name: String = ""
## Texto del input mostrado en el círculo del HUD ("LMB", "SPC", "Q"...).
var key_label: String = ""
## Color identitario del poder (círculo del HUD, tint de efectos).
var color: Color = Color.WHITE
## Cooldown base en segundos (antes de cast_speed/CDR del equipo).
var cooldown: float = 1.0
var mana_cost: float = 0.0
## true = se puede mantener presionado para re-castear (proyectiles).
var hold_to_cast: bool = false

## Descuento de cooldown generado por el último casteo (ej. legendario
## "Cascada Crítica"). El player lo consume al armar el timer del slot.
var _cooldown_refund: float = 0.0

## Intenta castear. Consume maná solo si el casteo ocurrió.
## Devuelve false si no se pudo lanzar (sin maná, sin carga, sin dirección...).
func execute(player) -> bool:
	if not _can_cast(player):
		return false
	if not _cast(player):
		return false
	player.stats.mana -= mana_cost
	return true

func _can_cast(player) -> bool:
	return player.stats.mana >= mana_cost

## Implementación concreta del poder. Devuelve true si se lanzó.
func _cast(_player) -> bool:
	return false

func consume_cooldown_refund() -> float:
	var refund := _cooldown_refund
	_cooldown_refund = 0.0
	return refund

## Helper compartido: instancia un proyectil en la varita del mago con daño
## rodado desde sus stats. `element` decide qué daño elemental del loot suma.
func _spawn_projectile(player, scene: PackedScene, element: StringName, multiplier: float) -> bool:
	var projectile = scene.instantiate()
	player.get_parent().add_child(projectile)
	projectile.global_transform = player.wand.global_transform

	var result: Array = player.stats.roll_spell_damage(element, multiplier)
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])
	return true
