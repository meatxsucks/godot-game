## Stats del mago: base del personaje + agregado de los ítems equipados.
##
## Cierra el loop ARPG: el loot equipado modifica estos valores y el combate
## (daño de hechizos, crítico, maná, cooldown) los lee en vivo.
class_name PlayerStats
extends RefCounted

## Stats base del mago a nivel 1, sin equipo. Las claves coinciden con las
## de los afijos (ver loot_database.gd) para que el agregado sea directo.
var base_stats := {
	&"max_health": 100.0,
	&"max_mana": 100.0,
	&"mana_regen": 8.0,        # maná recuperado POR KILL (no hay regen pasiva)
	&"spell_damage": 10.0,
	&"fire_damage": 0.0,
	&"cold_damage": 0.0,
	&"lightning_damage": 0.0,
	&"crit_chance": 5.0,       # %
	&"crit_damage": 50.0,      # % de daño extra al critear
	&"cast_speed": 0.0,        # % (reduce el cooldown de lanzamiento)
	&"cooldown_reduction": 0.0,# %
	&"move_speed": 0.0,        # % de velocidad de movimiento (botas)
	&"area": 0.0,              # %
	&"res_fire": 0.0,
	&"res_cold": 0.0,
	&"res_lightning": 0.0,
}

## slot (&"head", &"armor", &"weapon", &"offhand", &"ring", &"boots") -> LootItem
var equipment := {}

## Skills estilo Tibia: suben usando cada tipo de daño y potencian ese daño.
var skills := SkillSet.new()

var health: float = 0.0
var mana: float = 0.0

## Cache de stats efectivos (plano * (1 + %/100)). Se recalcula al equipar.
var _cache := {}

func _init() -> void:
	# Overrides de la clase elegida (rol): el Guerrero arranca tanque, etc.
	base_stats.merge(Game.selected_stats(), true)
	recompute()
	health = get_stat(&"max_health")
	mana = get_stat(&"max_mana")

## Equipa un ítem en su slot. Devuelve los ítems desplazados (0-2: el que
## ocupaba el slot, más el offhand/arma si hay conflicto a dos manos).
func equip(item: LootItem) -> Array[LootItem]:
	var displaced: Array[LootItem] = []
	if item == null or item.base == null:
		return displaced
	var slot: StringName = item.base.slot

	# Arma a dos manos: ocupa también la mano secundaria.
	if slot == &"weapon" and item.base.two_handed and equipment.get(&"offhand") != null:
		displaced.append(equipment[&"offhand"])
		equipment.erase(&"offhand")
	# Equipar offhand con un arma 2H puesta: el arma sale.
	if slot == &"offhand":
		var weapon: LootItem = equipment.get(&"weapon", null)
		if weapon and weapon.base.two_handed:
			displaced.append(weapon)
			equipment.erase(&"weapon")

	var previous: LootItem = equipment.get(slot, null)
	if previous:
		displaced.append(previous)
	equipment[slot] = item
	recompute()
	_clamp_resources()
	return displaced

## Saca el ítem de un slot. Devuelve el ítem (o null si estaba vacío).
func unequip(slot: StringName) -> LootItem:
	var item: LootItem = equipment.get(slot, null)
	if item == null:
		return null
	equipment.erase(slot)
	recompute()
	_clamp_resources()
	return item

## Re-clampea vida/maná a los máximos actuales (tras cambiar el equipo).
func _clamp_resources() -> void:
	health = minf(health, get_stat(&"max_health"))
	mana = minf(mana, get_stat(&"max_mana"))

## Recalcula el cache combinando base + planos + porcentajes de cada ítem.
func recompute() -> void:
	var flat: Dictionary = base_stats.duplicate()
	var pct := {}
	for slot in equipment:
		var item: LootItem = equipment[slot]
		if item == null:
			continue
		for k in item.stats:                 # planos (base del item + afijos FLAT)
			flat[k] = float(flat.get(k, 0.0)) + float(item.stats[k])
		for k in item.percent_mods:          # modificadores PERCENT
			pct[k] = float(pct.get(k, 0.0)) + float(item.percent_mods[k])
	_cache = {}
	for k in flat:
		var p := float(pct.get(k, 0.0))
		_cache[k] = float(flat[k]) * (1.0 + p / 100.0)
	# Stats que sólo existen como % (sin valor plano base).
	for k in pct:
		if not _cache.has(k):
			_cache[k] = float(base_stats.get(k, 0.0)) * (1.0 + float(pct[k]) / 100.0)

func get_stat(name: StringName) -> float:
	return float(_cache.get(name, 0.0))

## Daño de un golpe de hechizo con tirada de crítico. Devuelve [daño, es_critico].
## `element` es el stat elemental del loot que suma al daño base (fuego para
## la Bola de Fuego, rayo para la Descarga, frío para la Nova...) y
## `multiplier` escala el golpe (proyectil spam más débil, super más fuerte).
func roll_spell_damage(element: StringName = &"fire_damage", multiplier: float = 1.0) -> Array:
	var dmg := (get_stat(&"spell_damage") + get_stat(element)) * multiplier \
			* skills.damage_multiplier(element)
	var is_crit := randf() * 100.0 < get_stat(&"crit_chance")
	if is_crit:
		dmg *= 1.0 + get_stat(&"crit_damage") / 100.0
	return [dmg, is_crit]

## ¿Hay algún ítem equipado con este poder legendario activo?
func has_legendary(effect_id: StringName) -> bool:
	for slot in equipment:
		var item: LootItem = equipment[slot]
		if item and item.legendary and item.legendary.effect_id == effect_id:
			return true
	return false
