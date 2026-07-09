## Sistema de guardado (autoload "SaveService"). Serializa el estado del
## personaje a JSON en `user://`. `gold` y `world` quedan como placeholders
## en el archivo hasta que existan esos sistemas (TODO E5, E4) — no se
## pierden datos futuros, el formato ya tiene el campo reservado.
extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

## Settings de la app (volumen/resolución/pantalla completa): NO son parte
## del personaje, viven en su propio archivo y se aplican al boot.
const SETTINGS_PATH := "user://settings.json"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(854, 480),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const DEFAULT_SETTINGS := {
	"master_volume": 1.0, # lineal 0..1
	"resolution": Vector2i(854, 480),
	"fullscreen": false,
}

func _ready() -> void:
	apply_settings(load_settings())

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

## Guarda clase, nivel, XP, skills, equipo e inventario del personaje activo.
func save_game(stats: PlayerStats, inventory: Array[LootItem]) -> void:
	var data := {
		"version": SAVE_VERSION,
		"class": String(Game.selected_class),
		"level": stats.level,
		"xp": stats.xp,
		"health": stats.health,
		"mana": stats.mana,
		# `base_stats` no es función pura de `level`: acumula los bonos de cada
		# level-up (`_apply_level_up` en player_stats.gd) más los overrides de
		# clase. Se guarda tal cual para no duplicar esa fórmula acá.
		"base_stats": _str_keys(stats.base_stats),
		"skills": {
			"levels": _str_keys(stats.skills.levels),
			"xp": _str_keys(stats.skills.xp),
		},
		"equipment": _save_equipment(stats.equipment),
		"inventory": inventory.map(func(item: LootItem) -> Dictionary: return item.to_save_dict()),
		"gold": 0,   # TODO E5: economía aún no existe.
		"world": {}, # TODO E4: progreso de mundo/zonas aún no existe.
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveService] no se pudo abrir %s para escribir" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Carga el save sobre `stats`/`inventory` ya existentes (los reemplaza).
## false si no hay save o está corrupto — en ese caso no toca nada.
func load_game(stats: PlayerStats, inventory: Array[LootItem]) -> bool:
	var data := _read_save()
	if data.is_empty():
		return false

	Game.selected_class = StringName(data.get("class", "mage"))
	stats.level = int(data.get("level", 1))
	stats.xp = float(data.get("xp", 0.0))

	var base_stats_data: Dictionary = data.get("base_stats", {})
	if not base_stats_data.is_empty():
		var restored_base := {}
		for k in base_stats_data:
			restored_base[StringName(k)] = float(base_stats_data[k])
		stats.base_stats = restored_base

	var skills_data: Dictionary = data.get("skills", {})
	var levels_data: Dictionary = skills_data.get("levels", {})
	var xp_data: Dictionary = skills_data.get("xp", {})
	for skill in stats.skills.levels.keys():
		var key := String(skill)
		if levels_data.has(key):
			stats.skills.levels[skill] = int(levels_data[key])
		if xp_data.has(key):
			stats.skills.xp[skill] = float(xp_data[key])

	stats.equipment.clear()
	var equipment_data: Dictionary = data.get("equipment", {})
	for slot in equipment_data.keys():
		var item := LootItem.from_save_dict(equipment_data[slot])
		if item:
			stats.equipment[StringName(slot)] = item

	inventory.clear()
	for item_dict: Dictionary in data.get("inventory", []):
		var item := LootItem.from_save_dict(item_dict)
		if item:
			inventory.append(item)

	stats.recompute()
	stats.health = minf(float(data.get("health", stats.get_stat(&"max_health"))), stats.get_stat(&"max_health"))
	stats.mana = minf(float(data.get("mana", stats.get_stat(&"max_mana"))), stats.get_stat(&"max_mana"))
	return true

func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _str_keys(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = d[k]
	return out

func _save_equipment(equipment: Dictionary) -> Dictionary:
	var out := {}
	for slot in equipment:
		var item: LootItem = equipment[slot]
		if item:
			out[String(slot)] = item.to_save_dict()
	return out

# --- Settings (volumen / resolución / pantalla completa) --------------------

func has_settings() -> bool:
	return FileAccess.file_exists(SETTINGS_PATH)

## Devuelve los settings guardados, o `DEFAULT_SETTINGS` si no hay archivo
## o está corrupto. Siempre trae las 3 claves (nunca faltan por save viejo).
func load_settings() -> Dictionary:
	var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
	if not has_settings():
		return settings
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return settings
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return settings
	var data: Dictionary = parsed
	settings["master_volume"] = clampf(float(data.get("master_volume", settings["master_volume"])), 0.0, 1.0)
	settings["fullscreen"] = bool(data.get("fullscreen", settings["fullscreen"]))
	var res: Array = data.get("resolution", [])
	if res.size() == 2:
		settings["resolution"] = Vector2i(int(res[0]), int(res[1]))
	return settings

func save_settings(settings: Dictionary) -> void:
	var resolution: Vector2i = settings.get("resolution", DEFAULT_SETTINGS["resolution"])
	var data := {
		"master_volume": float(settings.get("master_volume", DEFAULT_SETTINGS["master_volume"])),
		"resolution": [resolution.x, resolution.y],
		"fullscreen": bool(settings.get("fullscreen", DEFAULT_SETTINGS["fullscreen"])),
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveService] no se pudo abrir %s para escribir" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Aplica settings al motor (bus Master + ventana). Se llama al boot
## (con lo último guardado) y en vivo cada vez que cambian en el menú.
func apply_settings(settings: Dictionary) -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var volume: float = clampf(settings.get("master_volume", 1.0), 0.0, 1.0)
		AudioServer.set_bus_mute(master_idx, volume <= 0.0001)
		if volume > 0.0001:
			AudioServer.set_bus_volume_db(master_idx, linear_to_db(volume))

	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(settings.get("resolution", DEFAULT_SETTINGS["resolution"]))
