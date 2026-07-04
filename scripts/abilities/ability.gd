## Habilidad del mago: definición (nombre, cooldown, coste) + casteo.
##
## Cada slot de la barra de poderes tiene una instancia. El player gestiona
## los timers de cooldown; la habilidad solo valida recursos y ejecuta.
class_name Ability
extends RefCounted

## Altura de vuelo de los proyectiles: a la cintura. La varita está a 1.2m
## y un slime normal mide ~0.9m — spawneando a esa altura los proyectiles
## pasaban POR ENCIMA de los enemigos chicos.
const PROJECTILE_HEIGHT := 0.55

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
## Elemento que entrena esta habilidad (skill estilo Tibia). &"" = ninguno.
var element: StringName = &""
## true = es el SUPER de la clase (usa la barra de stamina, no cooldown).
## El HUD lo usa para mostrar el círculo de carga en cualquier kit.
var is_super: bool = false

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

## Helper compartido: instancia un proyectil en la varita/mano del personaje
## con daño rodado desde sus stats. `stat` decide qué daño del loot suma.
func _spawn_projectile(player, scene: PackedScene, stat: StringName, multiplier: float) -> bool:
	var projectile = scene.instantiate()
	player.get_parent().add_child(projectile)
	projectile.global_transform = player.wand.global_transform
	projectile.global_position.y = PROJECTILE_HEIGHT

	var result: Array = player.stats.roll_spell_damage(stat, multiplier)
	if projectile.has_method("setup"):
		projectile.setup(result[0], player, result[1])
	return true

## Helper compartido: AoE expansivo centrado en el personaje (novas, tajos,
## gritos, torbellinos — todos usan frost_nova.gd con otra escena).
func _spawn_nova(player, scene: PackedScene, stat: StringName, multiplier: float) -> bool:
	var result: Array = player.stats.roll_spell_damage(stat, multiplier)
	var nova = scene.instantiate()
	player.get_parent().add_child(nova)
	nova.global_position = player.global_position
	if nova.has_method("setup"):
		nova.setup(result[0], player, result[1])
	return true
