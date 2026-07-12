## Habilidad data-driven del Laboratorio de Poderes: se construye desde un
## diccionario (JSON) en vez de una clase propia. La IA (o una persona)
## describe el poder con datos — comportamiento, plantilla visual, números —
## y esta clase lo interpreta reusando las escenas de magia existentes.
##
## El spec viene VALIDADO por AbilityLab (clamps y whitelists): acá se asume
## sano. Todos los spawns pasan por NetSpawn con el daño dentro del spawn,
## así el poder funciona igual en single-player, host y cliente de co-op.
class_name DataAbility
extends Ability

## Plantillas visuales permitidas: nombre → escena de magia que reutiliza.
const TEMPLATES := {
	&"fireball": "res://scenes/magic/Fireball.tscn",
	&"arrow": "res://scenes/magic/Arrow.tscn",
	&"arc_bolt": "res://scenes/magic/ArcBolt.tscn",
	&"axe": "res://scenes/magic/ThrowingAxe.tscn",
	&"nova": "res://scenes/magic/FrostNova.tscn",
	&"whirlwind": "res://scenes/magic/Whirlwind.tscn",
	&"slash": "res://scenes/magic/SwordSlash.tscn",
	&"meteor_storm": "res://scenes/magic/MeteorStorm.tscn",
	&"arrow_rain": "res://scenes/magic/ArrowRain.tscn",
	&"war_cry": "res://scenes/magic/WarCry.tscn",
}

## Elemento → stat de daño que rolea (skills estilo Tibia existentes).
const ELEMENT_STATS := {
	&"fire": &"fire_damage",
	&"lightning": &"lightning_damage",
	&"cold": &"cold_damage",
	&"melee": &"melee_damage",
	&"ranged": &"ranged_damage",
}

var behavior: StringName = &"projectile"
var template: StringName = &"fireball"
var damage_mult: float = 1.0
## Proyectiles/impactos por casteo y apertura del abanico (behavior projectile).
var count: int = 1
var spread_deg: float = 20.0
## Separación temporal entre impactos de una secuencia (behavior line).
var step_delay: float = 0.15
## Props extra aplicadas al nodo spawneado (ya filtradas por AbilityLab).
var extra_props: Dictionary = {}

func _init(spec: Dictionary = {}) -> void:
	if spec.is_empty():
		return
	id = StringName(spec.get("id", "lab_poder"))
	display_name = spec.get("name", "Poder del Lab")
	key_label = "Q"
	color = Color.from_string(spec.get("color", "#a06bff"), Color(0.63, 0.42, 1.0))
	cooldown = spec.get("cooldown", 2.0)
	mana_cost = spec.get("mana_cost", 10.0)
	element = StringName(spec.get("element", "fire"))
	behavior = StringName(spec.get("behavior", "projectile"))
	template = StringName(spec.get("template", "fireball"))
	damage_mult = spec.get("damage_mult", 1.0)
	count = int(spec.get("count", 1))
	spread_deg = spec.get("spread_deg", 20.0)
	step_delay = spec.get("step_delay", 0.15)
	extra_props = spec.get("props", {})

func _damage_stat() -> StringName:
	return ELEMENT_STATS.get(element, &"fire_damage")

func _scene() -> PackedScene:
	return load(TEMPLATES.get(template, TEMPLATES[&"fireball"])) as PackedScene

func _cast(player) -> Variant:
	match behavior:
		&"nova":
			return _cast_nova(player)
		&"line":
			return _cast_line(player)
		&"storm":
			return _cast_storm(player)
		_:
			return _cast_projectiles(player)

## Abanico de proyectiles desde la varita (count 1 = tiro simple).
func _cast_projectiles(player) -> bool:
	var scene := _scene()
	var base: Transform3D = player.wand.global_transform
	base.origin.y = PROJECTILE_HEIGHT
	for i in count:
		var xform := base
		if count > 1:
			var angle := deg_to_rad(spread_deg) * (float(i) / (count - 1) - 0.5)
			xform.basis = base.basis.rotated(Vector3.UP, angle)
		var result: Array = player.stats.roll_spell_damage(_damage_stat(), damage_mult)
		var props := {"transform": xform}
		props.merge(extra_props)
		NetSpawn.projectile(scene, props, player.get_parent(), result[0], player, result[1])
	return true

## AoE centrado en el personaje.
func _cast_nova(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(_damage_stat(), damage_mult)
	var props := {"position": player.global_position}
	props.merge(extra_props)
	NetSpawn.projectile(_scene(), props, player.get_parent(), result[0], player, result[1])
	return true

## Secuencia de impactos en línea recta hacia donde mira (estilo Temblor).
func _cast_line(player) -> bool:
	var dir: Vector3 = -player.visual.global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()
	_line_step(player, player.get_tree(), dir, 0)
	return true

func _line_step(player: Node, tree: SceneTree, dir: Vector3, i: int) -> void:
	if i >= count or not is_instance_valid(player) or not player.is_inside_tree() or player.get("_dead"):
		return
	var result: Array = player.stats.roll_spell_damage(_damage_stat(), damage_mult)
	var props := {"position": player.global_position + dir * (2.0 + i * 2.5)}
	props.merge(extra_props)
	NetSpawn.projectile(_scene(), props, player.get_parent(), result[0], player, result[1])
	tree.create_timer(step_delay).timeout.connect(_line_step.bind(player, tree, dir, i + 1))

## Lluvia sobre el punto frente al personaje (plantillas meteor_storm/arrow_rain).
func _cast_storm(player) -> bool:
	var result: Array = player.stats.roll_spell_damage(_damage_stat(), damage_mult)
	var props := {"position": player.get_front_point()}
	props.merge(extra_props)
	NetSpawn.projectile(_scene(), props, player.get_parent(), result[0], player, result[1])
	return true
