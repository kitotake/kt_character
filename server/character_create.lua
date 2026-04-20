-- server/character_create.lua

RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source

    local isValid, msg = Validator.character(data)
    if not isValid then
        TriggerClientEvent("kt_character:error", src, msg)
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then return end

    -- ✅ unique_id SAFE
    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = "chr_" .. exports['union']:generateUniqueId()
    end

    local genderEnum = Utils.modelToGenderEnum(data.gender)

    local character = {
        identifier = license,
        unique_id  = unique_id,
        firstname  = string.trim(data.firstname),
        lastname   = string.trim(data.lastname),
        position   = Config.DEFAULT_SPAWN,
        heading    = Config.DEFAULT_HEADING
    }

    exports.oxmysql:execute(
        "INSERT INTO characters (identifier, unique_id, firstname, lastname) VALUES (?, ?, ?, ?)",
        {character.identifier, character.unique_id, character.firstname, character.lastname}
    )

    TriggerClientEvent("kt_character:created", src, character)
end)