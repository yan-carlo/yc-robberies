# yc-robberies

Sistema de robos a tiendas/licorerias para FiveM con estado **solo en base de datos**
(se borra al reiniciar el recurso/servidor).

## Dependencias

- ox_lib
- ox_inventory
- ox_target
- origen_police
- qb-minigames
- qb-core
- oxmysql

## Instalacion

1. Coloca el recurso en tu carpeta `resources/[creados]/yc-robberies`.
2. Importa `sql/install.sql` en tu base de datos (o deja que la
   funcion `DB.EnsureSchema` la cree al iniciar; el recurso hace DROP+CREATE).
3. Anade `ensure yc-robberies` en tu `server.cfg` despues de las dependencias.
4. Ajusta `config.lua` (locales, recompensas, items, animaciones).

## Flujo

1. El jugador apunta `ox_target` a la caja registradora (requiere `lockpick`).
2. El servidor valida item, distancia, cooldown DB, policias minimos, y emite
   un **token de un solo uso** (anti-bypass del minijuego).
3. Se envia alerta inicial a `origen_police` (rate-limitada).
4. Se ejecuta `qb-minigames:Lockpick`.
5. Se reporta el resultado al servidor con el token.
   - Si fallo -> server consume token y descuenta 1 lockpick.
   - Si exito -> server revalida TODO, hace claim atomico (no race conditions),
     paga, marca DB y activa vitrinas en clientes. Segunda alerta a la policia.
6. La caja fuerte (opcional) se desbloquea al forzar la registradora y sigue
   el mismo patron canStart -> minijuego -> finishSafe (token).
7. Las vitrinas dan items con probabilidad y son de un solo uso por ciclo
   (claim atomico). Cuando se vacian todas (y la caja fuerte tambien si existe),
   las vitrinas se desactivan automaticamente.

## Anti-trampa / Seguridad

- Tokens de sesion de un solo uso para los minijuegos: el cliente no puede
  llamar al "exito" sin haber pasado por `canStart`.
- Revalidacion completa server-side antes de pagar (item, distancia, policias,
  cooldown).
- Claims atomicos a nivel SQL para registradora, caja fuerte y cada vitrina:
  imposible que dos jugadores cobren el mismo robo.
- `os.time()` y `cooldown` controlados solo en server.
- Anti-spam por jugador (`Config.AntiSpamCooldown`).
- Cache de policias en servicio (TTL 5s) para alta concurrencia.

## Estado en DB

Tabla `yc_robberies_active`:

| Columna          | Tipo            | Descripcion                                |
|------------------|-----------------|--------------------------------------------|
| store_id         | VARCHAR(60) PK  | id del local en `Config.Stores`            |
| last_robbed      | BIGINT          | timestamp `os.time()` del ultimo robo      |
| robbed_by        | VARCHAR(60)     | citizenid del jugador (fallback license)   |
| vitrines_active  | TINYINT(1)      | 1 = vitrinas/caja fuerte disponibles       |
| alert_sent_at    | BIGINT          | timestamp de la ultima alerta inicial      |
| safe_robbed      | TINYINT(1)      | 1 = caja fuerte ya vaciada en este ciclo   |

Tabla `yc_robberies_looted`:

| Columna       | Tipo        | Descripcion                          |
|---------------|-------------|--------------------------------------|
| store_id      | VARCHAR(60) | FK -> yc_robberies_active            |
| vitrine_index | INT         | indice de vitrina en `Config.Stores` |

`onResourceStart` ejecuta `DROP+CREATE` -> nada persiste tras reiniciar.

## Anadir un local

Edita `config.lua` y duplica una entrada de `Config.Stores`. El `id` debe ser unico.
Si tiene `safe`, se habilitara automaticamente al forzar la registradora.
