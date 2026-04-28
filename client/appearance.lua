-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER - APPEARANCE CLIENT
-- Toutes les natives GTA V d'apparence
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local DEBUG = true

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^5[kt_appearance:%s]^7 %s"):format(level or "INFO", msg))
end

-- ─── Utilitaire : charger un modèle avec timeout ──────────────────────────
local function loadModel(model)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 2000 do
        Wait(0)
        timeout = timeout + 1
    end
    return HasModelLoaded(model)
end

-- ─── Normalise le genre vers un modèle GTA V valide ─────────────────────
-- FIX: "m" / "f" (BDD) → "mp_m_freemode_01" / "mp_f_freemode_01"
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

    -- Déjà le bon modèle → gain de temps (pas de rechargement)
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
-- HEAD BLEND (mélange parental)
-- SetPedHeadBlendData(ped, shapeFirst, shapeSecond, shapethird,
--   skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix, isParent)
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
-- FACE FEATURES (20 traits du visage)
-- SetPedFaceFeature(ped, index, scale)  scale: -1.0 → 1.0
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyFaceFeatures(ped, faceFeatures)
    if not faceFeatures then return end
    for i = 0, 19 do
        local val = faceFeatures[i + 1] -- Lua est 1-indexé
        if val ~= nil then
            val = math.max(-1.0, math.min(1.0, val))
            SetPedFaceFeature(ped, i, val)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HEAD OVERLAYS (13 overlays : barbe, sourcils, maquillage, etc.)
-- SetPedHeadOverlay(ped, overlayId, index, opacity)
-- SetPedHeadOverlayColor(ped, overlayId, colorType, firstColor, secondColor)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- colorType par overlay
local OVERLAY_COLOR_TYPES = {
    [0]  = 0, -- Imperfections    → aucune couleur
    [1]  = 1, -- Barbe            → cheveux
    [2]  = 1, -- Sourcils         → cheveux
    [3]  = 0, -- Vieillissement   → aucune
    [4]  = 2, -- Maquillage       → maquillage
    [5]  = 2, -- Blush            → maquillage
    [6]  = 0, -- Teint            → aucune
    [7]  = 0, -- Dommages solaires→ aucune
    [8]  = 2, -- Rouge à lèvres   → maquillage
    [9]  = 0, -- Taches           → aucune
    [10] = 1, -- Poils thorax     → cheveux
    [11] = 0, -- Imperfections corps
    [12] = 0, -- Imperfections corps+
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
            if colorType > 0 and index > 0 then
                SetPedHeadOverlayColor(ped, overlayId, colorType, firstColor, secColor)
            end
        else
            SetPedHeadOverlay(ped, overlayId, 255, 1.0)
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HAIR (style + couleur + highlight)
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
-- CLOTHING COMPONENTS (11 composants)
-- SetPedComponentVariation(ped, componentId, drawableId, textureId, paletteId)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local VALID_COMPONENTS = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

local function applyComponents(ped, components)
    if not components then return end

    for _, compId in ipairs(VALID_COMPONENTS) do
        local key  = tostring(compId)
        local comp = components[key] or components[compId]

        if comp then
            SetPedComponentVariation(
                ped,
                compId,
                comp.drawable or 0,
                comp.texture  or 0,
                comp.palette  or 0
            )
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PROPS (5 ancres)
-- SetPedPropIndex(ped, anchorPoint, propIndex, propTextureIndex, attach)
-- ClearPedProp(ped, anchorPoint) si propIndex == -1
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
-- ClearPedDecorations(ped)
-- AddPedDecorationFromHashes(ped, GetHashKey(collection), GetHashKey(overlay))
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function applyTattoos(ped, tattoos)
    ClearPedDecorations(ped)

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
-- FONCTION PRINCIPALE : applyFullAppearance
-- Reçoit un objet FullAppearance et applique tout
-- OPTIMISÉ : Wait(100) seulement si le modèle a vraiment changé
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyFullAppearance(data)
    if not data then
        debugLog("ApplyFullAppearance: data nil", "ERROR")
        return
    end

    debugLog("Application apparence complète...", "INFO")

    -- 1. Modèle / Genre
    --    FIX: normalizeGenderModel gère "m", "f", et les noms complets
    local modelName    = normalizeGenderModel(data.gender)
    local model        = GetHashKey(modelName)
    local modelChanged = GetEntityModel(PlayerPedId()) ~= model

    local ped = applyGender(data.gender)
    if not ped or ped == 0 then
        debugLog("PED invalide après changement modèle", "ERROR")
        return
    end

    -- Attendre uniquement si le modèle a changé (gain de temps si déjà bon)
    if modelChanged then
        Wait(100)
        ped = PlayerPedId()
    end

    -- 2. Head Blend (doit être appliqué AVANT les face features)
    applyHeadBlend(ped, data.headBlend)

    -- 3. Face Features
    applyFaceFeatures(ped, data.faceFeatures)

    -- 4. Head Overlays (inclut la barbe)
    applyHeadOverlays(ped, data.headOverlays)

    -- 5. Cheveux (deux formats supportés)
    if data.hair and type(data.hair) == "table" then
        applyHair(ped, data.hair)
    elseif data.hair ~= nil then
        applyHair(ped, {
            style     = data.hair,
            color     = data.hairColor or 0,
            highlight = data.hairHighlight or 0,
        })
    end

    -- 6. Vêtements
    applyComponents(ped, data.components)

    -- 7. Props
    applyProps(ped, data.props)

    -- 8. Tatouages
    applyTattoos(ped, data.tattoos)

    debugLog("Apparence appliquée avec succès", "INFO")
end

exports("ApplyFullAppearance", ApplyFullAppearance)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- APPLY OUTFIT ONLY (vêtements + props)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyOutfit(data)
    if not data then return end
    local ped = PlayerPedId()
    applyComponents(ped, data.components)
    applyProps(ped, data.props)
    debugLog("Tenue appliquée", "INFO")
end

exports("ApplyOutfit", ApplyOutfit)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RegisterNetEvent("kt_appearance:apply", function(data)
    debugLog("Event kt_appearance:apply reçu", "INFO")
    Citizen.CreateThread(function()
        ApplyFullAppearance(data)
    end)
end)

-- Compat ancien event
RegisterNetEvent("kt_appearance:update", function(data)
    debugLog("Event kt_appearance:update reçu (compat)", "INFO")
    Citizen.CreateThread(function()
        ApplyFullAppearance(data)
    end)
end)

-- Appliquer une tenue uniquement (sans toucher au visage)
RegisterNetEvent("kt_character:applyOutfit", function(data)
    debugLog("Event kt_character:applyOutfit reçu", "INFO")
    ApplyOutfit(data)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PREVIEW EN TEMPS RÉEL (depuis NUI callback "update")
-- Applique uniquement ce qui a changé (partiel)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function ApplyPreview(data)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    -- Genre (change le modèle si nécessaire)
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
    if data.tattoos    then applyTattoos(ped, data.tattoos)       end
end

exports("ApplyPreview", ApplyPreview)