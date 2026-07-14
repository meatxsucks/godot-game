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

## Tags de estado (E3, GDD §4) que esta habilidad APLICA al golpear y los
## que DETONA (consume por daño extra). Los combos salen de combinar esto
## entre armas y clases — nunca se hardcodea un combo.
var applies: Array[StringName] = []
var detonates: Array[StringName] = []

## Descuento de cooldown generado por el último casteo (ej. legendario
## "Cascada Crítica"). El player lo consume al armar el timer del slot.
var _cooldown_refund: float = 0.0

## Intenta castear. Consume maná solo si el casteo ocurrió.
## Devuelve false si no se pudo lanzar (sin maná, sin carga, sin dirección...).
func execute(player) -> bool:
	if not _can_cast(player):
		return false
	var cast_result = _cast(player)
	if cast_result is bool and not cast_result:
		return false
	player.stats.mana -= mana_cost
	return true

func _can_cast(player) -> bool:
	return player.stats.mana >= mana_cost

## Implementación concreta del poder. Puede usar await (retorna coroutine) o bool.
func _cast(_player) -> Variant:
	return false

func consume_cooldown_refund() -> float:
	var refund := _cooldown_refund
	_cooldown_refund = 0.0
	return refund

## Suma los tags y el elemento de la habilidad a las props del spawn (viajan
## serializados). El proyectil usa los tags al golpear (host) y el elemento
## para entrenar el skill del lanzador al conectar (E6.1).
func _tag_props(props: Dictionary) -> Dictionary:
	if not applies.is_empty():
		props["applies"] = Array(applies)
	if not detonates.is_empty():
		props["detonates"] = Array(detonates)
	if element != &"":
		props["hit_element"] = element
	return props

## Helper compartido: instancia un proyectil en la varita/mano del personaje
## con daño rodado desde sus stats. `stat` decide qué daño del loot suma.
## El daño viaja DENTRO del spawn (en un cliente el nodo devuelto es null:
## el pedido se fue por RPC al host — ver NetSpawn.projectile).
func _spawn_projectile(player, scene: PackedScene, stat: StringName, multiplier: float) -> bool:
	var xform: Transform3D = player.wand.global_transform
	xform.origin.y = PROJECTILE_HEIGHT
	var result: Array = player.stats.roll_spell_damage(stat, multiplier)
	NetSpawn.projectile(scene, _tag_props({"transform": xform}), player.get_parent(),
		result[0], player, result[1])
	return true

## Helper compartido: AoE expansivo centrado en el personaje (novas, tajos,
## gritos, torbellinos — todos usan frost_nova.gd con otra escena).
## La posición va ANTES de add_child (el _ready arma el tween en su sitio).
func _spawn_nova(player, scene: PackedScene, stat: StringName, multiplier: float) -> bool:
	var result: Array = player.stats.roll_spell_damage(stat, multiplier)
	NetSpawn.projectile(scene, _tag_props({"position": player.global_position}),
		player.get_parent(), result[0], player, result[1])
	return true
