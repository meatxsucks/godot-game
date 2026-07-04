## Estado global de la partida (autoload "Game"): clase elegida (rol) y
## definiciones de clases. El kit de 5 poderes actual es el del Mago; los
## kits propios de Guerrero/Explorador llegarán después.
extends Node

const CLASSES := {
	&"mage": {
		"name": "Mago",
		"desc": "Cañón de cristal: hechizos potentes y mucho maná, pero poca vida. Kit de 5 poderes propio.",
		"color": Color(0.45, 0.6, 1.0),
		"stats": {
			&"max_health": 80.0,
			&"max_mana": 130.0,
			&"mana_regen": 10.0,
			&"spell_damage": 12.0,
			&"crit_chance": 6.0,
		},
	},
	&"warrior": {
		"name": "Guerrero",
		"desc": "Tanque: aguanta de todo con vida y resistencias altas. Su kit propio llega pronto (usa el del Mago).",
		"color": Color(1.0, 0.5, 0.3),
		"stats": {
			&"max_health": 170.0,
			&"max_mana": 60.0,
			&"mana_regen": 5.0,
			&"spell_damage": 8.0,
			&"res_fire": 10.0,
			&"res_cold": 10.0,
			&"res_lightning": 10.0,
		},
	},
	&"ranger": {
		"name": "Explorador",
		"desc": "Ágil y letal: crítico y velocidad de movimiento. Su kit propio llega pronto (usa el del Mago).",
		"color": Color(0.4, 0.9, 0.5),
		"stats": {
			&"max_health": 110.0,
			&"max_mana": 90.0,
			&"mana_regen": 7.0,
			&"spell_damage": 9.0,
			&"crit_chance": 12.0,
			&"crit_damage": 70.0,
			&"move_speed": 12.0,
		},
	},
}

## Clase elegida en ClassSelect. Default Mago (permite correr la Arena directo).
var selected_class: StringName = &"mage"

func class_def(id: StringName) -> Dictionary:
	return CLASSES.get(id, CLASSES[&"mage"])

## Overrides de stats base de la clase seleccionada (los aplica PlayerStats).
func selected_stats() -> Dictionary:
	return class_def(selected_class).get("stats", {})
