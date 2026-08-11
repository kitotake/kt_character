-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CLIENT UI
-- Relie le front web/dist (Creator + CharacterSelect) à la logique serveur.
--   - Ouvre/ferme la NUI (SetNuiFocus + SendNUIMessage)
--   - Écoute les events serveur qui déclenchent l'ouverture
--   - Répond aux NUI callbacks envoyés par le front (fetch vers /endpoint)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local uiOpen = false

local function openUI()
    if uiOpen then return end
    uiOpen = true
    SetNuiFocus(true, true)
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })

    if Preview.IsActive() then Preview.Stop() end
    if Camera.IsActive() then Camera.Destroy() end
    FreezeEntityPosition(PlayerPedId(), false)
end

-- ── OUVERTURE : CREATOR (aucun personnage) ───────────────────────────────
-- Déclenché par server/main.lua (union:spawn:noCharacters_server ou
-- hasCharacters_server sans résultat).

RegisterNetEvent("kt_character:openCreator", function()
    openUI()
    Camera.Create()
    SendNUIMessage({ type = "open" })

    -- Récupère license/unique_id pour les champs cachés du formulaire.
    TriggerServerEvent(KT.Events.C2S_REQUEST_IDENTIFIER)
end)

-- ── OUVERTURE : SÉLECTION DE PERSONNAGE ──────────────────────────────────
-- Déclenché par server/main.lua (union:spawn:hasCharacters_server) ou par
-- la commande admin /openselect.

RegisterNetEvent("kt_character:openCharacterSelection", function(characters, slots)
    openUI()
    SendNUIMessage({
        action     = "openCharacterSelection",
        characters = characters or {},
        slots      = slots or KT.Config.MAX_CHARACTERS,
    })
end)

-- ── FERMETURE APRÈS SUCCÈS ────────────────────────────────────────────────

-- Personnage créé : le front ferme déjà son propre overlay après le POST
-- /createCharacter, mais c'est le client Lua qui doit libérer le focus NUI.
RegisterNetEvent(KT.Events.S2C_CREATED, function()
    closeUI()
end)

-- Personnage sélectionné : le serveur déclenche UNION_SPAWN_APPLY juste
-- après (voir server/core/character.lua) — on ferme la NUI à ce moment,
-- en plus du handler existant dans client/core/events.lua qui applique
-- l'apparence.
RegisterNetEvent(KT.Events.UNION_SPAWN_APPLY, function()
    closeUI()
end)

-- ── ERREURS SERVEUR (création / sélection) → remontées au front ─────────

RegisterNetEvent(KT.Events.S2C_ERROR, function(message)
    SendNUIMessage({ type = "error", message = message })
end)

-- ── IDENTIFIANT REÇU → transmis au front ─────────────────────────────────

RegisterNetEvent(KT.Events.S2C_SEND_IDENTIFIER, function(license, unique_id)
    SendNUIMessage({
        type       = "setIdentifier",
        identifier = license,
        unique_id  = unique_id,
    })
end)

-- ── NUI CALLBACKS (front → client, via fetch https://kt_character/xxx) ──

RegisterNUICallback("close", function(_, cb)
    closeUI()
    cb({ ok = true })
end)

RegisterNUICallback("tabChange", function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback("update", function(data, cb)
    local ped = Preview.IsActive() and Preview.GetPed() or PlayerPedId()
    Ped.ApplyPreview(ped, data)
    cb({ ok = true })
end)

RegisterNUICallback("cameraControl", function(data, cb)
    if data and data.action then
        Camera.HandleAction(data.action)
    end
    cb({ ok = true })
end)

RegisterNUICallback("createCharacter", function(data, cb)
    TriggerServerEvent(KT.Events.C2S_CREATE_CHARACTER, data)
    cb({ ok = true })
end)

RegisterNUICallback("selectCharacter", function(data, cb)
    if data and data.charId then
        TriggerServerEvent(KT.Events.C2S_SELECT_CHARACTER, data.charId)
    end
    cb({ ok = true })
end)

print("^2[kt_character] client UI chargé^0")
