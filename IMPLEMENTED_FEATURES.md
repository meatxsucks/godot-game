# Sistemas y Features Implementados (Referencia para Claude Code)

Este documento detalla la arquitectura y las características mecánicas que ya se encuentran implementadas y funcionando en el proyecto Godot (versión 4.4, Forward+). Su propósito es servir de contexto para futuras sesiones de programación asistida por IA.

## 1. Sistema de Botín Procedural (Loot System)
Inspirado en *Diablo* y *Borderlands*. Genera ítems procedurales con rarezas y afijos.
- **Autoloads**: `Loot` (Lógica de generación) y `LootDB` (Base de datos de afijos, nombres base y poderes).
- **Rarezas**: Común (Blanco), Raro (Verde), Épico (Morado), Legendario (Naranja). Las rarezas más altas garantizan más afijos.
- **Items (`LootItem`)**: Estructura de datos generada que contiene un nombre, daño/defensa, tipo, rareza, y un array de *Afijos* (ej: "+10% Daño Fuego").
- **Drops en el Mundo (`LootDrop.tscn`)**: Un prisma 3D interactivo (`Area3D`) que aparece cuando muere un enemigo. Ajusta su color y brillo dependiendo de la rareza del ítem. Al colisionar con el jugador, actualmente imprime las estadísticas en consola.

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
  - Gestiona **maná** (coste por lanzamiento + regeneración por segundo) y vida.
  - `has_legendary(effect_id)` permite que el combate consulte poderes legendarios equipados (ej. `crit_cdr` = "Cascada Crítica" recorta el cooldown al critear).
- **Cooldown dinámico**: `cast_speed` y `cooldown_reduction` del equipo reducen el tiempo de recarga real (`_effective_cooldown()`).

## 4. Enemigos Básicos (Slime)
- **Script y Escena**: `Slime.tscn` (`CharacterBody3D`).
- **IA**: Busca el primer nodo en el grupo `"player"` en la escena y se mueve lentamente hacia él usando físicas y un vector direccional.
- **Sistema de Vida (Health)**: Responde a la función `take_damage(amount)`.
- **Gamefeel**: Al recibir daño, su material cambia temporalmente a color blanco puro durante 0.2 segundos usando un `Tween`, dando una sensación táctil al impacto.
- **Muerte**: Al llegar su vida a 0, instancia un `LootDrop.tscn` (con probabilidad `drop_chance`), le inyecta un `LootItem` de nivel `loot_level` (configurable por el spawner según la oleada), y luego hace `queue_free()`.

## 4b. Loteo y Equipamiento (loop cerrado)
- **Recogida (`LootDrop.gd`)**: al entrar el jugador, si el cuerpo está en el grupo `"player"` y expone `equip()`, **equipa el ítem** (antes solo hacía `print`).
- **Equipar (`Player.equip(item)`)**: delega en `PlayerStats.equip()`, recalcula stats, re-clampa vida/maná a los nuevos máximos y emite `item_equipped` / `stats_changed`. Devuelve el ítem reemplazado.
- **Loop ARPG**: enemigo muere → dropea loot por rareza → el jugador lo equipa → sube `spell_damage`/crit/maná → la siguiente Bola de Fuego pega más fuerte.
- **Señales para HUD** (en `player_controller.gd`): `health_changed`, `mana_changed`, `stats_changed`, `item_equipped`.

## 5. Cámara y Gestión de Escenas
- **SceneManager (Autoload)**: Gestiona transiciones fluidas de fundido a negro entre pantallas usando un `CanvasLayer` persistente y un `AnimationPlayer`.
- **Rig de Cámara Isométrica (`camera_rig.gd`)**: Nodo que sigue suavemente al jugador usando interpolación (`lerp`). La cámara en su interior está rotada para lograr un ángulo ARPG clásico (aprox Y=45, X=-35) y tiene un FOV bajo de 35 grados para achatamiento de perspectiva.

## 6. Estética y Renderizado ("Sabor PS2")
- **Resolución Interna**: En `project.godot`, el `viewport_width` es 854 y `viewport_height` es 480 (480p panorámico). El `stretch_mode` es "viewport", logrando un efecto de bajo pixelado nítido (crunchy) típico de la PS2.
- **Cel-Shading (Toon)**: Los materiales del Mago, su varita y los enemigos tienen la propiedad `diffuse_mode` establecida en `3` (`DIFFUSE_TOON`), dándoles sombras duras estilo anime que contrastan con el entorno realista.

## Próximos Pasos (Pendientes)
- Implementar una UI/HUD en pantalla para Vida, Maná e Inventario (las señales ya existen en `player_controller.gd`).
- Sistema de oleadas (spawner) que escale `loot_level` y dificultad de los slimes.
- Que los slimes ataquen al jugador (ahora el jugador tiene `take_damage`, pero nadie se lo aplica todavía).
- Enganchar los demás poderes legendarios (`fireball_chain`, `on_hit_frost_nova`, `mana_to_shield`) en la capa de combate.
- Añadir navegación compleja con `NavigationRegion3D` (Navmesh) para los enemigos.

> ✅ **Hecho recientemente**: integración de stats del botín equipado al combate (daño/crit/maná/cooldown), maná con coste+regen, fix de fuego amigo en la Bola de Fuego, y loteo que equipa de verdad.
