## Un afijo ya "rolleado" sobre un item concreto: referencia a la definición + valor final.
class_name AffixInstance
extends RefCounted

var source: Affix
var value: float = 0.0

func _init(p_source: Affix = null, p_value: float = 0.0) -> void:
	source = p_source
	value = p_value

func stat() -> StringName:
	return source.stat

func is_percent() -> bool:
	return source.mode == Affix.Mode.PERCENT

## Texto legible: "+12 Daño mágico" o "+8% Daño crítico".
func describe() -> String:
	var sign_str := "+" if value >= 0.0 else ""
	var unit := "%" if is_percent() else ""
	return "%s%s%s %s" % [sign_str, _fmt(value), unit, source.stat_label]

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return "%.1f" % v
