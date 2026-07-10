# Sync pendiente al vault de Obsidian

Este archivo es temporal. Se generó en una sesión remota (sin acceso a
`D:\Obsidian\godot-game`) que implementó **E1.1** y no pudo escribir en
`spec/TODO.md` / `spec/CHANGELOG.md` porque son symlinks al vault.

Corré la sesión local (la que sí tiene el vault montado) con el prompt de
abajo para que aplique estos cambios y borre este archivo.

## 1. TODO.md — marcar E1.1 hecha

Buscar la línea:
```
- [ ] **E1.1** Elegir e integrar transporte (`SteamMultiplayerPeer` vía GodotSteam; `ENet` para local). `Z: lógica`.
```
Reemplazar por:
```
- [x] **E1.1** Elegir e integrar transporte (`SteamMultiplayerPeer` vía GodotSteam; `ENet` para local). `Z: lógica`. Hecho: autoload `Net` (ENet local); Steam pendiente de instalar addon GodotSteam.
```

## 2. CHANGELOG.md — nueva entrada (arriba del todo)

```
## 2026-07-10 — Claude — E1.1
- Autoload `Net` (`scripts/core/net.gd`): `host_game`/`join_game`/`close_connection`
  sobre `ENetMultiplayerPeer` + señales de conexión/desconexión de peers.
- Transporte Steam (`SteamMultiplayerPeer`) queda como swap aislado en
  `Net._create_steam_peer()`, pendiente de instalar `addons/godotsteam`.
- Registrado en `project.godot [autoload]`.
- Zonas: lógica. Validación: no corrida en la sesión remota (sin binario de
  Godot); falta correr los 3 smokes headless localmente antes de dar por
  cerrada la tarea.
- Archivos: `scripts/core/net.gd` (nuevo), `project.godot`. Commit `4d45d80`
  en `claude/soec-docs-aly86g`.
```

## 3. Borrar este archivo

Una vez aplicado lo anterior en el vault, borrar `OBSIDIAN_SYNC_PENDING.md`
del repo (no debe quedar mergeado a main).
