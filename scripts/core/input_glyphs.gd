## Texto legible ("glifo") de un InputEvent para mostrar en el menú de
## Controles. Sin iconos gráficos todavía (no hay asset pack de glifos en
## el repo) — texto estilo Xbox para mando, consistente con la tabla de
## controles del GDD.
class_name InputGlyphs
extends RefCounted

const JOY_BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "Click stick izq.", JOY_BUTTON_RIGHT_STICK: "Click stick der.",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad arriba", JOY_BUTTON_DPAD_DOWN: "D-pad abajo",
	JOY_BUTTON_DPAD_LEFT: "D-pad izq.", JOY_BUTTON_DPAD_RIGHT: "D-pad der.",
}
const JOY_AXIS_NAMES := {
	JOY_AXIS_LEFT_X: "Stick izq.", JOY_AXIS_LEFT_Y: "Stick izq.",
	JOY_AXIS_RIGHT_X: "Stick der.", JOY_AXIS_RIGHT_Y: "Stick der.",
	JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}

static func text(event: InputEvent) -> String:
	if event is InputEventKey:
		# Nombre de tecla provisto por el motor (no pasa por el string table
		# del proyecto; sigue el locale del sistema/engine).
		return (event as InputEventKey).as_text_physical_keycode()
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT: return TranslationServer.translate("Click izq.")
			MOUSE_BUTTON_RIGHT: return TranslationServer.translate("Click der.")
			MOUSE_BUTTON_MIDDLE: return TranslationServer.translate("Click medio")
			_: return TranslationServer.translate("Mouse %d") % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		var idx := (event as InputEventJoypadButton).button_index
		if JOY_BUTTON_NAMES.has(idx):
			return TranslationServer.translate(JOY_BUTTON_NAMES[idx])
		return TranslationServer.translate("Botón %d") % idx
	if event is InputEventJoypadMotion:
		var axis := (event as InputEventJoypadMotion).axis
		if JOY_AXIS_NAMES.has(axis):
			return TranslationServer.translate(JOY_AXIS_NAMES[axis])
		return TranslationServer.translate("Eje %d") % axis
	return event.as_text()
