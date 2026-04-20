-- kt_character/client/main.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN v2.0.3
-- Clean version (fix closeUI, NUI sync, state handling)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION         = "2.0.3"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CLEAN CLOSE FUNCTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function closeCreator()
    if DestroyCharacterCam then
        DestroyCharacterCam()
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    SetNuiFocus(false, false)

    nuiOpen = false
    debugLog("Creator fermé proprement", "INFO")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMAND : OPEN CHARACTER CREATOR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("character", function()
    if nuiOpen then return end

    nuiOpen = true

    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()

    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })

    debugLog("Creator ouvert", "INFO")
end, false)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMAND : SKIN EDIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("skin", function()
    if nuiOpen then return end
    if not currentUniqueId then
        TriggerEvent("chat:addMessage", {
            color = {255, 100, 100},
            args = {"[SKIN]", "Aucun personnage actif."}
        })
        return
    end

    nuiOpen = true

    TriggerServerEvent("kt_character:requestSkinEdit", currentUniqueId)
    CreateCharacterCam()

    SetNuiFocus(true, true)

    debugLog("Skin mode ouvert", "INFO")
end, false)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("update", function(data, cb)
    Citizen.CreateThread(function()
        ApplyPreview(data)
    end)
    cb("ok")
end)

RegisterNUICallback("createCharacter", function(data, cb)
    TriggerServerEvent("kt_character:createCharacter", data)
    cb("ok")
end)

RegisterNUICallback("tabChange", function(data, cb)
    local tab = data and data.tab or "identity"

    if tab == "parents" or tab == "features" or tab == "overlays" then
        FocusFace()
    elseif tab == "hair" then
        FocusHair()
    elseif tab == "clothing" then
        FocusBody()
    elseif tab == "tattoos" then
        FocusFull()
    else
        FocusFace()
    end

    cb("ok")
end)

RegisterNUICallback("cameraControl", function(data, cb)
    if HandleCameraControl then
        HandleCameraControl(data and data.action or "")
    end
    cb("ok")
end)

-- CLOSE UI FROM NUI
RegisterNUICallback("close", function(_, cb)
    closeCreator()
    SendNUIMessage({ type = "close" })
    cb("ok")
end)

RegisterNUICallback("saveAppearance", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:updateAppearance", data)
    cb("ok")
end)

RegisterNUICallback("saveOutfit", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:saveOutfit", data)
    cb("ok")
end)

RegisterNUICallback("getOutfits", function(_, cb)
    if not currentUniqueId then cb("error") return end
    TriggerServerEvent("kt_character:getOutfits", { unique_id = currentUniqueId })
    cb("ok")
end)

RegisterNUICallback("loadOutfit", function(data, cb)
    TriggerServerEvent("kt_character:loadOutfit", data)
    cb("ok")
end)

RegisterNUICallback("deleteOutfit", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:deleteOutfit", data)
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SERVER EVENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    SendNUIMessage({
        type = "setIdentifier",
        identifier = license,
        unique_id = currentUniqueId or ""
    })
end)

RegisterNetEvent("kt_character:created", function(character)
    currentUniqueId = character.unique_id

    FreezeEntityPosition(PlayerPedId(), false)

    Citizen.CreateThread(function()
        Wait(1500)
        ApplyFullAppearance(character)
    end)

    debugLog("Character créé: " .. character.firstname, "INFO")
end)

RegisterNetEvent("kt_character:closeUI", function()
    closeCreator()
    SendNUIMessage({ type = "close" })
    debugLog("closeUI reçu", "INFO")
end)

RegisterNetEvent("kt_character:skinEditData", function(skinData)
    SendNUIMessage({
        type = "open",
        skinData = skinData
    })
    debugLog("Skin data reçu", "INFO")
end)

RegisterNetEvent("kt_character:openCreator", function()
    if nuiOpen then return end

    nuiOpen = true

    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()

    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })

    debugLog("Creator forcé open", "INFO")
end)

RegisterNetEvent("kt_character:error", function(msg)
    SendNUIMessage({
        type = "error",
        message = msg
    })
    debugLog("Erreur: " .. tostring(msg), "ERROR")
end)

RegisterNetEvent("kt_character:outfitSaved", function(outfit)
    SendNUIMessage({ type = "outfitSaved", outfit = outfit })
end)

RegisterNetEvent("kt_character:outfitsList", function(outfits)
    SendNUIMessage({ type = "outfitsList", outfits = outfits })
end)

RegisterNetEvent("kt_character:outfitDeleted", function(id)
    SendNUIMessage({ type = "outfitDeleted", id = id })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UNION SPAWN INTEGRATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("union:spawn:apply", function(characterData)
    if not characterData then return end

    currentUniqueId = characterData.unique_id

    Citizen.CreateThread(function()
        Wait(1500)
        ApplyFullAppearance(characterData)
    end)
end)

AddEventHandler("playerSpawned", function()
    if currentUniqueId then
        TriggerServerEvent("kt_character:reloadSkin", currentUniqueId)
    end
end)

AddEventHandler("playerDropped", function()
    nuiOpen = false
    currentUniqueId = nil
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- START
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Citizen.CreateThread(function()
    Wait(1000)
    debugLog("kt_character v" .. VERSION .. " loaded", "INFO")
end)