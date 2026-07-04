## Smoke test de equip/unequip con armas a dos manos (se corre headless).
extends Node

func _ready() -> void:
	var stats := PlayerStats.new()
	var staff2h := _make_item(&"staff_war")
	var orb := _make_item(&"orb_quartz")
	var staff := _make_item(&"staff_oak")

	# Equipar orbe y luego arma 2H: el orbe sale desplazado.
	assert(stats.equip(orb).is_empty(), "orbe en slot vacío no desplaza nada")
	var displaced := stats.equip(staff2h)
	assert(displaced.size() == 1 and displaced[0] == orb, "2H desplaza al offhand")
	assert(stats.equipment.get(&"offhand") == null, "offhand vacío con 2H")

	# Equipar offhand con 2H puesta: el arma sale.
	displaced = stats.equip(orb)
	assert(displaced.size() == 1 and displaced[0] == staff2h, "offhand desplaza al arma 2H")

	# Arma 1H convive con el offhand.
	displaced = stats.equip(staff)
	assert(displaced.is_empty(), "1H no desplaza al offhand")
	assert(stats.equipment.get(&"offhand") == orb, "orbe sigue equipado")

	# Unequip.
	assert(stats.unequip(&"weapon") == staff, "unequip devuelve el ítem")
	assert(stats.unequip(&"weapon") == null, "unequip de slot vacío devuelve null")

	print("SMOKE OK")
	get_tree().quit(0)

func _make_item(base_id: StringName) -> LootItem:
	var item := LootItem.new()
	for b in LootDB.item_bases:
		if b.id == base_id:
			item.base = b
	assert(item.base != null, "base %s existe en LootDB" % base_id)
	item.display_name = item.base.name
	item.recompute_stats()
	return item
