-- yc-robberies | schema
-- Nota: el recurso ejecuta DROP+CREATE al iniciar (TRUNCATE filosofico),
-- asi que este SQL es solo para instalacion manual / referencia.

CREATE TABLE IF NOT EXISTS `yc_robberies_active` (
    `store_id` VARCHAR(60) NOT NULL,
    `last_robbed` BIGINT NOT NULL DEFAULT 0,
    `robbed_by` VARCHAR(60) DEFAULT NULL,
    `vitrines_active` TINYINT(1) NOT NULL DEFAULT 0,
    `alert_sent_at` BIGINT NOT NULL DEFAULT 0,
    `safe_robbed` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `yc_robberies_looted` (
    `store_id` VARCHAR(60) NOT NULL,
    `vitrine_index` INT NOT NULL,
    PRIMARY KEY (`store_id`, `vitrine_index`),
    CONSTRAINT `fk_yc_looted_store` FOREIGN KEY (`store_id`)
        REFERENCES `yc_robberies_active` (`store_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
