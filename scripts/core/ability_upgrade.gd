## Nodo del árbol de talentos (E10.4): mejora UNA habilidad de CLASE por su
## `ability_id`. Data-driven (patrón E0.7): un nodo nuevo = un `.tres` en
## `resources/talents/`, sin tocar código. El árbol es POR CLASE (decisión
## 2026-07-17): los poderes de arma NO pasan por acá (suben por tier, E10.2).
class_name AbilityUpgrade
extends Resource

@export var id: StringName
## Habilidad de clase que mejora (&"frost_nova", &"dash"...).
@export var ability_id: StringName
## Nombre visible del nodo (español fuente, se traduce con tr()).
@export var name: String = ""
## Rangos comprables (cada rango acumula el efecto).
@export var max_ranks: int = 3
## Puntos de talento por rango.
@export var cost: int = 1
## Puntos ya GASTADOS en el árbol necesarios para desbloquear este nodo
## (gating por filas estilo Diablo: los nodos fuertes piden inversión).
@export var requires_spent: int = 0
## +daño por rango (0.15 = +15% al damage_scale de la habilidad).
@export var damage_per_rank: float = 0.0
## −cooldown por rango (0.12 = −12%).
@export var cooldown_per_rank: float = 0.0
## −coste de maná por rango (0.15 = −15%).
@export var mana_per_rank: float = 0.0

## Descripción legible del efecto por rango (para la UI del árbol).
func describe() -> String:
	var parts: Array[String] = []
	if damage_per_rank > 0.0:
		parts.append("+%d%% %s" % [roundi(damage_per_rank * 100.0), tr("daño")])
	if cooldown_per_rank > 0.0:
		parts.append("−%d%% %s" % [roundi(cooldown_per_rank * 100.0), tr("enfriamiento")])
	if mana_per_rank > 0.0:
		parts.append("−%d%% %s" % [roundi(mana_per_rank * 100.0), tr("maná")])
	return " · ".join(parts)
