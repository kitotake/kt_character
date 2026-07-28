-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CLIENT EVENTS
-- Reçoit les events réseau du serveur et les redistribue.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── SPAWN (union → apply apparence + position) ───────────────────────────

RegisterNetEvent(KT.Events.UNION_SPAWN_APPLY, function(characterData)
    if not characterData then return end

    State.OnSpawn(characterData)

    -- L'apparence est appliquée par le module spawn d'union.
    -- On applique quand même ici en fallback si union ne le fait pas.
    Citizen.CreateThread(function()
        Ped.ApplyFullAppearance(PlayerPedId(), characterData)
    end)
end)

-- ── APPLY APPARENCE (depuis serveur ou kt_clothing, etc.) ────────────────

RegisterNetEvent("kt_appearance:apply", function(data)
    Citizen.CreateThread(function()
        Ped.ApplyFullAppearance(PlayerPedId(), data)
    end)
end)

RegisterNetEvent("kt_appearance:update", function(data)
    Citizen.CreateThread(function()
        Ped.ApplyFullAppearance(PlayerPedId(), data)
    end)
end)

-- ── APPLY TENUE ───────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.S2C_APPLY_OUTFIT, function(data)
    Ped.ApplyOutfit(data)
end)

RegisterNetEvent("kt_character:applyOutfit", function(data)
    Ped.ApplyOutfit(data)
end)

-- ── IDENTIFIANT ───────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.S2C_SEND_IDENTIFIER, function(license, unique_id)
    State.identifier      = license or ""
    State.currentUniqueId = unique_id or State.currentUniqueId
end)

-- ── CLEANUP ───────────────────────────────────────────────────────────────

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Preview.IsActive() then Preview.Stop() end
    if Camera.IsActive() then Camera.Destroy() end
end)

AddEventHandler("playerDropped", function()
    State.Reset()
end)

print("^2[kt_character] client events chargés^0")
