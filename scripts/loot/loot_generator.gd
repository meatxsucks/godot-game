## Generador procedural de botín (autoload "Loot").
## Toma bases de LootDB, determina rareza, tira dados para afijos y ensambla un LootItem.
extends Node

## `type` opcional restringe la base (ej. &"staff" para cofres temáticos).
## `forced_rarity` >= 0 fuerza el tier (ej. legendario garantizado del boss).
func generate_random_item(level: int = 1, type: StringName = &"", forced_rarity: int = -1) -> LootItem:
	var item = LootItem.new()
	item.item_level = level

	# 1. Tirar rareza (basado en pesos, o forzada)
	item.rarity = forced_rarity if forced_rarity >= 0 else _roll_rarity()

	# 2. Elegir base aleatoria
	var bases = LootDB.bases_of_type(type)
	if bases.is_empty():
		return item
	item.base = bases.pick_random()
	item.display_name = item.base.name
	
	# 3. Determinar cantidad de afijos según rareza
	var affix_count_range = Rarity.AFFIX_RANGE.get(item.rarity, Vector2i(0, 0))
	var affix_count = randi_range(affix_count_range.x, affix_count_range.y)
	
	# 4. Seleccionar afijos válidos
	var available_affixes = LootDB.affixes_for(item.base.type, item.rarity, item.base.allowed_tags).duplicate()
	var quality_mult = Rarity.QUALITY_MULT.get(item.rarity, 1.0)
	
	var chosen_affixes: Array[Affix] = []
	var has_prefix = false
	var has_suffix = false
	
	for i in range(affix_count):
		if available_affixes.is_empty():
			break
		
		# Elección ponderada (weight)
		var total_weight = 0
		for a in available_affixes:
			total_weight += a.weight
		
		var roll = randi() % total_weight
		var current = 0
		var chosen: Affix = null
		
		for a in available_affixes:
			current += a.weight
			if roll < current:
				chosen = a
				break
				
		if chosen:
			chosen_affixes.append(chosen)
			available_affixes.erase(chosen) # No repetir el mismo afijo exacto
			
			# Lógica simple de nombre (toma el primero que encuentra)
			if chosen.kind == Affix.Kind.PREFIX and not has_prefix:
				item.display_name = chosen.name_word + " " + item.display_name
				has_prefix = true
			elif chosen.kind == Affix.Kind.SUFFIX and not has_suffix:
				item.display_name = item.display_name + " " + chosen.name_word
				has_suffix = true
				
			# Generar valor (AffixInstance)
			var base_range = chosen.value_range(level)
			# Randomizamos entre min y max, luego aplicamos quality_mult hacia el máximo
			var random_val = randf_range(base_range.x, base_range.y)
			# Un hack sencillo para mejorar stats con la rareza: subir el piso
			var better_val = lerpf(random_val, base_range.y, minf(1.0, (quality_mult - 1.0) * 0.5))
			
			item.affixes.append(AffixInstance.new(chosen, better_val))

	# 5. Legendarios
	if item.rarity == Rarity.Tier.LEGENDARY:
		var legs = LootDB.legendaries_for(item.base.type)
		if not legs.is_empty():
			item.legendary = legs.pick_random()
	
	item.recompute_stats()
	return item

## Crea una poción (consumible de un solo uso, sin rareza ni afijos).
## kind: &"potion_health" | &"potion_mana".
func make_potion(kind: StringName) -> LootItem:
	var item := LootItem.new()
	item.base = LootDB.potion_bases.get(kind, null)
	if item.base == null:
		push_warning("[Loot] poción desconocida: %s" % kind)
		return null
	item.display_name = item.base.name
	item.recompute_stats()
	return item

func _roll_rarity() -> int:
	var total_weight = 0
	for tier in Rarity.DROP_WEIGHT:
		total_weight += Rarity.DROP_WEIGHT[tier]
		
	var roll = randi() % total_weight
	var current = 0
	
	# Iterar ordenado por tier para consistencia
	for tier in [Rarity.Tier.COMMON, Rarity.Tier.UNCOMMON, Rarity.Tier.RARE, Rarity.Tier.EPIC, Rarity.Tier.LEGENDARY]:
		current += Rarity.DROP_WEIGHT[tier]
		if roll < current:
			return tier
			
	return Rarity.Tier.COMMON
