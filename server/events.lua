AddEventHandler("union:spawn:noCharacters_server", function(src)
    TriggerClientEvent("kt_character:openCreator", src)
end)