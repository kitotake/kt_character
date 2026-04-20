-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER - CAMERA CLIENT
-- Caméra scriptée avec focus dynamique par zone du creator
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local cam         = nil
local camActive   = false

-- Offset depuis le ped selon la zone de focus
-- { offsetX, offsetY, offsetZ, pointAtZ }
local CAM_PRESETS = {
    face    = { 0.55,  0.0,  0.70, 0.65 }, -- Visage (parents, traits, overlays)
    hair    = { 0.55,  0.0,  0.72, 0.68 }, -- Cheveux (un peu plus haut)
    body    = { 1.20,  0.0,  0.20, 0.30 }, -- Corps / vêtements
    full    = { 1.80,  0.0, -0.10, 0.20 }, -- Vue complète (tatouages)
    default = { 1.00,  0.0,  0.70, 0.60 }, -- Défaut
}

-- ─── Créer la caméra au démarrage du creator ──────────────────────────────
function CreateCharacterCam()
    if camActive then return end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Placer le ped dans une position neutre
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    -- Tourner le ped face à nous
    local heading = GetEntityHeading(ped)
    SetEntityHeading(ped, heading)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    -- Position initiale : focus visage
    local preset = CAM_PRESETS.face
    SetCamCoord(cam,
        coords.x + preset[1],
        coords.y + preset[2],
        coords.z + preset[3]
    )
    PointCamAtEntity(cam, ped, 0.0, 0.0, preset[4], true)
    SetCamFov(cam, 45.0)

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, true)

    camActive = true
end

-- ─── Déplacer la caméra selon un preset ───────────────────────────────────
local function moveCamToPreset(presetKey)
    if not camActive or not cam then return end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local preset = CAM_PRESETS[presetKey] or CAM_PRESETS.default

    -- Transition fluide
    local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(newCam,
        coords.x + preset[1],
        coords.y + preset[2],
        coords.z + preset[3]
    )
    PointCamAtEntity(newCam, ped, 0.0, 0.0, preset[4], true)
    SetCamFov(newCam, presetKey == "full" and 55.0 or 45.0)
    SetCamActive(newCam, true)

    -- Interpolation 400ms
    SetCamActiveWithInterp(newCam, cam, 400, 1, 1)

    Wait(420)

    -- Nettoyer l'ancienne caméra
    DestroyCam(cam, false)
    cam = newCam
end

-- ─── Focus par onglet ─────────────────────────────────────────────────────
function FocusFace()  moveCamToPreset("face")  end
function FocusHair()  moveCamToPreset("hair")  end
function FocusBody()  moveCamToPreset("body")  end
function FocusFull()  moveCamToPreset("full")  end

-- ─── Détruire la caméra ───────────────────────────────────────────────────
function DestroyCam()
    if cam then
        RenderScriptCams(false, true, 800, true, true)
        Wait(820)
        DestroyCam(cam, false)
        cam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    camActive = false
end