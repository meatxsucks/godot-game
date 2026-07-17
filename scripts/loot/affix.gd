## Definición de un afijo (Diablo-style). Es un Resource data-driven:
## se pueden crear/editar en el inspector de Godot o por código (ver loot_database.gd).
class_name Affix
extends Resource

## Prefijo añade palabra antes del nombre base; sufijo añade "del/de X" al final.
enum Kind { PREFIX, SUFFIX }
## FLAT suma plano (+12 daño); PERCENT escala porcentual (+8% crítico).
enum Mode { FLAT, PERCENT }

@export var id: StringName
## Palabra que aporta al nombre del item, p.ej. "Flamígero" (prefijo) o "del Arcano" (sufijo).
@export var name_word: String = ""
@export var kind: Kind = Kind.PREFIX
## Clave de stat que modifica, p.ej. &"spell_damage".
@export var stat: StringName
## Etiqueta legible del stat, p.ej. "Daño mágico".
@export var stat_label: String = ""
@export var mode: Mode = Mode.FLAT
@export var min_value: float = 1.0
@export var max_value: float = 5.0
## Crecimiento del rango por nivel de item (escala con la dificultad de oleada).
@export var per_level: float = 0.0
## Peso para selección ponderada dentro del pool.
@export var weight: int = 100
## Rareza mínima (Rarity.Tier) en la que este afijo puede aparecer.
@export var min_tier: int = 0
## Tipos de item permitidos (&"staff", &"orb"...). Vacío = cualquiera.
@export var item_types: Array[StringName] = []
## Etiquetas temáticas (&"fire", &"defensive"...). Útil para filtrar pools.
@export var tags: Array[StringName] = []
## Comportamiento pasivo (E6.2): id que la capa de gameplay engancha, p.ej.
## &"heal_on_kill" o &"bleed_extra_stack". Vacío = afijo de stat normal. Si
## está seteado, el valor rolado NO va a un stat: es la magnitud del efecto
## (vida curada al matar, stacks extra de Sangrado, % de velocidad...), y el
## ítem lo acumula en `LootItem.behaviors` en vez de en `stats`.
@export var behavior: StringName = &""

## Rango efectivo [min, max] para un nivel de item dado.
func value_range(item_level: int) -> Vector2:
	var bonus := per_level * float(item_level)
	return Vector2(min_value + bonus, max_value + bonus)
