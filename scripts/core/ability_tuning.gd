## Tuning de UNA habilidad (data-driven, pedido del dueño 2026-07-17): los
## números de balance de cada poder (daño/cooldown/maná) viven en un `.tres`
## en `resources/abilities/` y se ajustan en el Inspector sin tocar código.
## `Game.make_ability` los aplica al instanciar; el id debe coincidir con el
## id RUNTIME del Ability (ej. el R del Guerrero es `titan_slam`).
## La CONDUCTA del poder (qué hace al castear) sigue en su clase .gd.
class_name AbilityTuning
extends Resource

@export var id: StringName
## Multiplicador de daño base (lo que el _cast pasa a roll_spell_damage —
## en poderes multi-golpe es el multiplicador POR golpe).
@export var damage_mult: float = 1.0
@export var cooldown: float = 1.0
@export var mana_cost: float = 0.0
