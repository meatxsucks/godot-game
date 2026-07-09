## Base de datos de contenido de loot (autoload "LootDB").
##
## Data-driven: todo el contenido vive como Resources `.tres` bajo
## `res://resources/loot/` (items/, potions/, affixes/, legendaries/).
## El generador (`loot_generator.gd`) no asume de dónde vienen los arrays.
extends Node

const ITEMS_DIR := "res://resources/loot/items/"
const POTIONS_DIR := "res://resources/loot/potions/"
const AFFIXES_DIR := "res://resources/loot/affixes/"
const LEGENDARIES_DIR := "res://resources/loot/legendaries/"

var item_bases: Array[ItemBase] = []
var affixes: Array[Affix] = []
var legendaries: Array[LegendaryPower] = []
## Consumibles (kind -> ItemBase). Fuera de item_bases para que NO entren
## al pool del generador de equipo.
var potion_bases := {}

func _ready() -> void:
	for res in _list_tres(ITEMS_DIR):
		item_bases.append(res)
	for res in _list_tres(AFFIXES_DIR):
		affixes.append(res)
	for res in _list_tres(LEGENDARIES_DIR):
		legendaries.append(res)
	for res: ItemBase in _list_tres(POTIONS_DIR):
		potion_bases[res.id] = res

## Devuelve los Resources cargados de todos los `.tres` de un directorio.
func _list_tres(dir_path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("[LootDB] no se pudo abrir %s" % dir_path)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			if res:
				result.append(res)
			else:
				push_error("[LootDB] no se pudo cargar %s%s" % [dir_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

# --- Consultas para el generador -----------------------------------------

func bases_of_type(type: StringName) -> Array[ItemBase]:
	if type == &"":
		return item_bases
	return item_bases.filter(func(b): return b.type == type)

## Afijos válidos para un tipo de item y una rareza (filtra por min_tier, tipo y tags).
func affixes_for(type: StringName, tier: int, allowed_tags: Array[StringName]) -> Array[Affix]:
	return affixes.filter(func(a: Affix) -> bool:
		if a.min_tier > tier:
			return false
		if not a.item_types.is_empty() and not a.item_types.has(type):
			return false
		if not allowed_tags.is_empty() and not a.tags.any(func(t): return allowed_tags.has(t)):
			return false
		return true
	)

func legendaries_for(type: StringName) -> Array[LegendaryPower]:
	return legendaries.filter(func(l: LegendaryPower) -> bool:
		return l.item_types.is_empty() or l.item_types.has(type)
	)
