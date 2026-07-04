## Item base (la plantilla antes de tirar rareza/afijos). Data-driven Resource.
class_name ItemBase
extends Resource

@export var id: StringName
## Nombre visible del tipo, p.ej. "Bastón", "Orbe", "Anillo".
@export var name: String = ""
## Tipo lógico: &"staff", &"orb", &"wand", &"ring", &"armor".
@export var type: StringName
## Slot de equipo: &"weapon", &"offhand", &"ring", &"armor".
@export var slot: StringName
## Stats base implícitos del item (stat -> valor).
@export var base_stats: Dictionary = {}
## Etiquetas de afijos permitidas (vacío = todas). Filtra el pool.
@export var allowed_tags: Array[StringName] = []
@export var icon: Texture2D
