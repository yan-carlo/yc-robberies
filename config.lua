Config = {}

-- =====================================================
-- CONFIGURACION GENERAL
-- =====================================================
Config.Debug = false                    -- Activa prints de depuracion
Config.RequiredItem = 'lockpick'        -- Item necesario para robar la caja registradora
Config.RequiredItemSafe = 'drill'       -- Item necesario para robar la caja fuerte
Config.MinPolice = 0                    -- Policias minimos en servicio
Config.PoliceJobs = { 'police', 'lspd', 'bcso', 'sasp' } -- Trabajos considerados policia
Config.MinigameDifficulty = 'easy'      -- Dificultad del lockpick: easy / medium / hard
-- Mapeo dificultad -> nº de pins. qb-minigames Lockpick espera un NUMERO de pins.
Config.LockpickPins = { easy = 3, medium = 5, hard = 7 }
Config.SafeMinigame = {                 -- Parametros del KeyMinigame (caja fuerte)
    keys = 5,                           -- numero de teclas que hay que presionar
    maxFaults = 0                       -- fallos permitidos para considerar exito (0 = perfecto)
}
Config.RewardItem = 'cash'              -- Item de dinero en ox_inventory ('money' / 'cash' / 'black_money')
Config.AntiSpamCooldown = 3000          -- ms minimos entre interacciones del mismo jugador
Config.MaxInteractDistance = 3.0        -- Distancia maxima jugador <-> caja para validar en server
Config.AlertCooldown = 300              -- segundos durante los que NO se reenvia la alerta inicial al mismo store

-- =====================================================
-- ANIMACIONES
-- =====================================================
Config.RegisterAnim = {
    dict = 'mini@repair',
    name = 'fixing_a_player',
    duration = 8000,
    flag = 49,
    label = 'Robando caja registradora...',
    useWhileDead = false,
    canCancel = false,
    disableControls = { move = true, combat = true }
}

Config.VitrineAnim = {
    dict = 'anim@heists@ornate_bank@grab_cash',
    name = 'grab',
    duration = 4000,
    flag = 49,
    label = 'Robando vitrina...',
    useWhileDead = false,
    canCancel = false,
    disableControls = { move = true, combat = true }
}

Config.SafeAnim = {
    dict = 'anim@heists@fleeca_bank@drilling',
    name = 'drill_straight_idle',
    duration = 12000,
    flag = 49,
    label = 'Forzando caja fuerte...',
    useWhileDead = false,
    canCancel = false,
    disableControls = { move = true, combat = true }
}

-- =====================================================
-- ALERTAS A POLICIA (origen_police)
-- Firma oficial: coords, title, type (GENERAL/RADARS/215/DRUGS/FORCE/48X),
-- message, job, metadata.
-- =====================================================
Config.PoliceAlertJob = 'police' -- grupo/job que recibe la alerta

Config.PoliceAlerts = {
    onStart = {
        title = 'Robo en progreso',
        type = 'GENERAL',
        message = 'Un sospechoso esta forzando una caja registradora.'
    },
    onSuccess = {
        title = 'CAJA FORZADA',
        type = '215',
        message = 'Caja registradora forzada. Sospechoso posiblemente armado en escena.'
    }
    -- onSafe eliminado: el robo de la caja fuerte es silencioso (no alerta a la policia).
}

-- =====================================================
-- LOCALES (TIENDAS, LICORERIAS, ETC.)
-- =====================================================
Config.Stores = {

    -----------------------------------------------------
    -- 1) 24/7 INNOCENCE BLVD
    -----------------------------------------------------
    {
        id = 'store_innocence',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(373.29, 326.31, 103.78),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(378.21, 333.69, 103.01),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(379.87, 329.35, 103.88),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(381.38, 328.98, 103.9),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(382.87, 328.6, 103.91),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_mirror',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(1164.26, -322.89, 69.38),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(1159.21, -314.1, 68.65),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(1157.4, -319.16, 69.59),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(1154.39, -319.69, 69.56),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1152.19, -322.8, 69.52),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1152.19, -322.8, 69.52),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_central',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(-706.6, -913.69, 19.39),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(-710.03, -904.17, 18.65),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(-712.7, -908.83, 19.56),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(-715.75, -908.83, 19.59),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-718.46, -911.52, 19.6),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-718.46, -914.57, 19.57),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_grove',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(-47.17, -1757.7, 29.6),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(-43.68, -1748.19, 28.86),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(-48.71, -1750.06, 29.76),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(-51.05, -1748.1, 29.76),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-54.86, -1748.4, 29.76),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-56.83, -1750.75, 29.76),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_rockford_drive',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(-1820.41, 793.86, 138.27),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(-1829.42, 798.55, 137.64),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(-1828.21, 793.31, 138.58),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(-1830.45, 791.26, 138.65),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-1830.64, 787.44, 138.68),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-1828.59, 785.19, 138.65),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_freeway',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(2557.21, 381.25, 108.8),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(2548.93, 384.86, 108.06),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(2552.84, 387.37, 108.98),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(2552.96, 390.47, 108.98),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(2555.45, 390.48, 108.96),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(2558.56, 390.36, 108.97),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_route68',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(548.64, 2671.26, 42.33),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(546.49, 2662.49, 41.61),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(543.36, 2665.92, 42.51),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(540.27, 2665.51, 42.52),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(539.84, 2667.97, 42.5),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(539.44, 2671.03, 42.54),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_sandy',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(1960.45, 3740.25, 32.52),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(1959.09, 3749.17, 31.78),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(1963.3, 3747.21, 32.7),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(1965.97, 3748.75, 32.7),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1967.32, 3746.67, 32.69),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1968.88, 3743.97, 32.71),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_megamall',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(2678.22, 3279.79, 55.42),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(2672.48, 3286.75, 54.68),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(2677.1, 3287.23, 55.6),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(2678.61, 3289.93, 55.6),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(2680.83, 3288.83, 55.6),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(2683.55, 3287.31, 55.59),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_paleto',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(1728.28, 6415.04, 35.22),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(1734.92, 6421.13, 34.47),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(1735.63, 6416.54, 35.4),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(1738.41, 6415.16, 35.4),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1737.4, 6412.88, 35.39),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(1736.02, 6410.11, 35.4),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_barbareno',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(-3242.26, 1000.43, 13.01),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(-3250.35, 1004.4, 12.27),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(-3246.33, 1006.73, 13.17),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(-3246.07, 1009.81, 13.17),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-3243.59, 1009.72, 13.18),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-3240.48, 1009.45, 13.19),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    },

    {
        id = 'badulaque_inseno',
        name = '24/7 Alerta',
        cooldown = 15, -- minutos
        reward = { min = 100, max = 500 },

        register = {
            coords = vector3(-3039.11, 584.96, 8.09),
            heading = 259.6765
        },

        -- Caja fuerte (opcional). Solo aparece despues de robar la registradora.
        -- Da DINERO directo (no items). Requiere Config.RequiredItemSafe (drill).
        safe = {
            coords = vector3(-3048.13, 585.5, 7.36),
            heading = 259.0,
            reward = { min = 800, max = 1500 },
        },

        vitrines = {
            {
                coords = vector3(-3045.32, 589.2, 8.26),
                heading = 0.0,
                items = {
                    { name = 'water',     min = 1, max = 3, chance = 100 },
                    { name = 'sandwich',  min = 1, max = 2, chance = 60 },
                    { name = 'phone',     min = 1, max = 1, chance = 15 }
                }
            },
            {
                coords = vector3(-3046.27, 592.15, 8.26),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-3043.93, 593.01, 8.26),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            },
            {
                coords = vector3(-3040.97, 593.96, 8.26),
                heading = 0.0,
                items = {
                    { name = 'cola',      min = 1, max = 4, chance = 75 },
                    { name = 'sprunk',     min = 1, max = 3, chance = 70 },
                    { name = 'lockpick',  min = 1, max = 1, chance = 20 }
                }
            }
        }
    }
}
