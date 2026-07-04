## Poder legendario (estilo legendary effects de Borderlands / uniques de Diablo).
## Cambia CÓMO funciona un hechizo o build, no solo da números.
##
## `effect_id` es un identificador que la capa de gameplay interpreta para
## enganchar el comportamiento real (ver LOOT_SYSTEM.md -> "Hooks de gameplay").
class_name LegendaryPower
extends Resource

@export var id: StringName
@export var title: String = ""
@export_multiline var text: String = ""
## Tipos de item donde puede aparecer este poder (vacío = cualquiera).
@export var item_types: Array[StringName] = []
## Hechizo afectado (informativo / para tooltips), p.ej. &"fireball".
@export var modifies_skill: StringName
## Identificador del efecto que el sistema de combate engancha.
@export var effect_id: StringName
