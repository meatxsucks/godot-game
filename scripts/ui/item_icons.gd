## Íconos de ítems (feedback del dueño 2026-07-17: "los ítems deben ser
## gráficos para saber qué son"). Pixel-art 14×14 generado por código, por
## TIPO de ítem — estética PS2/retro (se escala con filtro NEAREST).
## Es el placeholder oficial hasta el arte real de E8.5: si un `ItemBase`
## trae `icon` (Texture2D), ese manda y esto no se usa.
class_name ItemIcons
extends RefCounted

## '.' transparente · 'X' color primario · 'o' secundario · '+' detalle.
const MAPS := {
	&"staff": [
		".....++++.....",
		"....+oooo+....",
		"....+oooo+....",
		".....++++.....",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
		"......XX......",
	],
	&"wand": [
		"...........+..",
		"..........+.+.",
		"...........+..",
		"........XX....",
		".......XXX....",
		"......XXX.....",
		".....XXX......",
		"....XXX.......",
		"...XXX........",
		"..XXX.........",
		".XXX..........",
		".XX...........",
		"..............",
		"..............",
	],
	&"sword": [
		"..........XXX.",
		".........XXXX.",
		"........XXXX..",
		".......XXXX...",
		"......XXXX....",
		".....XXXX.....",
		"....XXXX......",
		"...+XXX.......",
		"..++++........",
		"..oo++........",
		".oo...........",
		"oo............",
		"..............",
		"..............",
	],
	&"mace": [
		"....XXXXXX....",
		"...XXXXXXXX...",
		"...XX+XX+XX...",
		"...XXXXXXXX...",
		"...XXXXXXXX...",
		"....XXXXXX....",
		"......oo......",
		"......oo......",
		"......oo......",
		"......oo......",
		"......oo......",
		"......oo......",
		".....oooo.....",
		"..............",
	],
	&"bow": [
		".....XXX......",
		"...XX...X.....",
		"..X......X....",
		"..X.......X...",
		".X.........o..",
		".X.........o..",
		".X.........o..",
		".X.........o..",
		".X.........o..",
		"..X.......o...",
		"..X......o....",
		"...XX...o.....",
		".....XXX......",
		"..............",
	],
	&"shield": [
		"..XXXXXXXXXX..",
		"..XooooooooX..",
		"..XooooooooX..",
		"..Xooo++oooX..",
		"..Xooo++oooX..",
		"..XooooooooX..",
		"..XooooooooX..",
		"...XooooooX...",
		"...XooooooX...",
		"....XooooX....",
		"....XooooX....",
		".....XooX.....",
		"......XX......",
		"..............",
	],
	&"orb": [
		"..............",
		"....XXXXXX....",
		"...XooooooX...",
		"..Xoo++ooooX..",
		"..Xo++oooooX..",
		"..XooooooooX..",
		"..XooooooooX..",
		"..XooooooooX..",
		"...XooooooX...",
		"....XXXXXX....",
		"..............",
		"..............",
		"..............",
		"..............",
	],
	&"helmet": [
		"......XX......",
		".....XXXX.....",
		".....XXXX.....",
		"....XXXXXX....",
		"....XXXXXX....",
		"...XXXXXXXX...",
		"...XXXXXXXX...",
		"..XXXXXXXXXX..",
		".XXXXXXXXXXXX.",
		"XXXXXXXXXXXXXX",
		"..............",
		"..............",
		"..............",
		"..............",
	],
	&"armor": [
		"..XX......XX..",
		".XXXX....XXXX.",
		".XXXXXXXXXXXX.",
		".XXXXXXXXXXXX.",
		".XX.XXXXXX.XX.",
		"....XXXXXX....",
		"....XXXXXX....",
		"....XXXXXX....",
		"....XXXXXX....",
		"...XXXXXXXX...",
		"...XXXXXXXX...",
		"..............",
		"..............",
		"..............",
	],
	&"cape": [
		"..XXXXXXXXXX..",
		"..XXXXXXXXXX..",
		"...XXXXXXXX...",
		"...XXXXXXXX...",
		"...XXXXXXXX...",
		"....XXXXXX....",
		"....XXXXXX....",
		"....XXXXXX....",
		".....XXXX.....",
		".....XXXX.....",
		"....XX..XX....",
		"..............",
		"..............",
		"..............",
	],
	&"gloves": [
		"..............",
		"....XX........",
		"...XXXX.XX....",
		"...XXXXXXX....",
		"...XXXXXXX....",
		"...XXXXXXX....",
		"...XXXXXXX....",
		"....XXXXX.....",
		"....XXXXX.....",
		"....oooo......",
		"....oooo......",
		"..............",
		"..............",
		"..............",
	],
	&"potion_health": [
		"......oo......",
		"......oo......",
		".....oooo.....",
		"....oXXXXo....",
		"...oXXXXXXo...",
		"...oXXXXXXo...",
		"...oXX+XXXo...",
		"...oXXXXXXo...",
		"....oXXXXo....",
		".....oooo.....",
		"..............",
		"..............",
		"..............",
		"..............",
	],
	&"gold": [
		"..............",
		"....XXXXXX....",
		"...XXXXXXXX...",
		"..XXX+++XXXX..",
		"..XX+XXXX+XX..",
		"..XX+XXXX+XX..",
		"..XX+XXXX+XX..",
		"..XXX+++XXXX..",
		"...XXXXXXXX...",
		"....XXXXXX....",
		"..............",
		"..............",
		"..............",
		"..............",
	],
}

## Paleta por tipo: [X primario, o secundario, + detalle].
const PALETTES := {
	&"staff": [Color(0.55, 0.36, 0.2), Color(0.45, 0.8, 1.0), Color(0.8, 0.95, 1.0)],
	&"wand": [Color(0.9, 0.85, 0.75), Color(0.7, 0.65, 0.55), Color(1.0, 1.0, 0.6)],
	&"sword": [Color(0.8, 0.82, 0.88), Color(0.45, 0.3, 0.18), Color(0.95, 0.8, 0.3)],
	&"mace": [Color(0.45, 0.45, 0.5), Color(0.45, 0.3, 0.18), Color(0.7, 0.7, 0.75)],
	&"bow": [Color(0.55, 0.36, 0.2), Color(0.9, 0.9, 0.85), Color(1, 1, 1)],
	&"shield": [Color(0.4, 0.28, 0.15), Color(0.62, 0.45, 0.25), Color(0.8, 0.8, 0.85)],
	&"orb": [Color(0.7, 0.8, 0.95), Color(0.55, 0.7, 0.95), Color(1, 1, 1)],
	&"helmet": [Color(0.75, 0.65, 0.45), Color(0.6, 0.5, 0.35), Color(1, 1, 1)],
	&"armor": [Color(0.85, 0.8, 0.7), Color(0.65, 0.6, 0.5), Color(1, 1, 1)],
	&"cape": [Color(0.7, 0.25, 0.25), Color(0.5, 0.18, 0.18), Color(1, 1, 1)],
	&"gloves": [Color(0.6, 0.4, 0.22), Color(0.42, 0.28, 0.15), Color(1, 1, 1)],
	&"potion_health": [Color(0.9, 0.2, 0.2), Color(0.75, 0.78, 0.82), Color(1.0, 0.7, 0.7)],
	&"potion_mana": [Color(0.25, 0.5, 1.0), Color(0.75, 0.78, 0.82), Color(0.7, 0.85, 1.0)],
	&"gold": [Color(1.0, 0.82, 0.2), Color(0.8, 0.6, 0.1), Color(0.85, 0.65, 0.12)],
}

## El mapa de píxeles puede compartirse entre tipos (la poción de maná es la
## de vida con otra paleta).
const MAP_ALIASES := {&"potion_mana": &"potion_health"}

static var _cache := {}

## Textura del ícono para una base de ítem. Prioridad: `base.icon` (arte real,
## E8.5) → pixel-art por tipo → null (la casilla cae a la abreviatura).
static func texture_for(base: ItemBase) -> Texture2D:
	if base == null:
		return null
	if base.icon:
		return base.icon
	var key: StringName = base.type
	if _cache.has(key):
		return _cache[key]
	var map_key: StringName = MAP_ALIASES.get(key, key)
	if not MAPS.has(map_key) or not PALETTES.has(key):
		return null
	var rows: Array = MAPS[map_key]
	var palette: Array = PALETTES[key]
	var image := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			match row[x]:
				"X": image.set_pixel(x, y, palette[0])
				"o": image.set_pixel(x, y, palette[1])
				"+": image.set_pixel(x, y, palette[2])
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture
