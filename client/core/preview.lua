-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — PREVIEW SYSTEM (client)
-- Système centralisé de prévisualisation du personnage.
-- Toutes les ressources (kt_creation, kt_clothing, kt_barber, kt_tattoo...)
-- passent par ce module via les exports kt_character.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Preview = {}

local _active  = false
local _ped     = nil
local _heading = 180.0
local _options = {}

-- ── ANIM DICT LOADER ─────────────────────────────────────────────────────

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(0)
        timeout = timeout + 1
        if timeout > 5000 then
            print("[kt_preview] failed anim dict: " .. dict)
            return false
        end
    end
    return true
end

-- ── FLAGS PED ─────────────────────────────────────────────────────────────

local function applyPedFlags(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityDynamic(ped, false)
    DisablePedPainAudio(ped, true)
end

-- ── IDLE ANIM ─────────────────────────────────────────────────────────────

local function playIdleAnim(ped)
    if not ped or not DoesEntityExist(ped) then return end

    local dict = "amb@world_human_muscle_flex@arms_in_front@idle_a"
    local anim = "idle_c"

    if not loadAnimDict(dict) then return end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    Wait(50)
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    Wait(100)
    FreezeEntityPosition(ped, true)
end

-- ── POSITION ──────────────────────────────────────────────────────────────

local function getPreviewPosition(faceZoom)
    local camCoord = GetGameplayCamCoord()
    local camRot   = GetGameplayCamRot(2)

    local distance = faceZoom and 0.8 or 5.0

    local forward = vector3(
        -math.sin(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
         math.cos(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
         math.sin(math.rad(camRot.x))
    )

    local pos = camCoord + (forward * distance)
    if faceZoom then
        pos = pos + vector3(0.0, 0.0, 0.5)
    end
    return pos
end

-- ── LOOP ─────────────────────────────────────────────────────────────────

local function startLoop()
    CreateThread(function()
        while _active and _ped and DoesEntityExist(_ped) do
            local faceZoom = _options.faceZoom or false
            local pos      = getPreviewPosition(faceZoom)

            SetEntityCoordsNoOffset(_ped, pos.x, pos.y, pos.z, false, false, false)
            SetEntityHeading(_ped, GetGameplayCamRot(2).z + _heading)
            Wait(0)
        end
    end)
end

-- ── API PUBLIQUE ──────────────────────────────────────────────────────────

--- Démarre la preview (clone le ped joueur).
--- @param options table { heading, faceZoom, camera }
function Preview.Start(options)
    if _active then Preview.Stop() end

    options    = options or {}
    _options   = options
    _heading   = options.heading or 180.0

    local playerPed = PlayerPedId()
    _ped = ClonePed(playerPed, GetEntityHeading(playerPed), true, true)

    if not _ped or not DoesEntityExist(_ped) then
        print("[kt_preview] Echec clone ped")
        return false
    end

    applyPedFlags(_ped)
    SetEntityVisible(_ped, true, false)
    SetEntityAlpha(_ped, 255, false)
    NetworkSetEntityInvisibleToNetwork(_ped, true)

    _active = true

    Wait(200)
    playIdleAnim(_ped)
    startLoop()

    -- Caméra optionnelle
    if options.camera and Camera then
        Camera.SetPreset(options.camera, options)
    end

    TriggerEvent(KT.Events.PREVIEW_STARTED, _ped)
    print("[kt_preview] Preview démarrée")
    return true
end

--- Arrête la preview et nettoie le ped cloné.
function Preview.Stop()
    _active = false

    if _ped and DoesEntityExist(_ped) then
        DeleteEntity(_ped)
    end
    _ped    = nil
    _options = {}

    if Camera then Camera.Destroy() end

    TriggerEvent(KT.Events.PREVIEW_STOPPED)
    print("[kt_preview] Preview arrêtée")
end

--- Rafraîchit le ped cloné (re-clone depuis le joueur actuel).
function Preview.Refresh()
    if not Preview.IsActive() then return end

    ClonePedToTarget(PlayerPedId(), _ped)
    applyPedFlags(_ped)
    Wait(100)
    playIdleAnim(_ped)

    TriggerEvent(KT.Events.PREVIEW_REFRESHED, _ped)
end

--- Fait jouer une animation sur le ped preview.
--- @param dict string dictionnaire d'animation
--- @param anim string nom de l'animation
function Preview.PlayAnim(dict, anim)
    if not Preview.IsActive() then return end
    if not loadAnimDict(dict) then return end

    ClearPedTasksImmediately(_ped)
    FreezeEntityPosition(_ped, false)
    Wait(50)
    TaskPlayAnim(_ped, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    Wait(100)
    FreezeEntityPosition(_ped, true)
end

--- Remet l'animation idle par défaut.
function Preview.ResetAnim()
    if not Preview.IsActive() then return end
    playIdleAnim(_ped)
end

--- Tourne le ped preview.
--- @param degrees number degrés à ajouter au heading
function Preview.Rotate(degrees)
    _heading = (_heading + degrees) % 360
end

--- Active ou désactive le zoom visage.
--- @param state boolean
function Preview.SetFaceZoom(state)
    _options.faceZoom = state
end

--- Retourne si la preview est active.
function Preview.IsActive()
    return _active and _ped ~= nil and DoesEntityExist(_ped)
end

--- Retourne le handle du ped preview.
function Preview.GetPed()
    return _ped
end

--- Retourne les options courantes.
function Preview.GetOptions()
    return _options
end

_G.Preview = Preview
