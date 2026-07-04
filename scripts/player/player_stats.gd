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
	&"mana_regen": 8.0,        # por segundo
	&"spell_damage": 10.0,
	&"fire_damage": 0.0,
	&"cold_damage": 0.0,
	&"lightning_damage": 0.0,
	&"crit_chance": 5.0,       # %
	&"crit_damage": 50.0,      # % de daño extra al critear
	&"cast_speed": 0.0,        # % (reduce el cooldown de lanzamiento)
	&"cooldown_reduction": 0.0,# %
	&"area": 0.0,              # %
	&"res_fire": 0.0,
	&"res_cold": 0.0,
	&"res_lightning": 0.0,
}

## slot (&"weapon", &"offhand", &"ring", &"armor") -> LootItem
var equipment := {}

var health: float = 0.0
var mana: float = 0.0

## Cache de stats efectivos (plano * (1 + %/100)). Se recalcula al equipar.
var _cache := {}

func _init() -> void:
	recompute()
	health = get_stat(&"max_health")
	mana = get_stat(&"max_mana")

## Equipa un ítem en su slot. Devuelve el ítem que estaba antes (o null).
func equip(item: LootItem) -> LootItem:
	if item == null or item.base == null:
		return null
	var slot: StringName = item.base.slot
	var previous = equipment.get(slot, null)
	equipment[slot] = item
	recompute()
	# Re-clampear recursos a los nuevos máximos.
	health = minf(health, get_stat(&"max_health"))
	mana = minf(mana, get_stat(&"max_mana"))
	return previous

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
func roll_spell_damage() -> Array:
	var dmg := get_stat(&"spell_damage") + get_stat(&"fire_damage")
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
