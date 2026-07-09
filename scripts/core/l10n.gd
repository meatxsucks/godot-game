## Carga el string table de localización (autoload "L10n"). El español es
## el idioma fuente: los strings del código/escenas YA están en español y
## no necesitan tabla propia — `en.json` mapea ese texto a su traducción.
extends Node

const EN_STRINGS_PATH := "res://localization/en.json"

func _ready() -> void:
	_load_translation("en", EN_STRINGS_PATH)

func _load_translation(locale: String, path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("[L10n] no se encontró %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[L10n] no se pudo abrir %s" % path)
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[L10n] %s no es un objeto JSON válido" % path)
		return
	var translation := Translation.new()
	translation.locale = locale
	for key in parsed:
		translation.add_message(key, String(parsed[key]))
	TranslationServer.add_translation(translation)
