-- ─── Variables ─────────────────────────────────────────────────────────────────
local nuiOpen = false

-- ─── Ouvrir le Character Creator ───────────────────────────────────────────────
RegisterCommand("character", function()
    nuiOpen = true

    -- Demander l'identifier au serveur
    TriggerServerEvent("kt_character:requestIdentifier")

    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
end)

-- ─── Recevoir l'identifier depuis le serveur ───────────────────────────────────
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    -- Injecter dans le contexte window du NUI
    SendNUIMessage({
        type       = "setIdentifier",
        identifier = license,
        unique_id  = "" -- sera généré côté serveur
    })
end)

-- ─── NUI Callbacks ─────────────────────────────────────────────────────────────

-- Mise à jour de l'apparence en temps réel (preview)
RegisterNUICallback("update", function(data, cb)
    local ped = PlayerPedId()

    -- Changer le modèle si nécessaire
    if data.gender then
        local model = data.gender == "mp_f_freemode_01"
            and GetHashKey("mp_f_freemode_01")
            or  GetHashKey("mp_m_freemode_01")

        if GetEntityModel(ped) ~= model then
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            SetPlayerModel(PlayerId(), model)
            ped = PlayerPedId()
        end
    end

    -- Cheveux
    if data.hair ~= nil then
        SetPedComponentVariation(ped, 2, data.hair, 0, 0)
    end
    if data.hairColor ~= nil then
        SetPedHairColor(ped, data.hairColor, 0)
    end

    -- Barbe
    if data.beard ~= nil then
        SetPedHeadOverlay(ped, 1, data.beard, 1.0)
    end

    cb("ok")
end)

-- Création finale du personnage
RegisterNUICallback("createCharacter", function(data, cb)
    TriggerServerEvent("kt_character:createCharacter", data)
    cb("ok")
end)

-- ─── Personnage créé (retour serveur) ──────────────────────────────────────────
RegisterNetEvent("kt_character:created", function(character)
    -- Appliquer le modèle définitif
    local model = character.gender == "mp_f_freemode_01"
        and GetHashKey("mp_f_freemode_01")
        or  GetHashKey("mp_m_freemode_01")

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    SetPlayerModel(PlayerId(), model)

    -- Fermer l'interface
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    nuiOpen = false

    -- Notification
    local msg = string.format("Bienvenue, %s %s !", character.firstname, character.lastname)
    -- Exemple: exports['ox_lib']:notify({ title = msg, type = 'success' })
    print("[kt_character] " .. msg)
end)

-- ─── Erreur serveur ────────────────────────────────────────────────────────────
RegisterNetEvent("kt_character:error", function(msg)
    SendNUIMessage({ type = "error", message = msg })
end)

-- ─── Fermer avec Escape ────────────────────────────────────────────────────────
RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    nuiOpen = false
    cb("ok")
end)

-- ─── Application de l'apparence complète ───────────────────────────────────────
local function applyAppearance(data)
    local ped = PlayerPedId()

    if data.gender then
        local model = data.gender == "mp_f_freemode_01"
            and GetHashKey("mp_f_freemode_01")
            or  GetHashKey("mp_m_freemode_01")

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        SetPlayerModel(PlayerId(), model)
        ped = PlayerPedId()
    end

    if data.parents then
        SetPedHeadBlendData(
            ped,
            data.parents.mother, data.parents.father, 0,
            data.parents.mother, data.parents.father, 0,
            data.mixShape or 0.5, data.mixSkin or 0.5, 0.0,
            false
        )
    end

    if data.hair ~= nil then
        SetPedComponentVariation(ped, 2, data.hair, 0, 0)
        SetPedHairColor(ped, data.hairColor or 0, 0)
    end

    if data.beard ~= nil then
        SetPedHeadOverlay(ped, 1, data.beard, 1.0)
    end
end

RegisterNetEvent("kt_appearance:update", applyAppearance)