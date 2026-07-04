## Círculo de habilidad del HUD: se dibuja 100% por código (sin assets),
## acorde a la estética PS2. Dos modos:
## - Cooldown: círculo apagado que se rellena radialmente hasta estar listo.
## - Super (charge_ratio >= 0): muestra la carga de stamina y parpadea al llenarse.
class_name AbilitySlot
extends Control

var ability_color: Color = Color.WHITE
var key_label: String = ""
## Fracción de cooldown restante 0..1 (0 = listo). La setea el HUD cada frame.
var cooldown_ratio: float = 0.0
## Carga del super 0..1. -1 = este slot no es el super.
var charge_ratio: float = -1.0

var _pulse_time: float = 0.0

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 2.0

	draw_circle(center, radius, Color(0.08, 0.08, 0.12, 0.85))

	if charge_ratio >= 0.0:
		if charge_ratio >= 1.0:
			# Super listo: parpadeo para invitar a soltarlo.
			var pulse := 0.75 + 0.25 * sin(_pulse_time * 8.0)
			draw_circle(center, radius - 2.0, ability_color * Color(1, 1, 1, pulse))
		else:
			_draw_pie(center, radius - 2.0, charge_ratio, ability_color.darkened(0.25))
	elif cooldown_ratio <= 0.0:
		draw_circle(center, radius - 2.0, ability_color)
	else:
		draw_circle(center, radius - 2.0, ability_color.darkened(0.65))
		_draw_pie(center, radius - 2.0, 1.0 - cooldown_ratio, ability_color.darkened(0.3))

	draw_arc(center, radius, 0.0, TAU, 48, Color(0, 0, 0, 0.9), 2.0)

	# Tecla del poder, abajo del círculo.
	var font := ThemeDB.fallback_font
	var font_size := 10
	var text_size := font.get_string_size(key_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(center.x - text_size.x / 2.0, size.y - 4.0)
	draw_string_outline(font, pos, key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color.BLACK)
	draw_string(font, pos, key_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

## Sector circular ("pastel") desde las 12 en punto, en sentido horario.
func _draw_pie(center: Vector2, radius: float, ratio: float, color: Color) -> void:
	if ratio <= 0.0:
		return
	var points := PackedVector2Array([center])
	var steps := 40
	for i in steps + 1:
		var angle := -PI / 2.0 + TAU * minf(ratio, 1.0) * float(i) / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
