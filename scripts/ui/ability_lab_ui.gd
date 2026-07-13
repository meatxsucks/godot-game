## Laboratorio de Poderes: describe un poder en texto y la IA lo convierte
## en un spec jugable (DataAbility). Usa la API de Anthropic con el modelo
## barato (Haiku) y salida estructurada: la respuesta ES el JSON del spec,
## sin parseo frágil. Los poderes se guardan en user://ability_lab/ y se
## prueban en la Arena en el slot Q.
extends Control

const API_URL := "https://api.anthropic.com/v1/messages"
## Modelo barato a propósito: generar un spec chico no necesita más.
const MODEL := "claude-haiku-4-5"

## Poderes que ya existen en el juego: la IA debe proponer algo distinto.
const EXISTING_POWERS := "Bola de Fuego (proyectil), Descarga Arcana (proyectil), " \
	+ "Parpadeo Eléctrico (teleport+rayo), Muro de Llamas (línea de fuego), " \
	+ "Nova de Escarcha (nova de hielo), Tormenta de Meteoros (lluvia), " \
	+ "Corte Deslizante (tajo), Giro Movible (torbellino), Temblor Lineal (línea), " \
	+ "Grito de Guerra (nova que cura), Flecha, Flecha Perforante, Abanico de flechas, " \
	+ "Lluvia de Flechas, Hacha Arrojadiza, Embestida, Dash Arcano"

@onready var key_edit: LineEdit = %KeyEdit
@onready var prompt_edit: TextEdit = %PromptEdit
@onready var btn_generate: Button = %BtnGenerate
@onready var status: Label = %Status
@onready var power_list: VBoxContainer = %PowerList
@onready var btn_back: Button = %BtnBack

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 60.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	key_edit.text = AbilityLab.api_key()
	btn_generate.pressed.connect(_on_generate_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	_refresh_list()

func _refresh_list() -> void:
	for child in power_list.get_children():
		child.queue_free()
	if AbilityLab.specs.is_empty():
		var empty := Label.new()
		empty.text = tr("Aún no hay poderes creados.")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		power_list.add_child(empty)
		return
	for id: StringName in AbilityLab.specs:
		power_list.add_child(_make_row(AbilityLab.specs[id]))

func _make_row(spec: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)

	var title := Label.new()
	title.text = spec["name"]
	title.tooltip_text = "%s\n%s / %s / %s" % [spec.get("description", ""),
		spec["behavior"], spec["template"], spec["element"]]
	title.add_theme_color_override(&"font_color", Color.from_string(spec["color"], Color.WHITE))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var btn_try := Button.new()
	btn_try.text = tr("Probar")
	btn_try.pressed.connect(_on_try_pressed.bind(StringName(spec["id"])))
	row.add_child(btn_try)

	var btn_delete := Button.new()
	btn_delete.text = tr("Borrar")
	btn_delete.pressed.connect(_on_delete_pressed.bind(StringName(spec["id"])))
	row.add_child(btn_delete)
	return row

func _on_try_pressed(id: StringName) -> void:
	AbilityLab.test_ability_id = id
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")

func _on_delete_pressed(id: StringName) -> void:
	AbilityLab.delete_spec(id)
	_refresh_list()

func _on_back_pressed() -> void:
	AbilityLab.test_ability_id = &""
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")

# --- Generación con IA -------------------------------------------------------

func _on_generate_pressed() -> void:
	var key := key_edit.text.strip_edges()
	if key == "":
		status.text = tr("Falta la API key (pégala arriba).")
		return
	AbilityLab.save_api_key(key)
	var prompt := prompt_edit.text.strip_edges()
	if prompt == "":
		status.text = tr("Describe el poder primero.")
		return

	var body := JSON.stringify({
		"model": MODEL,
		"max_tokens": 1024,
		"system": _system_prompt(),
		"messages": [{"role": "user", "content": prompt}],
		"output_config": {"format": {"type": "json_schema", "schema": _spec_schema()}},
	})
	var headers := PackedStringArray([
		"content-type: application/json",
		"x-api-key: " + key,
		"anthropic-version: 2023-06-01",
	])
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		status.text = tr("Error de red (%d). ¿Sin internet?") % err
		return
	btn_generate.disabled = true
	status.text = tr("Generando…")

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	btn_generate.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS:
		status.text = tr("Error de red (%d). ¿Sin internet?") % result
		return
	var text := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text)
	if code != 200:
		var message: String = str(data.get("error", {}).get("message", text.substr(0, 120))) \
			if data is Dictionary else text.substr(0, 120)
		status.text = tr("La API respondió %d: %s") % [code, message]
		return
	# Con output_config el primer bloque de texto ES el JSON del spec.
	var spec_text := ""
	for block: Dictionary in data.get("content", []):
		if block.get("type") == "text":
			spec_text = block.get("text", "")
			break
	var raw: Variant = JSON.parse_string(spec_text)
	var spec: Dictionary = AbilityLab.validate(raw) if raw is Dictionary else {}
	if spec.is_empty():
		status.text = tr("La IA no devolvió un poder válido: %s") % spec_text.substr(0, 80)
		return
	AbilityLab.save_spec(spec)
	status.text = tr("Guardado: %s") % spec["name"]
	prompt_edit.text = ""
	_refresh_list()

func _system_prompt() -> String:
	return """Diseñas poderes para un ARPG estilo PS2 (Diablo + Borderlands). \
Convierte la descripción del jugador en UN spec JSON de poder, creativo pero balanceado \
para una arena por oleadas. Debe sentirse DISTINTO a los poderes existentes: %s.

Campos:
- behavior: "projectile" (abanico de count proyectiles con spread_deg), "nova" (AoE en el \
personaje), "line" (count impactos en línea al frente, cada step_delay seg), "storm" (lluvia \
sobre el punto apuntado).
- template: visual que reutiliza. Proyectiles: fireball, arrow, arc_bolt, axe. AoE/línea: \
nova, whirlwind, war_cry, slash. Storm: meteor_storm, arrow_rain.
- element decide qué skill entrena: fire, lightning, cold, melee, ranged.
- applies/detonates: tags de estado del combate (burn=quemado con ticks, \
frozen=congela/ralentiza, marked=el próximo golpe critea, bleed=sangrado \
apilable). Aplicar y detonar es la base de los combos: detonar consume el \
tag por daño extra. Usa 0-2 tags coherentes con el elemento.
- props (opcional, solo las que apliquen): proyectiles → speed, lifetime, pierces, \
chains_left; AoE → max_radius, expand_time, slow_factor (<1 ralentiza), slow_time; \
tajos → reach, arc_degrees, hit_radius; storm → meteor_count, spawn_radius, duration, \
impact_radius, meteor_size.
- Balance: más daño/área ⇒ más cooldown y maná. damage_mult 1.0 es un golpe normal.
- name en español, corto y evocador. id: minúsculas con guiones bajos, prefijo lab_. \
color: hex que pegue con el elemento.""" % EXISTING_POWERS

func _spec_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"id": {"type": "string"},
			"name": {"type": "string"},
			"description": {"type": "string"},
			"color": {"type": "string"},
			"element": {"type": "string", "enum": ["fire", "lightning", "cold", "melee", "ranged"]},
			"behavior": {"type": "string", "enum": ["projectile", "nova", "line", "storm"]},
			"template": {"type": "string", "enum": ["fireball", "arrow", "arc_bolt", "axe",
				"nova", "whirlwind", "slash", "meteor_storm", "arrow_rain", "war_cry"]},
			"cooldown": {"type": "number"},
			"mana_cost": {"type": "number"},
			"damage_mult": {"type": "number"},
			"count": {"type": "integer"},
			"spread_deg": {"type": "number"},
			"step_delay": {"type": "number"},
			"applies": {"type": "array",
				"items": {"type": "string", "enum": ["burn", "frozen", "marked", "bleed"]}},
			"detonates": {"type": "array",
				"items": {"type": "string", "enum": ["burn", "frozen", "marked", "bleed"]}},
			"props": {
				"type": "object",
				"properties": {
					"speed": {"type": "number"}, "lifetime": {"type": "number"},
					"pierces": {"type": "boolean"}, "chains_left": {"type": "integer"},
					"max_radius": {"type": "number"}, "expand_time": {"type": "number"},
					"slow_factor": {"type": "number"}, "slow_time": {"type": "number"},
					"reach": {"type": "number"}, "arc_degrees": {"type": "number"},
					"hit_radius": {"type": "number"}, "meteor_count": {"type": "integer"},
					"spawn_radius": {"type": "number"}, "duration": {"type": "number"},
					"impact_radius": {"type": "number"}, "meteor_size": {"type": "number"},
				},
				"required": [],
				"additionalProperties": false,
			},
		},
		"required": ["id", "name", "description", "color", "element", "behavior",
			"template", "cooldown", "mana_cost", "damage_mult", "count",
			"spread_deg", "step_delay", "applies", "detonates", "props"],
		"additionalProperties": false,
	}
