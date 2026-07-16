## Estado global de la partida (autoload "Game"): clase elegida (rol) y
## definiciones de clases. Las clases son data-driven: se cargan de
## res://resources/classes/*.tres (ClassDef) — agregar una clase nueva NO
## requiere tocar este archivo, salvo que su kit use habilidades nuevas
## (make_ability). Ver [[Crear una clase]] en el vault de Obsidian.
extends Node

const CLASSES_DIR := "res://resources/classes/"

## id → ClassDef, cargadas al arrancar.
var classes: Dictionary = {}

## Clase elegida en ClassSelect. Default Mago (permite correr la Arena directo).
var selected_class: StringName = &"mage"

## Semilla del escenario procedural. En co-op la reparte el HOST al comenzar
## (misma semilla = mismo mapa en todas las máquinas, estilo Valheim/NMS).
## 0 = aleatoria (single-player o escena directa).
var world_seed: int = 0

func _ready() -> void:
	var dir := DirAccess.open(CLASSES_DIR)
	if dir == null:
		push_error("[Game] no se pudo abrir %s" % CLASSES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var def: ClassDef = load(CLASSES_DIR + file_name)
			if def and def.id != &"":
				classes[def.id] = def
			else:
				push_error("[Game] ClassDef inválida: %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

## IDs de clase en el orden de la pantalla de selección (menu_order).
func class_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(classes.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return classes[a].menu_order < classes[b].menu_order)
	return ids

func class_def(id: StringName) -> ClassDef:
	return classes.get(id, classes.get(&"mage"))

## Overrides de stats base de una clase (los aplica PlayerStats). En co-op
## cada player instancia la suya; &"" = la clase seleccionada localmente.
func class_stats(id: StringName = &"") -> Dictionary:
	var def := class_def(id if id != &"" else selected_class)
	return def.stats if def else {}

## Overrides de stats base de la clase seleccionada (los aplica PlayerStats).
func selected_stats() -> Dictionary:
	return class_stats()

## Kit base de la clase (3 slots: Espacio, Q, R). &"" = la seleccionada local.
func build_class_kit(cls: StringName = &"") -> Array[Ability]:
	var def := class_def(cls if cls != &"" else selected_class)
	var kit: Array[Ability] = []
	if def == null:
		return kit
	for ability_id in def.kit:
		kit.append(make_ability(ability_id))
	return kit

## Instancia una habilidad por su ID. Al crear una habilidad nueva hay que
## registrarla acá (es el único punto de código que toca el contenido).
func make_ability(id: StringName) -> Ability:
	match id:
		&"fireball": return FireballAbility.new()
		&"arc_bolt": return ArcBoltAbility.new()
		&"chain_bolt": return ChainBoltAbility.new()
		&"multi_bolt": return MultiBoltAbility.new()
		&"sword_slash": return SlashAbility.new()
		&"spin_slash": return SpinSlashAbility.new()
		&"mace_smash": return MaceSmashAbility.new()
		&"shockwave": return ShockwaveAbility.new()
		&"arrow": return ArrowAbility.new()
		&"multi_shot": return MultiShotAbility.new()
		&"dash": return DashAbility.new()
		&"charge": return ChargeAbility.new()
		&"war_cry": return WarCryAbility.new()
		&"whirlwind": return WhirlwindAbility.new()
		&"piercing_arrow": return PiercingArrowAbility.new()
		&"arrow_rain": return ArrowRainAbility.new()
		&"acid_spit": return AcidSpitAbility.new()
		&"alchemist_flask": return AlchemistFlaskAbility.new()
		&"shared_elixir": return SharedElixirAbility.new()
		&"frost_nova": return FrostNovaAbility.new()
		&"meteor_storm": return MeteorStormAbility.new()
		&"frost_shard": return FrostShardAbility.new()
		&"blizzard": return BlizzardAbility.new()
		_:
			# Poderes del Laboratorio (data-driven, prefijo lab_).
			var lab := AbilityLab.make_ability(id)
			return lab if lab else UnarmedAbility.new()
