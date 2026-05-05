-- =====================================================
-- yc-robberies | client/main.lua
-- Targets, animaciones, minijuego.
-- Sin estado persistente: la fuente de verdad es el server.
--
-- Flujo (anti-trampa):
--   1) canStart            -> server emite token de un solo uso.
--   2) minigame (qb-minigames).
--   3) finishRegister/Safe -> server consume token, revalida y paga.
--      Si el cliente intenta TriggerServerEvent directo sin token, no pasa.
-- =====================================================

local activeVitrineTargets = {}  -- [storeId] = { targetName, ... }
local activeSafeTargets = {}     -- [storeId] = targetName
local registerTargets = {}       -- ids de targets de cajas registradoras
local busy = false               -- bloqueo local anti-spam de UI

-- Indice O(1) para Config.Stores. Tambien defensivo contra ids duplicados/missing.
local StoreById = {}
for _, store in ipairs(Config.Stores) do
    if store.id and not StoreById[store.id] then
        store.vitrines = store.vitrines or {}
        StoreById[store.id] = store
    end
end

-- ----------------------------------------------------
-- Helpers
-- ----------------------------------------------------

local function FindStoreById(storeId)
    return StoreById[storeId]
end

-- Ejecuta la barra de progreso con animacion. Devuelve true si completo, false si cancelo.
local function PlayAnim(animCfg)
    local completed = lib.progressBar({
        duration = animCfg.duration,
        label = animCfg.label,
        useWhileDead = animCfg.useWhileDead,
        canCancel = animCfg.canCancel,
        disable = animCfg.disableControls,
        anim = {
            dict = animCfg.dict,
            clip = animCfg.name,
            flag = animCfg.flag or 49
        }
    })
    -- cache.ped puede ser 0 si el ped no esta listo (respawn, transicion).
    -- ClearPedTasks(0) tira un warning innecesario en consola.
    local ped = cache.ped
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end
    return completed
end

-- Bloque busy seguro: garantiza liberacion incluso ante errores.
local function withBusy(fn)
    if busy then return end
    busy = true
    local ok, err = pcall(fn)
    busy = false
    if not ok then
        print('^1[yc-robberies] error en flujo:^7', err)
    end
end

-- ----------------------------------------------------
-- Vitrinas: crear / quitar targets dinamicos
-- ----------------------------------------------------

local function CreateVitrineTargets(storeId)
    local store = FindStoreById(storeId)
    if not store then return end
    if activeVitrineTargets[storeId] then return end

    activeVitrineTargets[storeId] = {}

    for vIndex, v in ipairs(store.vitrines) do
        local targetId = ('yc-rob-vit-%s-%d'):format(storeId, vIndex)
        exports.ox_target:addBoxZone({
            coords = v.coords,
            size = vec3(1.2, 1.2, 1.6),
            rotation = v.heading or 0.0,
            debug = Config.Debug,
            name = targetId,
            options = {
                {
                    name = targetId .. ':loot',
                    icon = 'fa-solid fa-box-open',
                    label = 'Robar vitrina',
                    distance = 2.0,
                    onSelect = function()
                        TriggerEvent('yc-robberies:client:lootVitrine', storeId, vIndex)
                    end
                }
            }
        })
        activeVitrineTargets[storeId][#activeVitrineTargets[storeId] + 1] = targetId
    end
end

local function RemoveVitrineTargets(storeId)
    local list = activeVitrineTargets[storeId]
    if not list then return end
    for _, name in ipairs(list) do
        exports.ox_target:removeZone(name)
    end
    activeVitrineTargets[storeId] = nil
end

-- ----------------------------------------------------
-- Caja fuerte: target dinamico (solo aparece tras forzar la registradora)
-- ----------------------------------------------------

local function CreateSafeTarget(storeId)
    local store = FindStoreById(storeId)
    if not store or not store.safe then return end
    if activeSafeTargets[storeId] then return end

    local zoneName = ('yc-rob-safe-%s'):format(storeId)
    exports.ox_target:addBoxZone({
        coords = store.safe.coords,
        size = vec3(1.0, 1.0, 1.5),
        rotation = store.safe.heading or 0.0,
        debug = Config.Debug,
        name = zoneName,
        options = {
            {
                name = zoneName .. ':drill',
                icon = 'fa-solid fa-screwdriver-wrench',
                label = 'Forzar caja fuerte',
                distance = 2.0,
                items = Config.RequiredItemSafe,
                onSelect = function()
                    TriggerEvent('yc-robberies:client:tryRobSafe', storeId)
                end
            }
        }
    })
    activeSafeTargets[storeId] = zoneName
end

local function RemoveSafeTarget(storeId)
    local name = activeSafeTargets[storeId]
    if not name then return end
    exports.ox_target:removeZone(name)
    activeSafeTargets[storeId] = nil
end

-- ----------------------------------------------------
-- Targets de cajas registradoras (siempre presentes)
-- ----------------------------------------------------

local function CreateRegisterTargets()
    for _, store in pairs(StoreById) do
        local zoneName = ('yc-rob-reg-%s'):format(store.id)
        exports.ox_target:addBoxZone({
            coords = store.register.coords,
            size = vec3(1.0, 1.0, 1.5),
            rotation = store.register.heading or 0.0,
            debug = Config.Debug,
            name = zoneName,
            options = {
                {
                    name = zoneName .. ':rob',
                    icon = 'fa-solid fa-cash-register',
                    label = ('Forzar caja (%s)'):format(store.name),
                    distance = 2.0,
                    items = Config.RequiredItem,
                    onSelect = function()
                        TriggerEvent('yc-robberies:client:tryRobRegister', store.id)
                    end
                }
            }
        })
        registerTargets[#registerTargets + 1] = zoneName
    end
end

local function RemoveAllTargets()
    for _, name in ipairs(registerTargets) do
        exports.ox_target:removeZone(name)
    end
    registerTargets = {}
    for storeId in pairs(activeVitrineTargets) do
        RemoveVitrineTargets(storeId)
    end
    for storeId in pairs(activeSafeTargets) do
        RemoveSafeTarget(storeId)
    end
end

-- ----------------------------------------------------
-- Flujo: forzar caja registradora
-- ----------------------------------------------------

RegisterNetEvent('yc-robberies:client:tryRobRegister', function(storeId)
    withBusy(function()
        -- 1) canStart -> token
        local ok, payload = lib.callback.await('yc-robberies:server:canStart', false, storeId)
        if not ok then
            if payload then lib.notify({ type = 'error', description = payload }) end
            return
        end
        local token = payload

        -- 2) Minijuego. qb-minigames Lockpick espera un NUMERO de pins (no un string).
        local pins = (Config.LockpickPins or {})[Config.MinigameDifficulty] or 3
        local result = exports['qb-minigames']:Lockpick(pins)
        local success = result == true

        -- 3) Animacion solo si tuvo exito (mejor UX). Si fallo, vamos directo al server.
        if success then
            -- Si el jugador cancela la animacion, no consideramos exito.
            success = PlayAnim(Config.RegisterAnim) == true
        end

        -- 4) Notificamos resultado al server (consume token + revalidacion + pago atomico)
        local paid = lib.callback.await(
            'yc-robberies:server:finishRegister', false, storeId, token, success
        )

        if not success then
            lib.notify({ type = 'error', description = 'Se rompio el lockpick.' })
            return
        end

        if paid then
            lib.notify({ type = 'success', description = 'Caja registradora forzada.' })
        else
            -- El server rechazo (cooldown, validacion fallida, race perdida, etc.)
            lib.notify({ type = 'error', description = 'No se pudo completar el robo.' })
        end
    end)
end)

-- ----------------------------------------------------
-- Flujo: forzar caja fuerte (taladro)
-- ----------------------------------------------------

RegisterNetEvent('yc-robberies:client:tryRobSafe', function(storeId)
    withBusy(function()
        local ok, payload = lib.callback.await('yc-robberies:server:canStartSafe', false, storeId)
        if not ok then
            if payload then lib.notify({ type = 'error', description = payload }) end
            return
        end
        local token = payload

        -- qb-minigames KeyMinigame devuelve una TABLA { quit, faults }, no un boolean.
        -- Una tabla siempre es truthy en Lua, asi que NO podemos usar 'if result then'.
        -- Exito = el jugador no cerro con ESC y los fallos no superan el limite.
        local result = exports['qb-minigames']:KeyMinigame(Config.SafeMinigame.keys)
        local maxFaults = Config.SafeMinigame.maxFaults or 0
        local success = type(result) == 'table'
            and result.quit ~= true
            and (tonumber(result.faults) or 0) <= maxFaults

        if success then
            success = PlayAnim(Config.SafeAnim) == true
        end

        local paid = lib.callback.await(
            'yc-robberies:server:finishSafe', false, storeId, token, success
        )

        if not success then
            lib.notify({ type = 'error', description = 'Fallaste el minijuego. Se rompio la broca.' })
            return
        end

        if paid then
            lib.notify({ type = 'success', description = 'Caja fuerte abierta.' })
        else
            lib.notify({ type = 'error', description = 'No se pudo abrir la caja fuerte.' })
        end
    end)
end)

-- ----------------------------------------------------
-- Flujo: robar vitrina
-- ----------------------------------------------------

RegisterNetEvent('yc-robberies:client:lootVitrine', function(storeId, vIndex)
    withBusy(function()
        if not PlayAnim(Config.VitrineAnim) then return end

        local got, reason = lib.callback.await(
            'yc-robberies:server:lootVitrine', false, storeId, vIndex
        )
        if reason == 'already_looted' then
            lib.notify({ type = 'inform', description = 'Esta vitrina ya fue saqueada.' })
        elseif got then
            lib.notify({ type = 'success', description = 'Conseguiste algo de la vitrina.' })
        else
            lib.notify({ type = 'inform', description = 'La vitrina estaba vacia.' })
        end
    end)
end)

-- ----------------------------------------------------
-- Sync con server
-- ----------------------------------------------------

RegisterNetEvent('yc-robberies:client:activateVitrines', function(storeId)
    CreateVitrineTargets(storeId)
    CreateSafeTarget(storeId)
end)

RegisterNetEvent('yc-robberies:client:deactivateVitrines', function(storeId)
    RemoveVitrineTargets(storeId)
    RemoveSafeTarget(storeId)
end)

-- ----------------------------------------------------
-- Init / cleanup
-- ----------------------------------------------------

local function Init()
    CreateRegisterTargets()

    -- Sync inicial: si hay vitrinas activas en DB (caso reconnect), las creamos.
    local activeIds = lib.callback.await('yc-robberies:server:getActiveVitrines', false) or {}
    for _, sid in ipairs(activeIds) do
        CreateVitrineTargets(sid)
        CreateSafeTarget(sid)
    end
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Init()
end)

AddEventHandler('onClientResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    RemoveAllTargets()
end)
