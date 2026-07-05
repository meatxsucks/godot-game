## Base de datos de contenido de loot (autoload "LootDB").
##
## Por defecto se puebla por código para que el demo funcione out-of-the-box.
## En producción podés cargar Resources (.tres) desde res://data/ y reemplazar
## estos arrays — el generador no asume de dónde vienen.
extends Node

var item_bases: Array[ItemBase] = []
var affixes: Array[Affix] = []
var legendaries: Array[LegendaryPower] = []
## Consumibles (kind -> ItemBase). Fuera de item_bases para que NO entren
## al pool del generador de equipo.
var potion_bases := {}

func _ready() -> void:
	_build_item_bases()
	_build_affixes()
	_build_legendaries()
	_build_potions()

# --- Constructores helper -------------------------------------------------

func _base(id: StringName, name: String, type: StringName, slot: StringName, base_stats: Dictionary, two_handed := false) -> ItemBase:
	var b := ItemBase.new()
	b.id = id
	b.name = name
	b.type = type
	b.slot = slot
	b.base_stats = base_stats
	b.two_handed = two_handed
	return b

func _affix(id: StringName, word: String, kind: int, stat: StringName, label: String,
		mode: int, vmin: float, vmax: float, per_level: float, weight: int,
		min_tier: int, types: Array[StringName] = [], tags: Array[StringName] = []) -> Affix:
	var a := Affix.new()
	a.id = id
	a.name_word = word
	a.kind = kind
	a.stat = stat
	a.stat_label = label
	a.mode = mode
	a.min_value = vmin
	a.max_value = vmax
	a.per_level = per_level
	a.weight = weight
	a.min_tier = min_tier
	a.item_types = types
	a.tags = tags
	return a

func _legendary(id: StringName, title: String, text: String, types: Array[StringName],
		skill: StringName, effect_id: StringName) -> LegendaryPower:
	var l := LegendaryPower.new()
	l.id = id
	l.title = title
	l.text = text
	l.item_types = types
	l.modifies_skill = skill
	l.effect_id = effect_id
	return l

# --- Contenido ------------------------------------------------------------

func _build_item_bases() -> void:
	# Pool de 6 ítems: TODOS visibles en el personaje ("menos es mejor").
	# La rareza multiplica los stats (Rarity.STAT_MULT).
	item_bases = [
		_base(&"staff_oak", "Bastón de roble", &"staff", &"weapon", {&"spell_damage": 10.0}),
		_base(&"wand_bone", "Varita de hueso", &"wand", &"weapon", {&"spell_damage": 6.0, &"cast_speed": 10.0, &"crit_chance": 3.0}),
		# El arma pesada: potencia el ataque de CUALQUIER clase (2 manos)
		# y convierte el click en CORTE de espada.
		_base(&"sword_war", "Espadón de guerra", &"sword", &"weapon", {&"spell_damage": 16.0, &"melee_damage": 10.0, &"ranged_damage": 10.0}, true),
		_base(&"shield_wood", "Escudo de madera", &"shield", &"offhand", {&"max_health": 30.0, &"res_fire": 10.0, &"res_cold": 10.0, &"res_lightning": 10.0}),
		_base(&"orb_quartz", "Orbe de cuarzo", &"orb", &"offhand", {&"max_mana": 40.0, &"mana_regen": 4.0}),
		_base(&"robe_linen", "Túnica de lino", &"armor", &"armor", {&"max_health": 35.0, &"move_speed": 4.0}),
	]

func _build_potions() -> void:
	potion_bases = {
		&"potion_health": _base(&"potion_health", "Poción de vida", &"potion_health", &"consumable", {&"restore_health": 40.0}),
		&"potion_mana": _base(&"potion_mana", "Poción de maná", &"potion_mana", &"consumable", {&"restore_mana": 50.0}),
	}

func _build_affixes() -> void:
	var K := Affix.Kind
	var M := Affix.Mode
	var T := Rarity.Tier
	# Tipos de arma (para afijos de daño ofensivo).
	var weapons: Array[StringName] = [&"staff", &"wand", &"sword"]
	var melee_types: Array[StringName] = [&"sword", &"shield"]
	affixes = [
		# Ofensivos
		_affix(&"flat_spell_dmg", "Arcano", K.PREFIX, &"spell_damage", "Daño mágico", M.FLAT, 3, 9, 0.8, 100, T.COMMON, weapons, [&"offense"]),
		_affix(&"pct_spell_dmg", "Devastador", K.PREFIX, &"spell_damage", "Daño mágico", M.PERCENT, 5, 12, 0.4, 70, T.RARE, weapons, [&"offense"]),
		_affix(&"fire_dmg", "Flamígero", K.PREFIX, &"fire_damage", "Daño de fuego", M.FLAT, 4, 12, 1.0, 60, T.UNCOMMON, weapons, [&"offense", &"fire"]),
		_affix(&"cold_dmg", "Glacial", K.PREFIX, &"cold_damage", "Daño de hielo", M.FLAT, 4, 12, 1.0, 60, T.UNCOMMON, weapons, [&"offense", &"cold"]),
		# Daño por clase: Guerrero (melee) y Explorador (distancia).
		_affix(&"melee_dmg", "Feroz", K.PREFIX, &"melee_damage", "Daño melee", M.FLAT, 4, 12, 1.0, 60, T.UNCOMMON, melee_types, [&"offense"]),
		_affix(&"ranged_dmg", "Certero", K.PREFIX, &"ranged_damage", "Daño distancia", M.FLAT, 4, 12, 1.0, 60, T.UNCOMMON, weapons, [&"offense"]),
		_affix(&"crit_chance", "Letal", K.PREFIX, &"crit_chance", "Prob. crítico", M.PERCENT, 2, 6, 0.1, 55, T.UNCOMMON, [], [&"offense"]),
		_affix(&"crit_dmg", "Brutal", K.PREFIX, &"crit_damage", "Daño crítico", M.PERCENT, 8, 20, 0.6, 45, T.RARE, [], [&"offense"]),
		_affix(&"cast_speed", "Veloz", K.PREFIX, &"cast_speed", "Vel. de lanzamiento", M.PERCENT, 3, 8, 0.1, 50, T.UNCOMMON, [], [&"utility"]),
		_affix(&"cdr", "Fluido", K.PREFIX, &"cooldown_reduction", "Reducción de enfriamiento", M.PERCENT, 3, 7, 0.1, 40, T.RARE, [], [&"utility"]),
		# Recursos / defensa (sufijos)
		_affix(&"max_mana", "del Mago", K.SUFFIX, &"max_mana", "Maná máximo", M.FLAT, 8, 25, 2.0, 90, T.COMMON, [], [&"resource"]),
		_affix(&"mana_regen", "del Flujo", K.SUFFIX, &"mana_regen", "Maná por kill", M.FLAT, 1, 4, 0.2, 60, T.UNCOMMON, [], [&"resource"]),
		_affix(&"max_health", "del Titán", K.SUFFIX, &"max_health", "Vida máxima", M.FLAT, 15, 45, 3.0, 90, T.COMMON, [], [&"defense"]),
		_affix(&"res_fire", "del Hogar", K.SUFFIX, &"res_fire", "Resist. al fuego", M.PERCENT, 5, 15, 0.3, 55, T.UNCOMMON, [], [&"defense", &"fire"]),
		_affix(&"res_cold", "del Invierno", K.SUFFIX, &"res_cold", "Resist. al hielo", M.PERCENT, 5, 15, 0.3, 55, T.UNCOMMON, [], [&"defense", &"cold"]),
		_affix(&"res_light", "de la Tormenta", K.SUFFIX, &"res_lightning", "Resist. al rayo", M.PERCENT, 5, 15, 0.3, 55, T.UNCOMMON, [], [&"defense", &"lightning"]),
		_affix(&"area", "del Coloso", K.SUFFIX, &"area", "Área de efecto", M.PERCENT, 4, 10, 0.2, 35, T.EPIC, [], [&"utility"]),
		# Solo túnicas: velocidad de movimiento (FLAT = puntos de % directos).
		_affix(&"move_speed", "del Viento", K.SUFFIX, &"move_speed", "Vel. de movimiento", M.FLAT, 3, 8, 0.2, 50, T.UNCOMMON, [&"armor"], [&"utility"]),
	]

func _build_legendaries() -> void:
	var weapons: Array[StringName] = [&"staff", &"wand"]
	legendaries = [
		_legendary(&"leg_chain_fire", "Pira en Cadena",
			"Tus Bolas de Fuego rebotan a 2 enemigos cercanos al impactar, con -40% de daño por rebote.",
			weapons, &"fireball", &"fireball_chain"),
		_legendary(&"leg_frost_nova", "Corazón de Escarcha",
			"Al recibir un golpe, liberas una Nova de Hielo que daña y ralentiza a los enemigos cercanos (cd 6s).",
			[&"orb", &"armor"], &"", &"on_hit_frost_nova"),
		_legendary(&"leg_mana_overflow", "Desborde Arcano",
			"El maná es tu escudo: la mitad del daño recibido se absorbe con maná (1:1) mientras tengas.",
			[&"orb"], &"", &"mana_to_shield"),
		_legendary(&"leg_crit_cascade", "Cascada Crítica",
			"Cada golpe crítico reduce 0.5s el enfriamiento de todos tus hechizos.",
			weapons, &"", &"crit_cdr"),
	]

# --- Consultas para el generador -----------------------------------------

func bases_of_type(type: StringName) -> Array[ItemBase]:
	if type == &"":
		return item_bases
	return item_bases.filter(func(b): return b.type == type)

## Afijos válidos para un tipo de item y una rareza (filtra por min_tier, tipo y tags).
func affixes_for(type: StringName, tier: int, allowed_tags: Array[StringName]) -> Array[Affix]:
	return affixes.filter(func(a: Affix) -> bool:
		if a.min_tier > tier:
			return false
		if not a.item_types.is_empty() and not a.item_types.has(type):
			return false
		if not allowed_tags.is_empty() and not a.tags.any(func(t): return allowed_tags.has(t)):
			return false
		return true
	)

func legendaries_for(type: StringName) -> Array[LegendaryPower]:
	return legendaries.filter(func(l: LegendaryPower) -> bool:
		return l.item_types.is_empty() or l.item_types.has(type)
	)
