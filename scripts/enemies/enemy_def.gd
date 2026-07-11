## Definición de una variante de enemigo, data-driven: crear un `.tres` en
## `res://resources/enemies/` la agrega a la ruleta de oleadas sin tocar
## código (el spawner las carga todas). Ver [[Crear un enemigo]] en el vault.
class_name EnemyDef
extends Resource

@export var id: StringName = &""
@export var hp: float = 30.0
@export var speed: float = 3.0
## Escala visual y de colisión (1.0 = slime normal).
@export var scale: float = 1.0
@export var dmg: float = 8.0
@export var xp: float = 10.0
## Color del cuerpo (esfera fallback + burst de muerte).
@export var color: Color = Color(0.2, 0.8, 0.2)
## Modelo KayKit (.glb). Vacío = esfera tintada.
@export_file("*.glb") var model: String = ""
## Animaciones del modelo (keys: idle/run/attack/hit/death/spawn).
@export var anims: Dictionary = {}
## true = tirador: mantiene rango y dispara proyectiles.
@export var ranged: bool = false

## Peso en la ruleta de spawn por oleada:
##   peso = weight_base + max(0, oleada - weight_from_wave) * weight_per_wave
## (weight_base 100 y per_wave 0 = presencia constante; base 0 y from_wave 3
## = recién aparece en la oleada 4 y crece de a per_wave).
@export var weight_base: int = 0
@export var weight_per_wave: int = 0
@export var weight_from_wave: int = 1

func weight(wave: int) -> int:
	return maxi(0, weight_base + maxi(0, wave - weight_from_wave) * weight_per_wave)
