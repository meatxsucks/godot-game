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
	&"melee_damage": 0.0,      # Guerrero
	&"ranged_damage": 0.0,     # Explorador
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

## Experiencia y nivel del personaje: XP por kill, stats base suben al nivel.
var level: int = 1
var xp: float = 0.0

## Escala global del daño de los poderes por nivel (feedback 2026-07-11:
## pegaban muy fuerte de entrada). Arrancan al 60% del daño y suben 5% por
## nivel (100% en nivel 9), con tope de 1.5x en nivel 19. Un solo knob para
## balancear la curva completa.
const LEVEL_DMG_BASE := 0.6
const LEVEL_DMG_PER_LEVEL := 0.05
const LEVEL_DMG_CAP := 1.5

func level_damage_scale() -> float:
	return minf(LEVEL_DMG_CAP, LEVEL_DMG_BASE + LEVEL_DMG_PER_LEVEL * (level - 1))

## Oro (E5.1): el recurso de la economía Tibia (tienda/herrería/banco E5).
var gold: int = 0

var health: float = 0.0
var mana: float = 0.0

## Corrupción (E2.1, mecánica central del GDD §5): 0..CORRUPTION_MAX. Sube con
## el tiempo en zona infectada y por golpes recibidos; se limpia en zona segura.
## Por ahora es solo el medidor — mutación de enemigos (E2.2), riesgo/beneficio
## (E2.3) y contagio (E2.4) son tareas aparte que todavía leen/escriben este valor.
const CORRUPTION_MAX := 100.0
var corruption: float = 0.0

func add_corruption(amount: float) -> void:
	corruption = clampf(corruption + amount, 0.0, CORRUPTION_MAX)

func clear_corruption(amount: float = CORRUPTION_MAX) -> void:
	corruption = clampf(corruption - amount, 0.0, CORRUPTION_MAX)

## Cache de stats efectivos (plano * (1 + %/100)). Se recalcula al equipar.
var _cache := {}

func _init(cls: StringName = &"") -> void:
	# Overrides de la clase del dueño (rol): el Guerrero arranca tanque, etc.
	# &"" = la clase seleccionada localmente (single-player).
	base_stats.merge(Game.class_stats(cls), true)
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

# --- Experiencia ------------------------------------------------------------

## XP necesaria para pasar del nivel actual al siguiente.
func xp_needed() -> float:
	return 40.0 + level * 30.0

## Suma XP. Devuelve cuántos niveles subió (0 = ninguno).
func add_xp(amount: float) -> int:
	xp += amount
	var ups := 0
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		ups += 1
		_apply_level_up()
	return ups

## Bonos por nivel (todas las clases se benefician). El level-up RELLENA
## vida y maná al 100% (GDD §7, E6.3): en un juego sin regeneración pasiva,
## subir de nivel es el respiro.
func _apply_level_up() -> void:
	base_stats[&"max_health"] = float(base_stats[&"max_health"]) + 10.0
	base_stats[&"max_mana"] = float(base_stats[&"max_mana"]) + 5.0
	base_stats[&"spell_damage"] = float(base_stats[&"spell_damage"]) + 1.0
	base_stats[&"melee_damage"] = float(base_stats[&"melee_damage"]) + 1.0
	base_stats[&"ranged_damage"] = float(base_stats[&"ranged_damage"]) + 1.0
	recompute()
	health = get_stat(&"max_health")
	mana = get_stat(&"max_mana")

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
			* skills.damage_multiplier(element) \
			* level_damage_scale()
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
