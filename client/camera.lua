-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER - CAMERA CLIENT
-- Caméra scriptée avec focus dynamique + contrôles rotation/zoom
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local cam          = nil
local camActive    = false

-- Angle et distance courants (contrôlables via boutons UI)
local camAngle     = 0.0     -- degrés autour du ped (0 = face à nous)
local camDistance  = 1.0     -- multiplicateur de distance (1.0 = normal)
local camFocusKey  = "face"  -- preset actif

-- Offset depuis le ped selon la zone de focus
-- { offsetX, offsetZ, pointAtZ }  (offsetX = distance latérale de base)
local CAM_PRESETS = {
    face    = { dist = 0.65, z = 0.68, pointZ = 0.65 },
    hair    = { dist = 0.60, z = 0.72, pointZ = 0.70 },
    body    = { dist = 1.20, z = 0.20, pointZ = 0.30 },
    full    = { dist = 1.80, z = -0.10, pointZ = 0.20 },
    default = { dist = 1.00, z = 0.60, pointZ = 0.60 },
}

-- ─── Sauvegarder la native GTA AVANT toute redéfinition ──────────────
-- (évite la récursion infinie si on avait besoin d'un alias)
local _nativeDestroyCam = DestroyCam

-- ─── Calcul position orbite ───────────────────────────────────────────
local function orbitPosition(pedCoords, preset, angle, distMult)
    local rad = math.rad(angle)
    local d   = preset.dist * distMult

    return
        pedCoords.x + math.sin(rad) * d,
        pedCoords.y - math.cos(rad) * d,
        pedCoords.z + preset.z
end

-- ─── Appliquer la caméra au preset + angle/zoom courants ─────────────
local function applyCam(presetKey, angle, distMult, interp)
    if not camActive then return end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local preset  = CAM_PRESETS[presetKey] or CAM_PRESETS.default

    local cx, cy, cz = orbitPosition(coords, preset, angle, distMult)

    if interp and cam then
        -- Créer une nouvelle caméra et interpoler
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(newCam, cx, cy, cz)
        PointCamAtEntity(newCam, ped, 0.0, 0.0, preset.pointZ, true)
        SetCamFov(newCam, presetKey == "full" and 55.0 or 45.0)
        SetCamActive(newCam, true)

        SetCamActiveWithInterp(newCam, cam, 350, 1, 1)
        Wait(370)

        _nativeDestroyCam(cam, false)
        cam = newCam
    elseif cam then
        SetCamCoord(cam, cx, cy, cz)
        PointCamAtEntity(cam, ped, 0.0, 0.0, preset.pointZ, true)
        SetCamFov(cam, presetKey == "full" and 55.0 or 45.0)
    end
end

-- Position de fallback si le ped est à (0,0,0) (cas player_zero non spawné)
local DEFAULT_CAM_POS = vector3(-268.5, -957.8, 31.2)
local DEFAULT_CAM_HEADING = 90.0

-- ─── Créer la caméra au démarrage du creator ──────────────────────────
function CreateCharacterCam()
    if camActive then return end

    camAngle    = 0.0
    camDistance = 1.0
    camFocusKey = "face"

    local ped    = PlayerPedId()

    -- ── Attendre que le ped soit valide ──────────────────────────────
    local timeout = 0
    while not DoesEntityExist(ped) and timeout < 100 do
        Wait(50)
        ped     = PlayerPedId()
        timeout = timeout + 1
    end

    -- ── Récupérer coords et corriger si (0,0,0) ───────────────────────
    local coords = GetEntityCoords(ped)
    if math.abs(coords.x) < 1.0 and math.abs(coords.y) < 1.0 then
        -- Le ped n'a pas encore été placé (player_zero en attente de spawn)
        -- On le téléporte à la position de spawn par défaut
        SetEntityCoords(ped, DEFAULT_CAM_POS.x, DEFAULT_CAM_POS.y, DEFAULT_CAM_POS.z,
            false, false, false, true)
        SetEntityHeading(ped, DEFAULT_CAM_HEADING)
        Wait(100) -- laisser le moteur repositionner le ped
        coords = GetEntityCoords(ped)
    end

    -- ── Orienter le ped face à la caméra ─────────────────────────────
    -- (heading 0 = vers le Nord ; la cam est au Sud → ped regarde la cam)
    SetEntityHeading(ped, 180.0)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    local preset = CAM_PRESETS.face
    local cx, cy, cz = orbitPosition(coords, preset, camAngle, camDistance)

    SetCamCoord(cam, cx, cy, cz)
    PointCamAtEntity(cam, ped, 0.0, 0.0, preset.pointZ, true)
    SetCamFov(cam, 45.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, true)

    camActive = true
end

-- ─── Focus par onglet ─────────────────────────────────────────────────
function FocusFace()
    camFocusKey = "face"
    applyCam(camFocusKey, camAngle, camDistance, true)
end

function FocusHair()
    camFocusKey = "hair"
    applyCam(camFocusKey, camAngle, camDistance, true)
end

function FocusBody()
    camFocusKey = "body"
    applyCam(camFocusKey, camAngle, camDistance, true)
end

function FocusFull()
    camFocusKey = "full"
    applyCam(camFocusKey, camAngle, camDistance, true)
end

-- ─── Contrôles caméra (depuis NUI) ───────────────────────────────────
local ROTATE_STEP  = 20.0   -- degrés par clic
local ZOOM_STEP    = 0.15   -- multiplicateur zoom
local ZOOM_MIN     = 0.4
local ZOOM_MAX     = 2.5

function HandleCameraControl(action)
    if not camActive then return end

    if action == "rotateLeft" then
        camAngle = (camAngle - ROTATE_STEP) % 360
        applyCam(camFocusKey, camAngle, camDistance, false)

    elseif action == "rotateRight" then
        camAngle = (camAngle + ROTATE_STEP) % 360
        applyCam(camFocusKey, camAngle, camDistance, false)

    elseif action == "zoomIn" then
        camDistance = math.max(ZOOM_MIN, camDistance - ZOOM_STEP)
        applyCam(camFocusKey, camAngle, camDistance, false)

    elseif action == "zoomOut" then
        camDistance = math.min(ZOOM_MAX, camDistance + ZOOM_STEP)
        applyCam(camFocusKey, camAngle, camDistance, false)

    elseif action == "focusHead" then
        FocusFace()

    elseif action == "focusBody" then
        FocusBody()

    elseif action == "focusFull" then
        FocusFull()

    elseif action == "resetCam" then
        camAngle    = 0.0
        camDistance = 1.0
        camFocusKey = "face"
        applyCam(camFocusKey, camAngle, camDistance, true)
    end
end

-- ─── Détruire la caméra ───────────────────────────────────────────────
function DestroyCharacterCam()
    if cam then
        RenderScriptCams(false, true, 800, true, true)
        Wait(820)
        _nativeDestroyCam(cam, false)  -- ✅ native GTA, pas de récursion
        cam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    camActive   = false
    camAngle    = 0.0
    camDistance = 1.0
end