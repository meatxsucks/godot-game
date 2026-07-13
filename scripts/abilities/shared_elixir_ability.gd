## Alquimista R — SUPER: Elixir Compartido. Toda la party recupera un % de
## vida y maná, y durante unos segundos los golpes de TODOS detonan
## cualquier tag de estado — el habilitador de combos de la party.
class_name SharedElixirAbility
extends Ability

## % de vida y maná que recupera cada aliado, y ventana del prime.
const HEAL_PCT := 0.35
const MANA_PCT := 0.5
const PRIME_SECONDS := 5.0

func _init() -> void:
	id = &"shared_elixir"
	display_name = "Elixir Compartido"
	key_label = "R"
	color = Color(0.35, 0.95, 0.55)
	cooldown = 1.0
	mana_cost = 0.0
	element = &"magic"
	is_super = true

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.3)
	# El RPC corre en TODAS las copias de cada aliado: la cura la aplica el
	# dueño (vida/maná locales) y el prime queda visible para el host, que
	# es quien resuelve las detonaciones.
	for ally in Players.alive(player.get_tree()):
		ally.receive_elixir.rpc(HEAL_PCT, MANA_PCT, PRIME_SECONDS)
	return true
