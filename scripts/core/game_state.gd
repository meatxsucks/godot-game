## Estado global de la partida (autoload "Game"): clase elegida (rol) y
## definiciones de clases. El kit de 5 poderes actual es el del Mago; los
## kits propios de Guerrero/Explorador llegarán después.
extends Node

const CLASSES := {
	&"mage": {
		"name": "Mago",
		"desc": "Cañón de cristal: hechizos potentes y mucho maná, pero poca vida. Kit de 5 poderes propio.",
		"color": Color(0.45, 0.6, 1.0),
		"model": "res://assets/kaykit/Mage.glb",
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "Spellcast_Shoot", "death": "Death_A"},
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
		"desc": "Tanque cuerpo a cuerpo: tajos, embestida y un Grito de Guerra que golpea y lo CURA. Aguanta de todo.",
		"color": Color(1.0, 0.5, 0.3),
		"model": "res://assets/kaykit/Knight.glb",
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "1H_Melee_Attack_Slice_Horizontal", "death": "Death_A"},
		"stats": {
			&"max_health": 170.0,
			&"max_mana": 60.0,
			&"mana_regen": 5.0,
			&"spell_damage": 8.0,
			&"melee_damage": 8.0,
			&"res_fire": 10.0,
			&"res_cold": 10.0,
			&"res_lightning": 10.0,
		},
	},
	&"ranger": {
		"name": "Explorador",
		"desc": "Arquero ágil: flechas rápidas, abanicos, perforantes y lluvia mortal. Crítico y velocidad.",
		"color": Color(0.4, 0.9, 0.5),
		"model": "res://assets/kaykit/Rogue.glb",
		"anims": {"idle": "Idle", "run": "Running_A", "attack": "1H_Ranged_Shoot", "death": "Death_A"},
		"stats": {
			&"max_health": 110.0,
			&"max_mana": 90.0,
			&"mana_regen": 7.0,
			&"spell_damage": 9.0,
			&"ranged_damage": 8.0,
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

## Kit de poderes de la clase seleccionada (5 slots: LMB/RMB/SPC/Q/R-super).
func build_kit() -> Array[Ability]:
	match selected_class:
		&"warrior":
			return [
				SlashAbility.new(),
				AxeThrowAbility.new(),
				ChargeAbility.new(),
				WarCryAbility.new(),
				WhirlwindAbility.new(),
			]
		&"ranger":
			return [
				ArrowAbility.new(),
				MultiShotAbility.new(),
				DashAbility.new(),
				PiercingArrowAbility.new(),
				ArrowRainAbility.new(),
			]
		_:
			return [
				FireballAbility.new(),
				ArcBoltAbility.new(),
				DashAbility.new(),
				FrostNovaAbility.new(),
				MeteorStormAbility.new(),
			]
