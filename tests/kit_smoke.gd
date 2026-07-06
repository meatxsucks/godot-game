## Smoke test de kits por clase: 5 slots por clase, elementos correctos y
## stats de clase aplicados (se corre headless).
extends Node

func _ready() -> void:
	for cls in [&"mage", &"warrior", &"ranger"]:
		Game.selected_class = cls
		var kit := Game.build_class_kit()
		assert(kit.size() == 3, "kit de clase de %s tiene 3 slots" % cls)
		for ability in kit:
			assert(ability.display_name != "", "habilidad con nombre en %s" % cls)
			assert(ability.key_label != "", "habilidad con tecla en %s" % cls)
		# El slot 2 es el SUPER en TODOS los kits de clase
		assert(kit[2].is_super, "el slot 2 de %s es el super" % cls)

	# El tajo de espada (arma) entrena melee y los stats de clase aplican al Guerrero.
	Game.selected_class = &"warrior"
	assert(Game.make_ability(&"sword_slash").element == &"melee", "Tajo entrena melee")
	var warrior_stats := PlayerStats.new()
	assert(warrior_stats.get_stat(&"melee_damage") == 8.0, "Guerrero con daño melee base")
	assert(warrior_stats.get_stat(&"max_health") == 170.0, "Guerrero tanque")

	# La flecha de arco entrena distancia.
	Game.selected_class = &"ranger"
	assert(Game.make_ability(&"arrow").element == &"ranged", "Flecha entrena distancia")
	var ranger_stats := PlayerStats.new()
	assert(ranger_stats.get_stat(&"ranged_damage") == 8.0, "Explorador con daño distancia base")

	# Las skills nuevas existen y multiplican su daño.
	var skills := SkillSet.new()
	skills.add_xp(&"melee", 100.0)
	assert(skills.level(&"melee") > 1, "melee sube de nivel")
	assert(skills.damage_multiplier(&"melee_damage") > 1.0, "el skill melee potencia el daño")

	# Experiencia: subir de nivel aumenta stats base.
	Game.selected_class = &"mage"
	var xp_stats := PlayerStats.new()
	var health_before := xp_stats.get_stat(&"max_health")
	var level_ups := xp_stats.add_xp(1000.0)
	assert(level_ups >= 2, "1000 XP sube varios niveles")
	assert(xp_stats.get_stat(&"max_health") > health_before, "el nivel sube la vida")
	assert(xp_stats.level == 1 + level_ups, "nivel consistente")

	# El Boss se instancia sin errores (hereda del slime; corona en _ready).
	var boss = load("res://scenes/enemies/Boss.tscn").instantiate()
	add_child(boss)
	assert(boss.max_health == 600.0, "boss con 600 HP")
	boss.queue_free()

	print("KIT SMOKE OK")
	get_tree().quit(0)
