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

## slot (&"head", &"armor", &"weapon", &"offhand", &"cape", &"hands",
## &"ring", &"boots") -> LootItem
var equipment := {}

## Skills estilo Tibia: suben usando cada tipo de daño y potencian ese daño.
var skills := SkillSet.new()

## Experiencia y nivel del personaje: XP por kill, stats base suben al nivel.
var level: int = 1
var xp: float = 0.0

## Escala global del daño de los poderes por nivel (feedback 2026-07-11:
## pegaban muy fuerte de entrada). Knobs en resources/balance.tres.
func level_damage_scale() -> float:
	var b := BalanceDef.bal()
	return minf(b.level_dmg_cap, b.level_dmg_base + b.level_dmg_per_level * (level - 1))

## Oro (E5.1): el recurso de la economía Tibia (tienda/herrería/banco E5).
var gold: int = 0

# --- Árbol de talentos (E10.3/E10.4/E10.6) ----------------------------------

## Nodos comprados: upgrade_id -> rangos. Se aplican al construir el kit de
## clase (apply_talents). Guardado en SaveService.
var talents: Dictionary = {}
## Cuántas veces se reseteó el árbol (el costo del respec crece, E10.6).
var respec_count: int = 0

## Puntos ganados: 1 cada N niveles (decisión 2026-07-17: 3 — escasos,
## pesan). N en resources/balance.tres.
func talent_points_total() -> int:
	return int(level / float(BalanceDef.bal().levels_per_talent_point))

func talent_points_spent() -> int:
	var spent := 0
	for up_id in talents:
		var up: AbilityUpgrade = Game.upgrade(up_id)
		if up:
			spent += int(talents[up_id]) * up.cost
	return spent

func talent_points_available() -> int:
	return talent_points_total() - talent_points_spent()

## Compra un rango del nodo. Valida puntos, rangos y el gating por inversión
## (requires_spent). Devuelve true si compró.
func buy_talent(up_id: StringName) -> bool:
	var up: AbilityUpgrade = Game.upgrade(up_id)
	if up == null:
		return false
	var ranks := int(talents.get(up_id, 0))
	if ranks >= up.max_ranks:
		return false
	if talent_points_available() < up.cost:
		return false
	if talent_points_spent() < up.requires_spent:
		return false
	talents[up_id] = ranks + 1
	return true

## Costo del PRÓXIMO respec: CRECIENTE (decisión 2026-07-17). Base y factor
## en resources/balance.tres.
func respec_cost() -> int:
	var b := BalanceDef.bal()
	return b.respec_base_gold * int(pow(b.respec_growth, respec_count))

## Resetea el árbol pagando oro. Devuelve true si pudo pagar.
func respec_talents() -> bool:
	if talents.is_empty():
		return false
	if gold < respec_cost():
		return false
	gold -= respec_cost()
	respec_count += 1
	talents.clear()
	return true

## Aplica los nodos comprados a una habilidad recién construida (la llama el
## player al armar el kit de clase). Modifica daño/cooldown/maná del Ability.
func apply_talents(ability: Ability) -> void:
	for up_id in talents:
		var up: AbilityUpgrade = Game.upgrade(up_id)
		if up == null or up.ability_id != ability.id:
			continue
		var ranks := int(talents[up_id])
		if up.damage_per_rank > 0.0:
			ability.damage_scale *= 1.0 + up.damage_per_rank * ranks
		if up.cooldown_per_rank > 0.0:
			ability.cooldown *= maxf(0.3, 1.0 - up.cooldown_per_rank * ranks)
		if up.mana_per_rank > 0.0:
			ability.mana_cost *= maxf(0.0, 1.0 - up.mana_per_rank * ranks)

var health: float = 0.0
var mana: float = 0.0

## Cache de stats efectivos (plano * (1 + %/100)). Se recalcula al equipar.
var _cache := {}
## Cache de pasivos de comportamiento (E6.2): behavior_id -> magnitud sumada
## del equipo. Se recalcula en recompute(); lo consulta el gameplay.
var _behaviors := {}

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
## Curva CRECIENTE (E10.7, 2026-07-17, pedido del dueño: progresión "poco a
## poco" y difícil): cada nivel cuesta bastante más que el anterior — antes
## era lineal (40+nv*30) y a la oleada 5 ya ibas por nivel 5.
## Con los defaults: nv1→85 · nv2→141 · nv3→222 · nv5→446 · nv10→1313.
## Knobs en resources/balance.tres.
func xp_needed() -> float:
	var b := BalanceDef.bal()
	return b.xp_base + pow(level, b.xp_power) * b.xp_scale

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
	var b := BalanceDef.bal()
	base_stats[&"max_health"] = float(base_stats[&"max_health"]) + b.level_up_hp
	base_stats[&"max_mana"] = float(base_stats[&"max_mana"]) + b.level_up_mana
	base_stats[&"spell_damage"] = float(base_stats[&"spell_damage"]) + b.level_up_dmg
	base_stats[&"melee_damage"] = float(base_stats[&"melee_damage"]) + b.level_up_dmg
	base_stats[&"ranged_damage"] = float(base_stats[&"ranged_damage"]) + b.level_up_dmg
	recompute()
	health = get_stat(&"max_health")
	mana = get_stat(&"max_mana")

## Recalcula el cache combinando base + planos + porcentajes de cada ítem.
func recompute() -> void:
	var flat: Dictionary = base_stats.duplicate()
	var pct := {}
	_behaviors = {}
	for slot in equipment:
		var item: LootItem = equipment[slot]
		if item == null:
			continue
		# Requisito de nivel BLANDO (E10.1): un ítem por encima de tu nivel
		# rinde penalizado. Se recalcula al subir de nivel (recompute corre
		# en _apply_level_up), así la penalización se afloja sola.
		var req_scale := LootItem.level_req_scale(item.base.level_req, level)
		for k in item.stats:                 # planos (base del item + afijos FLAT)
			flat[k] = float(flat.get(k, 0.0)) + float(item.stats[k]) * req_scale
		for k in item.percent_mods:          # modificadores PERCENT
			pct[k] = float(pct.get(k, 0.0)) + float(item.percent_mods[k]) * req_scale
		for b in item.behaviors:             # pasivos de comportamiento (E6.2)
			_behaviors[b] = float(_behaviors.get(b, 0.0)) + float(item.behaviors[b])
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

## Magnitud sumada de un pasivo de comportamiento del equipo (E6.2). 0 = el
## jugador no tiene ningún ítem con ese pasivo. Ver Affix.behavior.
func behavior(id: StringName) -> float:
	return float(_behaviors.get(id, 0.0))

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
