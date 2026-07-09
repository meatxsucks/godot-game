## Smoke test de localización (E0.5): el string table se carga, tr() traduce
## de verdad en inglés y el locale persiste vía SaveService (se corre headless).
extends Node

func _ready() -> void:
	# L10n (autoload) ya cargó localization/en.json a esta altura.
	assert(TranslationServer.get_loaded_locales().has("en"), "la traducción 'en' está registrada")

	TranslationServer.set_locale("es")
	assert(tr("Continuar") == "Continuar", "en español, tr() devuelve el texto fuente tal cual")

	TranslationServer.set_locale("en")
	assert(tr("Continuar") == "Resume", "en inglés, tr() traduce un string simple")
	assert(tr("Oleada %d") % 3 == "Wave 3", "tr() traduce una plantilla con %d antes de interpolar")
	assert(TranslationServer.translate("Vida") == "Health", "TranslationServer.translate() (usado en funciones static) también traduce")
	assert(tr("clave-inexistente-xyz") == "clave-inexistente-xyz", "sin match, tr() cae al string fuente (no rompe)")

	# End-to-end con contenido real: nombre de ítem (COMMON = sin afijos,
	# nombre exacto), rareza y nombre de habilidad.
	var item := Loot.generate_random_item(2, &"staff", Rarity.Tier.COMMON)
	assert(item.display_name == "Oaken Staff", "el nombre del ítem se traduce al generarlo (COMMON, sin afijos)")
	assert(Rarity.display_name(Rarity.Tier.COMMON) == "Common", "el nombre de rareza se traduce")
	assert(FireballAbility.new().display_name == "Bola de Fuego", "display_name de habilidad queda en español (dato fuente, se traduce recién al mostrarse)")

	TranslationServer.set_locale("es") # no ensuciar el resto de la corrida

	# Persistencia del locale vía SaveService.
	SaveService.save_settings({"locale": "en", "master_volume": 1.0, "resolution": Vector2i(854, 480), "fullscreen": false})
	var loaded := SaveService.load_settings()
	assert(loaded["locale"] == "en", "el locale guardado se relee igual")
	SaveService.apply_settings(loaded)
	assert(TranslationServer.get_locale() == "en", "apply_settings aplica el locale al TranslationServer")

	# Limpieza: dejar el archivo de settings como estaba antes del test.
	SaveService.apply_settings(SaveService.DEFAULT_SETTINGS)
	if SaveService.has_settings():
		DirAccess.remove_absolute(SaveService.SETTINGS_PATH)

	print("L10N SMOKE OK")
	get_tree().quit(0)
