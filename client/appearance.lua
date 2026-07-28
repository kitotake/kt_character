-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER - APPEARANCE CLIENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DEBUG = true

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^5[kt_appearance:%s]^7 %s"):format(level or "INFO", msg))
end

local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 2000 do
        Wait(0)
        timeout = timeout + 1
    end
    return HasModelLoaded(model)
end

local function normalizeGenderModel(gender)
    if gender == "f" or gender == "mp_f_freemode_01" then
        return "mp_f_freemode_01"
    end
    return "mp_m_freemode_01"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- APPLY GENDER MODEL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyGender(gender)
    local modelName = normalizeGenderModel(gender)
    local model     = GetHashKey(modelName)

    if GetEntityModel(PlayerPedId()) == model then
        return PlayerPedId()
    end

    if loadModel(model) then
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        debugLog("Modèle appliqué: " .. modelName, "INFO")
    else
        debugLog("Impossible de charger le modèle: " .. modelName, "ERROR")
    end

    return PlayerPedId()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HEAD BLEND
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyHeadBlend(ped, headBlend)
    if not headBlend then return end
    SetPedHeadBlendData(
        ped,
        headBlend.shapeFirst  or 0,
        headBlend.shapeSecond or 0,
        0,
        headBlend.skinFirst   or 0,
        headBlend.skinSecond  or 0,
        0,
        headBlend.shapeMix    or 0.5,
        headBlend.skinMix     or 0.5,
        0.0,
        false
    )
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FACE FEATURES
-- FIX : double fallback — array Lua (i+1) ET clés string JSON ("1"…"20")
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyFaceFeatures(ped, faceFeatures)
    if not faceFeatures then return end
    for i = 0, 19 do
        -- Lua array (1-indexed) en priorité, puis clé string JSON
        local val = faceFeatures[i + 1] or faceFeatures[tostring(i)]
        if val ~= nil then
            val = math.max(-1.0, math.min(1.0, tonumber(val) or 0.0))
            SetPedFaceFeature(ped, i, val)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HEAD OVERLAYS
-- FIX : la condition colorType > 0 and index >= 0 (et non > 0) pour permettre
--       l'application de couleur sur l'index 0 valide (ex: sourcils rasés style 0).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local OVERLAY_COLOR_TYPES = {
    [0]  = 0, [1]  = 1, [2]  = 1, [3]  = 0,
    [4]  = 2, [5]  = 2, [6]  = 0, [7]  = 0,
    [8]  = 2, [9]  = 0, [10] = 1, [11] = 0, [12] = 0,
}

local function applyHeadOverlays(ped, headOverlays)
    if not headOverlays then return end

    for overlayId = 0, 12 do
        local key     = tostring(overlayId)
        local overlay = headOverlays[key] or headOverlays[overlayId]

        if overlay then
            local index      = overlay.index      or 0
            local opacity    = overlay.opacity    or 1.0
            local firstColor = overlay.firstColor or 0
            local secColor   = overlay.secondColor or 0

            SetPedHeadOverlay(ped, overlayId, index, opacity)

            local colorType = OVERLAY_COLOR_TYPES[overlayId] or 0
            -- FIX : index >= 0 (pas > 0) — index 0 est un style valide qui peut
            --       avoir une couleur (ex: sourcils style 0, opacity > 0)
            if colorType > 0 and opacity > 0.0 then
                SetPedHeadOverlayColor(ped, overlayId, colorType, firstColor, secColor)
            end
        else
            SetPedHeadOverlay(ped, overlayId, 255, 1.0)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HAIR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyHair(ped, hair)
    if not hair then return end
    local style     = hair.style     or hair.hair or 0
    local color     = hair.color     or hair.hairColor or 0
    local highlight = hair.highlight or 0
    SetPedComponentVariation(ped, 2, style, 0, 0)
    SetPedHairColor(ped, color, highlight)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CLOTHING COMPONENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local VALID_COMPONENTS = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

local function applyComponents(ped, components)
    if not components then return end
    for _, compId in ipairs(VALID_COMPONENTS) do
        local key  = tostring(compId)
        local comp = components[key] or components[compId]
        if comp then
            SetPedComponentVariation(
                ped, compId,
                comp.drawable or 0,
                comp.texture  or 0,
                comp.palette  or 0
            )
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PROPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local VALID_PROP_ANCHORS = { 0, 1, 2, 6, 7 }

local function applyProps(ped, props)
    if not props then return end
    for _, anchor in ipairs(VALID_PROP_ANCHORS) do
        local key  = tostring(anchor)
        local prop = props[key] or props[anchor]
        if prop and prop.propIndex ~= nil then
            if prop.propIndex < 0 then
                ClearPedProp(ped, anchor)
            else
                SetPedPropIndex(ped, anchor, prop.propIndex, prop.propTextureIndex or 0, true)
            end
        else
            ClearPedProp(ped, anchor)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TATTOOS
-- FIX : ClearPedDecorations conditionnel — on ne l'appelle que si tattoos
--       est fourni (non-nil) pour éviter d'effacer lors d'un ApplyOutfit.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyTattoos(ped, tattoos, clearFirst)
    -- FIX : on n'efface que si explicitement demandé (ApplyFullAppearance)
    if clearFirst then
        ClearPedDecorations(ped)
    end

    if not tattoos or #tattoos == 0 then return end

    for _, tattoo in ipairs(tattoos) do
        if tattoo.collection and tattoo.overlay then
            local collHash    = GetHashKey(tattoo.collection)
            local overlayHash = GetHashKey(tattoo.overlay)
            AddPedDecorationFromHashes(ped, collHash, overlayHash)
        end
    end

    debugLog(("#%d tatouages appliqués"):format(#tattoos), "INFO")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FONCTION PRINCIPALE : ApplyFullAppearance
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyFullAppearance(data)
    if not data then
        debugLog("ApplyFullAppearance: data nil", "ERROR")
        return
    end

    debugLog("Application apparence complète...", "INFO")

    local modelName    = normalizeGenderModel(data.gender)
    local model        = GetHashKey(modelName)
    local modelChanged = GetEntityModel(PlayerPedId()) ~= model

    local ped = applyGender(data.gender)
    if not ped or ped == 0 then
        debugLog("PED invalide après changement modèle", "ERROR")
        return
    end

    if modelChanged then
        Wait(100)
        ped = PlayerPedId()
    end

    applyHeadBlend(ped, data.headBlend)
    applyFaceFeatures(ped, data.faceFeatures)
    applyHeadOverlays(ped, data.headOverlays)

    if data.hair and type(data.hair) == "table" then
        applyHair(ped, data.hair)
    elseif data.hair ~= nil then
        applyHair(ped, {
            style     = data.hair,
            color     = data.hairColor or 0,
            highlight = data.hairHighlight or 0,
        })
    end

    applyComponents(ped, data.components)
    applyProps(ped, data.props)

    -- FIX : clearFirst = true uniquement ici (application complète)
    applyTattoos(ped, data.tattoos, true)

    debugLog("Apparence appliquée avec succès", "INFO")
end

exports("ApplyFullAppearance", ApplyFullAppearance)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- APPLY OUTFIT ONLY (vêtements + props — sans toucher aux tatouages)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyOutfit(data)
    if not data then return end
    local ped = PlayerPedId()
    applyComponents(ped, data.components)
    applyProps(ped, data.props)
    -- FIX : on ne touche PAS aux tatouages lors d'un changement de tenue
    debugLog("Tenue appliquée", "INFO")
end

exports("ApplyOutfit", ApplyOutfit)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS
-- NOTE : ces handlers sont l'unique source d'application d'apparence.
--        client/main.lua ne duplique plus ces events.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("kt_appearance:apply", function(data)
    debugLog("Event kt_appearance:apply reçu", "INFO")
    Citizen.CreateThread(function()
        ApplyFullAppearance(data)
    end)
end)

RegisterNetEvent("kt_appearance:update", function(data)
    debugLog("Event kt_appearance:update reçu (compat)", "INFO")
    Citizen.CreateThread(function()
        ApplyFullAppearance(data)
    end)
end)

RegisterNetEvent("kt_character:applyOutfit", function(data)
    debugLog("Event kt_character:applyOutfit reçu", "INFO")
    ApplyOutfit(data)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PREVIEW EN TEMPS RÉEL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyPreview(data)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    if data.gender then
        local modelName = normalizeGenderModel(data.gender)
        local model     = GetHashKey(modelName)
        if GetEntityModel(ped) ~= model then
            ped = applyGender(data.gender)
            Wait(100)
            ped = PlayerPedId()
        end
    end

    if data.headBlend    then applyHeadBlend(ped, data.headBlend)       end
    if data.faceFeatures then applyFaceFeatures(ped, data.faceFeatures) end
    if data.headOverlays then applyHeadOverlays(ped, data.headOverlays) end

    if data.hair ~= nil then
        if type(data.hair) == "table" then
            applyHair(ped, data.hair)
        else
            applyHair(ped, {
                style     = data.hair,
                color     = data.hairColor or 0,
                highlight = data.hairHighlight or 0,
            })
        end
    end

    if data.components then applyComponents(ped, data.components) end
    if data.props      then applyProps(ped, data.props)           end

    -- FIX : dans la preview, clearFirst = true seulement si tattoos est fourni
    if data.tattoos    then applyTattoos(ped, data.tattoos, true) end
end

exports("ApplyPreview", ApplyPreview)


CreateThread(function()
    Wait(5000)
    print("^2KT_CHARACTER EXPORTS LOADED^7")
end)