-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CLIENT MAIN
-- Point d'entrée minimal — toute la logique est dans client/core/
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Citizen.CreateThread(function()
    Wait(500)
    print("^2[kt_character] v" .. KT.Config.VERSION .. " (client) chargé^0")
end)


-- Ajouter À LA FIN de kt_character/client/main.lua
-- (après que Ped, State, Preview, Camera sont tous initialisés)

-- Signale aux autres ressources que kt_character est pleinement opérationnel.
-- Union attend cet event avant d'appeler Appearance_Apply.
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    -- Légère pause pour que tous les modules Lua soient prêts
    SetTimeout(200, function()
        TriggerEvent("kt_character:clientReady")
        exports("_isReady", function() return true end)
    end)
end)