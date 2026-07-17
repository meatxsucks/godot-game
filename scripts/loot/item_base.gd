## Item base (la plantilla antes de tirar rareza/afijos). Data-driven Resource.
class_name ItemBase
extends Resource

@export var id: StringName
## Nombre visible del tipo, p.ej. "Bastón", "Orbe", "Anillo".
@export var name: String = ""
## Tipo lógico: &"staff", &"orb", &"wand", &"ring", &"armor", &"helmet",
## &"shield", &"boots", &"cape", &"gloves".
@export var type: StringName
## Slot de equipo: &"head", &"armor", &"weapon", &"offhand", &"cape",
## &"hands", &"ring", &"boots".
@export var slot: StringName
## Arma a dos manos: al equiparla desplaza el offhand (y viceversa).
@export var two_handed: bool = false
## Tier del ítem (E10.1): escala los base_stats (familias de armas por nivel,
## E10.2). 1 = tier inicial.
@export var tier: int = 1
## Nivel de personaje recomendado (E10.1). Requisito BLANDO (decisión
## 2026-07-17): se puede equipar por debajo, pero los stats del ítem rinden
## con penalización por nivel faltante (ver LootItem.level_req_scale).
@export var level_req: int = 1
## Stats base implícitos del item (stat -> valor).
@export var base_stats: Dictionary = {}
## Poder asociado al click izquierdo (LMB) si el ítem es un arma.
@export var lmb_power: StringName = &""
## Poder asociado al click derecho (RMB) si el ítem es un arma.
@export var rmb_power: StringName = &""
## Etiquetas de afijos permitidas (vacío = todas). Filtra el pool.
@export var allowed_tags: Array[StringName] = []
@export var icon: Texture2D
