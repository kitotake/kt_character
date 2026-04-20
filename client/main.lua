-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION          = "2.0.0"
local DEBUG            = true
local nuiOpen          = false
local currentUniqueId  = nil   -- unique_id du perso actif

-- ─── Debug log ────────────────────────────────────────────────────────────
local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ouvrir le creator
RegisterCommand("character", function()
    if nuiOpen then
        debugLog("Creator déjà ouvert", "WARN")
        return
    end

    nuiOpen = true
    debugLog("Ouverture du creator", "INFO")

    TriggerServerEvent("kt_character:requestIdentifier")

    CreateCharacterCam() -- camera.lua
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
end, false)

-- Recharger l'apparence du perso actif
RegisterCommand("reloadskin", function()
    if not currentUniqueId then
        debugLog("Aucun personnage actif (currentUniqueId nil)", "WARN")
        return
    end
    debugLog("Reloadskin pour: " .. currentUniqueId, "INFO")
    TriggerServerEvent("kt_character:reloadSkin", currentUniqueId)
end, false)

-- Charger un personnage par unique_id
RegisterCommand("loadchar", function(_, args)
    if not args[1] then
        debugLog("Usage: /loadchar [unique_id]", "WARN")
        return
    end
    TriggerServerEvent("kt_character:loadCharacter", args[1])
end, false)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── Preview temps réel (chaque changement de slider) ─────────────────────
RegisterNUICallback("update", function(data, cb)
    debugLog("Preview update reçu", "DEBUG")

    if not PlayerPedId() or PlayerPedId() == 0 then
        cb("error")
        return
    end

    -- Appeler la fonction de preview de appearance.lua
    Citizen.CreateThread(function()
        ApplyPreview(data)
    end)

    cb("ok")
end)

-- ─── Création finale du personnage ────────────────────────────────────────
RegisterNUICallback("createCharacter", function(data, cb)
    debugLog("Création de personnage", "INFO")
    TriggerServerEvent("kt_character:createCharacter", data)
    cb("ok")
end)

-- ─── Sauvegarder une tenue ────────────────────────────────────────────────
RegisterNUICallback("saveOutfit", function(data, cb)
    if not currentUniqueId then
        cb("error_no_character")
        return
    end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:saveOutfit", data)
    cb("ok")
end)

-- ─── Charger la liste des tenues ──────────────────────────────────────────
RegisterNUICallback("getOutfits", function(_, cb)
    if not currentUniqueId then
        cb("error_no_character")
        return
    end
    TriggerServerEvent("kt_character:getOutfits", { unique_id = currentUniqueId })
    cb("ok")
end)

-- ─── Charger une tenue (par ID) ───────────────────────────────────────────
RegisterNUICallback("loadOutfit", function(data, cb)
    TriggerServerEvent("kt_character:loadOutfit", data)
    cb("ok")
end)

-- ─── Supprimer une tenue ──────────────────────────────────────────────────
RegisterNUICallback("deleteOutfit", function(data, cb)
    if not currentUniqueId then
        cb("error")
        return
    end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:deleteOutfit", data)
    cb("ok")
end)

-- ─── Focus caméra selon l'onglet actif ────────────────────────────────────
RegisterNUICallback("tabChange", function(data, cb)
    local tab = data and data.tab or "identity"
    debugLog("Tab changé: " .. tab, "DEBUG")

    if tab == "parents" or tab == "features" or tab == "overlays" then
        FocusFace()       -- camera.lua
    elseif tab == "clothing" then
        FocusBody()       -- camera.lua
    elseif tab == "tattoos" then
        FocusFull()       -- camera.lua
    else
        FocusFace()
    end

    cb("ok")
end)

-- ─── Fermer le creator ────────────────────────────────────────────────────
RegisterNUICallback("close", function(_, cb)
    debugLog("Fermeture du creator", "INFO")
    DestroyCam()  -- camera.lua
    SetNuiFocus(false, false)
    nuiOpen = false
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS SERVEUR → CLIENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── Recevoir l'identifier ────────────────────────────────────────────────
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    debugLog("Identifier reçu: " .. license, "INFO")
    SendNUIMessage({
        type       = "setIdentifier",
        identifier = license,
        unique_id  = currentUniqueId or "",
    })
end)

-- ─── Personnage créé avec succès ──────────────────────────────────────────
RegisterNetEvent("kt_character:created", function(character)
    debugLog("Personnage créé: " .. character.firstname .. " " .. character.lastname, "INFO")

    currentUniqueId = character.unique_id

    -- Appliquer l'apparence complète
    Citizen.CreateThread(function()
        ApplyFullAppearance(character)
    end)

    -- Fermer l'UI
    DestroyCam()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    nuiOpen = false

    -- Notification
    local msg = ("Bienvenue, %s %s!"):format(character.firstname, character.lastname)
    debugLog(msg, "INFO")

    -- ox_lib (décommentez si disponible)
    -- exports['ox_lib']:notify({
    --     title = "Personnage créé",
    --     description = msg,
    --     type = 'success',
    --     duration = 4000
    -- })
end)

-- ─── Erreur serveur → afficher dans le NUI ────────────────────────────────
RegisterNetEvent("kt_character:error", function(msg)
    debugLog("Erreur serveur: " .. tostring(msg), "ERROR")
    SendNUIMessage({ type = "error", message = msg })
end)

-- ─── Tenue sauvegardée ────────────────────────────────────────────────────
RegisterNetEvent("kt_character:outfitSaved", function(outfit)
    debugLog("Tenue sauvegardée: " .. tostring(outfit.name), "INFO")
    SendNUIMessage({ type = "outfitSaved", outfit = outfit })
end)

-- ─── Liste des tenues reçue ───────────────────────────────────────────────
RegisterNetEvent("kt_character:outfitsList", function(outfits)
    debugLog(("#%d tenues reçues"):format(#outfits), "INFO")
    SendNUIMessage({ type = "outfitsList", outfits = outfits })
end)

-- ─── Tenue supprimée ──────────────────────────────────────────────────────
RegisterNetEvent("kt_character:outfitDeleted", function(outfitId)
    debugLog("Tenue supprimée ID: " .. tostring(outfitId), "INFO")
    SendNUIMessage({ type = "outfitDeleted", id = outfitId })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN → recharger l'apparence automatiquement
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("playerSpawned", function()
    debugLog("playerSpawned", "INFO")

    if currentUniqueId then
        debugLog("Rechargement skin pour: " .. currentUniqueId, "INFO")
        TriggerServerEvent("kt_character:reloadSkin", currentUniqueId)
    else
        debugLog("Aucun perso actif au spawn", "WARN")
    end
end)

-- ─── Déconnexion ──────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function()
    nuiOpen         = false
    currentUniqueId = nil
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DÉMARRAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Citizen.CreateThread(function()
    Wait(1000)
    debugLog("kt_character client v" .. VERSION .. " chargé", "INFO")
    debugLog("/character → ouvrir le creator", "INFO")
    debugLog("/reloadskin → recharger l'apparence", "INFO")
end)