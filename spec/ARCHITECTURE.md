# ARQUITECTURA — revisión y estándares (Steam / consola)

> Estado técnico y el camino de "prototipo" a "producto vendible". Complementa `IMPLEMENTED_FEATURES.md` (qué existe) y `spec/GDD.md` (qué se quiere).

## 1. Stack actual
- **Motor:** Godot 4.4 (Forward+). GDScript.
- **Autoloads (servicios):** `Game` (clases/kit), `FX` (números de daño, partículas, shake), `LootDB`/`Loot` (contenido de loot), `SceneManager` (transiciones).
- **Patrón:** escenas = vistas, autoloads = servicios, contenido de loot **hardcodeado por código** (pendiente → Resources).
- **Tests:** 3 smoke tests headless (`LootSmoke`, `KitSmoke`, `HitSmoke`).

## 2. 🔴 El cambio estructural más grande: CO-OP / networking
El prototipo es **100% single-player**. Convertirlo a cooperativo es el mayor riesgo y hay que abordarlo **temprano** (retrofitear red al final es carísimo).

**Recomendación de arquitectura de red:**
- **Transporte:** para Steam, usar **`SteamMultiplayerPeer`** (GodotSteam) → P2P/relay de Steam (sin abrir puertos, con lobbies). Para pruebas locales, `ENetMultiplayerPeer` sirve.
- **Autoridad:** **host-authoritative** (el host simula enemigos, loot, corrupción; los clientes envían input y reciben estado). Simple y suficiente para co-op cooperativo (no PvP competitivo).
- **Replicación:** `MultiplayerSpawner` (enemigos, drops, proyectiles) + `MultiplayerSynchronizer` (posición/estado de players y enemigos).
- **Refactor obligatorio en la lógica actual:**
  - Eliminar la suposición "un solo player": hoy hay muchos `get_first_node_in_group("player")`. Enemigos deben **elegir el player más cercano** de una **lista**; supers/curas deben resolver "¿qué player?".
  - La cámara, el HUD, el inventario y la corrupción pasan a ser **por-jugador (local)**.
  - El loot: decidir **instanciado por jugador** (cada uno ve el suyo) vs **compartido** (§ GDD abierto).
- **Regla:** todo lo nuevo se escribe **network-aware desde el día 1** (usar grupos/listas, no singletons de "el player").

## 3. De prototipo a producto (deuda a saldar)
| Área | Hoy | Objetivo comercial |
|------|-----|--------------------|
| **Contenido de loot** | arrays hardcodeados en `loot_database.gd` | **Resources `.tres`** en `resources/` (data-driven, editable sin código) |
| **Guardado** | ❌ no existe | Sistema de **save/load** robusto + versionado; Steam Cloud |
| **Opciones** | ❌ solo panel de pausa base | Menú de opciones (volumen, resolución, controles remapeables) |
| **Localización** | strings en español hardcodeados | **String tables** (mín. EN+ES); nada de texto hardcodeado en UI |
| **Input** | mando + teclado fijos | **Remapeable** (Steam Input / `InputMap` en runtime) |
| **Resolución** | 854×480 viewport stretch (estético) | Escalar limpio a 1080p/4K, soportar ultrawide, safe zones (TV) |
| **CI** | smokes manuales | CI (GitHub Actions) que corre los smokes en cada push |
| **Arquitectura de datos** | ok para prototipo | Capa de servicios clara: `Save`, `Audio`, `Settings`, `Net` como autoloads |

## 4. Estándares de Steam
- **Steamworks vía GodotSteam** (GDExtension): logros, **Steam Cloud** (saves), **P2P networking**, rich presence, stats.
- **Steam Deck "Verified":** input de mando completo (✔ ya), **texto legible** (el 854×480 debe escalar), sin launcher externo, arranque directo, glifos de botón correctos.
- **Input:** soporte de mando completo + remapeo; detectar tipo de mando para mostrar glifos correctos.
- **Cloud saves**, múltiples resoluciones, pausa al perder foco.

## 5. Estándares de consola (⚠️ realidad dura)
- **Godot NO tiene export oficial de consola.** Nintendo/PlayStation/Xbox requieren SDKs bajo NDA. Necesitas un **porting partner** (ej. *Lone Wolf Technology*, *Pineapple Works*) que porta Godot a consola. Presupuéstalo desde ya.
- **Certificación (TRC/TCR/lotcheck):** suspend/resume correcto, **pausa automática al desconectar el mando**, manejo de cuentas/guardado por API de la consola, **cero assets placeholder**, mensajes de error según estándar, localización requerida.
- Diseñar el guardado y el input **desacoplados** para que el porting partner los conecte a las APIs de consola sin reescribir gameplay.

## 6. Orden recomendado (por qué)
1. **Fundaciones técnicas** (save, settings, data-driven Resources, CI) — todo lo demás se apoya aquí.
2. **Networking/co-op** — cuanto antes, más barato; refactor de "el player".
3. **Corrupción** (mecánica central) — define el bucle.
4. Contenido: combos/tags, armas, ciudades, economía, facciones.
5. Re-tematización insecto (agente visual) en paralelo, respetando contratos de `AGENTS.md`.
6. Steam/consola (Steamworks, Deck, localización, cert) — capa final antes de vender.

Detalle de tareas en `TODO.md`.
