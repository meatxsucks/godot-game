# Demake Mago ARPG

ARPG isométrico *wave-based* hecho en **Godot 4.4** (Forward+). Mezcla el combate top-down de **Diablo**, el loot procedural por rareza de **Borderlands**, los poderes con dash de **Wizard of Legend** y el equipamiento/skills de **Tibia** — todo con estética **"PS2 bonito"**: low-poly, 854×480 con pixel crunch y cel-shading.

> 🎨 **¿Eres artista o animador?** Salta directo a [Guía para artistas](#-guía-para-artistas-y-animadores): todos los visuales actuales son placeholders diseñados para ser reemplazados sin tocar código.

---

## Cómo correr el juego

1. Instala [Godot 4.4.x](https://godotengine.org/download) (no requiere la versión Mono).
2. Abre `project.godot` con el editor e importa el proyecto.
3. Presiona **F5** — arranca en el menú principal.

## Controles

| Input | Acción |
|-------|--------|
| **WASD** | Moverse (relativo a cámara) |
| **Mouse** | Apuntar (el mago mira al cursor) |
| **Click izquierdo** | Ataque principal de tu clase (**gratis**, sin maná) |
| **Click derecho** | Ataque secundario |
| **Espacio** | Movilidad: dash/embestida/voltereta (impulso con **i-frames**: eres intangible mientras dura) |
| **Q** | Habilidad de área de tu clase |
| **R** | SUPER de tu clase (requiere barra de stamina llena) |
| **E** | Interactuar (abrir cofres) |
| **I / Tab** | Inventario y equipo (bloquea el casteo mientras está abierto) |

## Reglas del juego

### Clases (elige antes de empezar) — cada una con su kit de 5 poderes
| Clase | Perfil | Kit (LMB · RMB · Espacio · Q · R) |
|-------|--------|-----------------------------------|
| 🔵 **Mago** | Cañón de cristal: daño y maná altos, poca vida | Bola de Fuego · Descarga Arcana · Dash Arcano · Nova de Escarcha · ☄️ Tormenta de Meteoros |
| 🟠 **Guerrero** | Tanque melee: mucha vida y resistencias | Tajo Circular · Hacha Arrojadiza · **Embestida** (daña lo que atraviesa) · Grito de Guerra · 🌪️ Torbellino |
| 🟢 **Explorador** | Arquero ágil: crítico y velocidad | Flecha · Disparo Múltiple (abanico ×3) · Voltereta · **Flecha Perforante** (atraviesa filas) · 🏹 Lluvia de Flechas |

### Recursos limitados (¡no hay regeneración!)
- La **vida** y el **maná no se regeneran solos**. Son recursos que se administran.
- **Maná**: lo recuperas **matando** (stat "maná por kill") o con **pociones azules** que botan los enemigos (35%).
- **Vida**: **solo** con pociones rojas, y esas **solo salen de cofres**. Racionalas.
- Las pociones son **consumibles de un solo uso**: van al inventario y se usan con click.

### Loot y equipo (estilo Tibia)
- 5 rarezas: **Común** (blanco) → **Poco común** (verde) → **Raro** (azul) → **Épico** (morado) → **Legendario** (naranja, con poder único **activo**: bolas de fuego que rebotan en cadena, nova de hielo defensiva al recibir golpes, maná que absorbe daño como escudo, o críticos que recortan cooldowns). Más rareza = más afijos y mejores valores.
- Los drops van al **inventario (20 casillas)**; equipas a mano (click o **arrastrando**) en **6 slots**: cabeza, torso, arma, escudo/orbe, anillo, botas. Pasa el mouse sobre un ítem para **compararlo lado a lado** con el que llevas equipado.
- **El equipo se ve puesto**: empiezas con las manos vacías y lo que equipas aparece en el personaje (arma en mano, escudo/libro en la otra, sombrero/casco) — cada clase con su versión del ítem.
- Las **armas a dos manos** (ej. Bastón de guerra) ocupan también la mano del escudo.
- El equipo sube tus stats **en vivo** (visible en el panel con I/Tab).

### Skills (entrenan con el uso, estilo Tibia)
- **Magia** (general), **Fuego**, **Rayo**, **Hielo**, **Cuerpo a cuerpo** y **Distancia**: cada casteo da XP al skill del poder usado.
- Cada nivel = **+3% de daño de ese tipo** (+1% por nivel de Magia). El Mago entrena elementos, el Guerrero cuerpo a cuerpo, el Explorador distancia.

### El mundo
- El mapa (64×64) se **genera proceduralmente** cada partida: rocas, pilares y árboles repartidos por semilla que sirven de cobertura — y los enemigos los rodean con navegación real.
- Cada oleada emerge de **portales púrpura** ubicados proceduralmente por el mapa, visibles **durante el descanso**: sabes de dónde vendrá la ronda y puedes posicionarte (o embocarles una Lluvia de Flechas al salir).
- Empiezas en una **base segura amurallada** (zona cian) al borde sur: los enemigos no pueden entrar, el **cofre** con equipo inicial y pociones de vida está adentro. Cruza la **puerta** para pelear; retrocede a la base si te ves apretado.
- **Oleadas**: rondas anunciadas con **10s de descanso** entre medio (vuelve a la base, toma pociones, compara tu loot). Cada oleada trae más enemigos, con más vida y daño, y **botín de mayor nivel**. Los **cofres se reabastecen cada 3 oleadas** — tu única fuente de vida si aguantas.
- **Enemigos**: slimes en 3 variantes — normal (8 dmg), rápido (5 dmg, veloz) y tanque (15 dmg, 75 HP); las rondas avanzadas traen más rápidos y tanques. Pegan por contacto y navegan con navmesh (rodean los muros hasta la puerta).
- **Boss final**: tras 4 oleadas, en la **oleada 5** llega el **Rey Slime** — 600 HP, corona dorada, golpe sísmico telegrafiado (¡sal del círculo rojo!) e invocación de secuaces. Derrotarlo = **¡NIVEL SUPERADO!** con **legendario garantizado**; puedes seguir en modo endless.
- **Minimapa con niebla de guerra** (abajo a la derecha): el mapa se va **desbloqueando a medida que exploras**; muestra la base, cofres, enemigos cercanos y los portales de la próxima oleada.
- **Muerte**: a 0 de vida → Game Over (Reintentar con la misma clase, o volver al Menú).

---

## Arquitectura de scripts

```
scripts/
├── core/
│   ├── game_state.gd        # Autoload "Game": clase elegida + definiciones de clases
│   └── scene_manager.gd     # Autoload "SceneManager": transiciones con fade
├── player/
│   ├── player_controller.gd # CharacterBody3D: movimiento twin-stick, dash (i-frames),
│   │                        #   slots de poderes, inventario, super, muerte
│   ├── player_stats.gd      # PlayerStats: base de clase + agregado del equipo (flat/%),
│   │                        #   crítico, roll de daño por elemento
│   └── skill_set.gd         # SkillSet: skills Magia/Fuego/Rayo/Hielo (XP por uso)
├── abilities/
│   ├── ability.gd           # Clase base: id, tecla, color, cooldown, coste, elemento
│   │                        #   + helpers _spawn_projectile / _spawn_nova
│   └── *_ability.gd         # 15 poderes: kits de Mago, Guerrero y Explorador
│                            #   (Game.build_kit() arma el kit según la clase)
├── magic/
│   ├── fireball.gd          # Proyectil GENÉRICO (lo usan Fireball y ArcBolt con otros exports)
│   ├── frost_nova.gd        # Area3D que crece y daña una vez a cada enemigo
│   └── meteor_storm.gd      # Genera meteoros por código + AoE por query física
├── enemies/
│   ├── slime.gd             # IA de persecución, ataque por contacto, variantes por exports,
│   │                        #   drop de loot/maná, respeta la zona segura
│   └── health_bar_3d.gd     # Barra de vida flotante (2 quads, mira a cámara)
├── levels/
│   ├── camera_rig.gd        # Cámara isométrica que sigue al player con lerp
│   └── enemy_spawner.gd     # Spawner continuo con variantes (nunca en zona segura)
├── loot/
│   ├── rarity.gd            # Tiers, COLORES por rareza, pesos de drop
│   ├── item_base.gd         # Plantilla de ítem (tipo, slot, 2H, stats base, icon)
│   ├── affix.gd / affix_instance.gd / legendary_power.gd
│   ├── loot_item.gd         # Ítem generado (afijos, ficha to_text, color de UI)
│   ├── loot_database.gd     # Autoload "LootDB": bases, afijos, legendarios, pociones
│   ├── loot_generator.gd    # Autoload "Loot": rareza→base→afijos; make_potion()
│   └── loot_drop.gd         # Drop en el mundo (color por rareza, pickup al inventario)
├── world/
│   ├── chest.gd             # Cofre accionable con E: derrama su contenido al suelo
│   └── safe_zone.gd         # Zona donde los enemigos no entran
└── ui/
    ├── main_menu.gd / class_select.gd
    ├── hud.gd               # Barras vida/maná, barra de poderes, Game Over, toggle inventario
    ├── ability_slot.gd      # Círculo de poder con recarga radial (dibujado por código)
    ├── inventory_panel.gd   # Equipo estilo Tibia + inventario + stats + skills
    └── item_slot_ui.gd      # Casilla de ítem (borde por rareza + tooltip)
```

**Autoloads** (orden en `project.godot`): `Game`, `LootDB`, `Loot`, `SceneManager`.

**Flujo de escenas**: `MainMenu.tscn` → `ClassSelect.tscn` → `levels/Arena.tscn` (con `ui/HUD.tscn` instanciado adentro).

---

## 🎨 Guía para artistas y animadores

**Todos los visuales actuales son primitivas placeholder** (cápsulas, esferas, cajas). El código depende de **rutas de nodos**, no de los meshes — si respetas la estructura de nodos indicada, puedes reemplazar cualquier visual sin tocar scripts.

### Dirección de arte
- Estética **PS2**: low-poly limpio, texturas pequeñas **sin filtro** (pixel crunch), paleta saturada.
- Resolución interna **854×480** con `stretch_mode = viewport` — los assets se ven "crunchy" por diseño.
- Personajes y criaturas usan **cel-shading**: en el material, `diffuse_mode = Toon` (`DIFFUSE_TOON`). El entorno puede ser más realista para contrastar.

### Dónde enchufar cada asset

| Asset | Escena | Placeholder actual | Qué RESPETAR al reemplazar |
|-------|--------|--------------------|-----------------------------|
| **Jugador (3 clases)** | `scenes/player/Player.tscn` | ✅ **Ya usa KayKit Adventurers** (CC0): Mage/Knight/Rogue con animaciones Idle/Run/Attack/Death (`assets/kaykit/`, mapeo en `game_state.gd → CLASSES.model/anims`) | El modelo se instancia bajo `Visual` en runtime (rotado 180°: KayKit mira +Z). `Visual/Wand` sigue siendo el **punto de spawn de proyectiles** (invisible). Para cambiar un modelo: reemplaza el GLB y ajusta los nombres de animación en `game_state.gd`. |
| **Slime** (enemigo) | `scenes/enemies/Slime.tscn` | Esfera verde | La ruta `Visual/Mesh` (el script tinta su material por variante y lo flashea en blanco al recibir daño). El nodo raíz escala `Visual` según la variante (`size_scale`). |
| **Bola de Fuego** | `scenes/magic/Fireball.tscn` | Esfera emisiva + OmniLight | Es un `Area3D` que avanza por su `-Z`. Cambia mesh/luz libremente; ideal punto para `GPUParticles3D` (estela). |
| **Descarga Arcana** | `scenes/magic/ArcBolt.tscn` | Esfera celeste chica | Igual que Fireball (comparten script). |
| **Nova de Escarcha** | `scenes/magic/FrostNova.tscn` | Esfera transparente | El script escala `MeshInstance3D` de 0 al radio — el visual debe verse bien escalando. |
| **Meteoros (super)** | `scripts/magic/meteor_storm.gd` | Esferas creadas EN CÓDIGO | Único caso sin escena: el visual se construye en `_drop_meteor()`. Para assets propios, conviene extraer un `Meteor.tscn` (avisar a programación). |
| **Drop de loot** | `scenes/loot/LootDrop.tscn` | Prisma flotante que rota | `Visual/Mesh` (el script pinta el material según rareza) y `OmniLight3D` (brillo del color de rareza). La animación de flote/rotación es por código en `loot_drop.gd`. |
| **Cofre** | `scenes/world/Chest.tscn` | Cajas de madera | `LidPivot` es la **bisagra**: la apertura rota ese nodo con tween. La tapa nueva debe colgar de él. `Prompt` es el Label3D "[E] Abrir". |
| **Arena / entorno** | `scenes/levels/Arena.tscn` | Plano gris + muros caja | Piso con colisión (`Floor`), muros de la base (`WallLeft/WallRight` — la puerta es el hueco central). Luz direccional + WorldEnvironment configurados ahí. |
| **Zona segura** | `scenes/world/SafeZone.tscn` | Disco cian plano | Solo visual: el gameplay usa el `radius` del script, no el mesh. |
| **Obstáculos del mundo** | `scripts/levels/world_generator.gd` | Rocas/pilares/árboles EN CÓDIGO | El mundo es procedural: los 3 tipos se construyen en `_make_rock/_make_pillar/_make_tree`. Para assets propios conviene extraer escenas por tipo (avisar a programación). Los colliders alimentan el navmesh. |
| **Portal de oleada** | `scenes/world/SpawnPortal.tscn` | Disco púrpura pulsante | El pulso/rotación es por código (`spawn_portal.gd`); ideal para partículas de portal. |
| **Barra de vida enemiga** | `scripts/enemies/health_bar_3d.gd` | 2 quads por código | Reemplazable por sprites si se desea (hablar con programación). |

### Íconos de ítems y UI
- Hoy la UI es 100% dibujada por código (círculos de poderes, casillas con abreviaturas de 3 letras).
- `ItemBase` ya tiene un campo **`icon: Texture2D`** listo para recibir sprites de ítems — cuando existan los íconos, se conectan en `item_slot_ui.gd`.
- Colores oficiales por rareza: ver `scripts/loot/rarity.gd` (`COLORS`). Pociones: rojo vida / azul maná (`loot_item.gd → ui_color()`).

### Animaciones
- **El jugador ya está animado** (KayKit): idle/correr según velocidad, ataque al castear y muerte — manejado en `player_controller.gd` (`_update_animation`/`_play_attack_animation`). Los enemigos siguen con tweens por código.
- Para animar enemigos: mismo patrón — modelo con `AnimationPlayer` bajo `Visual` y clips `idle/run/attack/death` (los KayKit Skeletons calzan perfecto como enemigos).

### Créditos de assets
- Personajes: **KayKit Character Pack: Adventurers** de [Kay Lousberg](https://kaylousberg.itch.io/kaykit-adventurers) (CC0). Licencia incluida en `assets/kaykit/LICENSE.txt`.

### Reglas de oro
1. **No renombres ni muevas** los nodos mencionados en la tabla (`Visual`, `Visual/Mesh`, `Wand`, `LidPivot`...): los scripts los buscan por ruta.
2. Los materiales que el código modifica (tint/flash) se **duplican por instancia** en `_ready()` — tu material base no se rompe, pero el canal `albedo_color` debe quedar disponible.
3. Mantén las escalas reales: colisiones y alcances de ataque están calibrados en metros (el mago mide ~1.8).

---

## Desarrollo

```bash
# Validar el proyecto sin abrir el editor
godot --headless --path . --editor --quit-after 200

# Smoke tests (equipo 2H y kits por clase)
godot --headless --path . res://tests/LootSmoke.tscn   # imprime "SMOKE OK"
godot --headless --path . res://tests/KitSmoke.tscn    # imprime "KIT SMOKE OK"
```

Hecho con Godot 4.4 · Proyecto en desarrollo activo 🚧
