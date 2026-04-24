CreateThread(function()
    Utils.debug("kt_character chargé correctement", "INFO")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- se fichier avec se cote est la pour un essai un systeme pour voir si la logique fonctionne correctement ou pas ( donc se code va etre supprimer par la suite ou deplacer dans un autre fichier)

RegisterCommand("charselect", function(source)
    TriggerClientEvent("kt_character:openCharSelect", source)
end)