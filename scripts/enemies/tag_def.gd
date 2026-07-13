## Definición data-driven de un tag de estado (E3, GDD §4). Un tag nuevo =
## un .tres en resources/tags/ — los efectos son genéricos y se combinan
## con estos números (tick, slow, amplificar, detonación), sin código por tag.
class_name TagDef
extends Resource

@export var id: StringName
@export var display_name: String = ""
## Color identitario: números de daño de los ticks y ráfagas de FX.
@export var color: Color = Color.WHITE
## Segundos que dura puesto (re-aplicar refresca).
@export var duration: float = 4.0
## Stacks máximos (re-aplicar suma hasta acá; los ticks escalan por stack).
@export var max_stacks: int = 1
## Cada cuántos segundos hace daño (0 = no hace ticks).
@export var tick_interval: float = 0.0
## Daño de cada tick como fracción del daño del golpe que aplicó el tag.
@export var tick_damage_ratio: float = 0.0
## Al DETONAR: daño extra = daño aplicador × este mult × stacks.
@export var detonate_mult: float = 1.5
## Ralentización mientras dura (1.0 = no ralentiza; 0.45 = 55% más lento).
@export var slow_factor: float = 1.0
## Marcado: el PRÓXIMO golpe recibido se multiplica por esto y consume el
## tag (1.0 = sin efecto).
@export var amplify_next_hit: float = 1.0
