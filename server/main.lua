-- =====================================================
-- yc-robberies | server/main.lua
-- Logica principal del servidor. Todo lo critico se valida aqui.
--
-- Modelo anti-trampa:
--   1) canStart/canStartSafe emite un TOKEN de un solo uso (memoria).
--   2) finishRegister/finishSafe consume el token y revalida TODO
--      (item, distancia, policia, cooldown) antes de pagar.
--      Sin token valido, no hay pago. Sin pasar el minijuego, no hay token consumido.
--   3) MarkRobbed/SafeClaim/VitrineClaim son operaciones atomicas a nivel SQL,
--      asi dos jugadores no pueden cobrar el mismo robo.
-- =====================================================

local ox_inv = exports.ox_inventory
local QBCore = exports['qb-core']:GetCoreObject()

-- Sin un seed explicito, math.random puede producir secuencias deterministas
-- entre reinicios del recurso (y por tanto recompensas repetitivas).
math.randomseed(os.time() + GetGameTimer())

-- ----------------------------------------------------
-- Indices precomputados (O(1) lookups)
-- ----------------------------------------------------
local StoreById = {}
local PoliceJobsSet = {}

local function BuildIndexes()
    StoreById = {}
    for _, store in ipairs(Config.Stores) do
        if not store.id then
            print('^1[yc-robberies] ERROR: store sin id en Config.Stores. Saltando.^7')
        elseif StoreById[store.id] then
            print(('^1[yc-robberies] ERROR: store id duplicado "%s". Solo se usara la primera definicion.^7'):format(store.id))
        else
            -- Normalizamos vitrines para evitar nil checks repartidos por el codigo.
            store.vitrines = store.vitrines or {}
            StoreById[store.id] = store
        end
    end
    PoliceJobsSet = {}
    for _, jobName in ipairs(Config.PoliceJobs or {}) do
        PoliceJobsSet[jobName] = true
    end
end

BuildIndexes()

-- ----------------------------------------------------
-- Helpers
-- ----------------------------------------------------

local function dbg(...)
    if Config.Debug then print('^3[yc-robberies]^7', ...) end
end

local function FindStoreById(storeId)
    return StoreById[storeId]
end

local function FindVitrineByIndex(store, vIndex)
    return store.vitrines and store.vitrines[vIndex] or nil
end

local function GetIdentifier(src)
    -- Preferimos citizenid de QBCore (estable entre sesiones).
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        return Player.PlayerData.citizenid
    end
    -- Fallbacks
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return ('src:%d'):format(src)
end

-- Cache de policias en servicio. TTL corto: barato y suficiente para alertas.
local policeCache = { count = 0, expiresAt = 0 }
local POLICE_CACHE_TTL_MS = 5000

local function CountPolice()
    local now = GetGameTimer()
    if now < policeCache.expiresAt then return policeCache.count end

    local count = 0
    for _, pid in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(pid))
        if Player then
            local job = Player.PlayerData.job
            if job and job.onduty and PoliceJobsSet[job.name] then
                count = count + 1
            end
        end
    end

    policeCache.count = count
    policeCache.expiresAt = now + POLICE_CACHE_TTL_MS
    return count
end

local function GetPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function DistTo(coords, target)
    if not coords or not target then return 9999.0 end
    return #(vector3(coords.x, coords.y, coords.z) - vector3(target.x, target.y, target.z))
end

local function RollChance(chance)
    return math.random(1, 100) <= chance
end

local function RandRange(minV, maxV)
    if minV >= maxV then return minV end
    return math.random(minV, maxV)
end

-- oxmysql convierte TINYINT(1) a boolean, pero por seguridad aceptamos cualquier
-- representacion verdadera.
local function flagTrue(v)
    return v == true or v == 1 or v == '1'
end

-- ----------------------------------------------------
-- Anti-spam por jugador
-- ----------------------------------------------------
local lastInteract = {}

local function CanInteract(src)
    local now = GetGameTimer()
    local last = lastInteract[src] or 0
    if (now - last) < Config.AntiSpamCooldown then return false end
    lastInteract[src] = now
    return true
end

-- ----------------------------------------------------
-- Tokens de sesion (anti-bypass de minijuegos)
-- Cada canStart valido emite un token unico, atado a (src, storeId, kind).
-- finishRegister/finishSafe consume el token (un solo uso) antes de pagar.
-- Sin token valido o tras expirar -> rechazo.
-- ----------------------------------------------------
local activeTokens = {}
local TOKEN_TTL_MS = 60000  -- 60s para terminar el minijuego + animacion

local function genToken()
    return string.format('%08x%08x%08x',
        math.random(0, 2 ^ 31 - 1),
        math.random(0, 2 ^ 31 - 1),
        GetGameTimer()
    )
end

local function IssueToken(src, storeId, kind)
    local token = genToken()
    activeTokens[token] = {
        src = src,
        storeId = storeId,
        kind = kind,
        expiresAt = GetGameTimer() + TOKEN_TTL_MS
    }
    return token
end

local function ConsumeToken(token, src, storeId, kind)
    if type(token) ~= 'string' then return false end
    local t = activeTokens[token]
    if not t then return false end

    -- Validamos identidad ANTES de invalidar el token. Asi un mensaje espurio
    -- con un token ajeno no quema el token del propietario legitimo.
    if t.src ~= src or t.storeId ~= storeId or t.kind ~= kind then
        return false
    end

    -- Token valido para este jugador: lo consumimos (un solo uso) y comprobamos TTL.
    activeTokens[token] = nil
    if GetGameTimer() > t.expiresAt then return false end
    return true
end

-- Limpieza periodica de tokens expirados.
CreateThread(function()
    while true do
        Wait(30000)
        local now = GetGameTimer()
        for token, t in pairs(activeTokens) do
            if now > t.expiresAt then activeTokens[token] = nil end
        end
    end
end)

-- ----------------------------------------------------
-- Cleanup periodico de stores con cooldown expirado.
-- Cuando un jugador fuerza la registradora pero NO saquea las vitrinas/caja
-- fuerte y pasa el tiempo de cooldown, este thread desactiva las vitrinas
-- y notifica a los clientes para que se quiten los targets. Asi el local
-- queda en estado limpio para el siguiente robo.
-- ----------------------------------------------------
local CLEANUP_INTERVAL_MS = 30000  -- 30s

CreateThread(function()
    while true do
        Wait(CLEANUP_INTERVAL_MS)

        local rows = DB.GetActiveStoresWithTimestamp()
        if #rows > 0 then
            local now = os.time()
            for _, row in ipairs(rows) do
                local store = StoreById[row.store_id]
                if store then
                    local elapsed = now - row.last_robbed
                    if elapsed >= store.cooldown * 60 then
                        DB.DisableVitrines(row.store_id)
                        DB.ResetLootedForStore(row.store_id)
                        TriggerClientEvent('yc-robberies:client:deactivateVitrines', -1, row.store_id)
                        dbg(('Cleanup: vitrinas de %s desactivadas (cooldown expirado).'):format(row.store_id))
                    end
                end
            end
        end
    end
end)

-- ----------------------------------------------------
-- Alertas a origen_police (server export)
-- ----------------------------------------------------
local function SendPoliceAlert(coords, alertCfg, storeName)
    local payload = {
        coords  = vector3(coords.x, coords.y, coords.z),
        title   = alertCfg.title,
        type    = alertCfg.type or 'GENERAL',
        message = alertCfg.message,
        job     = Config.PoliceAlertJob or 'police',
        metadata = {
            name = storeName
        }
    }
    local ok, err = pcall(function()
        exports['origen_police']:SendAlert(payload)
    end)
    if not ok then
        dbg('Fallo SendAlert origen_police:', err)
    end
end

-- ----------------------------------------------------
-- Validaciones reutilizables
-- ----------------------------------------------------
local function ValidateRegisterStart(src, store)
    -- Distancia
    local pCoords = GetPlayerCoords(src)
    if DistTo(pCoords, store.register.coords) > Config.MaxInteractDistance then
        return false, 'Estas demasiado lejos.'
    end

    -- Item lockpick
    local count = ox_inv:Search(src, 'count', Config.RequiredItem)
    if not count or count < 1 then
        return false, ('Necesitas un %s.'):format(Config.RequiredItem)
    end

    -- Policias minimos
    local police = CountPolice()
    if police < Config.MinPolice then
        return false, ('No hay suficientes policias en servicio (%d/%d).'):format(police, Config.MinPolice)
    end

    return true
end

local function ValidateSafeStart(src, store)
    if not store.safe then return false, 'Caja fuerte no disponible.' end

    local pCoords = GetPlayerCoords(src)
    if DistTo(pCoords, store.safe.coords) > Config.MaxInteractDistance then
        return false, 'Estas demasiado lejos.'
    end

    local count = ox_inv:Search(src, 'count', Config.RequiredItemSafe)
    if not count or count < 1 then
        return false, ('Necesitas un %s.'):format(Config.RequiredItemSafe)
    end

    return true
end

-- Si se vacio todo el local, desactivamos vitrinas y notificamos a clientes.
local function MaybeDeactivateStore(store)
    local row = DB.GetStore(store.id)
    if not row or not flagTrue(row.vitrines_active) then return end

    local lootedCount = DB.CountLooted(store.id)
    local allVitrinesDone = lootedCount >= #(store.vitrines or {})
    local safeDone = (not store.safe) or flagTrue(row.safe_robbed)

    if allVitrinesDone and safeDone then
        DB.DisableVitrines(store.id)
        TriggerClientEvent('yc-robberies:client:deactivateVitrines', -1, store.id)
    end
end

-- ----------------------------------------------------
-- Resource start: limpiar estado
-- ----------------------------------------------------
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    BuildIndexes()
    DB.EnsureSchema()
    dbg('Estado de robos limpiado al iniciar.')
end)

-- ----------------------------------------------------
-- canStart: valida y emite TOKEN. Tambien dispara alerta inicial.
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:canStart', function(source, storeId)
    local src = source
    if not CanInteract(src) then
        return false, 'Espera un momento antes de volver a intentar.'
    end

    local store = FindStoreById(storeId)
    if not store then return false, 'Local invalido.' end

    local ok, msg = ValidateRegisterStart(src, store)
    if not ok then return false, msg end

    -- Cooldown
    local row = DB.GetStore(storeId)
    if row and row.last_robbed and row.last_robbed > 0 then
        local elapsed = (os.time() - row.last_robbed) / 60
        if elapsed < store.cooldown then
            local left = math.ceil(store.cooldown - elapsed)
            return false, ('Esta caja se reactivara en ~%d min.'):format(left)
        end
    end

    -- Alerta inicial (rate-limitada por AlertCooldown).
    local alertedAt = (row and row.alert_sent_at) or 0
    if alertedAt == 0 or (os.time() - alertedAt) > Config.AlertCooldown then
        SendPoliceAlert(store.register.coords, Config.PoliceAlerts.onStart, store.name)
        DB.MarkAlertSent(storeId, os.time())
    end

    -- Emitimos token de un solo uso
    local token = IssueToken(src, storeId, 'register')
    return true, token
end)

-- ----------------------------------------------------
-- finishRegister: consume token y aplica resultado del minijuego.
-- success=false  -> consume 1 lockpick (si lo tiene).
-- success=true   -> revalida TODO + claim atomico + paga.
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:finishRegister', function(source, storeId, token, success)
    local src = source
    local store = FindStoreById(storeId)
    if not store then return false end

    if not ConsumeToken(token, src, storeId, 'register') then
        return false
    end

    -- Distancia minima siempre
    local pCoords = GetPlayerCoords(src)
    if DistTo(pCoords, store.register.coords) > Config.MaxInteractDistance then
        return false
    end

    if not success then
        -- Penalizacion: pierde 1 lockpick
        local count = ox_inv:Search(src, 'count', Config.RequiredItem)
        if count and count > 0 then
            ox_inv:RemoveItem(src, Config.RequiredItem, 1)
        end
        return false
    end

    -- Revalidacion completa anti-trampa
    local ok = ValidateRegisterStart(src, store)
    if not ok then return false end

    -- Claim atomico: solo paga el primero que llega tras el cooldown.
    local identifier = GetIdentifier(src)
    local claimed = DB.TryClaimRobbery(storeId, identifier, os.time(), store.cooldown * 60)
    if not claimed then
        return false
    end

    -- Reset de vitrinas saqueadas (nuevo ciclo)
    DB.ResetLootedForStore(storeId)

    -- Recompensa
    local money = RandRange(store.reward.min, store.reward.max)
    local added = ox_inv:AddItem(src, Config.RewardItem, money)
    if added == false or added == nil then
        dbg(('AddItem fallo en register para player %d (inventario lleno?). Money=%d perdido.'):format(src, money))
    end

    -- Activar vitrinas en clientes
    TriggerClientEvent('yc-robberies:client:activateVitrines', -1, storeId)

    -- Segunda alerta mas fuerte
    SendPoliceAlert(store.register.coords, Config.PoliceAlerts.onSuccess, store.name)

    dbg(('Player %d robo %s ($%d)'):format(src, storeId, money))
    return true
end)

-- ----------------------------------------------------
-- Robo de vitrina (callback)
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:lootVitrine', function(source, storeId, vIndex)
    local src = source
    if not CanInteract(src) then return false end

    local store = FindStoreById(storeId)
    if not store then return false end

    local vitrine = FindVitrineByIndex(store, vIndex)
    if not vitrine then return false end

    -- Distancia a la vitrina
    local pCoords = GetPlayerCoords(src)
    if DistTo(pCoords, vitrine.coords) > Config.MaxInteractDistance then
        return false
    end

    -- Vitrinas activas?
    local row = DB.GetStore(storeId)
    if not row or not flagTrue(row.vitrines_active) then return false end

    -- Claim atomico de la vitrina
    if not DB.TryClaimVitrine(storeId, vIndex) then
        return false, 'already_looted'
    end

    -- Repartir items por probabilidad
    local given = false
    for _, def in ipairs(vitrine.items) do
        if RollChance(def.chance) then
            local qty = RandRange(def.min, def.max)
            if qty > 0 then
                local ok = ox_inv:AddItem(src, def.name, qty)
                if ok ~= false and ok ~= nil then
                    given = true
                else
                    dbg(('AddItem fallo para "%s" x%d'):format(def.name, qty))
                end
            end
        end
    end

    -- Si quedo todo el local agotado, desactivamos vitrinas (limpia targets cliente).
    MaybeDeactivateStore(store)

    return given
end)

-- ----------------------------------------------------
-- canStartSafe: valida y emite TOKEN para la caja fuerte.
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:canStartSafe', function(source, storeId)
    local src = source
    if not CanInteract(src) then
        return false, 'Espera un momento antes de volver a intentar.'
    end

    local store = FindStoreById(storeId)
    if not store then return false, 'Local invalido.' end

    local ok, msg = ValidateSafeStart(src, store)
    if not ok then return false, msg end

    local row = DB.GetStore(storeId)
    if not row or not flagTrue(row.vitrines_active) then
        return false, 'Primero hay que forzar la caja registradora.'
    end
    if flagTrue(row.safe_robbed) then
        return false, 'Esta caja fuerte ya fue vaciada.'
    end

    local token = IssueToken(src, storeId, 'safe')
    return true, token
end)

-- ----------------------------------------------------
-- finishSafe: consume token y aplica resultado del minijuego de la caja fuerte.
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:finishSafe', function(source, storeId, token, success)
    local src = source
    local store = FindStoreById(storeId)
    if not store or not store.safe then return false end

    if not ConsumeToken(token, src, storeId, 'safe') then
        return false
    end

    local pCoords = GetPlayerCoords(src)
    if DistTo(pCoords, store.safe.coords) > Config.MaxInteractDistance then
        return false
    end

    if not success then
        local count = ox_inv:Search(src, 'count', Config.RequiredItemSafe)
        if count and count > 0 then
            ox_inv:RemoveItem(src, Config.RequiredItemSafe, 1)
        end
        return false
    end

    local ok = ValidateSafeStart(src, store)
    if not ok then return false end

    -- Claim atomico de la caja fuerte
    if not DB.TryClaimSafe(storeId) then
        return false
    end

    local money = RandRange(store.safe.reward.min, store.safe.reward.max)
    local added = ox_inv:AddItem(src, Config.RewardItem, money)
    if added == false or added == nil then
        dbg(('AddItem fallo en safe para player %d (inventario lleno?). Money=%d perdido.'):format(src, money))
    end

    -- (Sin alerta a la policia: por configuracion el robo de caja fuerte es silencioso.)

    -- Si era lo ultimo que faltaba, desactivamos vitrinas.
    MaybeDeactivateStore(store)

    dbg(('Player %d forzo la caja fuerte de %s ($%d)'):format(src, storeId, money))
    return true
end)

-- ----------------------------------------------------
-- Sync inicial al cliente: lista de stores con vitrinas activas
-- ----------------------------------------------------
lib.callback.register('yc-robberies:server:getActiveVitrines', function(source)
    local rows = DB.GetActiveVitrines()
    local ids = {}
    for _, r in ipairs(rows) do ids[#ids + 1] = r.store_id end
    return ids
end)

-- ----------------------------------------------------
-- Limpieza al desconectar
-- ----------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    lastInteract[src] = nil
    -- Limpiar tokens del jugador
    for token, t in pairs(activeTokens) do
        if t.src == src then activeTokens[token] = nil end
    end
end)
