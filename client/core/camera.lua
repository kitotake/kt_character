-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CAMERA SYSTEM (client)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Camera = {}

local _cam         = nil
local _active      = false
local _angle       = 0.0
local _distance    = 1.0
local _focusKey    = "face"

local _nativeDestroyCam = DestroyCam

local CAM_PRESETS = {
    face    = { dist = 0.65, z = 0.68,  pointZ = 0.65 },
    hair    = { dist = 0.60, z = 0.72,  pointZ = 0.70 },
    body    = { dist = 1.20, z = 0.20,  pointZ = 0.30 },
    full    = { dist = 1.80, z = -0.10, pointZ = 0.20 },
    default = { dist = 1.00, z = 0.60,  pointZ = 0.60 },
}

local ZOOM_MIN = 0.4
local ZOOM_MAX = 2.5
local ZOOM_STEP   = 0.15
local ROTATE_STEP = 20.0

local DEFAULT_CAM_POS     = vector3(-268.5, -957.8, 31.2)
local DEFAULT_CAM_HEADING = 90.0

-- ── HELPERS ───────────────────────────────────────────────────────────────

local function orbitPosition(pedCoords, preset, angle, distMult)
    local rad = math.rad(angle)
    local d   = preset.dist * distMult
    return
        pedCoords.x + math.sin(rad) * d,
        pedCoords.y - math.cos(rad) * d,
        pedCoords.z + preset.z
end

local function applyCam(presetKey, angle, distMult, interp)
    if not _active then return end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local preset = CAM_PRESETS[presetKey] or CAM_PRESETS.default
    local cx, cy, cz = orbitPosition(coords, preset, angle, distMult)

    if interp and _cam then
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(newCam, cx, cy, cz)
        PointCamAtEntity(newCam, ped, 0.0, 0.0, preset.pointZ, true)
        SetCamFov(newCam, presetKey == "full" and 55.0 or 45.0)
        SetCamActive(newCam, true)
        SetCamActiveWithInterp(newCam, _cam, 350, 1, 1)
        Wait(370)
        _nativeDestroyCam(_cam, false)
        _cam = newCam
    elseif _cam then
        SetCamCoord(_cam, cx, cy, cz)
        PointCamAtEntity(_cam, ped, 0.0, 0.0, preset.pointZ, true)
        SetCamFov(_cam, presetKey == "full" and 55.0 or 45.0)
    end
end

-- ── API PUBLIQUE ──────────────────────────────────────────────────────────

--- Crée et active la caméra de prévisualisation.
function Camera.Create()
    if _active then return end

    _angle    = 0.0
    _distance = 1.0
    _focusKey = "face"

    local ped     = PlayerPedId()
    local timeout = 0

    while not DoesEntityExist(ped) and timeout < 100 do
        Wait(50)
        ped     = PlayerPedId()
        timeout = timeout + 1
    end

    local coords = GetEntityCoords(ped)
    if math.abs(coords.x) < 1.0 and math.abs(coords.y) < 1.0 then
        SetEntityCoords(ped, DEFAULT_CAM_POS.x, DEFAULT_CAM_POS.y, DEFAULT_CAM_POS.z, false, false, false, true)
        SetEntityHeading(ped, DEFAULT_CAM_HEADING)
        Wait(100)
        coords = GetEntityCoords(ped)
    end

    SetEntityHeading(ped, 180.0)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    _cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    local preset         = CAM_PRESETS.face
    local cx, cy, cz     = orbitPosition(coords, preset, _angle, _distance)

    SetCamCoord(_cam, cx, cy, cz)
    PointCamAtEntity(_cam, ped, 0.0, 0.0, preset.pointZ, true)
    SetCamFov(_cam, 45.0)
    SetCamActive(_cam, true)
    RenderScriptCams(true, true, 800, true, true)

    _active = true
end

--- Définit le preset de focus de la caméra.
--- @param preset string "face" | "hair" | "body" | "full"
--- @param options table { interp = bool }
function Camera.SetPreset(preset, options)
    _focusKey = preset
    local interp = (options and options.interp ~= false)
    applyCam(_focusKey, _angle, _distance, interp)
end

--- Gère une action caméra (rotation, zoom, focus).
--- @param action string
function Camera.HandleAction(action)
    if not _active then return end

    if action == "rotateLeft" then
        _angle = (_angle - ROTATE_STEP) % 360
        applyCam(_focusKey, _angle, _distance, false)

    elseif action == "rotateRight" then
        _angle = (_angle + ROTATE_STEP) % 360
        applyCam(_focusKey, _angle, _distance, false)

    elseif action == "zoomIn" then
        _distance = math.max(ZOOM_MIN, _distance - ZOOM_STEP)
        applyCam(_focusKey, _angle, _distance, false)

    elseif action == "zoomOut" then
        _distance = math.min(ZOOM_MAX, _distance + ZOOM_STEP)
        applyCam(_focusKey, _angle, _distance, false)

    elseif action == "focusHead" then Camera.SetPreset("face", { interp = true })
    elseif action == "focusHair" then Camera.SetPreset("hair", { interp = true })
    elseif action == "focusBody" then Camera.SetPreset("body", { interp = true })
    elseif action == "focusFull" then Camera.SetPreset("full", { interp = true })

    elseif action == "resetCam" then
        _angle    = 0.0
        _distance = 1.0
        _focusKey = "face"
        applyCam(_focusKey, _angle, _distance, true)
    end
end

--- Retourne la position de preview (utilisé par preview.lua pour positionner le ped cloné).
--- @param faceZoom boolean
function Camera.GetPreviewPosition(faceZoom)
    local camCoord = GetGameplayCamCoord()
    local camRot   = GetGameplayCamRot(2)
    local distance = faceZoom and 0.8 or 5.0

    local forward = vector3(
        -math.sin(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
         math.cos(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
         math.sin(math.rad(camRot.x))
    )

    local pos = camCoord + (forward * distance)
    if faceZoom then pos = pos + vector3(0.0, 0.0, 0.5) end
    return pos
end

--- Détruit la caméra et libère le ped.
function Camera.Destroy()
    if _cam then
        RenderScriptCams(false, true, 800, true, true)
        Wait(820)
        _nativeDestroyCam(_cam, false)
        _cam = nil
    end
    FreezeEntityPosition(PlayerPedId(), false)
    _active   = false
    _angle    = 0.0
    _distance = 1.0
end

--- Retourne si la caméra est active.
function Camera.IsActive()
    return _active
end

_G.Camera = Camera
