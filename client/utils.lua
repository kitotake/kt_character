-- utils.lua

-- se fichier avec se cote est la pour un essai un systeme pour voir si la logique fonctionne correctement ou pas ( donc se code va etre supprimer par la suite ou deplacer dans un autre fichier)
-- Toute la logique d'ouverture du menu de sélection de personnage est dans ce fichier
-- Le serveur déclenche l'ouverture de la NUI via "kt_character:openCharSelect"
-- Le client reçoit ce message et envoie une NUI message pour ouvrir la sélection
-- C'est volontairement simple pour éviter les problèmes de synchronisation entre serveur et client

RegisterNetEvent("kt_character:openCharSelect", function()
    SetNuiFocus(true, true)
print("Opening character selection NUI")

print("Triggering NUI message with characters and slots")
print("Characters:", characters)
print("Slots:", slots or 2)
print("Sending NUI message to open character selection")
print("NUI message content:", {
    action = "openCharacterSelection",
    characters = characters,
    slots = slots or 2
})

    SendNUIMessage({
        action = "openCharacterSelection",
        characters = characters,
        slots = slots or 2
    })
end)