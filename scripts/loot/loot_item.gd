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

## ¿Es un consumible (poción)? Se usa con click en el inventario, no se equipa.
func is_consumable() -> bool:
	return base != null and base.slot == &"consumable"

## Color para la UI y el brillo del drop: las pociones tienen color propio,
## el resto usa el color de rareza.
func ui_color() -> Color:
	if base:
		if base.type == &"potion_health":
			return Color(0.95, 0.25, 0.25)
		if base.type == &"potion_mana":
			return Color(0.25, 0.5, 1.0)
	return rarity_color()

## Combina base_stats (escalados por rareza) + afijos en `stats` (planos)
## y `percent_mods` (%).
func recompute_stats() -> void:
	stats = {}
	var mult := Rarity.stat_mult(rarity)
	for k in base.base_stats:
		stats[k] = float(base.base_stats[k]) * mult
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

# --- Guardado (SaveService) ------------------------------------------------

## Serializa el ítem a un Dictionary JSON-friendly (solo tipos primitivos:
## String/int/float/Array/Dictionary). Referencia la base/afijos/legendario
## por id — se resuelven contra `LootDB` al cargar, no se duplica su data.
func to_save_dict() -> Dictionary:
	var affix_list := []
	for inst: AffixInstance in affixes:
		affix_list.append({"id": String(inst.source.id), "value": inst.value})
	return {
		"base_id": String(base.id) if base else "",
		"rarity": rarity,
		"item_level": item_level,
		"display_name": display_name,
		"affixes": affix_list,
		"legendary_id": String(legendary.id) if legendary else "",
	}

## Reconstruye un LootItem desde `to_save_dict()`, resolviendo base/afijos/
## legendario contra el contenido actual de `LootDB`. Devuelve null si la
## base ya no existe (ej. se borró del pool entre versiones del juego).
static func from_save_dict(d: Dictionary) -> LootItem:
	var base_id := StringName(d.get("base_id", ""))
	var base_res: ItemBase = null
	for b: ItemBase in LootDB.item_bases:
		if b.id == base_id:
			base_res = b
			break
	if base_res == null:
		for pb: ItemBase in LootDB.potion_bases.values():
			if pb.id == base_id:
				base_res = pb
				break
	if base_res == null:
		push_warning("[LootItem] base desconocida al cargar save: %s" % base_id)
		return null

	var item := LootItem.new()
	item.base = base_res
	item.rarity = int(d.get("rarity", Rarity.Tier.COMMON))
	item.item_level = int(d.get("item_level", 1))
	item.display_name = String(d.get("display_name", base_res.name))

	for affix_data: Dictionary in d.get("affixes", []):
		var affix_id := StringName(affix_data.get("id", ""))
		for a: Affix in LootDB.affixes:
			if a.id == affix_id:
				item.affixes.append(AffixInstance.new(a, float(affix_data.get("value", 0.0))))
				break

	var legendary_id := StringName(d.get("legendary_id", ""))
	if legendary_id != &"":
		for l: LegendaryPower in LootDB.legendaries:
			if l.id == legendary_id:
				item.legendary = l
				break

	item.recompute_stats()
	return item
