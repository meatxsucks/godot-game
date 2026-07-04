## Item generado (instancia concreta lista para mostrar/equipar).
class_name LootItem
extends RefCounted

var base: ItemBase
var rarity: int = Rarity.Tier.COMMON
var item_level: int = 1
var display_name: String = ""
var affixes: Array[AffixInstance] = []
var legendary: LegendaryPower = null
## Stats agregados finales (base + afijos planos). Los % se guardan aparte.
var stats: Dictionary = {}
## Modificadores porcentuales acumulados (stat -> % total).
var percent_mods: Dictionary = {}

func rarity_color() -> Color:
	return Rarity.color(rarity)

## Combina base_stats + afijos en `stats` (planos) y `percent_mods` (%).
func recompute_stats() -> void:
	stats = base.base_stats.duplicate(true)
	percent_mods = {}
	for inst in affixes:
		var key := inst.stat()
		if inst.is_percent():
			percent_mods[key] = float(percent_mods.get(key, 0.0)) + inst.value
		else:
			stats[key] = float(stats.get(key, 0.0)) + inst.value

## Valor final de un stat aplicando planos y % (para el motor de combate).
func effective(stat: StringName) -> float:
	var flat := float(stats.get(stat, 0.0))
	var pct := float(percent_mods.get(stat, 0.0))
	return flat * (1.0 + pct / 100.0)

## Representación con BBCode coloreado para RichTextLabel.
func to_bbcode() -> String:
	var hex := rarity_color().to_html(false)
	var s := "[color=#%s][b]%s[/b][/color]  [i](nv %d · %s)[/i]\n" % [
		hex, display_name, item_level, Rarity.display_name(rarity)
	]
	for k in stats:
		s += "    [color=#cfcfcf]%s: %s[/color]\n" % [k, _fmt(stats[k])]
	for inst in affixes:
		s += "    [color=#8fd0ff]%s[/color]\n" % inst.describe()
	if legendary:
		s += "  [color=#%s]★ %s[/color]\n" % [hex, legendary.title]
		s += "      [i][color=#ffd9a8]%s[/color][/i]\n" % legendary.text
	return s

func to_text() -> String:
	var bb := to_bbcode()
	var re := RegEx.create_from_string("\\[/?[^\\]]+\\]")
	return re.sub(bb, "", true)

func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return "%.1f" % v
