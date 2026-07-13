## Tags de estado de UN enemigo (E3, GDD §4): Quemado, Congelado, Marcado,
## Sangrado (Corroído/Aturdido entran después — decisión 2026-07-13).
## Vive dentro del enemigo y corre SOLO en el host (quien resuelve daño);
## las réplicas solo reciben los FX por RPC del enemigo.
##
## Combo cruzado de party: detonar un tag que aplicó OTRO jugador multiplica
## la detonación (CROSS_BONUS) — coordinarse paga (decisión del dueño).
class_name StatusTags
extends RefCounted

const TAGS_DIR := "res://resources/tags/"
## Bonus del combo cruzado (detonador ≠ aplicador).
const CROSS_BONUS := 1.25

static var _defs: Dictionary = {}

## TagDef por id (carga el directorio una sola vez, patrón data-driven E0.7).
static func def(id: StringName) -> TagDef:
	if _defs.is_empty():
		_load_defs()
	return _defs.get(id)

static func _load_defs() -> void:
	var dir := DirAccess.open(TAGS_DIR)
	if dir == null:
		push_error("[Tags] no se pudo abrir %s" % TAGS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var tag_def: TagDef = load(TAGS_DIR + file_name)
			if tag_def and tag_def.id != &"":
				_defs[tag_def.id] = tag_def
		file_name = dir.get_next()
	dir.list_dir_end()

## Enemigo dueño: debe exponer _status_tick(def, amount) y apply_slow().
var _enemy: Node3D
## id -> {stacks, time_left, tick_timer, base_damage, applier_peer}
var _active: Dictionary = {}

func _init(enemy: Node3D) -> void:
	_enemy = enemy

## Pone (o apila) un tag. `base_damage` = daño del golpe que lo aplicó (los
## ticks y la detonación escalan de ahí). Devuelve false si el tag no existe.
func apply(id: StringName, base_damage: float, applier_peer: int = 0) -> bool:
	var d := def(id)
	if d == null:
		return false
	if _active.has(id):
		var entry: Dictionary = _active[id]
		entry.stacks = mini(entry.stacks + 1, d.max_stacks)
		entry.time_left = d.duration
		entry.base_damage = maxf(entry.base_damage, base_damage)
		entry.applier_peer = applier_peer
	else:
		_active[id] = {
			"stacks": 1, "time_left": d.duration, "tick_timer": d.tick_interval,
			"base_damage": base_damage, "applier_peer": applier_peer,
		}
	if d.slow_factor < 1.0 and _enemy.has_method("apply_slow"):
		_enemy.apply_slow(d.slow_factor, d.duration)
	return true

## Avanza duraciones y ticks. Lo llama el enemigo en su physics (host).
func update(delta: float) -> void:
	for id: StringName in _active.keys():
		var d := def(id)
		var entry: Dictionary = _active[id]
		entry.time_left -= delta
		if d.tick_interval > 0.0:
			entry.tick_timer -= delta
			if entry.tick_timer <= 0.0:
				entry.tick_timer += d.tick_interval
				_enemy._status_tick(d, entry.base_damage * d.tick_damage_ratio * entry.stacks)
		if entry.time_left <= 0.0:
			_active.erase(id)

## Marcado y similares: multiplicador para el próximo golpe (consume el tag).
func consume_amplifier() -> float:
	for id: StringName in _active.keys():
		var d := def(id)
		if d.amplify_next_hit > 1.0:
			_active.erase(id)
			return d.amplify_next_hit
	return 1.0

## Detona los tags pedidos que estén activos: los consume y devuelve el daño
## extra total. Combo cruzado (detonador ≠ aplicador) multiplica el total.
func detonate(ids: Array, detonator_peer: int = 0) -> float:
	var total := 0.0
	var cross := false
	for id: StringName in ids:
		if not _active.has(id):
			continue
		var d := def(id)
		var entry: Dictionary = _active[id]
		total += entry.base_damage * d.detonate_mult * entry.stacks
		if entry.applier_peer != 0 and detonator_peer != 0 \
				and entry.applier_peer != detonator_peer:
			cross = true
		_active.erase(id)
	return total * (CROSS_BONUS if cross else 1.0)

func has(id: StringName) -> bool:
	return _active.has(id)

func active_ids() -> Array:
	return _active.keys()
