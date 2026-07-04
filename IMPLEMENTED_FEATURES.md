# Sistemas y Features Implementados (Referencia para Claude Code)

Este documento detalla la arquitectura y las características mecánicas que ya se encuentran implementadas y funcionando en el proyecto Godot (versión 4.4, Forward+). Su propósito es servir de contexto para futuras sesiones de programación asistida por IA.

## 1. Sistema de Botín Procedural (Loot System)
Inspirado en *Diablo* y *Borderlands*. Genera ítems procedurales con rarezas y afijos.
- **Autoloads**: `Loot` (Lógica de generación) y `LootDB` (Base de datos de afijos, nombres base y poderes).
- **Rarezas**: Común (Blanco), Raro (Verde), Épico (Morado), Legendario (Naranja). Las rarezas más altas garantizan más afijos.
- **Items (`LootItem`)**: Estructura de datos generada que contiene un nombre, daño/defensa, tipo, rareza, y un array de *Afijos* (ej: "+10% Daño Fuego").
- **Drops en el Mundo (`LootDrop.tscn`)**: Un prisma 3D interactivo (`Area3D`) que aparece cuando muere un enemigo. Ajusta su color y brillo dependiendo de la rareza del ítem. Al colisionar con el jugador, el ítem va al **inventario** (ver sección 9); si está lleno, el drop queda en el suelo.

## 2. Controlador del Jugador (Mago)
- **Script**: `scripts/player/player_controller.gd`
- **Movimiento**: *Twin-stick* absoluto. Usa las teclas WASD (`move_up`, `move_down`, `move_left`, `move_right`). El vector de movimiento se alinea con la rotación de la cámara para que "W" siempre mueva al personaje hacia "arriba" en la pantalla.
- **Apuntado (Aiming)**: Dispara un `RayCast` desde la cámara actual hacia el cursor del ratón e intersecta con el plano del suelo (Y=0). El modelo visual del mago rota (`look_at`) constantemente hacia esa intersección.
- **Grupos**: El jugador está registrado en el grupo `"player"`.

## 3. Combate y Magia
- **Bola de Fuego (`Fireball.tscn`)**: Es un proyectil de tipo `Area3D`.
  - Se instancia en el nodo `Wand` (la varita del mago) al hacer click izquierdo (`attack_primary`).
  - El **daño ya no es fijo**: el jugador llama a `fireball.setup(daño, lanzador, es_critico)` con el daño calculado desde sus stats.
  - **Sin fuego amigo**: ignora al `source` (lanzador) y a cualquier nodo del grupo `"player"`; muere al impactar contra cualquier otro cuerpo físico.
  - Posee autodestrucción temporal (3 segundos) para evitar fugas de memoria.
- **Stats del Mago (`PlayerStats`, `scripts/player/player_stats.gd`)**: `RefCounted` que mantiene los stats base + el agregado del equipo.
  - Combina aportes **planos** (FLAT) y **porcentuales** (PERCENT) de cada ítem: `efectivo = plano * (1 + %/100)`.
  - `roll_spell_damage()` calcula el daño del hechizo con tirada de **crítico** (`crit_chance` / `crit_damage`).
  - Gestiona **maná** (coste por lanzamiento) y vida. **Sin regeneración pasiva**: ambos son recursos limitados — se recuperan con pociones y con el **maná por kill** (stat `mana_regen`, otorgado en `on_enemy_killed()`).
  - `has_legendary(effect_id)` permite que el combate consulte poderes legendarios equipados (ej. `crit_cdr` = "Cascada Crítica" recorta el cooldown al critear).
- **Cooldown dinámico**: `cast_speed` y `cooldown_reduction` del equipo reducen el tiempo de recarga real (`_effective_cooldown()`).

## 4. Enemigos (Slime + variantes)
- **Script y Escena**: `Slime.tscn` (`CharacterBody3D`), en el grupo `"enemies"`.
- **IA**: Busca el primer nodo en el grupo `"player"` en la escena y se mueve hacia él usando físicas y un vector direccional.
- **Ataque por contacto**: si el jugador está al alcance (según su escala), le pega `attack_damage` (normal 8 / rápido 5 / tanque 15) con cadencia `attack_interval` (1s por slime). El player recibe el golpe con flash rojo.
- **Barra de vida flotante** (`HealthBar3D`, `scripts/enemies/health_bar_3d.gd`): dos quads sin assets sobre la cabeza, anclada a la izquierda, va de verde a rojo y mira a la cámara cada frame — se ve claramente cómo van perdiendo vida con cada golpe.
- **Variantes por exports** (`body_color`, `size_scale`, `max_health`, `speed`): normal (verde), **rápido** (chico, celeste, 16 HP, veloz) y **tanque** (grande, verde oscuro, 75 HP, lento). El tint usa material propio por instancia; la escala ajusta visual + colisión.
- **Gamefeel**: parpadeo blanco 0.2s al recibir daño (vuelve al color de la variante, no al color leído — fix del flash encadenado).
- **Muerte**: dropea equipo con probabilidad `drop_chance` (0.5) y **además** una poción de maná con `mana_drop_chance` (0.35). **Los enemigos nunca botan vida** (sale de cofres). El kill acredita +12 de stamina del super.
- **Spawner continuo** (`scripts/levels/enemy_spawner.gd`, en la Arena): mantiene hasta 8 enemigos vivos, spawneando una variante al azar cada 3s en un anillo de 8–16m del centro.

## 4b. Loteo y Equipamiento (loop cerrado)
- **Recogida (`LootDrop.gd`)**: al entrar el jugador llama `pick_up(item)` → el ítem va al **inventario** (ya no auto-equipa). Si el inventario está lleno, el drop no desaparece.
- **Equipar (`Player.equip_from_inventory(index)`)**: delega en `PlayerStats.equip()` (que devuelve los ítems **desplazados**, 0–2 por conflictos de slot/dos manos), los desplazados vuelven al inventario, recalcula stats, re-clampa vida/maná y emite `item_equipped` / `stats_changed`.
- **Loop ARPG**: enemigo muere → dropea loot por rareza → el jugador lo recoge, lo compara y lo equipa → sube `spell_damage`/crit/maná → la siguiente Bola de Fuego pega más fuerte.
- **Señales para HUD** (en `player_controller.gd`): `health_changed`, `mana_changed`, `stats_changed`, `item_equipped`, `inventory_changed`, `super_charge_changed`.

## 5. Cámara y Gestión de Escenas
- **SceneManager (Autoload)**: Gestiona transiciones fluidas de fundido a negro entre pantallas usando un `CanvasLayer` persistente y un `AnimationPlayer`.
- **Rig de Cámara Isométrica (`camera_rig.gd`)**: Nodo que sigue suavemente al jugador usando interpolación (`lerp`). La cámara en su interior está rotada para lograr un ángulo ARPG clásico (aprox Y=45, X=-35) y tiene un FOV bajo de 35 grados para achatamiento de perspectiva.

## 6. Estética y Renderizado ("Sabor PS2")
- **Resolución Interna**: En `project.godot`, el `viewport_width` es 854 y `viewport_height` es 480 (480p panorámico). El `stretch_mode` es "viewport", logrando un efecto de bajo pixelado nítido (crunchy) típico de la PS2.
- **Cel-Shading (Toon)**: Los materiales del Mago, su varita y los enemigos tienen la propiedad `diffuse_mode` establecida en `3` (`DIFFUSE_TOON`), dándoles sombras duras estilo anime que contrastan con el entorno realista.

## 7. Sistema de Poderes — barra de 5 slots (estilo Wizard of Legend)
- **Clase base `Ability`** (`scripts/abilities/ability.gd`, `RefCounted`): define `id`, nombre, tecla (`key_label`), color, `cooldown` y `mana_cost`; valida recursos y castea (`execute(player)`). El player mantiene el array de 5 slots y sus timers de cooldown (`_update_abilities` en `player_controller.gd`).
- **Cooldowns**: `effective_cooldown(base)` aplica `cast_speed`/`cooldown_reduction` del loot a **todos** los poderes. El legendario `crit_cdr` ("Cascada Crítica") sigue recortando el cooldown de la Bola de Fuego al critear (vía `_cooldown_refund`).
- **Los 5 poderes de la demo** (una subclase de `Ability` cada uno, en `scripts/abilities/`):
  1. **Bola de Fuego** — Click izq, 2.0s, 15 maná. El proyectil principal; escala con `spell_damage + fire_damage`.
  2. **Descarga Arcana** — Click der, 0.6s, 6 maná. Proyectil rápido y débil para spamear (40% de daño); escala con `lightning_damage`. **Reutiliza `fireball.gd`** con otros exports (`ArcBolt.tscn`).
  3. **Dash Arcano** — Espacio, 1.5s, gratis. Impulso de 0.15s a velocidad x4 hacia el input de movimiento (o hacia el cursor si el mago está quieto). El estado del dash vive en `_move()` del player (`start_dash()`). Al terminar el impulso la velocidad **se corta en seco** (sin deslizamiento). Durante el dash eres **intangible** (i-frames): `take_damage` ignora los golpes — esquivar es real.
  4. **Nova de Escarcha** — Q, 5.0s, 25 maná. `Area3D` que crece de 0→4m en 0.4s dañando **una sola vez** a cada enemigo; escala con `cold_damage` (`FrostNova.tscn` + `frost_nova.gd`).
  5. **SUPER: Tormenta de Meteoros** — R, sin cooldown: requiere la **stamina llena**. 8 meteoros caen en radio 5m sobre el punto del cursor (`get_aim_point()`), 150% de daño cada uno con AoE de impacto vía query física (`MeteorStorm.tscn` + `meteor_storm.gd`).
- **Stamina del super** (`super_charge` 0–100 en el player): **+4 por impacto** de habilidad (proyectiles y nova acreditan a su `source` con `add_super_charge`) y **+12 por kill** (el slime acredita al morir). `MeteorStormAbility` consume la barra entera (`consume_super_charge()`).
- `PlayerStats.roll_spell_damage(element, multiplier)` ahora es paramétrico: cada poder suma su daño elemental del loot, así los afijos de fuego/rayo/frío potencian poderes distintos.
- Acciones de input nuevas en `project.godot`: `attack_secondary` (click der), `ability_dash` (Espacio), `ability_nova` (Q), `ability_super` (R).

## 8. HUD in-game
- **`HUD.tscn`** (`CanvasLayer` + `scripts/ui/hud.gd`) instanciado en la Arena; encuentra al player por el grupo `"player"`.
- **Barras de vida (roja) y maná (azul)** arriba-izquierda con números (`82/100`), conectadas a las señales `health_changed`/`mana_changed`.
- **5 círculos de habilidad** abajo-centro: `AbilitySlot` (`scripts/ui/ability_slot.gd`), un `Control` dibujado 100% por código con `_draw()` (sin assets, acorde a la estética PS2). Muestra la recarga radial tipo "pastel", la tecla del poder, y el color identitario de cada habilidad al estar lista.
- El **slot del super** es más grande, se rellena con la carga de stamina (señal `super_charge_changed`) y **parpadea** cuando está listo para soltar.
- Los cooldowns se polean cada frame (`_process`) para que el relleno radial sea suave; vida/maná/super van por señales.

## 9. Inventario y Equipamiento (estilo Tibia)
- **Inventario del player** (`player_controller.gd`): `inventory` de **20 casillas**. `pick_up(item)` (lo llama `LootDrop`), `equip_from_inventory(index)`, `unequip_slot(slot)` y señal `inventory_changed`.
- **6 slots de equipo** en `PlayerStats.equipment`: `head` (cabeza), `armor` (torso), `weapon` (mano principal), `offhand` (escudo/orbe), `ring` (anillo), `boots` (zapatos).
- **Armas a dos manos** (`ItemBase.two_handed`): equipar una 2H desplaza el offhand al inventario, y equipar un offhand con 2H puesta desplaza el arma. `PlayerStats.equip()` devuelve `Array[LootItem]` con los desplazados. Smoke test headless en `tests/LootSmoke.tscn`.
- **Bases nuevas en LootDB**: Sombrero de tela (`head`), Botas de cuero (`boots`), Escudo de madera (`offhand`) y **Bastón de guerra** (arma 2H, spell_damage alto).
- **Stat nuevo `move_speed`** (%): lo aplica `current_speed()` al caminar y al dash. Afijo "del Viento" (3–8%, solo botas) — las botas rolean velocidad.
- **UI (`InventoryPanel.tscn` + `inventory_panel.gd`)**: panel a la derecha, toggle con **I** o **Tab** (acción `toggle_inventory`, la maneja el HUD). Cruz de equipo 3×3 estilo Tibia (cabeza arriba; arma|torso|escudo; anillo|botas) + grilla de inventario 5×4 con contador.
- **`ItemSlotUI`** (`item_slot_ui.gd`, Button 40×40): abreviatura de 3 letras y borde coloreados por **rareza**, tooltip con la ficha completa (`LootItem.to_text()`: stats, afijos, legendarios). Click en inventario = equipar; click en slot de equipo = quitar. Sin drag & drop (v1).
- Con el inventario abierto `combat_input_enabled = false`: los clicks en la UI **no disparan** hechizos (los cooldowns siguen corriendo).

## 10. Consumibles y Cofres
- **Pociones** (`LootDB.potion_bases`, fuera del pool del generador de equipo): **Poción de vida** (+40) y **Poción de maná** (+50). Son de **un solo uso, no recargables**: van al inventario y con click se consumen (`equip_from_inventory` detecta `is_consumable()` y llama `heal()`/`restore_mana()` del player).
- Colores propios en UI y drops (`LootItem.ui_color()`): rojo vida, azul maná; abreviaturas "VID"/"MAN" en las casillas.
- **Economía**: los enemigos botan **solo maná** (35%); la **vida sale únicamente de cofres**.
- **Cofre accionable** (`Chest.tscn` + `scripts/world/chest.gd`, `StaticBody3D`): al acercarse muestra el prompt `[E] Abrir` (Label3D billboard); con **E** (acción `interact`) la tapa se abre con tween y el contenido **cae al suelo en anillo** alrededor (tween de derrame): **bastón, sombrero, zapatos y túnica** generados por tipo (`Loot.generate_random_item(level, type)`) + 2 pociones de vida. Un solo uso.
- `Loot.generate_random_item()` ahora acepta un `type` opcional para restringir la base (cofres temáticos), y `Loot.make_potion(kind)` crea consumibles.

## 11. Rol: Clases, Skills estilo Tibia y Zona Segura
- **Autoload `Game`** (`scripts/core/game_state.gd`): `selected_class` (default `mage`) + `CLASSES` con 3 clases jugables:
  - **Mago** — cañón de cristal: vida 80, maná 130, regen 10, daño 12, crít 6%. Kit de 5 poderes propio (el actual).
  - **Guerrero** — tanque: vida 170, maná 60, resistencias +10%. *Kit propio pendiente (usa el del Mago).*
  - **Explorador** — ágil: vida 110, crít 12%, daño crít 70%, move_speed +12%. *Kit propio pendiente.*
- **Selección de clase** (`ClassSelect.tscn` + `class_select.gd`): pantalla entre el menú y la Arena con tarjetas construidas por código desde `Game.CLASSES` (nombre, descripción, stats, botón Elegir). `PlayerStats._init` hace merge de los stats de la clase sobre los base.
- **Skills estilo Tibia** (`SkillSet`, `scripts/player/skill_set.gd`, vive en `PlayerStats.skills`): **Magia** (general), **Fuego**, **Rayo**, **Hielo**. Cada casteo da +2 XP al elemento del poder (`Ability.element`) y +1 a Magia; umbral `10 + nivel*8`. Bonus de daño: **+3%/nivel del elemento, +1%/nivel de Magia**, aplicado en `roll_spell_damage()` — entrenar fuego hace pegar más fuerte a la Bola de Fuego y los Meteoros, el rayo a la Descarga, el hielo a la Nova. Dos ejes de progresión: loot (stats) + uso (skills).
- **Base inicial / Zona Segura** (`SafeZone.tscn` + `safe_zone.gd`, grupo `"safe_zone"`): la partida empieza en una **base al borde sur del mapa** (disco cian radio 6.5, cofre adentro, spawn del player), separada del campo de batalla por **dos muros con una puerta central**. Te equipas en paz y cruzas la puerta para enfrentar a los enemigos. Los slimes nunca entran a la zona (salen si quedan dentro), esperan afuera si el jugador está a salvo y la rodean por la tangente; el spawner tampoco spawnea dentro.
- **Panel de inventario a 2 columnas**: izquierda equipo + bloque de **Stats** (vida, maná, daño, crít, vel. lanzamiento/movimiento) y **Skills** (nivel + % de progreso); derecha la grilla 5×4. Refresca en vivo con `stats_changed`/`skills_changed` — se ve cómo el equipo y el entrenamiento suben los números.

## 12. Muerte y Game Over
- El player muere al llegar a 0 de vida: cae de espaldas (tween), `_dead` bloquea input/físicas y emite la señal `died`.
- El **HUD muestra el Game Over** ("HAS MUERTO") con **Reintentar** (recarga la Arena con la misma clase) y **Menú** (vuelve al menú principal).
- Feedback de daño recibido: flash rojo del cuerpo del mago (material propio por instancia).

## Próximos Pasos (Pendientes)
- **Poderes por clase**: kits propios de Guerrero (melee) y Explorador (distancia); hoy usan el del Mago.
- Oleadas con escalado: subir `loot_level`, `max_alive` y dificultad del spawner con el tiempo/rondas.
- Enganchar los demás poderes legendarios (`fireball_chain`, `on_hit_frost_nova`, `mana_to_shield`) en la capa de combate.
- Añadir navegación compleja con `NavigationRegion3D` (Navmesh) para los enemigos.
- Comparación de ítems lado a lado y drag & drop en el inventario (v2 de la UI).

> ✅ **Hecho recientemente**: combate con riesgo real — los slimes pegan por contacto (daño por variante), el dash tiene i-frames, y hay muerte con Game Over (Reintentar/Menú).
