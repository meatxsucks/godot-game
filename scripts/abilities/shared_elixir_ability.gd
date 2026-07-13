## Alquimista R — SUPER: Elixir Compartido. Una ONDA de ácido enorme desde
## el alquimista que daña a los enemigos y DETONA todos sus tags de estado;
## además toda la party recupera vida/maná y durante unos segundos los
## golpes de TODOS detonan cualquier tag. Burst real en solo, habilitador
## de combos en party.
class_name SharedElixirAbility
extends Ability

const FLASK_SCENE := preload("res://scenes/magic/Flask.tscn")

## % de vida y maná que recupera cada aliado, ventana del prime y tamaño
## de la onda.
const HEAL_PCT := 0.35
const MANA_PCT := 0.5
const PRIME_SECONDS := 5.0
const WAVE_RADIUS := 6.0

func _init() -> void:
	id = &"shared_elixir"
	display_name = "Elixir Compartido"
	key_label = "R"
	color = Color(0.55, 0.9, 0.25)
	cooldown = 1.0
	mana_cost = 0.0
	element = &"magic"
	is_super = true
	# La onda revienta TODO lo aplicado (por ti o por tus aliados).
	detonates = [&"burn", &"frozen", &"marked", &"bleed"]

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.4)
	# Onda ácida centrada en el alquimista: daño pleno + detonaciones (+ de
	# paso cura a los aliados que estén dentro, como todo frasco).
	var result: Array = player.stats.roll_spell_damage(&"magic", 1.6)
	NetSpawn.projectile(FLASK_SCENE,
		_tag_props({"position": player.global_position, "radius": WAVE_RADIUS,
			"enemy_damage_ratio": 1.0}),
		player.get_parent(), result[0], player, result[1])
	# El RPC corre en TODAS las copias de cada aliado: la cura la aplica el
	# dueño (vida/maná locales) y el prime queda visible para el host, que
	# es quien resuelve las detonaciones.
	for ally in Players.alive(player.get_tree()):
		ally.receive_elixir.rpc(HEAL_PCT, MANA_PCT, PRIME_SECONDS)
	return true
