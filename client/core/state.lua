-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CLIENT STATE
-- Stocke l'état du personnage actif côté client.
-- Accessible par toutes les ressources via exports kt_character.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

State = {
    currentUniqueId   = nil,
    currentAppearance = {},
    identifier        = "",
}

--- Met à jour l'état après un spawn.
function State.OnSpawn(characterData)
    if not characterData then return end
    State.currentUniqueId   = characterData.unique_id
    State.currentAppearance = characterData
end

--- Réinitialise l'état.
function State.Reset()
    State.currentUniqueId   = nil
    State.currentAppearance = {}
    State.identifier        = ""
end

_G.State = State
