## Definición de una clase jugable, 100% data-driven: para agregar una clase
## nueva alcanza con crear un `.tres` en `res://resources/classes/` (Game las
## carga todas al arrancar) — código nuevo SOLO si su kit usa habilidades que
## aún no existen (ver Game.make_ability). Ver la guía "Cómo agregar
## contenido" en el vault de Obsidian.
class_name ClassDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Color identitario (borde de la tarjeta, título).
@export var color: Color = Color.WHITE
## Posición de la tarjeta en la pantalla de selección (menor = más a la izquierda).
@export var menu_order: int = 0
## Modelo KayKit (.glb). Vacío = cápsula placeholder.
@export_file("*.glb") var model: String = ""
## Animaciones del modelo (keys: idle/run/attack/death).
@export var anims: Dictionary = {}
## Overrides de stats base (keys StringName, ver PlayerStats.base_stats).
@export var stats: Dictionary = {}
## Kit de 3 poderes (Espacio, Q, R) por id — ver Game.make_ability.
@export var kit: Array[StringName] = []
