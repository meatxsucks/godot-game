## Smoke test de kits por clase: 5 slots por clase, elementos correctos y
## stats de clase aplicados (se corre headless).
extends Node

func _ready() -> void:
	for cls in [&"mage", &"warrior", &"ranger"]:
		Game.selected_class = cls
		var kit := Game.build_kit()
		assert(kit.size() == 5, "kit de %s tiene 5 slots" % cls)
		for ability in kit:
			assert(ability.display_name != "", "habilidad con nombre en %s" % cls)
			assert(ability.key_label != "", "habilidad con tecla en %s" % cls)

	# El kit del Guerrero entrena melee y sus stats de clase aplican.
	Game.selected_class = &"warrior"
	assert(Game.build_kit()[0].element == &"melee", "Tajo entrena melee")
	var warrior_stats := PlayerStats.new()
	assert(warrior_stats.get_stat(&"melee_damage") == 8.0, "Guerrero con daño melee base")
	assert(warrior_stats.get_stat(&"max_health") == 170.0, "Guerrero tanque")

	# El kit del Explorador entrena distancia.
	Game.selected_class = &"ranger"
	assert(Game.build_kit()[0].element == &"ranged", "Flecha entrena distancia")
	var ranger_stats := PlayerStats.new()
	assert(ranger_stats.get_stat(&"ranged_damage") == 8.0, "Explorador con daño distancia base")

	# Las skills nuevas existen y multiplican su daño.
	var skills := SkillSet.new()
	skills.add_xp(&"melee", 100.0)
	assert(skills.level(&"melee") > 1, "melee sube de nivel")
	assert(skills.damage_multiplier(&"melee_damage") > 1.0, "el skill melee potencia el daño")

	Game.selected_class = &"mage"
	print("KIT SMOKE OK")
	get_tree().quit(0)
