-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CLIENT EXPORTS (API publique)
-- Ces exports sont la seule interface entre kt_character et les autres
-- ressources (kt_clothing, kt_barber, kt_tattoo, kt_dressing...).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ════════════════════════════════════════════════════════════
-- PREVIEW
-- ════════════════════════════════════════════════════════════

--- Démarre la preview (clone ped + caméra optionnelle).
--- @param options table { heading, faceZoom, camera }
--- Exemple : exports["kt_character"]:Preview_Start({ camera = "body" })
exports("Preview_Start", function(options)
    Preview.Start(options)
end)

--- Arrête la preview.
exports("Preview_Stop", function()
    Preview.Stop()
end)

--- Rafraîchit le ped cloné depuis l'apparence actuelle du joueur.
exports("Preview_Refresh", function()
    Preview.Refresh()
end)

--- Change le preset de caméra.
--- @param preset string "face" | "hair" | "body" | "full"
exports("Preview_SetCamera", function(preset)
    if Camera.IsActive() then
        Camera.SetPreset(preset, { interp = true })
    end
end)

--- Gère une action caméra.
--- @param action string "rotateLeft"|"rotateRight"|"zoomIn"|"zoomOut"|"focusHead"|"focusBody"|"focusFull"|"resetCam"
exports("Preview_CameraAction", function(action)
    Camera.HandleAction(action)
end)

--- Fait tourner le ped preview.
--- @param degrees number
exports("Preview_Rotate", function(degrees)
    Preview.Rotate(degrees)
end)

--- Active/désactive le zoom visage.
exports("Preview_SetFaceZoom", function(state)
    Preview.SetFaceZoom(state)
end)

--- Retourne si la preview est active.
exports("Preview_IsActive", function()
    return Preview.IsActive()
end)

--- Retourne le handle du ped preview.
exports("Preview_GetPed", function()
    return Preview.GetPed()
end)

--- Joue une animation sur le ped preview.
exports("Preview_PlayAnim", function(dict, anim)
    Preview.PlayAnim(dict, anim)
end)

--- Remet l'animation idle.
exports("Preview_ResetAnim", function()
    Preview.ResetAnim()
end)

-- ════════════════════════════════════════════════════════════
-- APPARENCE — APPLICATION SUR LE PED PREVIEW
-- Ces exports sont utilisés par les UIs des ressources pour
-- voir le résultat en temps réel sans toucher au joueur.
-- ════════════════════════════════════════════════════════════

--- Applique une apparence complète sur le ped preview.
--- Utilisé par kt_creation pour la preview en temps réel.
exports("Preview_ApplyAppearance", function(data)
    if not Preview.IsActive() then return end
    Ped.ApplyFullAppearance(Preview.GetPed(), data)
end)

--- Applique uniquement des vêtements sur le ped preview.
--- Utilisé par kt_clothing, kt_dressing.
exports("Preview_ApplyClothing", function(components, props)
    if not Preview.IsActive() then return end
    Ped.ApplyClothing(Preview.GetPed(), components, props)
end)

--- Applique uniquement la coiffure sur le ped preview.
--- Utilisé par kt_barber.
exports("Preview_ApplyHair", function(hair)
    if not Preview.IsActive() then return end
    Ped.ApplyHair(Preview.GetPed(), hair)
end)

--- Applique uniquement les tatouages sur le ped preview.
--- Utilisé par kt_tattoo.
exports("Preview_ApplyTattoos", function(tattoos, clearFirst)
    if not Preview.IsActive() then return end
    Ped.ApplyTattoos(Preview.GetPed(), tattoos, clearFirst)
end)

--- Applique une apparence partielle sur le ped preview (champs optionnels).
--- Utilisé pour la synchronisation temps réel fine.
exports("Preview_ApplyPartial", function(data)
    if not Preview.IsActive() then return end
    Ped.ApplyPreview(Preview.GetPed(), data)
end)

-- ════════════════════════════════════════════════════════════
-- APPARENCE — APPLICATION SUR LE JOUEUR
-- ════════════════════════════════════════════════════════════

--- Applique une apparence complète sur le joueur.
exports("Appearance_Apply", function(data)
    Ped.ApplyFullAppearance(PlayerPedId(), data)
end)

--- Applique uniquement des vêtements sur le joueur.
exports("Appearance_ApplyClothing", function(components, props)
    Ped.ApplyClothing(PlayerPedId(), components, props)
end)

--- Applique uniquement la coiffure sur le joueur.
exports("Appearance_ApplyHair", function(hair)
    Ped.ApplyHair(PlayerPedId(), hair)
end)

--- Applique uniquement les tatouages sur le joueur.
exports("Appearance_ApplyTattoos", function(tattoos, clearFirst)
    Ped.ApplyTattoos(PlayerPedId(), tattoos, clearFirst)
end)

--- Applique une tenue (components + props) sur le joueur.
exports("Appearance_ApplyOutfit", function(data)
    Ped.ApplyOutfit(data)
end)

-- ════════════════════════════════════════════════════════════
-- DONNÉES
-- ════════════════════════════════════════════════════════════

--- Retourne le unique_id du personnage actif.
exports("Character_GetUniqueId", function()
    return State.currentUniqueId
end)

--- Retourne l'apparence actuelle du personnage.
exports("Character_GetCurrentAppearance", function()
    return State.currentAppearance
end)

--- Retourne l'identifiant (license) du joueur.
exports("Character_GetIdentifier", function()
    return State.identifier
end)
