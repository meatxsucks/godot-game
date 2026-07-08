# TODO — backlog, tareas e ideas

> **Cómo usar:** un agente toma **UNA** tarea, sigue `AGENTS.md`, la marca `[~] (nombre-agente)` al empezar y `[x]` al terminar (con smokes en verde). Al terminar, **registra el cambio en `CHANGELOG.md`** (obligatorio). Cada tarea es chica a propósito, para dársela a un chat/agente pequeño. `Z:` = zona de propiedad (ver `AGENTS.md §2`). El contexto de diseño/técnica está en `spec/`.

Estado: `[ ]` pendiente · `[~]` en progreso · `[x]` hecha · `⚠️` requiere coordinar zonas.

---

## E0 — Fundaciones técnicas (hacer PRIMERO)
- [ ] **E0.1** Migrar loot de arrays hardcodeados a Resources `.tres` en `resources/loot/`. `Z: lógica`. *Aceptación:* `LootDB` carga desde `.tres`; smokes pasan.
- [ ] **E0.2** Sistema de guardado `SaveService` (autoload): serializar clase, nivel, XP, skills, inventario, oro, progreso de mundo. `Z: lógica`. *Aceptación:* guardar/cargar reproduce el estado.
- [ ] **E0.3** Menú de Opciones (volumen, resolución, pantalla completa) enganchado al menú de pausa existente. `Z: lógica`. *Aceptación:* cambios persisten vía `SaveService`.
- [ ] **E0.4** Input remapeable en runtime (`InputMap`), con glifos de teclado/mando. `Z: lógica`.
- [ ] **E0.5** Localización: mover strings de UI a un `String table` (EN+ES). `Z: lógica`. *Aceptación:* ningún texto de UI hardcodeado.
- [ ] **E0.6** CI (GitHub Actions) que corre los 3 smokes en cada push. `Z: lógica`.

## E1 — Co-op / networking (el gran refactor — temprano)
- [ ] **E1.1** Elegir e integrar transporte (`SteamMultiplayerPeer` vía GodotSteam; `ENet` para local). `Z: lógica`.
- [ ] **E1.2** Refactor "el player": enemigos/curas/supers dejan de usar `get_first_node_in_group("player")` y operan sobre **lista de players / más cercano**. `Z: lógica`. *Aceptación:* con 2 players en escena, enemigos targetean al más cercano.
- [ ] **E1.3** `MultiplayerSpawner` para enemigos, drops y proyectiles. `Z: lógica`.
- [ ] **E1.4** `MultiplayerSynchronizer` de players y enemigos (posición/estado). `Z: lógica`.
- [ ] **E1.5** Lobby/matchmaking Steam (crear/unirse), host-authoritative. `Z: lógica`.
- [ ] **E1.6** HUD/cámara/inventario/corrupción **por-jugador local**. `Z: lógica`.
- [ ] **E1.7** Decidir e implementar reparto de loot (por jugador vs compartido). `Z: lógica` (decisión de diseño en GDD §11).

## E2 — Corrupción (mecánica central)
- [ ] **E2.1** `CorruptionSystem`: medidor por jugador, sube por tiempo/golpes/nodos, se limpia en ciudad. `Z: lógica`.
- [ ] **E2.2** Reloj del mundo: enemigos **mutan** al subir la corrupción de zona (stats/velocidad/ataques). `Z: lógica`.
- [ ] **E2.3** Riesgo/beneficio al jugador según nivel de corrupción (+daño/-defensa, loot corrupto). `Z: lógica`.
- [ ] **E2.4** Contagio: enemigos infectan a otros / mutan por tiempo. `Z: lógica`.
- [ ] **E2.5** UI de corrupción en el HUD. `Z: lógica` (+ arte del medidor `Z: visual`).

## E3 — Combos / tags de estado
- [ ] **E3.1** `StatusTags` en enemigos (Quemado, Congelado, Corroído, Marcado, Sangrado, Aturdido). `Z: lógica`.
- [ ] **E3.2** Habilidades declaran qué tags **aplican** y **detonan**; detonación da bonus. `Z: lógica`.
- [ ] **E3.3** Migrar las habilidades actuales al sistema de tags. `Z: lógica`.

## E4 — Mundo (ciudades + zonas)
- [ ] **E4.1** Ciudad-hub persistente (escena base con NPCs, tienda, herrería, banco, limpieza de corrupción). `Z: niveles` + `Z: lógica`.
- [ ] **E4.2** Generador de zonas: construir procedural **una vez** y **persistir** (semilla fija por zona, guardada). `Z: niveles`/`lógica`.
- [ ] **E4.3** Espina narrativa por zona (ruta + boss + eventos únicos, una sola vez). `Z: niveles`.
- [ ] **E4.4** Ramificaciones exploratorias con loot (estilo Borderlands, no oleadas). `Z: niveles`.
- [ ] **E4.5** Muerte estilo Tibia: perder XP + loot aleatorio no equipado, reaparecer en ciudad. `Z: lógica`.

## E5 — Economía
- [ ] **E5.1** Oro como recurso + drops. `Z: lógica`.
- [ ] **E5.2** Tienda (comprar/vender, precios altos). `Z: lógica`.
- [ ] **E5.3** Herrería (mejorar armas con oro). `Z: lógica`.
- [ ] **E5.4** Banco/depot expandible con oro. `Z: lógica`.
- [ ] **E5.5** Pociones planas escalables (curan menos al subir el pool). `Z: lógica`.

## E6 — Progresión (Tibia)
- [ ] **E6.1** Skills por uso por elemento/arma (ya hay base en `skill_set.gd`; expandir). `Z: lógica`.
- [ ] **E6.2** Objetos pasivos (ej. botas que regeneran maná). `Z: lógica`.
- [ ] **E6.3** Level-up rellena vida/maná al 100%. `Z: lógica`.

## E7 — Clases y armas
- [ ] **E7.1** 4 clases-rol (Tanque, Carry, Especialista, Heal) con Q/R propios; el Heal aporta soporte de party. `Z: lógica`.
- [ ] **E7.2** Set inicial de armas con LMB/RMB únicos por arma (base ya existe; ampliar y balancear). `Z: lógica`.
- [ ] **E7.3** Slots de equipo cabeza/pecho/pies/manos + offhand (escudo/runa); 2H ocupa offhand. `Z: lógica`.

## E8 — Re-tematización insecto (VISUAL)
- [ ] **E8.1** Modelos de personajes-insecto por clase (respetando rutas de nodo `Visual`, `handslot`, etc.). `Z: visual`.
- [ ] **E8.2** Enemigos infectados (modelos + animaciones). `Z: visual`.
- [ ] **E8.3** Boss de área. `Z: visual`.
- [ ] **E8.4** Ambientes de ciudad subterránea. `Z: visual`.
- [ ] **E8.5** Íconos de ítems (campo `ItemBase.icon` ya listo). `Z: visual`.

## E9 — Steam / consola (capa final)
- [ ] **E9.1** Integrar GodotSteam (logros, Cloud, stats). `Z: lógica`.
- [ ] **E9.2** Steam Deck: escalar UI legible, glifos de mando, verificar arranque. `Z: lógica`+`visual`.
- [ ] **E9.3** Contactar porting partner para consola; desacoplar save/input de gameplay. `Z: lógica`.

---

## 💡 Ideas (sin comprometer — mover a épica cuando se decidan)
- Sonido y música (pendiente grande, se aborda más adelante a propósito).
- Shaders PSX (dithering/vertex snap) para el look retro.
- Modelo propio para el boss (hoy: esfera dorada con corona).
- Persistencia de récords (oleada máxima) y meta-progresión.
- Mascotas/símbolos de facción; misiones secundarias por colonia.
- Modo "juego solo con bots" si el co-op queda grande (GDD §11).
- Loot corrupto: ítems mejores pero con maldición ligada a la Corrupción.
- Eventos de mundo: brotes de infección temporales en zonas ya limpiadas.

## Decisiones abiertas (bloquean tareas — resolver con el dueño)
- Tamaño de party (¿2 o 4?) → bloquea E1.5.
- Loot compartido vs instanciado por jugador → bloquea E1.7.
- ¿Corrupción por-jugador o de party? → afecta E2.1.
