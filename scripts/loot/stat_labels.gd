## Etiquetas legibles de stats base (compartidas entre inventario, selección
## de clase y tooltips de ítems — antes duplicadas en 3 lugares distintos).
class_name StatLabels
extends RefCounted

const LABELS := {
	&"max_health": "Vida",
	&"max_mana": "Maná",
	&"mana_regen": "Maná por kill",
	&"spell_damage": "Daño mágico",
	&"fire_damage": "Daño de fuego",
	&"cold_damage": "Daño de hielo",
	&"lightning_damage": "Daño de rayo",
	&"melee_damage": "Daño melee",
	&"ranged_damage": "Daño distancia",
	&"crit_chance": "Crítico %",
	&"crit_damage": "Daño crít. %",
	&"cast_speed": "Vel. lanz. %",
	&"cooldown_reduction": "Reducción de enfriamiento %",
	&"move_speed": "Vel. mov. %",
	&"area": "Área %",
	&"res_fire": "Res. fuego %",
	&"res_cold": "Res. hielo %",
	&"res_lightning": "Res. rayo %",
}

## Etiqueta traducida de un stat (o el nombre crudo de la clave si no está
## mapeado, para no romper con stats nuevos que todavía no se documentaron).
static func label(stat: StringName) -> String:
	return TranslationServer.translate(LABELS.get(stat, String(stat)))
