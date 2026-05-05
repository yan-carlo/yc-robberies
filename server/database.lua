-- =====================================================
-- yc-robberies | server/database.lua
-- Capa de acceso a datos. Todo el estado vive en MySQL.
-- Schema normalizado: una fila por store en yc_robberies_active,
-- y una fila por (store, vitrina) saqueada en yc_robberies_looted.
-- Esto permite "claims" atomicos via INSERT IGNORE / UPDATE condicional,
-- evitando race conditions entre jugadores simultaneos.
-- =====================================================

DB = {}

-- Recrea las tablas con el schema actual.
-- Como onResourceStart wipea, hacemos DROP+CREATE para asegurar columnas.
function DB.EnsureSchema()
    MySQL.query.await('DROP TABLE IF EXISTS `yc_robberies_looted`')
    MySQL.query.await('DROP TABLE IF EXISTS `yc_robberies_active`')

    MySQL.query.await([[
        CREATE TABLE `yc_robberies_active` (
            `store_id` VARCHAR(60) NOT NULL,
            `last_robbed` BIGINT NOT NULL DEFAULT 0,
            `robbed_by` VARCHAR(60) DEFAULT NULL,
            `vitrines_active` TINYINT(1) NOT NULL DEFAULT 0,
            `alert_sent_at` BIGINT NOT NULL DEFAULT 0,
            `safe_robbed` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`store_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE `yc_robberies_looted` (
            `store_id` VARCHAR(60) NOT NULL,
            `vitrine_index` INT NOT NULL,
            PRIMARY KEY (`store_id`, `vitrine_index`),
            CONSTRAINT `fk_yc_looted_store` FOREIGN KEY (`store_id`)
                REFERENCES `yc_robberies_active` (`store_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

-- Devuelve la fila de un store (o nil si no existe).
function DB.GetStore(storeId)
    return MySQL.single.await(
        'SELECT store_id, last_robbed, robbed_by, vitrines_active, alert_sent_at, safe_robbed FROM yc_robberies_active WHERE store_id = ?',
        { storeId }
    )
end

-- Marca una caja como robada de forma ATOMICA.
-- Estrategia en dos pasos para evitar el problema de evaluacion left-to-right
-- de MySQL en ON DUPLICATE KEY UPDATE (donde las columnas ya actualizadas
-- afectan condiciones posteriores):
--   1) UPDATE condicional: solo escribe si la fila existe y el cooldown expiro.
--   2) INSERT IGNORE: solo entra si la fila no existia.
-- Devuelve true si este intento gano el claim (debe pagarse).
function DB.TryClaimRobbery(storeId, identifier, timestamp, cooldownSecs)
    -- 1) Caso normal: la fila ya existe (MarkAlertSent la creo en canStart).
    --    El WHERE garantiza que solo el primero que llega tras el cooldown gana.
    local updated = MySQL.update.await([[
        UPDATE yc_robberies_active
        SET last_robbed = ?, robbed_by = ?, vitrines_active = 1,
            alert_sent_at = 0, safe_robbed = 0
        WHERE store_id = ? AND (? - last_robbed) >= ?
    ]], { timestamp, identifier, storeId, timestamp, cooldownSecs }) or 0

    if updated > 0 then return true end

    -- 2) La fila no existia o el cooldown sigue vigente. INSERT IGNORE solo
    --    entra si no hay fila; si ya hay (cooldown vigente), ignora -> 0 affected.
    local inserted = MySQL.update.await([[
        INSERT IGNORE INTO yc_robberies_active
            (store_id, last_robbed, robbed_by, vitrines_active, alert_sent_at, safe_robbed)
        VALUES (?, ?, ?, 1, 0, 0)
    ]], { storeId, timestamp, identifier }) or 0

    return inserted > 0
end

-- Cuando se reclama una caja, las vitrinas saqueadas previas deben limpiarse.
function DB.ResetLootedForStore(storeId)
    MySQL.query.await('DELETE FROM yc_robberies_looted WHERE store_id = ?', { storeId })
end

-- Marca la caja fuerte como ya robada en este ciclo. Atomico: solo gana si estaba en 0.
function DB.TryClaimSafe(storeId)
    local affected = MySQL.update.await(
        'UPDATE yc_robberies_active SET safe_robbed = 1 WHERE store_id = ? AND vitrines_active = 1 AND safe_robbed = 0',
        { storeId }
    ) or 0
    return affected > 0
end

-- Reclama una vitrina puntual (atomico). true si esta sesion la gano, false si ya estaba.
function DB.TryClaimVitrine(storeId, vIndex)
    local affected = MySQL.update.await(
        'INSERT IGNORE INTO yc_robberies_looted (store_id, vitrine_index) VALUES (?, ?)',
        { storeId, vIndex }
    ) or 0
    return affected > 0
end

-- Cuenta de vitrinas saqueadas para un store (para saber si ya se vacio el local).
function DB.CountLooted(storeId)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM yc_robberies_looted WHERE store_id = ?',
        { storeId }
    ) or 0
end

-- Marca que ya se envio la alerta inicial para este store.
-- Asi solo suena una vez aunque el jugador falle el lockpick muchas veces.
function DB.MarkAlertSent(storeId, timestamp)
    MySQL.query.await([[
        INSERT INTO yc_robberies_active (store_id, last_robbed, robbed_by, vitrines_active, alert_sent_at)
        VALUES (?, 0, NULL, 0, ?)
        ON DUPLICATE KEY UPDATE alert_sent_at = VALUES(alert_sent_at)
    ]], { storeId, timestamp })
end

-- Desactiva las vitrinas (cuando se vacian todas o pasa el cooldown).
function DB.DisableVitrines(storeId)
    MySQL.query.await(
        'UPDATE yc_robberies_active SET vitrines_active = 0 WHERE store_id = ?',
        { storeId }
    )
end

-- Devuelve todos los stores con vitrinas activas (para sync inicial al cliente).
function DB.GetActiveVitrines()
    return MySQL.query.await(
        'SELECT store_id FROM yc_robberies_active WHERE vitrines_active = 1'
    ) or {}
end

-- Devuelve stores con vitrinas activas y su last_robbed (para limpieza periodica
-- de cooldowns expirados).
function DB.GetActiveStoresWithTimestamp()
    return MySQL.query.await(
        'SELECT store_id, last_robbed FROM yc_robberies_active WHERE vitrines_active = 1 AND last_robbed > 0'
    ) or {}
end
