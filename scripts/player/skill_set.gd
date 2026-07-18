## Skills estilo Tibia: entrenan con el uso (cada casteo da XP a su elemento)
## y suben el daño de ese tipo. "Magia" es el nivel general: sube con todo.
class_name SkillSet
extends RefCounted

const SKILLS: Array[StringName] = [&"magic", &"fire", &"lightning", &"cold", &"melee", &"ranged"]

const NAMES := {
	&"magic": "Magia",
	&"fire": "Fuego",
	&"lightning": "Rayo",
	&"cold": "Hielo",
	&"melee": "Cuerpo a cuerpo",
	&"ranged": "Distancia",
}

var levels := {}
var xp := {}

func _init() -> void:
	for skill in SKILLS:
		levels[skill] = 1
		xp[skill] = 0.0

## XP necesaria para pasar del nivel dado al siguiente. Curva LENTA y
## creciente (E10.7, feedback del dueño 2026-07-17: con la lineal 10+nv*8
## subía un skill POR OLEADA — muy Tibia falso). Con los defaults: nv1→55 ·
## nv2→100 · nv3→164 · nv5→343 · nv10→1037: entrenar un elemento toma
## partidas. Knobs en resources/balance.tres.
func xp_needed(level_now: int) -> float:
	var b := BalanceDef.bal()
	return b.skill_xp_base + pow(level_now, b.skill_xp_power) * b.skill_xp_scale

## Suma XP. Devuelve true si el skill subió al menos un nivel.
func add_xp(skill: StringName, amount: float) -> bool:
	if not levels.has(skill):
		return false
	xp[skill] += amount
	var leveled := false
	while xp[skill] >= xp_needed(levels[skill]):
		xp[skill] -= xp_needed(levels[skill])
		levels[skill] += 1
		leveled = true
	return leveled

func level(skill: StringName) -> int:
	return int(levels.get(skill, 1))

## Progreso 0..1 hacia el siguiente nivel.
func progress(skill: StringName) -> float:
	return clampf(float(xp.get(skill, 0.0)) / xp_needed(level(skill)), 0.0, 1.0)

## Multiplicador de daño por skills para un stat elemental (&"fire_damage"...):
## +3% por nivel del elemento y +1% por nivel de Magia (sobre el nivel 1).
func damage_multiplier(element_stat: StringName) -> float:
	var element := StringName(String(element_stat).trim_suffix("_damage"))
	var bonus := (level(&"magic") - 1) * 0.01
	if levels.has(element):
		bonus += (level(element) - 1) * 0.03
	return 1.0 + bonus
