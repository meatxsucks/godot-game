## Autoload "AbilityLab": el Laboratorio de Poderes (habilidades data-driven).
## Guarda specs JSON en user://ability_lab/ (creadas con IA o a mano), las
## valida contra whitelists/clamps y las convierte en DataAbility jugables.
## `test_ability_id` es el poder a probar: player_controller lo equipa en el
## slot Q al construir el kit.
extends Node

const LAB_DIR := "user://ability_lab"
## Ejemplos que viajan en el repo (se listan junto a los del usuario).
const EXAMPLES_DIR := "res://resources/ability_lab"
const SETTINGS_PATH := "user://ability_lab.cfg"

## Rango permitido por campo numérico del spec (la IA propone, esto manda).
const NUM_LIMITS := {
	"cooldown": [0.3, 15.0],
	"mana_cost": [0.0, 60.0],
	"damage_mult": [0.1, 3.0],
	"count": [1, 8],
	"spread_deg": [0.0, 180.0],
	"step_delay": [0.05, 0.6],
}

## Props extra permitidas por plantilla (nada fuera de esta lista pasa).
const PROP_LIMITS := {
	"speed": [4.0, 30.0],
	"lifetime": [0.5, 6.0],
	"pierces": [],       # bool
	"chains_left": [0, 3],
	"max_radius": [1.5, 8.0],
	"expand_time": [0.2, 1.2],
	"slow_factor": [0.3, 1.0],
	"slow_time": [0.0, 4.0],
	"reach": [1.0, 3.5],
	"arc_degrees": [40.0, 360.0],
	"hit_radius": [0.6, 3.0],
	"meteor_count": [3, 14],
	"spawn_radius": [2.0, 8.0],
	"duration": [0.6, 3.0],
	"impact_radius": [1.0, 3.0],
	"meteor_size": [0.2, 1.0],
}

## id → spec validado, cargados al arrancar.
var specs: Dictionary = {}

## Poder a probar en la Arena (&"" = ninguno; se equipa en el slot Q).
var test_ability_id: StringName = &""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(LAB_DIR)
	reload()

func reload() -> void:
	specs.clear()
	_load_dir(EXAMPLES_DIR)
	_load_dir(LAB_DIR)

func _load_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var spec := load_spec_file(path.path_join(file_name))
			if not spec.is_empty():
				specs[StringName(spec["id"])] = spec
		file_name = dir.get_next()
	dir.list_dir_end()

func load_spec_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary):
		push_warning("[AbilityLab] JSON inválido: %s" % path)
		return {}
	var spec := validate(data)
	if spec.is_empty():
		push_warning("[AbilityLab] spec inválido: %s" % path)
	return spec

## Valida y sanea un spec crudo. Devuelve {} si no es usable.
func validate(raw: Dictionary) -> Dictionary:
	if not (raw.get("name") is String) or String(raw["name"]).strip_edges() == "":
		return {}
	var spec := {}
	# id determinístico desde el nombre si no viene (o viene raro).
	var raw_id := str(raw.get("id", "")).strip_edges()
	if raw_id == "" or not raw_id.begins_with("lab_"):
		raw_id = "lab_" + String(raw["name"]).to_lower().replace(" ", "_")
	spec["id"] = raw_id.substr(0, 48)
	spec["name"] = String(raw["name"]).substr(0, 32)
	spec["description"] = str(raw.get("description", "")).substr(0, 200)
	spec["color"] = _valid_color(str(raw.get("color", "#a06bff")))
	spec["element"] = _pick(raw.get("element"), DataAbility.ELEMENT_STATS.keys(), "fire")
	spec["behavior"] = _pick(raw.get("behavior"), ["projectile", "nova", "line", "storm"], "projectile")
	spec["template"] = _pick(raw.get("template"), DataAbility.TEMPLATES.keys(), "fireball")
	for key: String in NUM_LIMITS:
		spec[key] = _clamped(raw.get(key), NUM_LIMITS[key])
	spec["count"] = int(spec["count"])

	var props := {}
	var raw_props: Variant = raw.get("props", {})
	if raw_props is Dictionary:
		for key: String in raw_props:
			if not PROP_LIMITS.has(key):
				continue
			var limits: Array = PROP_LIMITS[key]
			if limits.is_empty():
				props[key] = bool(raw_props[key])
			else:
				props[key] = _clamped(raw_props[key], limits)
				if props[key] is float and limits[0] is int:
					props[key] = int(props[key])
	spec["props"] = props
	return spec

func _pick(value: Variant, allowed: Array, fallback: String) -> String:
	var text := str(value)
	for option in allowed:
		if text == str(option):
			return text
	return fallback

func _clamped(value: Variant, limits: Array) -> float:
	var number := float(value) if (value is float or value is int) else float(limits[0])
	return clampf(number, float(limits[0]), float(limits[1]))

func _valid_color(text: String) -> String:
	return text if Color.html_is_valid(text) else "#a06bff"

## Guarda un spec (ya validado) en el directorio del usuario.
func save_spec(spec: Dictionary) -> void:
	var file := FileAccess.open(LAB_DIR.path_join("%s.json" % spec["id"]), FileAccess.WRITE)
	file.store_string(JSON.stringify(spec, "\t"))
	file.close()
	specs[StringName(spec["id"])] = spec

func delete_spec(id: StringName) -> void:
	DirAccess.remove_absolute(LAB_DIR.path_join("%s.json" % id))
	specs.erase(id)
	if test_ability_id == id:
		test_ability_id = &""
	reload() # si era un ejemplo del repo no se borra: reaparece

## Instancia el poder si existe (lo usa Game.make_ability como fallback).
func make_ability(id: StringName) -> Ability:
	if specs.has(id):
		return DataAbility.new(specs[id])
	return null

## Equipa el poder en prueba en el slot Q del kit (índice 3 de la barra).
func apply_test_loadout(abilities: Array[Ability]) -> void:
	if test_ability_id == &"" or not specs.has(test_ability_id):
		return
	if abilities.size() > 3:
		abilities[3] = DataAbility.new(specs[test_ability_id])

# --- API key (solo local, nunca al repo) -----------------------------------

func api_key() -> String:
	var env := OS.get_environment("ANTHROPIC_API_KEY")
	if env != "":
		return env
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return ""
	return str(config.get_value("anthropic", "api_key", ""))

func save_api_key(key: String) -> void:
	var config := ConfigFile.new()
	config.set_value("anthropic", "api_key", key.strip_edges())
	config.save(SETTINGS_PATH)
