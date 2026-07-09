## Smoke test de SaveService: guardar y cargar reproduce clase, nivel, xp,
## skills, equipo (con afijos/legendario) e inventario (se corre headless).
extends Node

func _ready() -> void:
	Game.selected_class = &"warrior"
	var stats := PlayerStats.new()
	stats.add_xp(500.0)
	stats.skills.add_xp(&"melee", 50.0)

	# Rareza forzada para garantizar afijos/legendario y probar el round-trip completo.
	var weapon := Loot.generate_random_item(3, &"sword", Rarity.Tier.RARE)
	var displaced := stats.equip(weapon)
	assert(displaced.is_empty(), "arma entra en slot vacío")

	var inventory: Array[LootItem] = []
	inventory.append(Loot.generate_random_item(4, &"orb", Rarity.Tier.LEGENDARY))
	inventory.append(Loot.make_potion(&"potion_health"))

	var level_before := stats.level
	var xp_before := stats.xp
	var melee_level_before := stats.skills.level(&"melee")
	var health_before := stats.health
	var weapon_affix_count := weapon.affixes.size()
	var orb_legendary_id := inventory[0].legendary.id

	SaveService.save_game(stats, inventory)
	assert(SaveService.has_save(), "el archivo de save existe tras guardar")

	# Estado en blanco (simula reabrir el juego).
	Game.selected_class = &"mage"
	var loaded_stats := PlayerStats.new()
	var loaded_inventory: Array[LootItem] = []
	assert(SaveService.load_game(loaded_stats, loaded_inventory), "load_game devuelve true con save existente")

	assert(Game.selected_class == &"warrior", "la clase guardada se restaura")
	assert(loaded_stats.level == level_before, "el nivel se restaura")
	assert(absf(loaded_stats.xp - xp_before) < 0.01, "la xp se restaura")
	assert(loaded_stats.skills.level(&"melee") == melee_level_before, "el skill de melee se restaura")
	assert(absf(loaded_stats.health - health_before) < 0.01, "la vida se restaura")
	assert(loaded_inventory.size() == 2, "el inventario se restaura completo")

	var loaded_weapon: LootItem = loaded_stats.equipment.get(&"weapon", null)
	assert(loaded_weapon != null, "el arma equipada se restaura")
	assert(loaded_weapon.base.id == weapon.base.id, "el arma restaurada es la misma base")
	assert(loaded_weapon.affixes.size() == weapon_affix_count, "los afijos del arma se restauran")

	assert(loaded_inventory[0].legendary != null, "el legendario del inventario se restaura")
	assert(loaded_inventory[0].legendary.id == orb_legendary_id, "el legendario restaurado es el mismo")
	assert(loaded_inventory[1].base.id == &"potion_health", "la poción del inventario se restaura")

	SaveService.delete_save()
	assert(not SaveService.has_save(), "delete_save limpia el archivo")

	print("SAVE SMOKE OK")
	get_tree().quit(0)
